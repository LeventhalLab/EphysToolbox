function extract_PLXtimestamps_sincInterp( hsdFile, targetDir, wireList, thresholds, varargin )
%
% usage: extract_timestamps( hsdFile, wireList, thresholds, varargin )
%
% INPUTS:
%   hsdFile - string containing the name of the .hsd file (include the full
%       path)
%   targetDir - directory in which to save the .nex file
%   wireList - vector containing the list of wires for this
%       tetrode/stereotrode
%   thresholds - vector containing the thresholds for each wire in wireList
%
% VARARGs:
%   datatype - data type in binary file (ie, 'int16')
%   maxlevel - maximum level for the wavelet filter (default 5 + the
%       upsampling ratio)
%   wavelength - duration of waveforms in samples
%   peakloc - location of peaks within waveforms in samples
%   deadtime - dead time required before detecting another spike, in
%       samples
%   upsample - boolean indicating whether or not to upsample the signal
%   sinclength - length of the sinc function to use for upsampling
%   upsampleratio - ratio by which to upsample the signal (ie, a value of 2
%       would take Fs from, for example, 30 kHz to 60 kHz)

deadTime   = 16;     % dead time after a spike within which another spike
                     % cannot be detected on the same wire (in samples)
peakLoc    = 8;      % number of samples to look backwards from a peak (ie,
                     % peaks should be aligned peakLoc samples into each
                     % waveform
waveLength = 24;     % duration of each waveform in number of samples
upsample   = true;   % whether to perform sinc interpolation to upsample
                     % the waveforms
sincLength = 13;     % length of sinc function for sinc interpolation
r_upsample = 2;      % upsampling ratio - ie, if original Fs = 31250 and
                     % r_upsample = 2, the sampling rate for each waveform
                     % will be 62500 Hz.
maxLevel   = 0;      % max level for wavelet filtering

overlapTolerance = 1;

% note that deadTime, peakLoc, waveLength, and sincLength are in units of
% number of samples for the ORIGINAL signal. That is, if the signal is
% upsampled by a factor of 2, the deadTime, etc. written to the .plx file
% will be 2 * the deadTime supplied above (or as a varargin).

dataType = 'int16';

for iarg = 1 : 2 : nargin - 4
    switch lower(varargin{iarg})
        case 'datatype',
            dataType = varargin{iarg + 1};
        case 'maxlevel',
            maxLevel = varargin{iarg + 1};
        case 'wavelength',
            waveLength = varargin{iarg + 1};
        case 'peakloc',
            peakLoc = varargin{iarg + 1};
        case 'deadtime',
            deadTime = varargin{iarg + 1};
        case 'upsample',
            upsample = varargin{iarg + 1};
        case 'sinclength',
            sincLength = varargin{iarg + 1};
        case 'upsampleratio',
            r_upsample = varargin{iarg + 1};
        case 'overlaptolerance',
            overlapTolerance = varargin{iarg + 1};
    end
end

r_upsample = round(r_upsample);
if ~upsample
    r_upsample = 1;   % for later on to make sure timestamps in the .nex file are interpreted correctly
end

if maxLevel == 0
    maxLevel = r_upsample + 5;      % cutoff frequency = samplingrate/(2^(maxlevel+1))
                                    % this should make the cutoff frequency
                                    % ~230 Hz for an initial sampling rate
                                    % of ~30 kHz. For an initial sampling
                                    % rate of 20 kHz, the cutoff will be
                                    % ~150 Hz. May want to use r_upsample +
                                    % 4 if Fs = 20 kHz (cutoff ~300 Hz)
end

bytes_per_sample = getBytesPerSample( dataType );
switch dataType
    case 'int16',
        ADprecision = 16;   % bits
end
ADrange = [-10 10];

hsdInfo    = dir(hsdFile);
hsdHeader  = getHSDHeader( hsdFile );
Fs         = hsdHeader.main.sampling_rate;
dataOffset = hsdHeader.dataOffset;
numWires   = hsdHeader.main.num_channels;   % total number of wires in the .hsd file
datalength = (hsdInfo.bytes - dataOffset) / (bytes_per_sample * numWires);

blockSize   = round(Fs * 10);    % process 10 sec at a time
overlapSize = round(Fs * 0.1);   % 100 ms overlap between adjacent blocks 
                                 % to avoid edge effects
final_Fs         = r_upsample * Fs;
final_peakLoc    = r_upsample * peakLoc;
final_waveLength = r_upsample * waveLength;

% make sure wireList and thresholds are column vectors
if size(wireList, 1) < size(wireList, 2); wireList = wireList'; end
if size(thresholds, 1) < size(thresholds, 2); thresholds = thresholds'; end

takeAllWires = ones(length(wireList), 1); % added by RS to preserve signal from all wires
goodWires = zeros(length(wireList), 1);
for iWire = 1 : length(wireList)
    goodWires(iWire) = hsdHeader.channel(wireList(iWire)).good;
end
% is it more efficient to read single wires in sequence, or read in a big
% chunk of data including all wires, then pull out the one to four wires of
% interest? I think the latter... - DL 3/27/2012

numBlocks = ceil(datalength / blockSize);

%numBlocks = 3;                          % just for debugging
%datalength = round(blockSize * (numBlocks - 0.5));    % just for debugging

% write the .plx header
PLX_fn = createPLXName( hsdFile, targetDir, wireList );

plxInfo.comment    = hsdHeader.comment;
plxInfo.ADFs       = final_Fs;           % record the upsampled Fs as the AD freq for timestamps
plxInfo.numWires   = length(wireList);
plxInfo.numEvents  = 0;
plxInfo.numSlows   = 0;
plxInfo.waveLength = final_waveLength;
plxInfo.peakLoc    = final_peakLoc;

dateVector = datevec(hsdHeader.date, 'yyyy-mm-dd');
plxInfo.year       = dateVector(1);
plxInfo.month      = dateVector(2);
plxInfo.day        = dateVector(3);

timeVector = datevec(hsdHeader.time, 'HH:MM');
plxInfo.hour       = timeVector(4);
plxInfo.minute     = timeVector(5);
plxInfo.second     = 0;
plxInfo.waveFs     = final_Fs;          % record the upsampled Fs as the waveform sampling frequency
plxInfo.dataLength = datalength * r_upsample;

% plxInfo.next4fields = sprintf('%02d%02d%02d%02d', length(wireList), 1, 16, 16);
% plxInfo.next4fields = ['\x0' num2str(length(wireList)) '\x01\x0c\x0c'];
plxInfo.Trodalness     = length(wireList);   % modified from = 1 on 6/20/2012
plxInfo.dataTrodalness = 1;

plxInfo.bitsPerSpikeSample = 16;
plxInfo.bitsPerSlowSample  = 16;

plxInfo.SpikeMaxMagnitudeMV = 10000;    % +/- 10 V dynamic range on DAQ cards
plxInfo.SlowMaxMagnitudeMV  = 10000;    % +/- 10 V dynamic range on DAQ cards (probably not relevant for Berke lab systems)
plxInfo.SpikePreAmpGain     = 1;        % gain before final amplification stage

PLXid = fopen(PLX_fn, 'w');
writePLXheader( PLXid, plxInfo );

subjectName = strrep(hsdHeader.subject, '-', '');   % get rid of any hyphens in the subject name
dateString  = sprintf('%04d%02d%02d', plxInfo.year, plxInfo.month, plxInfo.day);
baseName    = [subjectName dateString];
for iWire = 1 : length(wireList)
    switch length(wireList)
        case 1,   % single wire/recording site
            chInfo.wireName = sprintf('%sW%02d', ...
                                      baseName, ...
                                      hsdHeader.channel(wireList(iWire)).wire_number);
            chInfo.tetName  = sprintf('%sW%02d', ...
                                      baseName, ...
                                      hsdHeader.channel(wireList(iWire)).wire_number);
        case 2,   % stereotrode ("ref")
%             chInfo.wireName = sprintf('%sR%02dW%02d', ...
%                                       baseName, ...
%                                       hsdHeader.channel(wireList(iWire)).channel_number, ...
%                                       hsdHeader.channel(wireList(iWire)).wire_number);
%             chInfo.tetName  = sprintf('%sR%02d', ...
%                                       baseName, ...
%                                       hsdHeader.channel(wireList(iWire)).channel_number);
            chInfo.wireName = sprintf('%sR%02d', ...
                                      baseName, ...
                                      hsdHeader.channel(wireList(iWire)).channel_number);
                                  % RS removed actual Wire number for
                                  % consistency and file name conventions
            chInfo.tetName = ['Tetrode SIG ' num2str(hsdHeader.channel(wireList(iWire)).wire_number)];                                  
             % we dont know what tetrode name is used for...                     
                                  
        case 4,   % tetrode
%             chInfo.wireName = sprintf('%sT%02dW%02d', ...
%                                       baseName, ...
%                                       hsdHeader.channel(wireList(iWire)).channel_number, ...
%                                       hsdHeader.channel(wireList(iWire)).wire_number);
            chInfo.wireName = sprintf('%sT%02d', ...
                                      baseName, ...
                                      hsdHeader.channel(wireList(iWire)).channel_number);
                                  % RS removed actual Wire number for
                                  % consistency and file name conventions
            chInfo.tetName = ['Tetrode SIG ' num2str(hsdHeader.channel(wireList(iWire)).wire_number)];
            % changed by RS 
%             chInfo.tetName  = sprintf('%sT%02d', ...
%                                       baseName, ...
%                                       hsdHeader.channel(wireList(iWire)).channel_number);
    end
                                  
    chInfo.wireNum   = iWire;
    chInfo.WFRate    = final_Fs;
    %chInfo.SIG       = iWire;   % not sure what SIG is in plexon parlance; hopefully this just works
    chInfo.SIG       = hsdHeader.channel(wireList(iWire)).channel_number;   % changed by RS: i think in Alex code SIG refers to tetrode number
    chInfo.refWire   = 0;    % not sure exactly what this is; Alex had it set to zero
    chInfo.gain      = hsdHeader.channel(wireList(iWire)).gain;
    chInfo.filter    = 0;    % not sure what this is; Alex had it set to zero
    chInfo.thresh    = int32(thresholds(iWire));
    chInfo.numUnits  = 0;    % no sorted units
    chInfo.sortWidth = final_waveLength;
    chInfo.comment   = 'created by extractSpikes.m';
    
    writePLXChanHeader( PLXid, chInfo );
end

for iBlock = 1 : numBlocks

    disp(['Finding timestamps and extracting waveforms for block ' num2str(iBlock) ' of ' num2str(numBlocks)]);
    
    rawData_curSamp   = (iBlock - 1) * blockSize;
    upsampled_curSamp = rawData_curSamp * r_upsample;
    
    % get overlapSize samples on either side of each block to prevent edge
    % effects (may not be that important, but it's easy to do)
    startSample = max(1, rawData_curSamp - overlapSize);
    if iBlock == 1
        numSamples  = blockSize + overlapSize;
    elseif iBlock == numBlocks
        numSamples = datalength - startSample + 1;
    else
        numSamples = blockSize + 2 * overlapSize;
    end
    
    rawData = readHSD(hsdFile, numWires, dataOffset, Fs, [], ...
        'usesamplelimits', [startSample, numSamples]);
    
    rawData = rawData(wireList, :);
    if upsample
        interp_rawData = zeros(size(rawData, 1), size(rawData, 2) * r_upsample);
        for iWire = 1 : size(rawData, 1)
            cutoff_Fs = hsdHeader.channel(wireList(iWire)).high_cut;
            interp_rawData(iWire, :) = sincInterp(rawData(iWire, :), Fs, ...
                cutoff_Fs, final_Fs, 'sinclength', sincLength);
        end
        %fdata = wavefilter(interp_rawData, goodWires, maxLevel);
        fdata = wavefilter(interp_rawData, takeAllWires, maxLevel); % changed by RS
    else
        % wavelet filter the raw data
        % Don't bother to do the calculations for noisy wires.
        %fdata = wavefilter(rawData, goodWires, maxLevel);
        fdata = wavefilter(rawData, takeAllWires, maxLevel); % changed by RS
    end
    
    % calculate the smoothed nonlinear energy of the wavelet filtered data.
    % Don't bother to do the calculations for noisy wires.
    % RS: actually DO bother to do the calculation because we want to
    % preserve even noisy signals to see them in offline sorter (see fdata above!)
    
    SNLEdata = snle( fdata, goodWires, 'windowsize', 12 * r_upsample );   % 12 is Alex's default window size
    %plot(SNLEdata)
    %title('snledata')
    
    % changed by RS to include upsampling rate
    
    % extract the timestamps of peaks in the smoothed non-linear energy
    % signal that are above threshold. Exclude wires with noisy recordings
    % from timestamp extraction.
    ts = gettimestampsSNLE(SNLEdata, thresholds, goodWires, ...
                           'deadtime', deadTime * r_upsample, ...
                           'overlaptolerance', overlapTolerance * r_upsample);
    
    % make sure peaks above threshold are not contained in the overlap
    % regions for adjacent blocks of data (and also that the first peak
    % location has enough data before it to extract a full waveform, and
    % the last spike has enough data after it to extract the full
    % waveform).
    switch iBlock
        case 1,
            block_ts = ts(ts > final_peakLoc & ts <= blockSize * r_upsample);
            ts = block_ts;
        case numBlocks,
            block_ts = ts((ts >= overlapSize * r_upsample + 2) & ...
                      (ts < (size(SNLEdata,2) - (final_waveLength - final_peakLoc))));
            ts = block_ts - (overlapSize * r_upsample + 1);
        otherwise,
            block_ts = ts((ts >= overlapSize * r_upsample + 2) & ...
                 (ts <= overlapSize * r_upsample + 1 + blockSize * r_upsample));
            ts = block_ts - (overlapSize * r_upsample + 1);
    end
    % NOTE: ts is timestamps in samples, not in real time. Divide by the
    % sampling rate to get real time
    
    if isempty(ts); continue; end
    
    waveforms = extractWaveforms(fdata, block_ts, final_peakLoc, final_waveLength);
    %plot(waveforms)
    %title('waveforms')
    
    %   waveforms - m x n x p matrix, where m is the number of timestamps
    %   (spikes), n is the number of points in a single waveform, and p is
    %   the number of wires

    ts = ts + upsampled_curSamp;
    
    writePLXdatablock( PLXid, waveforms, ts );
    
end

fclose(PLXid);


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function nexName = createNexName( hsdFile, targetDir, wireList )
%
% usage: nexName = createNexName( hsdFile, wireList )
%
% INPUTS:
%   hsdFile - name of the .hsd file
%   targetDir - target directory in which to save the .nex file
%   wireList - wires on which to extract spiked
%
% OUTPUTS:
%   nexName - name of the .nex file to create for this
%       tetrode/stereotrode/single wire. It is made by taking the name of
%       the .hsd file, which is assumed to be of the form:
%           XXXX_YYYYMMDD_HH-MM-SS.hsd,
%       where XXXX is the animal identifier, YYYYMMDD is the date of the
%       recording, and HH-MM-SS is the time. To the name of the .hsd file,
%       '_ZZZ' is appended, where ZZZ is the name of the channel on which
%       spikes are being extracted (ie, 'T01' = tetrode 1, 'R01' - ref 1,
%       etc. So, the final name is of the form:
%           XXXX_YYYYMMDD_HH-MM-SS_ZZZ.nex

[~, hsdName, ~] = fileparts(hsdFile);

header = getHSDHeader( hsdFile );

chType = header.channel(wireList(1)).channel_type;
chNum  = header.channel(wireList(1)).channel_number;

switch chType
    case 1,     % tetrode
        typeString = 'T';
    case 2,     % ref (stereotrode)
        typeString = 'R';
end

ZZZ = sprintf('%c%02d', typeString, chNum);

nexName = fullfile(targetDir, [hsdName '_' ZZZ '.nex']);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plxName = createPLXName( hsdFile, targetDir, wireList )
%
% usage: nexName = createNexName( hsdFile, wireList )
%
% INPUTS:
%   hsdFile - name of the .hsd file
%   targetDir - target directory in which to save the .nex file
%   wireList - wires on which to extract spiked
%
% OUTPUTS:
%   nexName - name of the .nex file to create for this
%       tetrode/stereotrode/single wire. It is made by taking the name of
%       the .hsd file, which is assumed to be of the form:
%           XXXX_YYYYMMDD_HH-MM-SS.hsd,
%       where XXXX is the animal identifier, YYYYMMDD is the date of the
%       recording, and HH-MM-SS is the time. To the name of the .hsd file,
%       '_ZZZ' is appended, where ZZZ is the name of the channel on which
%       spikes are being extracted (ie, 'T01' = tetrode 1, 'R01' - ref 1,
%       etc. So, the final name is of the form:
%           XXXX_YYYYMMDD_HH-MM-SS_ZZZ.nex

[~, hsdName, ~] = fileparts(hsdFile);

header = getHSDHeader( hsdFile );

chType = header.channel(wireList(1)).channel_type;
chNum  = header.channel(wireList(1)).channel_number;

switch chType
    case 1,     % tetrode
        typeString = 'T';
    case 2,     % ref (stereotrode)
        typeString = 'R';
end

ZZZ = sprintf('%c%02d', typeString, chNum);

plxName = fullfile(targetDir, [hsdName '_' ZZZ '.plx']);

end