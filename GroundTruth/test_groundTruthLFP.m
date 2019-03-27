% timePeriod = 10;
% Fs = 1000;
% oscillationFreq = [4;10;30;75];
% oscillationOnOff = [0,10;1,2;0,5;6,9];
% oscillationAmp = [1;1;3;2];
% [lfp,t] = groundTruthLFP(timePeriod,Fs,oscillationFreq,oscillationOnOff,oscillationAmp);
% 
% fpass = [1,100];
% nFreqs = 500;
% freqList = exp(linspace(log(fpass(1)),log(fpass(2)),nFreqs)); % 1-100 Hz, 100 points
% W = calculateComplexScalograms_EnMasse(lfp,'Fs',Fs,'freqList',freqList);

% timePeriod = 3;
% Fs = 1000;
% oscillationFreq = [4;6;8];
% oscillationOnOff = [0 2;1 3;1.5 2.5];
% [lfp,t] = groundTruthLFP(timePeriod,Fs,oscillationFreq,oscillationOnOff);

timePeriod = 2;
% Fs = 1000;
oscillationFreq = [2.5];
oscillationOnOff = [1 2];
oscillationAmp = [1];
[lfp,t] = groundTruthLFP(timePeriod,Fs,oscillationFreq,oscillationOnOff,oscillationAmp);

fpass = [1,15];
nFreqs = 100;
freqList = exp(linspace(log(fpass(1)),log(fpass(2)),nFreqs)); % 1-100 Hz, 100 points
W = calculateComplexScalograms_EnMasse(lfp,'Fs',Fs,'freqList',freqList);

ff(1200,600);
subplot(211);
plot(t,lfp);
xticks([0:timePeriod]);
yticks(sort([ylim,0]));
xlabel('Time (s)');
ylabel('Amplitude');
title('LFP signal');
grid on;
set(gca,'fontSize',16);

subplot(212);
imagesc(t,1:numel(freqList),squeeze(mean(abs(W).^2, 2))'); 
colormap parula;
ylabel('Frequency (Hz)')
xlabel('Time (s)');
set(gca,'YDir','normal')
xticks([0:timePeriod]);
yticklabels(compose('%2.1f',freqList(yticks)));
title('Power Spectrogram');
grid on;
set(gca,'fontSize',16);
set(gcf,'color','w');