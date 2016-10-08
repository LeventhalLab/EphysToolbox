function [A,f] = simpleFFT(varargin)
% simpleFFT(data,Fs,newFigure);

data = varargin{1};
Fs = varargin{2};
T = 1/Fs; % Sample time
L = length(data); % Length of signal
t = (0:L-1)*T; % Time vector
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
f = Fs/2*linspace(0,1,NFFT/2+1);

Y = fft(double(data),NFFT)/L;
A = 2*abs(Y(1:NFFT/2+1));

if length(varargin) > 2
    if varargin{3}
        figure;
    else
        hold on;
    end
    semilogy(f,smooth(A,round(Fs/1000)));
    xlim([10 100]);
    xlabel('Frequency (Hz)')
    ylabel('|Y(f)|')
end