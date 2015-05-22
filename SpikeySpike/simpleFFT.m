function simpleFFT(data,Fs)
T = 1/Fs; % Sample time
L = length(data); % Length of signal
t = (0:L-1)*T; % Time vector
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
f = Fs/2*linspace(0,1,NFFT/2+1);

Y = fft(double(data),NFFT)/L;
A = 2*abs(Y(1:NFFT/2+1));

figure;
plot(f,A);
xlim([10 2000]);
xlabel('Frequency (Hz)')
ylabel('|Y(f)|')