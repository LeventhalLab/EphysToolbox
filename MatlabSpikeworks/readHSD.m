function rawData = readHSD( fn, numWires, dataOffset, Fs, timeLimits, varargin )
% function to read in raw data from an hsd/hsdw file given the filename,
% number of channels, data offset, sampling rate, and timelimits
%
% data = readHSD(filename, numWires, dataOffset, Fs, timeLimits, varargin)
%
% INPUTS:
%   fn = name of the .hsd file
%   numWires - number of wires contained in the .hsd file (ie, 81 for a
%       standard Berke lab 21-tetrode drive)
%   dataOffset - number of bytes in header (before data actually start);
%       20*1024 = 20480 for the standard Berke lab .hsd as of 3/2012
%   Fs = sampling rate in Hz; typically 31250 for Berke .hsds as of 3/2012
%   timeLimits - 2-element vector containing start and end times to read
%       (in seconds)
%
% VARARGs:
%   datatype - data type for the binary file (ie, 'int16')
%   bitorder - big vs little-endian; 'b' = big endian, 'l' = little endian
%       Berke lab labView vi's write data big-endian
%   usesamplelimits - instead of using timeLimits to determine which
%       samples to extract, user provides a 2-element vector, where the
%       first element is the sample at which to start reading, and the
%       second element is the number of samples to read.
%
% OUTPUTS:
%   rawData - m x n array containing the .hsd data, where m is the number
%       of wires, and n is the number of samples

dataType = 'int16';
bitOrder = 'b';

startSample = 0;
numSamples  = 0;
for iarg = 1 : 2 : nargin - 5
    switch lower(varargin{iarg})
        case 'datatype',
            dataType = varargin{iarg + 1};
        case 'bitorder',
            bitOrder = varargin{iarg + 1};
        case 'usesamplelimits',
            startSample = varargin{iarg + 1}(1);
            numSamples  = varargin{iarg + 1}(2);
    end
end

fin = fopen(fn, 'r');

bytes_per_sample = getBytesPerSample( dataType );

if startSample == 0
    startSample = floor( Fs * timeLimits(1));
    numSamples  = round(Fs * range(timeLimits));
end

startPosition = dataOffset + startSample * numWires * bytes_per_sample;
fseek(fin, startPosition, 'bof');

% if fn(length(fn)) == 'd'    % this is a .hsd file
    
    if or(strcmp(fn(length(fn) - 7 : length(fn)), 'wire.hsd'), ...
          strcmp(fn(length(fn) - 7 : length(fn)), '.lfp.hsd'));    % this is a single wire file or lfp file
        [rawData, ~] = fread(fin, [numWires, numSamples], dataType);
    else            % this is a .hsd or .hsdf file
        [rawData, ~] = fread(fin, [numWires, numSamples], dataType, 0, bitOrder);
    end
    
% else    % this is a .hsdw file
    
%    [rawData, number_elements_read] = fread(fin, [numWires, numSamples], 'int16');
    
% end    
    

fclose(fin);