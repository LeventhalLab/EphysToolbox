function extract_timestamps( hsdFile, targetDir, wireList, thresholds, varargin )
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
%   maxlevel - maximum level for the wavelet filter (default 6)
%   wavelength - duration of waveforms in samples
%   peakloc - location of peaks within waveforms in samples
%   deadtime - dead time required before detecting another spike, in
%       samples
%


maxLevel   = 6;
deadTime   = 16;
peakLoc    = 8;
waveLength = 24;

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
    end
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
numWires   = hsdHeader.main.num_channels;
datalength = (hsdInfo.bytes - dataOffset) / (bytes_per_sample * numWires);

blockSize   = round(Fs * 10);    % process 10 sec at a time
overlapSize = round(Fs * 0.1);   % 100 ms overlap between adjacent blocks 
                                 % to avoid edge effects

% make sure wireList and thresholds are column vectors
if size(wireList, 1) < size(wireList, 2); wireList = wireList'; end
if size(thresholds, 1) < size(thresholds, 2); thresholds = thresholds'; end

goodWires = zeros(length(wireList), 1);
for iWire = 1 : length(wireList)
    goodWires(iWire) = hsdHeader.channel(wireList(iWire)).good;
end
% is it more efficient to read single wires in sequence, or read in a big
% chunk of data including all wires, then pull out the one to four wires of
% interest? I think the latter... - DL 3/27/2012

numBlocks = ceil(datalength / blockSize);
% numBlocks = 2;                          % just for debugging
% datalength = round(blockSize * 1.5);    % just for debugging
% first, pull out the timestamps.
all_ts    = [];
for iBlock = 1 : numBlocks

    disp(['Finding timestamps for block ' num2str(iBlock) ' of ' num2str(numBlocks)]);
    
    currentTime = (iBlock - 1) * blockSize;
    
    % get overlapSize samples on either side of each block to prevent edge
    % effects (may not be that important, but it's easy to do)
    startSample = max(1, currentTime - overlapSize);
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
    
    % wavelet filter the raw data
    % Don't bother to do the calculations for noisy wires.
    fdata = wavefilter(rawData, goodWires, maxLevel);
    
    % calculate the smoothed nonlinear energy of the wavelet filtered data.
    % Don't bother to do the calculations for noisy wires.
    SNLEdata = snle( fdata, goodWires, 'windowsize', 12 );   % 12 is Alex's default window size
%     if iBlock == 1
%         fdata    = fdata(:, 1 : blockSize);
%         SNLEdata = SNLEdata(:, 1 : blockSize);
%     elseif iBlock == numBlocks
%         fdata    = fdata(:, overlapSize + 2 : end);
%         SNLEdata = SNLEdata(:, overlapSize + 2 : end);
%     else
%         fdata    = fdata(:, overlapSize + 2 : overlapSize + 1 + blockSize);
%         SNLEdata = SNLEdata(:, overlapSize + 2 : overlapSize + 1 + blockSize);
%     end
    
    % extract the timestamps of peaks in the smoothed non-linear energy
    % signal that are above threshold. Exclude wires with noisy recordings
    % from timestamp extraction.
    ts = gettimestampsSNLE(SNLEdata, thresholds, goodWires, 'deadtime', deadTime);
    
    % make sure peaks above threshold are not contained in the overlap
    % regions for adjacent blocks of data (and also that the first peak
    % location has enough data before it to extract a full waveform, and
    % the last spike has enough data after it to extract the full
    % waveform).
    switch iBlock
        case 1,
            ts = ts(ts > peakLoc & ts <= blockSize);
        case numBlocks,
            ts = ts(ts >= overlapSize + 2 & ts < length(ts) - (waveLength - peakLoc)) - ...
                (overlapSize + 1);
        otherwise,
            ts = ts(ts >= overlapSize + 2 & ts <= overlapSize + 1 + blockSize) - ...
                (overlapSize + 1);
    end
    % NOTE: ts is timestamps in samples, not in real time. Divide by the
    % sampling rate to get real time
    
%     if isempty(waveforms)
%         waveforms = extractWaveforms(fdata, ts, peakLoc, waveLength);
%     else
%         waveforms = [waveforms, extractWaveforms(fdata, ts, peakLoc, waveLength)];
%     end
    
    ts = ts + currentTime;
    all_ts = [all_ts, ts];
    
end
all_ts = all_ts';   % all_ts should be a column vector for the routines that write to .nex files

% write the timestamps into a .nex file
nexStruct = nexCreateFileData( Fs );
nex_fn    = createNexName( hsdFile, targetDir, wireList );

for iWire = 1 : length(wireList)
    nexStruct.waves{iWire, 1}.name        = sprintf('w%02d', iWire);
    nexStruct.waves{iWire, 1}.NPointsWave = waveLength;
    nexStruct.waves{iWire, 1}.WFrequency  = Fs;
    nexStruct.waves{iWire, 1}.timestamps  = all_ts / Fs;
    nexStruct.waves{iWire, 1}.waveforms   = zeros(waveLength, 1);
    nexStruct.waves{iWire, 1}.ADtoMV      = (range(ADrange) / 2 ^ ADprecision * 1000) / ...
                                            hsdHeader.channel(wireList(iWire)).gain;
    nexStruct.waves{iWire, 1}.wireNumber  = wireList(iWire);
end

writeNexHeader( nexStruct, nex_fn );
for iWire = 1 : length(wireList)
    writeNex_wf_ts( nex_fn, iWire, all_ts );
end

% now, pull out the waveforms corresponding to the timestamps
numSamplesWritten = 0;
for iBlock = 1 : numBlocks
    
    disp(['extracting waveforms for block ' num2str(iBlock) ' of ' num2str(numBlocks)]);
    
    currentTime = (iBlock - 1) * blockSize;
    startSample = max(1, currentTime - overlapSize);
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
    
    % wavelet filter the raw data; here, do all the wires so noisy wires
    % are included in the final .nex file.
    fdata = wavefilter(rawData, ones(length(wireList), 1), maxLevel);
%     if iBlock == 1
%         fdata        = fdata(:, 1 : blockSize);
%         timeInterval = (ts <= 
%     elseif iBlock == numBlocks
%         fdata        = fdata(:, overlapSize + 2 : end);
%     else
%         fdata        = fdata(:, overlapSize + 2 : overlapSize + 1 + blockSize);
%     end
    ts = all_ts(all_ts > currentTime & all_ts <= currentTime + blockSize);
    if iBlock > 1
        ts = ts - currentTime + overlapSize;
    end
    waveforms = extractWaveforms(fdata, ts, peakLoc, waveLength);
    
    for iWire = 1 : length(wireList)
        wf = squeeze(waveforms(:, :, iWire))';
        if ~isempty(wf)
            appendNexWaveforms( nex_fn, iWire, numSamplesWritten, wf);
        end
    end
    numSamplesWritten = numSamplesWritten + length(ts);
    
end
% may have to write timestamps into the .nex file first, then go back and
% put the waveforms in to avoid overflowing memory (and keep the ordering
% of data in the .nex file intact



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