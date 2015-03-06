function chList = channelTypeFromHeader(hsdHeader, chType)
%
% usage: chList = channelTypeFromHeader(hsdHeader, chType)
%
% INPUTS:
%   hsdHeader - hsd header structure
%   chType - channel types to extract
%       1 - tetrodes
%       2 - refs/stereotrodes
%       3 - eeg/emg/reference
%
% OUTPUTS:
%   chList - vector containing all original numbers for tetrodes

numChannels = hsdHeader.main.num_channels;
channel = hsdHeader.channel;
chList = [];

for iCh = 1 : numChannels
    
    if channel(iCh).channel_type == chType
        chList = [chList, channel(iCh).channel_number];
    end
    
end