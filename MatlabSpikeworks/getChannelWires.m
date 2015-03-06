function wiresPerChannel = getChannelWires(hsdHeader, chList, chType)
%
% usage: wiresPerChannel = getChannelWires(hsdHeader, chList, chType)
%
% INPUTS:
%   hsdHeader - hsd header structure
%   chList - list of channels to extract (ie, tetrodes 1, 3, 4 or refs 2,
%       3, etc.)
%   chType - type of channel (are we looking for tetrodes or stereotrodes?)
%       1 - tetrodes, 2 - stereotrodes/refs, 3 - single wires
%
% OUTPUTS:
%   wiresPerChannel - m x n matrix; m = number of channels, n = number of
%       wires/channel (4 for tetrodes, 2 for stereotrodes)

channel = hsdHeader.channel;

switch chType
    case 1,
        numWiresPerChannel = 4;
    case 2,
        numWiresPerChannel = 2;
end

wiresPerChannel = zeros(length(chList), numWiresPerChannel);

for iCh = 1 : length(chList)
    
    % find all wires for this tetrode/stereotrode
    numChannelWires = 0;
    
    for iHeaderChan = 1 : length(channel)
        
        if channel(iHeaderChan).channel_type == chType
            
            if channel(iHeaderChan).channel_number == chList(iCh)
                
                numChannelWires = numChannelWires + 1;
                
                if numChannelWires > numWiresPerChannel
                    error(['too many wires for channel ' num2str(chList(iCh))]);
                end
                
                wireNum = channel(iHeaderChan).wire_number;
                wiresPerChannel(iCh, wireNum) = channel(iHeaderChan).original_number;
                
            end
            
        end
        
    end
    
    if numChannelWires < numWiresPerChannel
        error(['too few wires for channel ' num2str(chList(iCh))]);
    end
    
end