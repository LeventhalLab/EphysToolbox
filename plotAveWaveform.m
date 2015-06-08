function plotAveWaveform(meanWaveforms, upperStd, lowerStd, windowSize, varargin)
% Function to plot the average waveform of a unit
%
% Inputs:
%   waveforms - vector from aveWaveform function
%   windowSize - the number of milliseconds on either side of the peak
%   optional color  in [R/255, G/255, B/255] format

color = [145/255, 205/255, 114/255];

for iarg = 1: 2 : nargin - 4
    switch varargin{iarg}
        case 'color'
            color = varargin{iarg + 1};
    end
end

% %Calculate the mean for each column in the waveform vector
% meanWave = mean(waveforms,1);
% 
% %Calculate the standard deviations
% stdDev = std(waveforms);
% upperStd = meanWave + stdDev;
% lowerStd = meanWave - stdDev;

%Plot the waveform and shade upper and lower standard deviations
figure
t = linspace(-windowSize, windowSize, length(meanWaveforms));
fill([t fliplr(t)], [upperStd fliplr(lowerStd)], color, 'edgeColor', color);
alpha(.25);
hold on
plot(t, meanWaveforms, 'color', color, 'lineWidth', 2)
hold on
% plot(t, upperStd, 'k');
% plot(t, lowerStd, 'k');
xlabel('time (ms)');
ylabel('uV');