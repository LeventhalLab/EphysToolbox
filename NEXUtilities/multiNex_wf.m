function [adfreq, n, ts, nf, w] = multiNex_wf(filenames, varname)

% function to extract waveforms from multiple nex files that are
% continuations of each other (files broken up for memory purposes in
% offline sorter)

% INPUT:
% filenames - cell array of filenames to load
% varname - variable to load
% breakTimes - times at which the file was broken. breakTimes should have
%   one fewer element than filenames. breakTimes(1) = time at which first
%   file ends and second file begins

n = 0;
cumTime = 0;

for iFile = 1 : length(filenames)
    
    [nvar, names, types, duration] = DLnex_info(filenames{iFile});    
    [adfreq, nwf, tstamps, nf, wf] = ...
        nex_wf(filenames{iFile}, varname);
    
    n = n + nwf;
    
    if iFile == 1
        ts = tstamps;
        w = wf;
    else
        ts = [ts, (tstamps + cumTime)];
        w = [w, wf];
    end
    
    cumTime = cumTime + duration;
    
end    % end for iFile...