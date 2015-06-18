close all; clear all; clc;

t = TDTlive();
t.TYPE = {'epocs','scalars'};
t.VERBOSE = false;

while 1
    
    % slow it down a little
    pause(0.1)
    
    % get the most recent data
    t.update;
    
    % grab the latest Tick events
    if ~isstruct(t.data.epocs)
        continue
    end
    if ~isfield(t.data.epocs, 'Tick')
        continue
    end
    
    ts = t.data.epocs.Tick.onset;
    values = t.data.epocs.Tick.data;
    if ~isnan(ts)
        ts
        values
    end
end