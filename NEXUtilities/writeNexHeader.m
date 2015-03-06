function [result] = writeNexHeader(nexFile, fileName)
% [result] = writeNexHeader(nexFile, fileName) -- write nexFile structure
% to the specified .nex file. returns 1 if succeeded, 0 if failed.
% 
% this function writes all of the variable headers into a .nex file, but
% does not write the actual data. This is useful for the spike extraction
% software so that all of the waveforms do not need to be stored in memory
% at the same time.
%
% INPUT:
%   nexFile - a structure containing .nex file data
%   fileName - if empty string, will use File Open dialog
%
%   nexFile - a structure containing .nex file data
%   nexFile.version - file version
%   nexFile.comment - file comment
%   nexFile.tbeg - beginning of recording session (in seconds)
%   nexFile.tend - end of resording session (in seconds)
%
%   nexFile.neurons - array of neuron structures
%           neurons.name - name of a neuron variable
%           neurons.timestamps - array of neuron timestamps (in seconds)
%               to access timestamps for neuron 2 use {n} notation:
%               nexFile.neurons{2}.timestamps
%
%   nexFile.events - array of event structures
%           event.name - name of neuron variable
%           event.timestamps - array of event timestamps (in seconds)
%               to access timestamps for event 3 use {n} notation:
%               nexFile.events{3}.timestamps
%
%   nexFile.intervals - array of interval structures
%           interval.name - name of neuron variable
%           interval.intStarts - array of interval starts (in seconds)
%           interval.intEnds - array of interval ends (in seconds)
%
%   nexFile.waves - array of wave structures
%           wave.name - name of neuron variable
%           wave.NPointsWave - number of data points in each wave
%           wave.WFrequency - A/D frequency for wave data points
%           wave.timestamps - array of wave timestamps (in seconds)
%           wave.waveforms - matrix of waveforms (in milliVolts), each
%                             waveform is a vector 
%
%   nexFile.contvars - array of contvar structures
%           contvar.name - name of neuron variable
%           contvar.ADFrequency - A/D frequency for data points
%
%           continuous (a/d) data come in fragments. Each fragment has a timestamp
%           and an index of the a/d data points in data array. The timestamp corresponds to
%           the time of recording of the first a/d value in this fragment.
%
%           contvar.timestamps - array of timestamps (fragments start times in seconds)
%           contvar.fragmentStarts - array of start indexes for fragments in contvar.data array
%           contvar.data - array of data points (in milliVolts)
%
%%%%%%%%%%%%%%%%%%%%% POP VECTORS ARE NOT WRITTEN IN THIS VERSION OF
%%%%%%%%%%%%%%%%%%%%% WRITENEXFILE
%   nexFile.popvectors - array of popvector (population vector) structures
%           popvector.name - name of popvector variable
%           popvector.weights - array of population vector weights
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   nexFile.markers - array of marker structures
%           marker.name - name of marker variable
%           marker.timestamps - array of marker timestamps (in seconds)
%           marker.values - array of marker value structures
%           	marker.value.name - name of marker value 
%           	marker.value.strings - array of marker value strings
%

result = 0;

if (nargin < 2 || isempty(fileName))
   [fname, pathname] = uiputfile('*.nex', 'Save file name');
	fileName = strcat(pathname, fname);
end

fid = fopen(fileName, 'w');
if(fid == -1)
   error 'Unable to open file'
   return
end

% write header information
fwrite(fid, 827868494, 'int32');
fwrite(fid, nexFile.version, 'int32');
fwrite(fid, nexFile.comment, 'char');
padding = char(zeros(1, 256 - size(nexFile.comment,2)));
fwrite(fid, padding, 'char');
fwrite(fid, nexFile.freq, 'double');
fwrite(fid, int32(nexFile.tbeg*nexFile.freq), 'int32');
fwrite(fid, int32(nexFile.tend*nexFile.freq), 'int32');

% count all the variables
neuronCount = 0;
eventCount = 0;
intervalCount = 0;
waveCount = 0;
contCount = 0;
markerCount = 0;

if(isfield(nexFile, 'neurons'))
    neuronCount = size(nexFile.neurons, 1);
end
if(isfield(nexFile, 'events'))
    eventCount = size(nexFile.events, 1);
end
if(isfield(nexFile, 'intervals'))
    intervalCount = size(nexFile.intervals, 1);
end
if(isfield(nexFile, 'waves'))
    waveCount = size(nexFile.waves, 1);
end
if(isfield(nexFile, 'contvars'))
	contCount = size(nexFile.contvars, 1);
end
if(isfield(nexFile, 'markers'))
    markerCount = size(nexFile.markers, 1);
end

nvar = int32(neuronCount+eventCount+intervalCount+waveCount+contCount+markerCount);
fwrite(fid, nvar, 'int32');

% skip location of next header and padding
fwrite(fid, char(zeros(1, 260)), 'char');

% calculate where variable data starts
dataOffset = int32(544 + nvar*208);

% write variable headers
varVersion = int32(100);
n = 0;
wireNumber = 0;
unitNumber = 0;
gain = 0;
filter = 0;
xPos = 0;
yPos = 0;
WFrequency = 0;
ADtoMV = 0;
NPointsWave = 0;
NMarkers = 0;
MarkerLength = 0;
MVOfffset = 0;

% write neuron headers
for i = 1:neuronCount
    neuron = nexFile.neurons{i};
    % neuron variable type is zero
    fwrite(fid, 0, 'int32');
    varVersion = int32(100);
    if(isfield(neuron, 'varVersion'))
        varVersion = neuron.varVersion;
    end
    fwrite(fid, varVersion, 'int32');
    fwrite(fid, neuron.name, 'char');
    padding = char(zeros(1, 64 - size(neuron.name,2)));
    fwrite(fid, padding, 'char');
    fwrite(fid, dataOffset, 'int32');
    n = int32(size(neuron.timestamps,1));
    dataOffset = dataOffset + n*4;
    fwrite(fid, n, 'int32');
    wireNumber = 0;
    if(isfield(neuron, 'wireNumber'))
        wireNumber = neuron.wireNumber;
    end
    fwrite(fid, wireNumber, 'int32');
    unitNumber = 0;
    if(isfield(neuron, 'unitNumber'))
        unitNumber = neuron.unitNumber;
    end
    fwrite(fid, unitNumber, 'int32');
    fwrite(fid, gain, 'int32');
    fwrite(fid, filter, 'int32');
    xPos = 0;
    if(isfield(neuron, 'xPos'))
        xPos = neuron.xPos;
    end
    fwrite(fid, xPos, 'double');
    yPos = 0;
    if(isfield(neuron, 'yPos'))
        yPos = neuron.yPos;
    end
    fwrite(fid, yPos, 'double');
    fwrite(fid, WFrequency, 'double');
    fwrite(fid, ADtoMV, 'double');
    fwrite(fid, NPointsWave, 'int32');
    fwrite(fid, NMarkers, 'int32');
    fwrite(fid, MarkerLength, 'int32');
    fwrite(fid, MVOfffset, 'double');
    fwrite(fid, char(zeros(1, 60)), 'char');
end
   
% event headers
n = 0;
varVersion = int32(100);
wireNumber = 0;
unitNumber = 0;
gain = 0;
filter = 0;
xPos = 0;
yPos = 0;
WFrequency = 0;
ADtoMV = 0;
NPointsWave = 0;
NMarkers = 0;
MarkerLength = 0;
MVOfffset = 0;

for i = 1:eventCount
    event = nexFile.events{i};
    % event variable type is 1
    fwrite(fid, 1, 'int32');
    fwrite(fid, varVersion, 'int32');
    fwrite(fid, event.name, 'char');
    padding = char(zeros(1, 64 - size(event.name,2)));
    fwrite(fid, padding, 'char');
    fwrite(fid, dataOffset, 'int32');
    n = int32(size(event.timestamps,1));
    dataOffset = dataOffset + n*4;
    fwrite(fid, n, 'int32');
    fwrite(fid, wireNumber, 'int32');
    fwrite(fid, unitNumber, 'int32');
    fwrite(fid, gain, 'int32');
    fwrite(fid, filter, 'int32');
    fwrite(fid, xPos, 'double');
    fwrite(fid, yPos, 'double');
    fwrite(fid, WFrequency, 'double');
    fwrite(fid, ADtoMV, 'double');
    fwrite(fid, NPointsWave, 'int32');
    fwrite(fid, NMarkers, 'int32');
    fwrite(fid, MarkerLength, 'int32');
    fwrite(fid, MVOfffset, 'double');
    fwrite(fid, char(zeros(1, 60)), 'char');
end
    
% interval headers
n = 0;
varVersion = int32(100);
wireNumber = 0;
unitNumber = 0;
gain = 0;
filter = 0;
xPos = 0;
yPos = 0;
WFrequency = 0;
ADtoMV = 0;
NPointsWave = 0;
NMarkers = 0;
MarkerLength = 0;
MVOfffset = 0;

for i = 1:intervalCount
    interval = nexFile.intervals{i};
    % interval variable type is 2
    fwrite(fid, 2, 'int32');
    fwrite(fid, varVersion, 'int32');
    fwrite(fid, interval.name, 'char');
    padding = char(zeros(1, 64 - size(interval.name,2)));
    fwrite(fid, padding, 'char');
    fwrite(fid, dataOffset, 'int32');
    n = int32(size(interval.intStarts,1));
    dataOffset = dataOffset + n*8;
    fwrite(fid, n, 'int32');
    fwrite(fid, wireNumber, 'int32');
    fwrite(fid, unitNumber, 'int32');
    fwrite(fid, gain, 'int32');
    fwrite(fid, filter, 'int32');
    fwrite(fid, xPos, 'double');
    fwrite(fid, yPos, 'double');
    fwrite(fid, WFrequency, 'double');
    fwrite(fid, ADtoMV, 'double');
    fwrite(fid, NPointsWave, 'int32');
    fwrite(fid, NMarkers, 'int32');
    fwrite(fid, MarkerLength, 'int32');
    fwrite(fid, MVOfffset, 'double');
    fwrite(fid, char(zeros(1, 60)), 'char');
end

% wave headers
varVersion = int32(100);
n = 0;
wireNumber = 0;
unitNumber = 0;
gain = 0;
filter = 0;
xPos = 0;
yPos = 0;
WFrequency = 0;
ADtoMV = 0;
NPointsWave = 0;
NMarkers = 0;
MarkerLength = 0;
MVOfffset = 0;

for i = 1:waveCount
    wave = nexFile.waves{i};
    % wave variable type is 3
    fwrite(fid, 3, 'int32');
    varVersion = int32(100);
    if(isfield(wave, 'varVersion'))
        varVersion = wave.varVersion;
    end
    fwrite(fid, varVersion, 'int32');
    fwrite(fid, wave.name, 'char');
    padding = char(zeros(1, 64 - size(wave.name,2)));
    fwrite(fid, padding, 'char');
    fwrite(fid, dataOffset, 'int32');
    n = int32(size(wave.timestamps,1));
    NPointsWave = wave.NPointsWave;
    dataOffset = dataOffset + n*4 + NPointsWave*n*2;
    fwrite(fid, n, 'int32');
    wireNumber = 0;
    if(isfield(wave, 'wireNumber'))
        wireNumber = wave.wireNumber;
    end
    fwrite(fid, wireNumber, 'int32');
    unitNumber = 0;
    if(isfield(wave, 'unitNumber'))
        unitNumber = wave.unitNumber;
    end
    fwrite(fid, unitNumber, 'int32');
    fwrite(fid, gain, 'int32');
    fwrite(fid, filter, 'int32');
    fwrite(fid, xPos, 'double');
    fwrite(fid, yPos, 'double');
    fwrite(fid, wave.WFrequency, 'double');
    nexFile.waves{i}.MVOfffset = 0;
    % we need to recalculate a/d to millivolts factor
%     wmin = min(min(nexFile.waves{i}.waveforms));
%     wmax = max(max(nexFile.waves{i}.waveforms));
%     c = max(abs(wmin),abs(wmax));
%     if (c == 0)
%         c = 1;
%     else
%         c = c/32767;
%     end
%     nexFile.waves{i}.ADtoMV = c;
    
    fwrite(fid, nexFile.waves{i}.ADtoMV, 'double');
    fwrite(fid, wave.NPointsWave, 'int32');
    fwrite(fid, NMarkers, 'int32');
    fwrite(fid, MarkerLength, 'int32');
    fwrite(fid, nexFile.waves{i}.MVOfffset, 'double');
    fwrite(fid, char(zeros(1, 60)), 'char');
end
 
% continuous variables
varVersion = int32(100);
n = 0;
wireNumber = 0;
unitNumber = 0;
gain = 0;
filter = 0;
xPos = 0;
yPos = 0;
WFrequency = 0;
ADtoMV = 0;
NPointsWave = 0;
NMarkers = 0;
MarkerLength = 0;
MVOfffset = 0;

% write variable headers
for i = 1:contCount
    % cont. variable type is 5
    fwrite(fid, 5, 'int32');
    varVersion = int32(100);
    if(isfield(nexFile.contvars{i}, 'varVersion'))
        varVersion = nexFile.contvars{i}.varVersion;
    end
    fwrite(fid, varVersion, 'int32');
    fwrite(fid, nexFile.contvars{i}.name, 'char');
    padding = char(zeros(1, 64 - size(nexFile.contvars{i}.name,2)));
    fwrite(fid, padding, 'char');
    fwrite(fid, dataOffset, 'int32');
    n = int32(size(nexFile.contvars{i}.timestamps,1));
    NPointsWave = size(nexFile.contvars{i}.data, 1);
    dataOffset = dataOffset + n*8 + NPointsWave*2;
    fwrite(fid, n, 'int32');
    fwrite(fid, wireNumber, 'int32');
    fwrite(fid, unitNumber, 'int32');
    fwrite(fid, gain, 'int32');
    fwrite(fid, filter, 'int32');
    fwrite(fid, xPos, 'double');
    fwrite(fid, yPos, 'double');
    fwrite(fid, nexFile.contvars{i}.ADFrequency, 'double');
    nexFile.contvars{i}.MVOfffset = 0;
        
    wmin = min(min(nexFile.contvars{i}.data));
    wmax = max(max(nexFile.contvars{i}.data));
    c = max(abs(wmin),abs(wmax));
    if (c == 0)
        c = 1;
    else
        c = c/32767;
    end
    nexFile.contvars{i}.ADtoMV = c;
    
    fwrite(fid, nexFile.contvars{i}.ADtoMV, 'double');
    fwrite(fid, NPointsWave, 'int32');
    fwrite(fid, NMarkers, 'int32');
    fwrite(fid, MarkerLength, 'int32');
    fwrite(fid, nexFile.contvars{i}.MVOfffset, 'double');
    fwrite(fid, char(zeros(1, 60)), 'char');
end

% markers
n = 0;
varVersion = int32(100);
wireNumber = 0;
unitNumber = 0;
gain = 0;
filter = 0;
xPos = 0;
yPos = 0;
WFrequency = 0;
ADtoMV = 0;
NPointsWave = 0;
NMarkers = 0;
MarkerLength = 0;
MVOfffset = 0;

for i = 1:markerCount
    marker = nexFile.markers{i};
    % marker variable type is 6
    fwrite(fid, 6, 'int32');
    fwrite(fid, varVersion, 'int32');
    fwrite(fid, marker.name, 'char');
    padding = char(zeros(1, 64 - size(marker.name,2)));
    fwrite(fid, padding, 'char');
    fwrite(fid, dataOffset, 'int32');
    n = int32(size(marker.timestamps,1));
    dataOffset = dataOffset + n*4;
    NMarkers = size(marker.values, 1);
    MarkerLength = 0;
    for j = 1:NMarkers
      v = marker.values{j,1};
      for k = 1:size(v.strings, 1)
        MarkerLength = max(MarkerLength, size(v.strings{k,1}, 2));
      end
    end
    % add extra char to hold zero (end of string)
    MarkerLength = MarkerLength + 1;
    nexFile.markers{i}.NMarkers = NMarkers;
    nexFile.markers{i}.MarkerLength = MarkerLength;
    dataOffset = dataOffset + NMarkers*64 + NMarkers*n*MarkerLength;
    fwrite(fid, n, 'int32');
    fwrite(fid, wireNumber, 'int32');
    fwrite(fid, unitNumber, 'int32');
    fwrite(fid, gain, 'int32');
    fwrite(fid, filter, 'int32');
    fwrite(fid, xPos, 'double');
    fwrite(fid, yPos, 'double');
    fwrite(fid, WFrequency, 'double');
    fwrite(fid, ADtoMV, 'double');
    fwrite(fid, NPointsWave, 'int32');
    fwrite(fid, NMarkers, 'int32');
    fwrite(fid, MarkerLength, 'int32');
    fwrite(fid, MVOfffset, 'double');
    fwrite(fid, char(zeros(1, 60)), 'char');
end


fclose(fid);
result = 1;
