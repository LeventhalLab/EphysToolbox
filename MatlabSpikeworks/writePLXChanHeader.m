function writePLXChanHeader( fid, chInfo )
%
% usage: writePLXChanHeader( fid, chInfo )
%
% 	Writes a channel header in a PLX file.
% 	Call multiple times to write multiple channels.
% 	NOTE: in this context, "channel" means "wire".
% 	So, one channel header is necessary for each wire, 
% 	i.e., one tetrode has 4 channel headers.
%     
% see http://hardcarve.com/wikipic/PlexonDataFileStructureDocumentation.pdf
% for info on .plx file structure
%
% INPUTS:
%   fn - file identifier for the .plx file
%   chInfo - structure containing the following:

% make sure the wire name is exactly 32 characters long
if length(chInfo.wireName) > 32
    chInfo.wireName = chInfo.wireName(1:32);
    nameToWrite = uint8(chInfo.wireName);
else
    numBlanks = 32 - length(chInfo.wireName);
%     chInfo.wireName = [chInfo.wireName, blanks(numBlanks)];
    nameToWrite = [uint8(chInfo.wireName), zeros(1, numBlanks)];
end
% fwrite(fid, chInfo.wireName, 'char*1', 0, 'l');
fwrite(fid, nameToWrite, 'uint8', 0, 'l');

% make sure the tetrode name is exactly 32 characters long
if length(chInfo.tetName) > 32
    chInfo.tetName = chInfo.tetName(1:32);
    tetToWrite = uint8(chInfo.tetName);
else
    numBlanks = 32 - length(chInfo.tetName);
%     chInfo.tetName = [chInfo.tetName, blanks(numBlanks)];
    tetToWrite = [uint8(chInfo.tetName), zeros(1, numBlanks)];
end
fwrite(fid, tetToWrite, 'uint8', 0, 'l');

fwrite(fid, chInfo.wireNum, 'int32', 0, 'l');
fwrite(fid, chInfo.WFRate, 'int32', 0, 'l');    % not exactly sure what this is; Alex had it set to zero
fwrite(fid, chInfo.SIG, 'int32', 0, 'l');
fwrite(fid, chInfo.refWire, 'int32', 0, 'l');   % not exactly sure what this is; Alex had it set to zero
fwrite(fid, chInfo.gain, 'int32', 0 , 'l');     % actual gain divided by SpikePreAmpGain
fwrite(fid, chInfo.filter, 'int32', 0, 'l');    % 0 or 1 - boolean for plexon systems and whether filter was in place?
fwrite(fid, chInfo.thresh, 'int32', 0, 'l');    % threshold for spike detection in a/d values
fwrite(fid, 1, 'int32', 0, 'l');			% sort-type; standard is "box sorting"; not sure what this means
fwrite(fid, chInfo.numUnits, 'int32', 0, 'l');			% number of sorted units; zero to start
fwrite(fid, zeros(1, 320), 'int16', 0, 'l');	% Pad the short Templates[5][64] spot (in plexon, would be spike templates)
fwrite(fid, zeros(1, 5), 'int32', 0, 'l');	% Pad the int Fit[5] spot; has something to do with template matching in Offline sorter
fwrite(fid, chInfo.sortWidth, 'int32', 0, 'l');	% number of points to use in template sorting
fwrite(fid, zeros(1, 40), 'int16', 0, 'l');	% Pad the short Boxes[5][2][4] spot
fwrite(fid, 0, 'int32', 0, 'l');		% Pad the int SortBeg spot (beginning of the sorting window for template sorting)

% make sure the comment is exactly 128 characters long
if length(chInfo.comment) > 128
    chInfo.comment = chInfo.comment(1:128);
    commentToWrite = uint8(chInfo.comment);
else
    numBlanks = 128 - length(chInfo.comment);
%     chInfo.comment = [chInfo.comment, blanks(numBlanks)];
    commentToWrite = [uint8(chInfo.comment), zeros(1, numBlanks)];
end
fwrite(fid, commentToWrite, 'uint8', 0, 'l');	% comment we're not typically using
fwrite(fid, zeros(1, 11), 'int32', 0, 'l');	% padding to finish it off (what the heck does this mean?)