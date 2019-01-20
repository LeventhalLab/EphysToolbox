function [W, freqList, t] = calculateComplexScalograms_EnMasse(data, varargin)
%
% this version is slightly different from Alex's original in that phase
% information is retained (the output is complex)
%
% Usage:
% W = calculateGabor_EnMasse(data, 'sigma', 0.2, 'fpass', [1 100], 'numfreqs',
%                   100, 'Fs', 1024)
%
% Input:
% data	- 1D or 2D data array (numsamples x numtrials)
%
% Output:
% W - a 3D array containing the gabor transforms of each signal (numsamples x numtrials x numfreqs)
%
% Parameters:
% fpass: length=2 vector with the lower and upper frequencies to look at.
% numfreqs: the number of frequencies to look at in the fpass range.
% Fs: sampling rate. 
% kernelwidth: calculate the Gabor kernels from -kernelwidth:kernelwidth. 
%         I keep it at 1s after playing with it. Bigger width means more 
%         computation.
% doplot: do an imagesc plot of the gabor analysis. This is what you came 
%         for, probably. (this is on by default)
% showwavelet: show the gabor wavelet (kernel, function, whatever) used for
%         analysis. plots the wavelet using a center frequency in the 
%         middle of the fpass range. (off by default, I use this to get a 
%         sense if my wavelet looks okay)
%
% Description: 
% Convert a 1-D signal "data" into its corresponding
% time-frequency gabor space.
% What's that mean?
% Convolve the signal with a number of gabor
% kernels with varying center frequency.
% A gabor kernel is a complex sinusoid multiplied by a Gaussian,
% so that it doesn't go on forever in both directions.

% gsigma = 0.2; % default SD of the gaussian window
% sigma is not relevant for scalograms; calculated automatically to make
% gaussian window width correlate with center frequency of interest

fpass = [1 100]; % default, look at 1-30Hz
numfreqs = 100; 
Fs = 31250/63;
doplot = 0;
freqList = [];
f_filterBank = [];

if size(varargin)>0
    for iarg= 1:2:length(varargin),   % assume an even number of varargs
        switch lower(varargin{iarg}),
			case 'fpass'
				fpass = varargin{iarg+1};
			case 'numfreqs'
				numfreqs = varargin{iarg+1};
			case {'fs', 'samplingrate'}
				Fs = varargin{iarg+1};
			case {'doplot', 'plot'}
				doplot = varargin{iarg+1};
            case 'freqlist',
                freqList = varargin{iarg + 1};
                numfreqs = length(freqList);
            case 'filterbank'
                f_filterBank = varargin{iarg + 1};
                numfreqs = size(f_filterBank, 2);
        end % end of switch
    end % end of for iarg
end



numOrigSamples = size(data, 1);
data = padarray(data, [round(numOrigSamples/2), 0], 0, 'both');

[numsamples, numtrials] = size(data);

%% Create the filter bank (where each kernel is the length of the signal input)
if isempty(f_filterBank)
    x = linspace(-numsamples/2, numsamples/2, numsamples)/Fs;

    % windowLength = (numsamples/Fs)/2
    % x = linspace(-windowLength, windowLength, numsamples);


    % t_filterBank = zeros(numsamples, numfreqs);

    if isempty(freqList)   % if freqlist explicitly specified by the user, don't manufacture the linearly spaced frequency list
                           % in this case, fpass and numfreqs are unused
        freqList = linspace(fpass(1), fpass(2), numfreqs);
    end
    numfreqs = length(freqList);
    for i=1:numfreqs
        % expand/contract the Gaussian window to accomodate lower/higher
        % frequences instead of using a constant window width -DL 9/28/2011
        
        % effective center frequency is f/a
        % Setting f = 0.849, gsigma = 0.849/frequency of interest
        gsigma = 0.849 / freqList(i);
        gaussWindow = exp( -0.5*(x./gsigma).^2 );
        gaussWindow = padarray(gaussWindow, [0 numsamples - length(gaussWindow)]);
        
        % (1/pi^0.25) is a scaling factor
    	t_filterBank(:,i) = (1/pi^0.25) * gaussWindow.*exp(1i*2*pi*x*freqList(i));
        t_filterBank(:,i) = t_filterBank(:,i) ./ sum(abs(t_filterBank(:,i)));
    end

%     recip_gsigma = freqList ./ 0.849;
%     gaussWindow = exp( -0.5*(x'*recip_gsigma).^2 );
%     sinusoid_matrix = exp(1i*2*pi*x'*freqList);
%     t_filterBank = (1/pi^0.25) * gaussWindow .* sinusoid_matrix;
    % nfft = 2^nextpow2(size(t_filterBank,1));
    % f = Fs*linspace(0,1,size(t_filterBank,1));
    % t = linspace(0,1,size(t_filterBank,1)) * size(t_filterBank,1) / Fs;
    f_filterBank = fft(t_filterBank); % move the kernels into frequency space
end

%% Calculate the Fourier transform of the input signals
f_data = fft(data);

W = zeros(size(data, 1), size(data, 2), numfreqs); % numsamples x numtrials x numfreqs
% for i=1:numfreqs
% 	W(:,:,i) = f_data(:,:);
% end

% For each kernel in the filter bank (# = numfreqs), element-wise
% multiply the kernel in to each signal, and then IFFT the result, 
% then store it in an output 3D array W

for i=1:numtrials
%     W(:,:,i_f) = f_data' * f_filterBank;
	for j=1:numfreqs
		W(:,i,j) = f_data(:,i).*f_filterBank(:,j);
	end
end

% WORKING HERE, SEE IF THIS CAN BE OPTIMIZED BY AVOIDING THE LOOP. ALSO,
% CHECK TO SEE IF THE TWIN PROBLEM MESSED UP THE ACTUAL DATA FILES THAT
% HAVE BEEN STORED ALREADY.


W = ifft(W);
W = circshift(W, [round(numOrigSamples/2) 0]);
W = W(1:numOrigSamples,:,:);

t = [0:size(W,1)]./Fs;
if doplot
	figure; imagesc(t, freqList, squeeze(mean(abs(W).^2, 2))'); 
    colormap jet;
	ylabel('Frequency (Hz)')
	xlabel('Time (s)');
	set(gca, 'YDir', 'normal')
end

end