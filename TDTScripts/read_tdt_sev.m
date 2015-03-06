function [sev, header] = read_tdt_sev(filename)

% READ_TDT_SEV
%
% Use as
%   sev = read_tdt_sev(filename, dtype, begsample, endsample)
%
% Note: sev files contain raw broadband data that is streamed to the RS4
data = [];
ALLOWED_FORMATS = {'single','int32','int16','int8','double','int64'};
MAP = containers.Map(...
    0:length(ALLOWED_FORMATS)-1,...
    ALLOWED_FORMATS);
fid = fopen(filename, 'rb','ieee-le');

% create and fill streamHeader struct
    streamHeader = [];
    
    streamHeader.fileSizeBytes   = fread(fid,1,'uint64');
    streamHeader.fileType        = char(fread(fid,3,'char')');
    streamHeader.fileVersion     = fread(fid,1,'char');
    
    if streamHeader.fileVersion < 3
        
        % event name of stream
        if streamHeader.fileVersion == 2 
            streamHeader.eventName  = char(fread(fid,4,'char')');
        else
            streamHeader.eventName  = fliplr(char(fread(fid,4,'char')'));
        end
        
        % current channel of stream
        streamHeader.channelNum        = fread(fid, 1, 'uint16');
        % total number of channels in the stream
        streamHeader.totalNumChannels  = fread(fid, 1, 'uint16');
        % number of bytes per sample
        streamHeader.sampleWidthBytes  = fread(fid, 1, 'uint16');
        reserved                 = fread(fid, 1, 'uint16');
        
        % data format of stream in lower four bits
        streamHeader.dForm      = MAP(bitand(fread(fid, 1, 'uint8'),7));
        
        % used to compute actual sampling rate
        streamHeader.decimate   = fread(fid, 1, 'uint8');
        streamHeader.rate       = fread(fid, 1, 'uint16');
        
        % reserved tags
        reserved = fread(fid, 1, 'uint64');
        reserved = fread(fid, 2, 'uint16');
        
    end
    
    if streamHeader.fileVersion > 0
        % determine data sampling rate
        streamHeader.Fs = 2^(streamHeader.rate)*25000000/2^12/streamHeader.decimate;
        % handle multiple data streams in one folder
        exists = isfield(data, streamHeader.eventName);
    else
        streamHeader.dForm = 'single';
        streamHeader.Fs = 0;
        s = regexp(file_list(i).name, '_', 'split');
        streamHeader.eventName = s{end-1};
        streamHeader.channelNum = str2double(regexp(s{end},  '\d+', 'match'));
        warning(sprintf('%s has empty header; assuming %s ch %d format %s\nupgrade to OpenEx v2.18 or above\n', ...
            file_list(i).name, streamHeader.eventName, ...
            streamHeader.channelNum, streamHeader.dForm));
        
        exists = 1;
        data.(streamHeader.eventName).fs = streamHeader.Fs;
    end
temp_data = fread(fid, inf, ['*' streamHeader.dForm])';
sev=temp_data;
header = streamHeader;

fclose(fid);