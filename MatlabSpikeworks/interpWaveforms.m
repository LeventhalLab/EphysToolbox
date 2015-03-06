function [interp_wv, upsample_Fs] = interpWaveforms( wv_data, sincLength, Fs, cutoff_Fs, upsample_Fs )
%
% usage: [interp_wv, upsample_Fs] = interpWaveforms( wv_data, sincLength, Fs, cutoff_Fs, upsample_Fs )
%
% INPUTS:
%   wv_data - the original waveforms, with some buffering at the edges to
%       account for edge effects during the sinc interpolation. An 
%       m x n x p array, where m is the number of timestamps
%       (spikes), n is the number of points in a single waveform, and p is
%       the number of wires
%   sinclength - length of the sinc function for interpolation. This is the
%       number of samples in the ORIGINAL signal, going one direction from the
%       origin. That is, sincLength = p, an input to the function intfilt
%   Fs - the original sampling rate
%   cutoff_Fs - the cutoff frequency of the anti-aliasing filter (may want
%       to make it slightly higher to allow for the transition band)
%   upsample_Fs - the target upsampled frequency. Should be an integer
%       multiple of Fs
%
% varargins:
%
% OUTPUTS:
%   interp_wv - the interpolated signal with dimensions the same as
%       wv_data, except that there are twice as many points per waveform
%   upsample_Fs - the actual upsampled frequency. This could be different
%       from the INPUT variable upsample_Fs if the supplied target upsampled
%       rate is not an integer multiple of Fs

interp_wv = zeros(size(wv_data, 1), size(wv_data, 2) * 2, size(wv_data, 3));

for iWire = 1 : size(wv_data, 3)
    for i_wv = 1 : size(wv_data, 1)
        
        cur_wv = squeeze(wv_data(i_wv, :, iWire));
        % make sure cur_wv is a column vector
        if length(cur_wv) == size(cur_wv, 2); cur_wv = cur_wv'; end

        [y, upsample_Fs] = sincInterp(cur_wv, Fs, cutoff_Fs, ...
            upsample_Fs, 'sinclength', sincLength);
        
        interp_wv(i_wv, :, iWire) = y;
        
    end 
    
end