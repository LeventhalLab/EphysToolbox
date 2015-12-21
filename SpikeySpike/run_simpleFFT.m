[sev,header] = ezSEV();
hicutoff = 500;
decimateFactor = 10;
dFs = header.Fs / decimateFactor;

sev = decimate(double(sev),decimateFactor);
sev = eegfilt(sev,dFs,[],hicutoff); % lowpass
simpleFFT(sev,dFs);
