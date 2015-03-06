function wireSigma = extractSigma_snle(hsdFile, wireList, numSigmaSegments, t_chunk, r_upsample, varargin)
%
% usage: wireSigma = extractSigma_snle(hsdFile, wireList, numSigmaSegments,
%   chunkSize)
%
% INPUTS:
%   hsdFile - name of the .hsd file
%   wireList - list of wires in the original .hsd file for which to
%       calculate the standard deviation of the signal
%   numSigmaSegments - number of segments to use in calculating sigma
%   chunkSize - size of each data segment to use in calculating sigma
%
% VARARGs:
%   'datatype' - type of data; default int16
%   'machineformat' - machine format for reading the binary data (ie, 'b'
%       for big-endian, 'l' for little-endian)
%   'snlewindow' - window width for the smoothed nonlinear energy
%       calculation
%
% OUTPUTS:
%   wireSigma - vector containing the standard deviation of the signal on
%       each wire in wireList

dataType      = 'int16';
machineFormat = 'b';
windowSize    = 12 * r_upsample;
upsample      = true;   % whether to perform sinc interpolation to upsample
                        % the waveforms
sincLength    = 13;     % length of sinc function for sinc interpolation
maxLevel      = 0;
maxSNLE       = 10^7;   % maximum allowable non-linear energy. Any values 
                        % greater than this are assumed to be noise and
                        % are not included in the standard deviation
                        % calculations (but are thresholded and
                        % extracted as potential spikes)

for iarg = 1 : 2 : nargin - 5
    
    switch lower(varargin{iarg})

        case 'datatype',
            dataType = varargin{iarg + 1};
        case 'machineformat',
            machineFormat = varargin{iarg + 1};
        case 'snlewindow',
            windowSize = varargin{iarg + 1};
        case 'upsample',
            upsample = varargin{iarg + 1};
        case 'maxlevel',
            maxLevel = varargin{iarg + 1};
        case 'sinclength',
            sincLength = varargin{iarg + 1};
        case 'maxsnle',
            maxSNLE = varargin{iarg + 1};
    end
    
end
r_upsample = round(r_upsample);
%maxLevel   = r_upsample + 1; % old (probably bug!)
%maxLevel = r_upsample + 5;  % new (changed by RS) % actually dont set here
%because it should be set by the input

% get the hsd header
hsdInfo    = dir(hsdFile);
hsdHeader  = getHSDHeader(hsdFile);
dataOffset = hsdHeader.dataOffset;
Fs         = hsdHeader.main.sampling_rate;
final_Fs   = Fs * r_upsample;

goodWires    = zeros(size(wireList));

numChannels  = hsdHeader.main.num_channels;
samplingrate = hsdHeader.main.sampling_rate;
datalength   = (hsdInfo.bytes - dataOffset) / (2 * numChannels);   % assumes 16-bit integers

chunkSize = t_chunk * samplingrate;

%padLength = (datalength - chunkSize * numSigmaSegments) / numSigmaSegments;
padLength = floor((datalength - chunkSize * numSigmaSegments) / numSigmaSegments);
%RS2012: added rounding for potential bug fix

if padLength < 0
    if datalength/samplingrate < 70
        padLength = 0;
        chunkSize = datalength;
        padLength = 0;
        numSigmaSegments = 1;
    else
        numSigmaSegments = floor(datalength / samplingrate);
        chunkSize = samplingrate;
        padLength = 0;
    end
end

numWires   = length(wireList);
totSamples = chunkSize * numSigmaSegments;

wireSamps = zeros(totSamples, numWires);

% check which wires have been labelled good or bad
for iWire = 1 : numWires
    for iCh = 1 : numChannels
        if hsdHeader.channel(iCh).original_number == wireList(iWire)
            goodWires(iWire) = hsdHeader.channel(iCh).good;
            break;
        end
    end
end

wireSampIdx = 1;
readStartSamp = 1;
for iChunk = 1 : numSigmaSegments
    %figure
    disp(['Calculating standard deviation(s) for chunk ' num2str(iChunk) ' of ' num2str(numSigmaSegments)]);
    for iWire = 1 : numWires
        if goodWires(iWire)
            temp = readSingleWire_bySamples( hsdFile, wireList(iWire), ...
                readStartSamp, chunkSize, 'datatype', dataType, 'machineformat', machineFormat);
          %  disp(readStartSamp)
          %  subplot(4,1,iWire)
          %  plot(temp)
          %  title(num2str(readStartSamp))
            cutoff_Fs = hsdHeader.channel(wireList(iWire)).high_cut;
            temp = sincInterp(temp, Fs, cutoff_Fs, final_Fs, 'sinclength', sincLength);
          % subplot(4,1,iWire)
          % plot(temp)
            temp = wavefilter(temp', maxLevel);
          %  subplot(4,1,iWire)
          %  plot(temp)
            SNLEdata = snle( temp, true, 'windowsize', windowSize );
          %  subplot(4,1,iWire)
          %  plot(SNLEdata)
            wireSamps(wireSampIdx : wireSampIdx + chunkSize * r_upsample - 1, iWire) = SNLEdata;
        end
    end
    wireSampIdx = wireSampIdx + chunkSize * r_upsample;
    readStartSamp = readStartSamp + chunkSize + padLength;
end

%wireSamps(wireSamps > maxSNLE) = NaN;
%wireSigma = nanstd(wireSamps, 0, 1); % the two methods to choose from...
wireSigma = nanmedian((wireSamps / .6745), 1);

wireSigma = wireSigma';