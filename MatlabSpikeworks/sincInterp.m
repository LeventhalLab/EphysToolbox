function [y_interp, upsample_Fs] =  sincInterp(y, Fs,  cutoff_Fs, upsample_Fs, varargin)
%
% usage: [y_interp, upsample_Fs] =  sincInterp(y, Fs,  cutoff_Fs, upsample_Fs, varargin)
%
% INPUTS:
%   y - the original signal
%   Fs - the original sampling rate
%   cutoff_Fs - the cutoff frequency of the anti-aliasing filter (may want
%       to make it slightly higher to allow for the transition band)
%   upsample_Fs - the target upsampled frequency. Should be an integer
%       multiple of Fs
%
% varargins:
%   sinclength - length of the sinc function for interpolation. This is the
%       number of samples in the ORIGINAL signal, going one direction from the
%       origin. That is, sincLength = p, an input to the function intfilt
%
% OUTPUTS:
%   y_interp - the interpolated signal
%   upsample_Fs - the actual upsampled frequency. This could be different
%       from the INPUT variable upsample_Fs if the supplied target upsampled
%       rate is not an integer multiple of Fs

sincLength = 48; 

for iarg = 1 : 2 : nargin - 4
    switch lower(varargin{iarg})
        case 'sinclength',
            sincLength = varargin{iarg + 1};
    end
end

% figure out the ratio between the upsampled rate and the original sampling
% rate. If not an integer, change the upsampling rate to be an integral
% multiple of the original sampling rate.

   
interp_ratio = ceil(upsample_Fs / Fs);
upsample_Fs = Fs * interp_ratio;

num_origSamples = length(y);
num_upSamples = num_origSamples * interp_ratio;

t = linspace(1/Fs, num_origSamples / Fs, length(y));
t_upsample = linspace(1/upsample_Fs, num_upSamples / upsample_Fs, num_upSamples);

% make sure y is a column vector
if length(y) == size(y, 2); y = y'; end

% y_interp = sinc(t_upsample(:, ones(size(t))) - t(:, ones(size(t_upsample)))') * y;

alpha = cutoff_Fs / (Fs / 2);    % filter low-pass cutoff divided by the Nyquist frequency
h1 = intfilt(interp_ratio, sincLength, alpha);

yr = reshape([y zeros(length(y), interp_ratio-1)]', interp_ratio*length(y), 1);
padLength = ceil(length(h1)/2);

yr = padarray(yr, padLength);

y_interp = filter(h1, 1, yr);

startSamp = padLength + ceil(length(h1)/2)  -1;
y_interp = y_interp(startSamp : startSamp + length(t_upsample) - 1);