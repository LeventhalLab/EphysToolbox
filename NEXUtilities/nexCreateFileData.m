function [ nexFile ] = nexCreateFileData( timestampFrequency )
% [nexFile] = nexCreateFileData(timestampFrequency) -- creates empty nex file data structure
%
% INPUT:
%   timestampFrequency - timestamp frequency in Hertz
%
    nexFile.version = 100;
    nexFile.comment = '';
    nexFile.freq = timestampFrequency;
    nexFile.tbeg = 0;
    nexFile.tend = 10; % fake end time of 10 time ticks
end

