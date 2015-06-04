function aveWaveform(ts, SEVfilename)
%Function to plot the average waveform of a unit with the peak centered at
%zero. Default color of summer tree green. Default window size of 4 ms.
%
%Inputs: 
%   ts - vector of time stamps
%   SEVfilename - the path for the SEV file of interest
% 
% possible variable inputs: color, window size

summerTreeColor = [145/255, 205/255, 114/255];

%Read in data and filter
[sev, header] = read_tdt_sev(SEVfilename);
[b,a] = butter(4, [.02, .2]);
for ii = 1:size(sev,1)
    sev(ii,:) = filtfilt(b,a,double(sev(ii,:)));
end

windowSize = round(.002*header.Fs);
waveforms = [];

%Create the segments of the wave form that are 2ms on either side of the
%peak
for ii = 1:length(ts)
    waveforms = [waveforms; sev(round(header.Fs*ts(ii))-windowSize:round(header.Fs*ts(ii))+windowSize)]     
end    

%Calculate the mean for each column in the waveform vector
meanWave = mean(waveforms,1);

%Calculate the standard deviations
stdDev = std(waveforms);
upperStd = meanWave + stdDev;
lowerStd = meanWave - stdDev;

%Plot the waveform and shade upper and lower standard deviations
figure
t = linspace(-2, 2, length(meanWave));
fill([t fliplr(t)], [upperStd fliplr(lowerStd)], summerTreeColor, 'edgeColor', summerTreeColor);
alpha(.25);
hold on
plot(t, meanWave, 'color', summerTreeColor, 'lineWidth', 2)
hold on
% plot(t, upperStd, 'k');
% plot(t, lowerStd, 'k');
xlabel('time (ms)');
ylabel('uV');
title('T05 W01a')

end