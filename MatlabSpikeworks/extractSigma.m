function wireSigma = extractSigma(hsdFile, wireList, numSigmaSegments, t_chunk, varargin)
%
% usage: wireSigma = extractSigma(hsdFile, wireList, numSigmaSegments,
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
%
% OUTPUTS:
%   wireSigma - vector containing the standard deviation of the signal on
%       each wire in wireList

dataType      = 'int16';
machineFormat = 'b';

for iarg = 1 : 2 : nargin - 4
    
    switch lower(varargin{iarg})

        case 'datatype',
            dataType = varargin{iarg + 1};
        case 'machineformat',
            machineFormat = varargin{iarg + 1};

    end
    
end

% get the hsd header
hsdInfo    = dir(hsdFile);
hsdHeader  = getHSDHeader(hsdFile);
dataOffset = hsdHeader.dataOffset;

goodWires    = zeros(size(wireList));

numChannels  = hsdHeader.main.num_channels;
samplingrate = hsdHeader.main.sampling_rate;
datalength   = (hsdInfo.bytes - dataOffset) / (2 * numChannels);   % assumes 16-bit integers

chunkSize = t_chunk * samplingrate;

padLength = (datalength - chunkSize * numSigmaSegments) / numSigmaSegments;

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
    disp(['Calculating standard deviation(s) for chunk ' num2str(iChunk) ' of ' num2str(numSigmaSegments)]);
    for iWire = 1 : numWires
        if goodWires(iWire)
            temp = readSingleWire_bySamples( hsdFile, wireList(iWire), ...
                readStartSamp, chunkSize, 'datatype', dataType, 'machineformat', machineFormat);
            temp = wavefilter(temp', true, 6);    % the max wavelet level may be modified in the future
            wireSamps(wireSampIdx : wireSampIdx + chunkSize - 1, iWire) = temp;
        end
    end
    wireSampIdx = wireSampIdx + chunkSize;
    readStartSamp = readStartSamp + chunkSize + padLength;
end

wireSigma = std(wireSamps, 0, 1);

wireSigma = wireSigma';