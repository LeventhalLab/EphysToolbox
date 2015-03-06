function waveFilter_MER(varargin)
%
% usage: 
%
%

blockSize        = 100000;
bufferLength     = 10000;   % to prevent edge effects
netBlockSize     = blockSize + 2 * bufferLength;
dataType         = 'int16';
bytes_per_sample = getBytesPerSample(dataType);
numCh = 1;

fn        = '';
targetDir = '';

for iarg = 1 : 2 : nargin
    switch lower(varargin{iarg})
        case 'filename',
            fn = varargin{iarg + 1};
        case 'targetdir',
            targetDir = varargin{iarg + 1};
    end
end

if isempty(fn)
    [fname, pn, ~] = uigetfile('*.bin');
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

% generate names of files in which to save .hsdw files
saveName = fullfile(targetDir, [fname '.hsdw']);
fout     = fopen(saveName, 'w');

% now load in the .hsd data in blocks and wavelet filter it
fileInfo   = dir(fn);
numBytes   = fileInfo.bytes;
Fs         = 30000;    % for the OR MER recordings; can change in the future
dataOffset = 0;

data_bytes = numBytes - dataOffset;
hsdSamples = data_bytes / (bytes_per_sample * numCh);

numBlocks  = ceil(hsdSamples / blockSize);

fin = fopen(fn, 'r');
fseek(fin,dataOffset,'bof');
for iBlock = 1 : numBlocks
    disp(['wavelet filtering ' fname ', block ' num2str(iBlock) ' of ' num2str(numBlocks)]);
    
    hsd = fread(fin, [numCh, netBlockSize], dataType, 0, 'l');      % OR MER data written little-endian, unlike LabView on windows
    hsd_to_filt = hsd(1, :);
    
    fdata = wavefilter(hsd_to_filt, 6);
    if iBlock == 1
        fdata = fdata(:, 1:blockSize);
    elseif iBlock == numBlocks
        fdata = fdata(:, bufferLength+1:end);
    else
        fdata = fdata(:, bufferLength+1:bufferLength+blockSize);
    end
    fwrite(fout, fdata(1, :), dataType, 0, 'l');   % OR MER data written little-endian, unlike LabView on windows
    
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

fclose(fout);

        