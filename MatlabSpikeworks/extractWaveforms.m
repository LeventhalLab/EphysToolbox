function waveforms = extractWaveforms( data, ts, peakLoc, waveLength )
%
% usage: waveforms = extractWaveforms( data, ts, peakLoc, waveLength )
%
% INPUTS:
%   data - m x n matrix containing wavelet filtered data; m is the number
%       of wires, n is the number of samples
%   ts - timestamps of the waveform peaks
%   peakLoc - desired location of the peak within the waveform (ie, 
%       peakLoc = 8 means that the peak will be placed at the 8th sample -
%       that is, start the waveform at ts - peakLoc + 1
%   waveLength - number of points to extract for each waveform. Waveforms
%       extend from (ts - peakLoc + 1) to ((ts - peakLoc + 1 + waveLength)
%
% OUTPUTS:
%   waveforms - m x n x p matrix, where m is the number of timestamps
%       (spikes), n is the number of points in a single waveform, and p is
%       the number of wires

numWires   = size(data, 1);
numSamples = size(data, 2);

ts = ts(ts > peakLoc + 1);
ts = ts(ts < (numSamples + peakLoc - waveLength));

numSpikes = length(ts);
waveforms = zeros(numSpikes, waveLength, numWires);

for i_ts = 1 : numSpikes
    waveStart = ts(i_ts) - peakLoc + 1;
    waveEnd   = ts(i_ts) - peakLoc + waveLength;
    waveforms(i_ts, :, :) = data(:, waveStart : waveEnd)';
end