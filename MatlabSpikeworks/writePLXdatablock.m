function writePLXdatablock( fid, spikes, ts )
%
% usage: writePLXdatablock( fid, spikes, ts )
%
% Write PLX datablocks corresponding to the data
% found in the arrays spikes, ts, and channel
% We assume these are spikes on the given channel, 
% of the length of the waveforms given in spikes
%
% INPUTS:
%	fid - pointer to an open PLX file with headers written in (using writePLXfileheader and  writePLXchanheader)
%	spikes     - numspikes by len(spike) by 4 array of spikes on a tetrode (the actual waveforms?)
%	channel    - the channel number that the spikes are found on
%	ts         - time-stamps corresponding the spikes (int16's in tick counts, I think - DL 20120515)


% Only the time-stamps, spikes & channel number change when writing all spikes and 
% time-stamps out from a particular channel, so we can make 
% slices of byte-bread to sandwich the time-stamp that stay constant

numSpikes = size(spikes, 1);
numWires  = size(spikes, 3);    % check that the dimensions are correct for my data structures
for iSpike = 1 : numSpikes
    for iWire = 1 : numWires
   
        fwrite(fid, 1,'int16', 0, 'l');    % not sure why these constants are written, but it worked in Alex's python code
        fwrite(fid, 0,'int16', 0, 'l');
        fwrite(fid, ts(iSpike),'uint32', 0, 'l');    % write the timestamp
        fwrite(fid, iWire, 'int16', 0, 'l');
        fwrite(fid, [0 1 size(spikes, 2)], 'int16', 0, 'l');
        fwrite(fid, squeeze(spikes(iSpike, :, iWire)), 'int16', 0, 'l');
        
    end
end

