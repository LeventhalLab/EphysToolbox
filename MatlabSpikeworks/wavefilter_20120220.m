function fdata = wavefilter_20120220(data, maxlevel, Fs, upsample_rate)
% fdata = wavefilter(data, maxlevel, Fs, upsample_rate)
% data	- an N x M array of continuously-recorded raw data
%		where N is the number of channels, each containing M samples
% maxlevel - the level of decomposition to perform on the data. This integer
%		implicitly defines the cutoff frequency of the filter.
% 		Specifically, cutoff frequency = samplingrate/(2^(maxlevel+1))
% Fs - original sampling rate (Hz)
% upsample_rate - target upsampling rate (Hz). If upsample_rate and Fs are
%       equal, no upsampling interpolation is performed
%
% Matlab code for wavelet filtering.
% This function requires the Wavelet Toolbox.
% added 2-2012: functionality to upsample using sinc interpolation prior to
% wavelet filtering
%
% For a reference on wavelet vs standard filtering,
% see Wiltschko, Gage, and Berke "Wavelet filtering before spike detection
% preserves waveform shape and enhances single-unit discrimination", J
% Neurosci Methods, vol 173, issue 1, 2008
%
% For a reference on upsampling by sinc interpolation, see
% Blanche and Swindale, "Nyquist interpolation improves neuron yield in
% multiunit recordings", J Neurosci Methods, vol 155, iss 1, 2006
%
% original code by Alex Wiltschko
% upsampling by sinc interpolation added by Dan Leventhal 2-20-2012

[numwires, numpoints] = size(data);
fdata = zeros(numwires, numpoints);

% We will be using the Daubechies(4) wavelet.
% Other available wavelets can be found by typing 'wavenames'
% into the Matlab console.
wname = 'db4'; 

for i=1:numwires % For each wire
    % Decompose the data
    [c,l] = wavedec(data(i,:), maxlevel, wname);
    % Zero out the approximation coefficients
    c = wthcoef('a', c, l);
    % then reconstruct the signal, which now lacks low-frequency components
    fdata(i,:) = waverec(c, l, wname);
end