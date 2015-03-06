function ts = gettimestampsSNLE(SNLEdata, threshold, goodWires, varargin)
%
% usage: ts = gettimestampsSNLE(SNLEdata, threshold, varargin)
%
% INPUTS:
%   SNLEdata - matrix of wavelet filtered, smoothed nonlinear
%       energy-transformed data. m x n, where m is the number of data wires
%       and n is the number of samples
%   threshold - vector containing thresholds corresponding to each wire
%   goodWires - vector containing true/false values corresponding to each
%       wire, indicating whether the recording is worth thresholding or not
% varargs:
%   'deadtime' - dead time in samples
%
% OUTPUTS:
%   ts - timestamps of SNLE peaks in samples (NOT units of time)

deadTime         = 16;
overlapTolerance = 2;

for iarg = 1 : 2 : nargin - 3
    
    switch lower(varargin{iarg})
        case 'deadtime',
            deadTime = varargin{iarg + 1};
        case 'overlaptolerance',
            overlapTolerance = varargin{iarg + 1};
    end
    
end

%threshold = threshold/2.5;

% do the thresholding
ts = [];
for iWire = 1 : size(SNLEdata, 1);
    
    if ~goodWires(iWire); continue; end;
    
    % get positive peaks in the SNLE signal at a scale of 1 point (could
    % the scale be optimized to get better results?)
    SNLEpeaks = logical(get_peaks(SNLEdata(iWire, :), 1, 'pos'));
    peakIdx   = find(SNLEpeaks);
    
    % now see which peaks are > threshold
    SNLEpeaks = peakIdx(SNLEdata(iWire, SNLEpeaks) > threshold(iWire));
%     SNLEpeaks = find(SNLEpeaks);        % pull out indices of SNLE peaks > threshold
    
    
    % this is slightly different from what Alex did. It looks like he threw
    % out any candidate spikes if the previous spike occurred less than
    % deatTime points before the current one. However, I think this
    % could eliminate spikes unneccessarily. For example, if the dead time
    % is 16 and there are 3 spikes at samples 10, 18, and 27, both the
    % second AND third spike would be eliminated due to ISIs of 8 and 11,
    % respectively. I think that the middle spike should be eliminated
    % first, then there would be a single ISI of 17 and the second spike
    % would be preserved. Not sure if this makes a big difference or not...
    % See Alex's code gettimestampsSNLE in "wavefilter.py"
    
    % get rid of the dead time spikes
    
    % RS tried alternative from here
    iPeak = 1;
    while iPeak < length(SNLEpeaks) - 1
        if SNLEpeaks(iPeak + 1) - SNLEpeaks(iPeak) < deadTime
            if iPeak == length(SNLEpeaks) - 1
                SNLEpeaks = SNLEpeaks(1:iPeak);
            else
                SNLEpeaks = [SNLEpeaks(1:iPeak), SNLEpeaks(iPeak+2:end)];
            end
        else
            iPeak = iPeak + 1;
        end
    end
    
%    SNLEpeaks = SNLEpeaks(logical([1 (diff(SNLEpeaks) > deadTime)]));
% till here
    
    
    ts = [ts, SNLEpeaks];
    
end

ts = unique(ts);
if isempty(ts); return; end;

% markers for where the time difference between adjacent spikes is >
% overlapTolerance tick counts
nonoverlapMarkers = [true, diff(ts) > overlapTolerance];
ts = ts(nonoverlapMarkers);