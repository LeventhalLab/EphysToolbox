function [lfp,t] = groundTruthLFP(timePeriod,Fs,oscillationFreq,oscillationOnOff,oscillationAmp)
% timePeriod: how long?
% Fs: sampling rate
% oscillationFreq: n x 1
% oscillationOnset: n x 2
% oscillationAmp: n x 1

% check for errors in inputs
if any(oscillationFreq > Fs / 2)
    error('Insufficient resolution for high frequency oscillations');
end
if any(max(oscillationOnOff) > timePeriod)
    error('Must turn off oscillation before time period');
end
if any(diff(oscillationOnOff') < 0)
    error('Turn on oscillation before turning it off in time');
end

% fill amplitude array if it doesn't exist
if ~exist('oscillationAmp')
    oscillationAmp = ones(size(oscillationFreq));
end

dt = 1/Fs; % seconds per sample 
t = (0:dt:timePeriod)'; % seconds 
lfp = zeros(size(t)); % init lfp to zero
for iFreq = 1:numel(oscillationFreq) % sum all frequency components
    startIdx = find(t >= oscillationOnOff(iFreq,1),1,'first');
    endIdx = find(t < oscillationOnOff(iFreq,2),1,'last');
% %     lfp(startIdx:endIdx) = lfp(startIdx:endIdx) + oscillationAmp(iFreq) * sin(2*pi*oscillationFreq(iFreq)*t(startIdx:endIdx));
    lfp(startIdx:endIdx) = lfp(startIdx:endIdx) + oscillationAmp(iFreq) * sin(2*pi*oscillationFreq(iFreq)*t(1:(endIdx-startIdx+1)));
end