function waveforms = aveWaveform(ts, SEVfilename, varargin)
%Function to plot the average waveform of a unit with the peak centered at
%zero. Default color of summer tree green. Default window size of 4 ms.
%
%Inputs: 
%   ts - vector of time stamps
%   SEVfilename - the path for the SEV file of interest
% 
% possible variable inputs: color (in [R/255, B/255, G/255] format), window
% size (in milliseconds)
%
% Outputs:
%   waveforms - vector to plot the waveform later




% color = [145/255, 205/255, 114/255];
windowSize = .002;

for iarg = 1: 2 : nargin - 2
    switch varargin{iarg}
%         case 'color'
%             color = varargin{iarg + 1};
        case 'windowSize'
            windowSize = varargin{iarg + 1};
    end
end

%Read in data and filter
[sev, header] = read_tdt_sev(SEVfilename);
window = round((windowSize/1000)* header.Fs);
[b,a] = butter(4, [.02, .2]);
for ii = 1:size(sev,1)
    sev(ii,:) = filtfilt(b,a,double(sev(ii,:)));
end

waveforms = [];

%Create the segments of the wave form that are 2ms on either side of the
%peak
for ii = 1:length(ts)
    waveforms = [waveforms; sev(round(header.Fs*ts(ii))-window:round(header.Fs*ts(ii))+window)];     
end    

% %Calculate the mean for each column in the waveform vector
% meanWave = mean(waveforms,1);
% 
% %Calculate the standard deviations
% stdDev = std(waveforms);
% upperStd = meanWave + stdDev;
% lowerStd = meanWave - stdDev;
% 
% %Plot the waveform and shade upper and lower standard deviations
% figure
% t = linspace(-windowSize, windowSize, length(meanWave));
% fill([t fliplr(t)], [upperStd fliplr(lowerStd)], color, 'edgeColor', color);
% alpha(.25);
% hold on
% plot(t, meanWave, 'color', color, 'lineWidth', 2)
% hold on
% % plot(t, upperStd, 'k');
% % plot(t, lowerStd, 'k');
% xlabel('time (ms)');
% ylabel('uV');
end