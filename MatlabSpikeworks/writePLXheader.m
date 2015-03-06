function writePLXheader( fid, plxInfo )

% see http://hardcarve.com/wikipic/PlexonDataFileStructureDocumentation.pdf
% for info on .plx file structure
%

% I'm still not sure what a "slow" channel is - an LFP channel?

% make sure the comment is 128 characters long
if length(plxInfo.comment) > 128
    plxInfo.comment = plxInfo.comment(1:128);
else
    numBlanks = 128 - length(plxInfo.comment);
    plxInfo.comment = [plxInfo.comment, blanks(numBlanks)];
end

fwrite(fid, 1480936528, 'int32', 0, 'l');         % magic number at start of .plx file; this is what was in Alex's .plx files
fwrite(fid, 105, 'int32', 0, 'l');                % version number
fwrite(fid, plxInfo.comment, 'char', 0, 'l');     % comment
fwrite(fid, plxInfo.ADFs, 'int32', 0, 'l');       % sampling rate of AD converter; used to get timestamps(seconds) = timestamps(clock ticks) / ADFs
fwrite(fid, plxInfo.numWires, 'int32', 0, 'l');   % number of wires (1, 2, or 4 for single wires, stereotrodes, or tetrodes respectively)
fwrite(fid, plxInfo.numEvents, 'int32', 0, 'l');  % number of event channels
fwrite(fid, plxInfo.numSlows, 'int32', 0, 'l');   % number of slow channels (I'm not sure what this entry or the previous one are actually for - both are zero in Alex's code)
fwrite(fid, plxInfo.waveLength, 'int32', 0, 'l'); % number of points per waveform
fwrite(fid, plxInfo.peakLoc, 'int32', 0, 'l');    % points before waveform peak

fwrite(fid, plxInfo.year, 'int32', 0, 'l');       % date (year, month, day, hour, minute)
fwrite(fid, plxInfo.month, 'int32', 0, 'l');
fwrite(fid, plxInfo.day, 'int32', 0, 'l');
fwrite(fid, plxInfo.hour, 'int32', 0, 'l'); 
fwrite(fid, plxInfo.minute, 'int32', 0, 'l');
fwrite(fid, plxInfo.second, 'int32', 0, 'l');

fwrite(fid, 0, 'int32', 0, 'l');                  % fast read (not sure what this is)
fwrite(fid, plxInfo.waveFs, 'int32', 0, 'l');     % sampling rate of the waveform (may be different from ADFs)
fwrite(fid, plxInfo.dataLength, 'double', 0, 'l'); % last timestamp in clock ticks. Length in seconds = dataLength / ADFs

% fwrite(fid, plxInfo.next4fields, 'char*1', 0, 'l');
fwrite(fid, plxInfo.Trodalness, 'uint8', 0, 'l'); % 1 for single wires, 2 for stereotrodes, 4 for tetrodes
fwrite(fid, plxInfo.dataTrodalness, 'uint8', 0, 'l'); % not exactly sure how this differs from Trodalness above
fwrite(fid, plxInfo.bitsPerSpikeSample, 'uint8', 0, 'l');  % ADC resolution for spike waveforms in bits
fwrite(fid, plxInfo.bitsPerSlowSample, 'uint8', 0, 'l');   % ADC resolution for slow-channel data in bits

fwrite(fid, plxInfo.SpikeMaxMagnitudeMV, 'uint16', 0, 'l'); % zero-to-peak voltage in mV for the spike waveform
fwrite(fid, plxInfo.SlowMaxMagnitudeMV, 'uint16', 0, 'l');  % zero-to-peak voltage in mV for the slow-channel adc values
fwrite(fid, plxInfo.SpikePreAmpGain, 'uint16', 0, 'l');     % pre-amp gain; 1 for standard Berke lab rigs

fwrite(fid, zeros(1, 46), 'uint8', 0, 'l');    % pad 46 bytes

fwrite(fid, zeros(1, 650), 'int32', 0, 'l');  % TSCounts (130x5 array that we're not using)
fwrite(fid, zeros(1, 650), 'int32', 0, 'l');  % WFCounts (130x5 array that we're not using)
fwrite(fid, zeros(1, 512), 'int32', 0, 'l');  % EVCounts (512 element vector that we're not using)