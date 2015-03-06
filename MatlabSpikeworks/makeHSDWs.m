function makeHSDWs( varargin )
%
% usage: makeHSDW( varargin )
%
% function to make a .hsdw file from a .hsd file by wavelet filtering each
% wire and writing the results to a .hsdw file
%
% varargins:
%   filename - the name of the .hsd file to decompose
%   targetdir - the directory to save the .hsdw files to
%   wires - vector of wire numbers to decompose

blockSize        = 100000;
bufferLength     = 10000;   % to prevent edge effects
netBlockSize     = blockSize + 2 * bufferLength;
dataType         = 'int16';
bytes_per_sample = getBytesPerSample(dataType);

fn        = '';
targetDir = '';
wires     = [];

for iarg = 1 : 2 : nargin
    switch lower(varargin{iarg})
        case 'filename',
            fn = varargin{iarg + 1};
        case 'targetdir',
            targetDir = varargin{iarg + 1};
        case 'wires',
            wires = varargin{iarg + 1};
    end
end

if isempty(fn)
    [fname, pn, ~] = uigetfile('*.hsd');
    fn = fullfile(pn, fname);
else
    [pn, fname, ~, ~] = fileparts(fn);
end
if isempty(targetDir)
    targetDir = uigetdir(pn);
end

if ~targetDir
    disp('no target directory');
    return;
end

if ~isdir(targetDir)
    mkdir(targetDir);
end

header     = getHSDHeader( fn );
ch         = header.channel;
numCh      = length(ch);
chWireList = [ch.original_number];

if isempty(wires)
    wires  = chWireList;
    ch_idx = 1 : numCh;
else
    % figure out which channel indices to get
    ch_idx = [];
    for iWire = 1 : length(wires)
        curIdx = (chWireList == wires(iWire));
        if any(chWireList == wires(iWire))
            ch_idx = [ch_idx find(curIdx)];
        end
    end
end

% generate names of files in which to save .hsdw files
saveName = cell(1, length(ch_idx));
fout     = zeros(1, length(ch_idx));
for iFile = 1 : length(ch_idx)
    saveName{iFile} = fullfile(targetDir, [fname '_' ch(ch_idx(iFile)).name '.hsdw']);
    fout(iFile)     = fopen(saveName{iFile}, 'w');
end

% now load in the .hsd data in blocks and wavelet filter it
fileInfo   = dir(fn);
numBytes   = fileInfo.bytes;
Fs         = header.main.sampling_rate;
dataOffset = header.dataOffset;

data_bytes = numBytes - dataOffset;
hsdSamples = data_bytes / (bytes_per_sample * numCh);

numBlocks  = ceil(hsdSamples / blockSize);

fin = fopen(fn, 'r');
fseek(fin,dataOffset,'bof');
for iBlock = 1 : numBlocks
    disp(['wavelet filtering ' fname ', block ' num2str(iBlock) ' of ' num2str(numBlocks)]);
    
    hsd = fread(fin, [numCh, netBlockSize], dataType, 0, 'b');
    hsd_to_filt = hsd(ch_idx, :);
    
    fdata = wavefilter(hsd_to_filt, 6);
    if iBlock == 1
        fdata = fdata(:, 1:blockSize);
    elseif iBlock == numBlocks
        fdata = fdata(:, bufferLength+1:end);
    else
        fdata = fdata(:, bufferLength+1:bufferLength+blockSize);
    end
    for iFile = 1 : length(ch_idx)
        fwrite(fout(iFile), fdata(ch_idx(iFile), :), dataType, 0, 'b');
    end
    
    if iBlock == 1
        % if first block, rewind to bufferLength samples before the end of
        % the previous block. This is because 2*bufferLength extra samples
        % are read on the first pass, but bufferLength samples are read in
        % at either side of subsequent passes
        rewindLength = -(bufferLength * 3) * numCh * bytes_per_sample;
    else
        % if not the first block, rewind to bufferLength samples before the
        % end of the previous block
        rewindLength = -(bufferLength * 2)* numCh * bytes_per_sample;
    end
    if iBlock < numBlocks
        fseek(fin, rewindLength, 'cof');
    end
    
end
fclose(fin);
for iFile = 1 : length(ch_idx)
    fclose(fout(iFile));
end

        