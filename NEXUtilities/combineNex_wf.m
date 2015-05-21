function [varargout] = combineNex_wf( nexfn, nSampleRate, sessionName )
%
% usage: [varargout] = combineNex_wf2012( varargin )
%
% function to combine timestamps from different nex files into a single nex
% data structure. It differs from combineNex in that it renames the units
% to reflect whether the recording was from session "a", "b", etc. on the
% same day.


if ~iscell(nexfn)
    nexfn = { nexfn };
end


if isempty(nexfn)
    [nexfn, pathname] = uigetfile('*.nex', 'Pick a nex data file', 'MultiSelect', 'on');
    % If the user didn't select any file, quit RIGHT NOW
    if isequal(nexfn,0) || isequal(pathname,0)
        disp('No nex file selected. Goodbye!');
        nexData = [];
        return 
    end
    % If the user selects only one file, we need to change the "filenames" variable from a string to
    % a cell array with one entry. If more than one file is selected,
    % then we have a cell array anyway.
    if ~iscell(nexfn)
        nexfn = { nexfn };
    end
    for i=1:length(nexfn) % Add the full directory path to each filename
        nexfn{i} = fullfile(pathname, nexfn{i});
    end
end


% Set up the NEX file data structure
nexData.version = 100;
nexData.comment = 'Combined nex files by combineNex.m. Dan Leventhal, 2010';
nexData.freq = nSampleRate;
nexData.tbeg = 0;

% assume that all .nex files selected are from the same session, and
% therefore have the same tbeg and tend.
fid = fopen(nexfn{1}, 'r');
if(fid == -1)
	disp('cannot open first .nex file');
   return
end

disp(strcat('file = ', nexfn{2}));
magic = fread(fid, 1, 'int32');
version = fread(fid, 1, 'int32');
comment = fread(fid, 256, 'char');
freq = fread(fid, 1, 'double');
tbeg = fread(fid, 1, 'int32');
nexData.tend = fread(fid, 1, 'int32');   % should this be in samples or seconds?

fclose(fid);

nexData.events = {};
nexData.neurons = {};
nexData.intervals = {};
        
numVar = 0;
numNeurons = 0;
numEvents = 0;
numWaveforms = 0;
numIntervals = 0;
numContVars = 0;
numMarkers = 0;
for iNex = 1 : length(nexfn)
    [nvar, names, types] = nex_info(nexfn{iNex});
    
    for iVar = 1 : nvar
        curName = deblank(names(iVar,:));
        type = types(iVar);
        
        switch type
            case 0, % neuron
                % first, check to see if this neuron already exists
                
                % create a new neuron name based on the session name,
                % site/tetrode identifier, and unit identifier (ie, a, b,
                % c, etc.)
                
                % this was not working, curName=T02_W01a, so...?
%                 numCharsBeforeSite = length(sessionName) - 2;
%                 unitID = curName(numCharsBeforeSite+1:end);
%                 newUnitName = [sessionName '_' unitID];
                
                %temp fix, added iNex so this works with single channel sorting
                newUnitName = [sessionName,'_',curName,'_',num2str(iNex)]; 
                
                if ~isempty(nexData.neurons)
                    exitFlag = 0;
                    for iNeuron = 1 : numNeurons
                        if strcmpi(nexData.neurons{iNeuron}.name, newUnitName)
                            exitFlag = 1;
                            break;
                        end
                    end
                    if exitFlag
                        continue;
                    end
                end
                % this neuron has not already been included
                numNeurons = numNeurons + 1;
                nexData.neurons{numNeurons, 1}.name = newUnitName;
                [~, nexData.neurons{numNeurons, 1}.timestamps] = ...
                    nex_ts(nexfn{iNex}, curName);
                
                if length(nexData.neurons{numNeurons, 1}.timestamps) > ...
                     size(nexData.neurons{numNeurons, 1}.timestamps, 1)
                    % this is a row vector, convert to column vector
                    nexData.neurons{numNeurons, 1}.timestamps = ...
                        nexData.neurons{numNeurons, 1}.timestamps';
                end
            case 1, % event
                % first, check to see if this event already exists
                if ~isempty(nexData.events)
                    exitFlag = 0;
                    for iEvent = 1 : numEvents
                        if strcmpi(nexData.events{iEvent}.name, curName)
                            exitFlag = 1;
                            break;
                        end
                    end
                    if exitFlag
                        continue;
                    end
                end
                % this event has not already been included
                numEvents = numEvents + 1;
                nexData.events{numEvents, 1}.name = curName;
                [~, nexData.events{numEvents, 1}.timestamps] = ...
                    nex_ts(nexfn{iNex}, curName);
                
                if length(nexData.events{numEvents, 1}.timestamps) > ...
                     size(nexData.events{numEvents, 1}.timestamps, 1)
                    % this is a row vector, convert to column vector
                    nexData.events{numEvents, 1}.timestamps = ...
                        nexData.events{numEvents, 1}.timestamps';
                end
            case 2, % interval
                % first, check to see if this interval already exists
                if ~isempty(nexData.intervals)
                    exitFlag = 0;
                    for iInt = 1 : numIntervals
                        if strcmpi(nexData.intervals{iInt}.name, curName)
                            exitFlag = 1;
                            break;
                        end
                    end
                    if exitFlag
                        continue;
                    end
                end
                % these intervals have not already been included
                numIntervals = numIntervals + 1;
                nexData.intervals{numIntervals, 1}.name = curName;
                [~, nexData.intervals{numIntervals, 1}.intStarts, ...
                    nexData.intervals{numIntervals, 1}.intEnds] = ...
                    nex_int(nexfn{iNex}, curName);

                if length(nexData.intervals{numIntervals, 1}.intStarts) > ...
                     size(nexData.intervals{numIntervals, 1}.intStarts, 1)
                    % this is a row vector, convert to column vector
                    nexData.intervals{numIntervals, 1}.intStarts = ...
                        nexData.intervals{numIntervals, 1}.intStarts';
                end

                if length(nexData.intervals{numIntervals, 1}.intEnds) > ...
                     size(nexData.intervals{numIntervals, 1}.intEnds, 1)
                    % this is a row vector, convert to column vector
                    nexData.intervals{numIntervals, 1}.intEnds = ...
                        nexData.intervals{numIntervals, 1}.intEnds';
                end
                
            case 3, % waveform
                % first, check to see if this waveform already exists
                if isfield(nexData,'waves') && ~isempty(nexData.waves)
                    exitFlag = 0;
                    for iWave = 1 : numWaveforms
                        if strcmpi(nexData.waves{iWave}.name, curName)
                            exitFlag = 1;
                            break;
                        end
                    end
                    if exitFlag
                        continue;
                    end
                end
                % these intervals have not already been included
                numWaveforms = numWaveforms + 1;
                nexData.waves{numWaveforms, 1}.name = curName;
                [nexData.waves{numWaveforms, 1}.WFrequency, ...
                    ~, ...
                    nexData.waves{numWaveforms, 1}.timestamps, ...
                    nexData.waves{numWaveforms, 1}.NPointsWave, ...
                    nexData.waves{numWaveforms, 1}.waveforms] = ...
                    nex_wf(nexfn{iNex}, curName);
                    
                if length(nexData.waves{numWaveforms, 1}.timestamps) > ...
                     size(nexData.waves{numWaveforms, 1}.timestamps, 1)
                    % this is a row vector, convert to column vector
                    nexData.waves{numWaveforms, 1}.timestamps = ...
                        nexData.waves{numWaveforms, 1}.timestamps';
                end
                
%             case 4, % population vector

            case 5, % contnuous variable
                % first, check to see if this continuous variable already exists
                if ~isempty(nexData.contvars)
                    exitFlag = 0;
                    for iContVar = 1 : numContVars
                        if strcmpi(nexData.contvars{iContVar}.name, curName)
                            exitFlag = 1;
                            break;
                        end
                    end
                    if exitFlag
                        continue;
                    end
                end
                % this continuous variable has not already been included
                
%           continuous (a/d) data come in fragments. Each fragment has a timestamp
%           and an index of the a/d data points in data array. The timestamp corresponds to
%           the time of recording of the first a/d value in this fragment.
                numContVars = numContVars + 1;
                nexData.contvars{numContVars, 1}.name = curName;
                [nexData.contvars{numContVars, 1}.ADFrequency, ...
                    ~, ...
                    nexData.contvars{numContVars, 1}.timestamps, ...
                    Fn, ...    % Fn is the number of data points in each fragment
                    nexData.contvars{numContVars, 1}.data] = ...
                    nex_cont(nexfn{iNex}, curName);
                
                nexData.contvars{numContVars, 1}.fragmentStarts = cumsum([1 Fn(1:end-1)]);

                if length(nexData.contvars{numContVars, 1}.timestamps) > ...
                     size(nexData.contvars{numContVars, 1}.timestamps, 1)
                    % this is a row vector, convert to column vector
                    nexData.contvars{numContVars, 1}.timestamps = ...
                        nexData.contvars{numContVars, 1}.timestamps';
                end
                
            case 6, % marker
                % first, check to see if this marker already exists
                if ~isempty(nexData.markers)
                    exitFlag = 0;
                    for iMarker = 1 : numMarkers
                        if strcmpi(nexData.markers{iMarker}.name, curName)
                            exitFlag = 1;
                            break;
                        end
                    end
                    if exitFlag
                        continue;
                    end
                end
                % this marker has not already been included
                
                numMarkers = numMarkers + 1;
                nexData.markers{numMarkers, 1}.name = curName;
                [~, nm, ~, nexData.markers{numMarkers, 1}.timestamps, ...
                    markerNames, markerVals] = nex_marker(nexfn{iNex}, curName);
                for iValue = 1 : nm
                    nexData.markers{numMarkers, 1}.values{iValue}.name = ...
                        deblank(markerNames(iValue, :));
                    nexData.markers{numMarkers, 1}.values(iValue).strings = ...
                        markerVals(:, :, iValue);
                end
                
                if length(nexData.markers{numMarkers, 1}.timestamps) > ...
                     size(nexData.markers{numMarkers, 1}.timestamps, 1)
                    % this is a row vector, convert to column vector
                    nexData.markers{numMarkers, 1}.timestamps = ...
                        nexData.markers{numMarkers, 1}.timestamps';
                end
                
                    %   nexFile.markers - array of marker structures
                    %           marker.name - name of marker variable
                    %           marker.timestamps - array of marker timestamps (in seconds)
                    %           marker.values - array of marker value structures
                    %           	marker.value.name - name of marker value 
                    %           	marker.value.strings - array of marker
                    %           	value strings

                    % nex_marker(filename, varname): Read a marker variable from a .nex file
                    %
                    % [n, nm, nl, ts, names, m] = nex_marker(filename, varname)
                    %

                    % OUTPUT:
                    %   n - number of markers
                    %   nm - number of fields in each marker
                    %   nl - number of characters in each marker field
                    %   ts - array of marker timestamps (in seconds)
                    %   names - names of marker fields ([nm 64] character array)
                    %   m - character array of marker values [n nl nm]

        end    % end switch
                    
    end    % end for iVar...
    
end    % end for iNex...

varargout(1) = {nexData};
