function aveWaveform(ts, SEVfilename)
summerTreeColor = [145/255, 205/255, 114/255];
[sev, header] = read_tdt_sev(SEVfilename);
[b,a] = butter(4, [.02, .2]);
for ii = 1:size(sev,1)
    sev(ii,:) = filtfilt(b,a,double(sev(ii,:)));
end
windowSize = round(.002*header.Fs);
waveforms = [];
for ii = 1:length(ts)
    waveforms = [waveforms; sev(round(header.Fs*ts(ii))-windowSize:round(header.Fs*ts(ii))+windowSize)]     
end    

meanWave = mean(waveforms,1);
stdDev = std(waveforms);
upperStd = meanWave + stdDev;
lowerStd = meanWave - stdDev;
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