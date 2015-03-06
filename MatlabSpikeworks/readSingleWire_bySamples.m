function [out] = readSingleWire_bySamples( fn, wireNum, startSample, numSamples, varargin )
% function to read in a single wire of raw data from an hsd/hsdw file given
% the filename, number of channels, data offset, sampling rate, and
% timelimits
%
% out = readSingleWire( fn, wireNum, varargin )
%
% USAGE:
% fn = 'myWonderfulData.hsd';
% numChannels = 81;
% dataOffset = 20*1024; % this accounts for the header data
% Fs = 31250;
% timeLimits = [0 30]; % read the first 30 seconds
% data = readHSD( filename, numWires, dataOffset, Fs, timeLimits )
%
% VARARGs:
%   'timelimits' - 2-element vector with start time and end time to read in
%      (in seconds). Default is the full recording.
%   'datatype' - type of data; default int16
%   'machineformat' - machine format for reading the binary data (ie, 'b'
%       for big-endian, 'l' for little-endian)

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

bytes_per_sample = getBytesPerSample( dataType );
hsd_header = getHSDHeader( fn );

numChannels = hsd_header.main.num_channels;
dataOffset = hsd_header.dataOffset;

% check which wire is being pulled out (for example, the nth row in the
% data array may not be the nth wire)
channelNum = 0;
for iChannel = 1 : numChannels
    if hsd_header.channel(iChannel).original_number == wireNum
        channelNum = iChannel;
        break;
    end
end

if ~ channelNum
    % there were no matches for the target wire number in the hsd header
    disp(['Error in readSingleWire - wire ' num2str(wireNum) ' was not found in the list of channels in the file header.']);
    out = 0;
    return;
end

fin = fopen(fn, 'r');

startPosition = dataOffset + (startSample * numChannels + (channelNum - 1)) * bytes_per_sample;
skipBytes = (numChannels - 1) * bytes_per_sample;


fseek( fin, startPosition, 'bof' );
% if strcmp(fn(length(fn) - 3 : length(fn)), '.hsd')
[out, ~] = fread(fin, numSamples, dataType, skipBytes, machineFormat);
% elseif strcmp(fn(length(fn) - 4 : length(fn)), '.hsdf')
%     [out, number_elements_read] = fread(fin, numSamples, dataType, skipBytes);
% end

fclose(fin);