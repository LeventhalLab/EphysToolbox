% Matlab code for wavelet filtering.
% This function requires the Wavelet Toolbox.

function fdata = wavefilter(data, maxlevel, varargin)
%
% usage: fdata = wavefilter(data, maxlevel, varargin)
%
% INPUTS:
%   data - an N x M array of continuously-recorded raw data
%		where N is the number of channels, each containing M samples
%   maxlevel - the level of decomposition to perform on the data. This integer
%		implicitly defines the cutoff frequency of the filter.
% 		Specifically, cutoff frequency = samplingrate/(2^(maxlevel+1))
% 
% VARARGs:
%   validMask - vector of booleans indicating whether a given channel has a
%       clean signal. Set elements to zero to prevent wavelet filtering of
%       "garbage" data, hopefully this will make things run faster

validMask = ones(size(data,1), 1);

for iarg = 1 : 2 : nargin - 2
    switch lower(varargin{iarg})
        case 'validmask',
            validMask = varargin{iarg + 1};
    end
end

[numwires, numpoints] = size(data);
fdata = zeros(numwires, numpoints);

% We will be using the Daubechies(4) wavelet.
% Other available wavelets can be found by typing 'wavenames'
% into the Matlab console.
wname = 'db4'; 

for i=1:numwires % For each wire
    if validMask(i)
        % Decompose the data
        [c,l] = wavedec(data(i,:), maxlevel, wname);
        % Zero out the approximation coefficients
        c = wthcoef('a', c, l);
        % then reconstruct the signal, which now lacks low-frequency components
        fdata(i,:) = waverec(c, l, wname);
    end
end