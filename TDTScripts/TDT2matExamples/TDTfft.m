function fft_data = TDTfft(data, channel, varargin)
%TDTFFT  performs a frequency analysis of the data stream
%   fft_data = TDTfft(DATA, CHANNEL), where DATA is a stream from the 
%   output of TDT2mat and CHANNEL is an integer.
%
%   fft_data    contains power spectrum array
%
%   fft_data = TDTfft(DATA, CHANNEL,'parameter',value,...)
%
%   'parameter', value pairs
%      'PLOT'       boolean, set to false to disable figure
%      'NUMAVG'     scalar, number of subsets of data to average together
%                   in fft_data (default = 1)
%      'SPECPLOT'   boolean, include spectrogram plot (default = false)
%
%   Example
%      data = TDT2mat('DEMOTANK2', 'Block-1');
%	   TDTfft(data.streams.Wave, 1);

% defaults
PLOT     = true;
NUMAVG   = 1;
SPECPLOT = false;

% parse varargin
for i = 1:2:length(varargin)
    eval([upper(varargin{i}) '=varargin{i+1};']);
end

numplots = 3;
if SPECPLOT, numplots = 4; end;

y = data.data(channel,:);
Fs = data.fs;

T = 1/Fs;  % Sample time
L = numel(y);   % Length of signal
t = (0:L-1)*T;  % Time vector

% do averaging here, if we are doing it
if NUMAVG > 1
    NFFT = 2^nextpow2(L/NUMAVG); % Next power of 2 from length of y
    step = floor(L/NUMAVG);
    for i = 0:NUMAVG-1
        d = y(1+(i*step):(i+1)*step);
        Y = fft(d,NFFT)/numel(d);
        f = Fs/2*linspace(0,1,NFFT/2+1);
        d = 2*abs(Y(1:NFFT/2+1));
        if i == 0
            fft_data = d;
        else
            fft_data = fft_data + d;
        end
    end
    fft_data = fft_data/NUMAVG;
else
    NFFT = 2^nextpow2(L); % Next power of 2 from length of y
    Y = fft(y,NFFT)/L;
    f = Fs/2*linspace(0,1,NFFT/2+1);

    fft_data = 2*abs(Y(1:NFFT/2+1));    
end

if ~PLOT, return, end
    
figure;
subplot(numplots,1,1);

% set time scale
if round(max(t)) == 0
    t = t*1000;
    x_units = 'ms';
else
    x_units = 's';
end
plot(t,y)

xlabel(['Time (' x_units ')'])
axis([0 t(end) min(y)*1.05 max(y)*1.05]);

% set voltage scale
r = rms(y);
if round(r*1e6) == 0
    r = r*1e9;
    y_units = 'nV';
elseif round(r*1e3) == 0
    r = r*1e6;
    y_units = 'uV';
elseif round(r) == 0
    r = r*1000;
    y_units = 'mV';
else
    y_units = 'V';
end
ylabel(y_units)
title(sprintf('Raw Signal (%.2f %srms)', r, y_units))

% Plot single-sided amplitude spectrum.
subplot(numplots,1,2);
plot(f, fft_data)
title('Single-Sided Amplitude Spectrum of y(t)')
xlabel('Frequency (Hz)')
ylabel('|Y(f)|')
axis([0 f(end) 0 max(fft_data)*1.05]);

subplot(numplots,1,3)
fft_data = 20*log10(fft_data);
plot(f, fft_data)
title('Power Spectrum')
xlabel('Frequency (Hz)')
ylabel('dBV')
axis([0 f(end) min(fft_data)*1.05 max(fft_data)/1.05]);

if ~SPECPLOT, return, end
subplot(numplots,1,4)
spectrogram(double(y),256,240,256,Fs,'yaxis'); 