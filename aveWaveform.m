function aveWaveform(ts, SEVfilename)

[sev, header] = read_tdt_sev(SEVfilename);
windowSize = round(.002*header.Fs);
waveforms = [];
for ii = 1:length(ts)
    waveforms = [waveforms; sev(ts(ii)-windowSize:ts(ii)+windowSize)]     
end    

meanWave = mean(waveforms,1);
stdDev = std(waveforms);
upperStd = meanWave + stdDev;
lowerStd = meanWave - stdDev;
figure
t = linspace(-2, 2, length(meanWave));
fill([t fliplr(t)], [upperStd fliplr(lowerStd)], 'k'];
alpha(.25);
plot(t, meanWave, 'k', 'Linewidth', 2)
hold on
plot(t, upperStd, 'k');
plot(t, lowerStd, 'k');
xlabel('time(ms)');
ylabel('uV');

end