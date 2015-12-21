function nexData = TDTtoNex(sessionConf)
%
% usage:
%
%this function converts TDTtank files into a nex file
%output nexData.data with all header fields from the tsq file
%       nexData.raw represents all the fields from the raw data
%       nexData.events represents all the events that we recorded in
%       box2nex script
% plus the usual nex field: 
%       nexData.version
% 		nexData.comment 
% 		nexData.freq
% 		nexData.tbeg
% 		nexData.events
% 	    nexData.tbeg
%
% INPUTS:
%   tevName - name of the .tev file to use
%   tsqName - name of the .tsq file to use
%
% OUTPUTS:
%   none

% allow empty input to manually select files
if ~isempty(sessionConf)
    leventhalPaths = buildLeventhalPaths(sessionConf,{'processed'});

    tevInfo = dir(fullfile(leventhalPaths.rawdata,'*.tev'));
    if isempty(tevInfo)
        error('TDTtoNex_20141204:noTevFile', ['no tev file found for session ' sessionConf.sessionName]);
    end
    if length(tevInfo) > 1
        error('TDTtoNex_20141204:multipleTevFiles', ['more than one tev file found for session ' sessionConf.sessionName]);
    end
    tsqInfo = dir(fullfile(leventhalPaths.rawdata,'*.tsq'));
    if isempty(tsqInfo)
        error('TDTtoNex_20141204:noTsqFile', ['no tsq file found for session ' sessionConf.sessionName]);
    end
    if length(tsqInfo) > 1
        error('TDTtoNex_20141204:multipleTsqFiles', ['more than one tsq file found for session ' sessionConf.sessionName]);
    end
    tevName = fullfile(leventhalPaths.rawdata, tevInfo.name);
    tsqName = fullfile(leventhalPaths.rawdata, tsqInfo.name);
else
    tdtDir = uigetdir;
    tevInfo = dir(fullfile(tdtDir,'*.tev'));
    tsqInfo = dir(fullfile(tdtDir,'*.tsq'));
    tevName = fullfile(tdtDir,tevInfo.name);
    tsqName = fullfile(tdtDir,tsqInfo.name);
end
store_id2 = 'Vide';
store_id = 'Wave';  % this is just an example
tev = fopen(tevName);
tsq = fopen(tsqName); fseek(tsq, 0, 'eof'); ntsq = ftell(tsq)/40; fseek(tsq, 0, 'bof');

%read from tsq
nexData.data.size      = fread(tsq, [ntsq 1], 'int32',  36); fseek(tsq,  4, 'bof');
nexData.data.type      = fread(tsq, [ntsq 1], 'int32',  36); fseek(tsq,  8, 'bof');
nexData.data.name      = fread(tsq, [ntsq 1], 'uint32', 36); fseek(tsq, 12, 'bof');
nexData.data.chan      = fread(tsq, [ntsq 1], 'ushort', 38); fseek(tsq, 14, 'bof');
nexData.data.sortcode  = fread(tsq, [ntsq 1], 'ushort', 38); fseek(tsq, 16, 'bof');
nexData.data.timestamp = fread(tsq, [ntsq 1], 'double', 32); fseek(tsq, 24, 'bof');
nexData.data.fp_loc    = fread(tsq, [ntsq 1], 'int64',  32); fseek(tsq, 24, 'bof');
nexData.data.strobe    = fread(tsq, [ntsq 1], 'double', 32); fseek(tsq, 32, 'bof');
nexData.data.format    = fread(tsq, [ntsq 1], 'int32',  36); fseek(tsq, 36, 'bof');
nexData.data.frequency = fread(tsq, [ntsq 1], 'float',  36);

nexData2.data.size      = fread(tsq, [ntsq 1], 'int32',  36); fseek(tsq,  4, 'bof');
nexData2.data.type      = fread(tsq, [ntsq 1], 'int32',  36); fseek(tsq,  8, 'bof');
nexData2.data.name      = fread(tsq, [ntsq 1], 'uint32', 36); fseek(tsq, 12, 'bof');
nexData2.data.chan      = fread(tsq, [ntsq 1], 'ushort', 38); fseek(tsq, 14, 'bof');
nexData2.data.sortcode  = fread(tsq, [ntsq 1], 'ushort', 38); fseek(tsq, 16, 'bof');
nexData2.data.timestamp = fread(tsq, [ntsq 1], 'double', 32); fseek(tsq, 24, 'bof');
nexData2.data.fp_loc    = fread(tsq, [ntsq 1], 'int64',  32); fseek(tsq, 24, 'bof');
nexData2.data.strobe    = fread(tsq, [ntsq 1], 'double', 32); fseek(tsq, 32, 'bof');
nexData2.data.format    = fread(tsq, [ntsq 1], 'int32',  36); fseek(tsq, 36, 'bof');
nexData2.data.frequency = fread(tsq, [ntsq 1], 'float',  36);

%typecast Store ID (such as 'Wave') to number
name = 256.^(0:3)*double(store_id)';
name2 = 256.^(0:3)*double(store_id2)';

row2 = (name2 == nexData2.data.name);
row = (name == nexData.data.name);

table = { 'float',  1, 'float';
'long',   1, 'int32';
'short',  2, 'short';
'byte',   4, 'schar'; }; % a look-up table

first_row = find(1==row,1);
first_row2 = find(1==row2,1);

format = nexData.data.format(first_row)+1; % from 0-based to 1-based
format2 = nexData.data.format(first_row2)+1; % from 0-based to 1-based

nexData.raw.format = table{format,1};
nexData.raw.sampling_rate = nexData.data.frequency(first_row);
nexData.raw.chan_info = [nexData.data.timestamp(row) nexData.data.chan(row)];

nexData2.raw.format = table{format2,1};
nexData2.raw.sampling_rate = nexData.data.frequency(first_row2);
nexData2.raw.chan_info = [nexData2.data.timestamp(row2) nexData2.data.chan(row2)];

fp_loc  = nexData.data.fp_loc(row);
fp_loc2  = nexData.data.fp_loc(row2);

nsample = (nexData.data.size(row)-10) * table{format,2};
nsample2 = (nexData.data.size(row2)-10) * table{format2,2};

nexData.raw.sample_point = NaN(length(fp_loc),max(nsample));
nexData2.raw.sample_point = NaN(length(fp_loc2),max(nsample2));

for n=1:length(fp_loc)
    fseek(tev,fp_loc(n),'bof');
    nexData.raw.sample_point(n,1:nsample(n)) = fread(tev,[1 nsample(n)],table{format,3});
end

for n=1:length(fp_loc2)
    fseek(tev,fp_loc2(n),'bof');
    nexData2.raw.sample_point(n,1:nsample2(n)) = fread(tev,[1 nsample2(n)],table{format2,3});
end
% For your specialized task,
% replace these with your line names, 
% tone1=low, tone2=high
linenames = {'cue1On','cue1Off', 'cue2On','cue2Off','cue3On','cue3Off','cue4On','cue4Off','cue5On','cue5Off','houselightOn','houselightOff', ...
         'foodOn','foodOff', 'line08On','line08Off', 'nose1In', 'nose1Out', 'nose2In', 'nose2Out', ...
         'nose3In', 'nose3Out', 'nose4In', 'nose4Out','nose5In', 'nose5Out', 'foodportOn', 'foodportOff','line15On','line15Off', ...
         'line16On','line16Off', 'tone1On','tone1Off', 'tone2On','tone2Off', 'line19On', 'line19Off', 'gotrialOn','gotrialOff', 'line21On', 'line21Off', 'line22On', 'line22Off', ...
         'line23On', 'line23Off', 'videoOn', 'videoOff','VoBlue','VoGreen','VpdBlue','VpdGreen'};

% Set up the NEX file data structure
nexData.version = 1;
nexData.comment = 'Converted TDTtoNex. Alex Zotov, Matt Gaidica.';
if ~isempty(sessionConf)
    nexData.freq = sessionConf.Fs;
end
nexData.tbeg = 0;
nexData.events = {};
nexData.tbeg = nexData.data.timestamp(2);
        
for ii=1:length(linenames)
   nexData.events{ii}.name= linenames{ii};
   nexData.events{ii}.timestamps = [];
end 

for ii=1:length(linenames)
   nexData2.events{ii}.name= linenames{ii};
   nexData2.events{ii}.timestamps = [];
end 
    
channelCount=ones(128,1);    
    %read bits lines to get the nex file
for i_ts = 0 : (length(nexData.raw.chan_info)-1)
    if i_ts==0
        switched_bits =  [bitget(16777215, 1:32);bitget(nexData.raw.sample_point(1), 1:32)];
        bitsDiff = switched_bits(1,:)-switched_bits(2,:);
        linesOn = find(bitsDiff==1);
        linesOff = find(bitsDiff==-1);
        if ~isempty(linesOn)
            for j=1:length(linesOn)
                nexData.events{(2*linesOn((j)))-1}.timestamps(channelCount((2*linesOn((j)))-1),1) = nexData.raw.sample_point(1)-nexData.data.timestamp(2);
                channelCount((2*linesOn((j)))-1) = channelCount((2*linesOn((j)))-1) +1;
            end
        end
    
        if ~isempty(linesOff)
            for k=1:length(linesOff)
                nexData.events{2*linesOff(k)}.timestamps(channelCount(2*linesOff(k)),1) = nexData.raw.sample_point(1)-nexData.data.timestamp(2);
                channelCount(2*linesOff(k)) = channelCount(2*linesOff(k))+1;
            end
        end
    else
        switched_bits =  [bitget(nexData.raw.sample_point(i_ts), 1:32);bitget(nexData.raw.sample_point(i_ts+1), 1:32)];
        bitsDiff = switched_bits(1,:)-switched_bits(2,:);
        linesOn = find(bitsDiff==1);
        linesOff = find(bitsDiff==-1);
        if ~isempty(linesOn)
            for j=1:length(linesOn)
                nexData.events{(2*linesOn((j)))-1}.timestamps(channelCount((2*linesOn((j)))-1),1) = nexData.raw.chan_info(i_ts+1)-nexData.data.timestamp(2);
                channelCount((2*linesOn((j)))-1) = channelCount((2*linesOn((j)))-1) +1;
            end
        end
    
        if ~isempty(linesOff)
            for k=1:length(linesOff)
                nexData.events{2*linesOff(k)}.timestamps(channelCount(2*linesOff(k)),1) = nexData.raw.chan_info(i_ts+1)-nexData.data.timestamp(2);
                channelCount(2*linesOff(k)) = channelCount(2*linesOff(k))+1;
            end
        end
    end
end

for i_ts = 0 : (length(nexData2.raw.chan_info)-1)
    if i_ts==0
        switched_bits = [bitget(16777215, 1:32);bitget(nexData2.raw.sample_point(1), 1:32)];
        bitsDiff = switched_bits(1,:)-switched_bits(2,:);
        linesOn = find(bitsDiff==1);
        linesOff = find(bitsDiff==-1);
        if ~isempty(linesOn)
            for j=1:length(linesOn)
                nexData2.events{(2*linesOn((j)))-1}.timestamps(channelCount((2*linesOn((j)))-1),1) = nexData2.raw.sample_point(1)-nexData.data.timestamp(2);
                channelCount((2*linesOn((j)))-1) = channelCount((2*linesOn((j)))-1) +1;
            end
        end
    
        if ~isempty(linesOff)
            for k=1:length(linesOff)
                nexData2.events{2*linesOff(k)}.timestamps(channelCount(2*linesOff(k)),1) = nexData2.raw.sample_point(1)-nexData.data.timestamp(2);
                channelCount(2*linesOff(k)) = channelCount(2*linesOff(k))+1;
            end
        end
    else
        switched_bits =  [bitget(nexData2.raw.sample_point(i_ts), 1:32);bitget(nexData2.raw.sample_point(i_ts+1), 1:32)];
        bitsDiff = switched_bits(1,:)-switched_bits(2,:);
        linesOn = find(bitsDiff==1);
        linesOff = find(bitsDiff==-1);
        if ~isempty(linesOn)
            for j=1:length(linesOn)
                nexData2.events{(2*linesOn((j)))-1}.timestamps(channelCount((2*linesOn((j)))-1),1) = nexData2.raw.chan_info(i_ts+1)-nexData.data.timestamp(2);
                channelCount((2*linesOn((j)))-1)= channelCount((2*linesOn((j)))-1) +1;
            end
        end
    
        if ~isempty(linesOff)
            for k=1:length(linesOff)
                nexData2.events{2*linesOff(k)}.timestamps(channelCount(2*linesOff(k)),1) = nexData2.raw.chan_info(i_ts+1)-nexData.data.timestamp(2);
                channelCount(2*linesOff(k)) = channelCount(2*linesOff(k))+1;
            end
        end
    end
end

nexData.events{47}.name = 'videoOn';
nexData.events{48}.name = 'videoOff';
nexData.events{47}.timestamps = nexData2.events{51}.timestamps;
nexData.events{48}.timestamps = nexData2.events{52}.timestamps;

nexData.events = nexData.events';
nexData.tend = nexData.raw.chan_info(end,1);

% only save if sessionConf is passed in
if ~isempty(sessionConf)
    filePath = fullfile(leventhalPaths.processed,[sessionConf.sessionName '.box.nex']);
    save([filePath,'.mat'],'nexData','-v7.3');
    writeNexFile(nexData, filePath);
end
fclose(tev);
fclose(tsq);