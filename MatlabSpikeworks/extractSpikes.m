function extractSpikes( hsdFile, varargin )
%
% usage: extractSpikes( hsdFile, varargin )
%
% This function will
%
% INPUTS:
%   hsdFile - name of the .hsd file to be processed, including the path
%
% VARARGs:
%   tetrodes - vector containing tetrodes on which to extract spikes
%   refs - vector containing refs (stereotrodes) on which to extract spikes
%   wires - single wires on which to extract spikes
%   usewires - 
%
% REQUIRED M-FILES:
%   appendNexWaveforms
%   channelTypeFromHeader
%   extract_timestamps_sincInterp
%   getBytesPerSample
%   getHSDHeader
%   getHSDlength
%   gettimestampsSNLE
%   lfpFs
%   readHSD
%   wavefilter

% consider adding a functionality to create a PDF of the thresholding so
% that the user can go back later and see if they're satisfied with it (for
% example, plot the threshold on top of the SNLE and wavelet-filtered data
% for each wire)


validTets        = [];
validRefs        = [];
validWires       = [];
startTime        = 0;
endTime          = getHSDlength('filename', hsdFile);
rel_threshold    = 4.5;   % in units of standard deviation (or median!)
numSigmaSegments = 60;  % number of segments to use to calculate the standard deviation of the signal on each wire
sigmaChunkLength = 1;   % duration in seconds of data chunks to use to extract the standard deviations of the wavelet-filtered signals
dataType         = 'int16';
machineFormat    = 'b';
r_upsample       = 2;     % the upsampling ratio
snle_window      = 12 * r_upsample;    % Alex's default % changed by RS to include upsampling rate
useValidTets     = false;
useValidRefs     = false;
waveLength       = 24;    % width of waveform sampling window in A-D clock ticks
peakLoc          = 8;     % location of waveform peak in A-D clock ticks
deadTime         = 16;    % dead time in A-D clock ticks
overlapTolerance = 16;     % amount waveforms can overlap on different wires
                          % of the same tetrode (in A-D clock ticks) and
                          % still be counted as the same waveform
maxSNLE          = 10^7;  % maximum allowable non-linear energy. Any values 
                          % greater than this are assumed to be noise and
                          % are not included in the standard deviation
                          % calculations (but are thresholded and
                          % extracted as potential spikes)
extractWires = false;

for iarg = 1 : 2 : nargin - 1
    
    switch lower(varargin{iarg})
        
        case 'tetrodes',
            validTets    = varargin{iarg + 1};
            useValidTets = true;
        case 'refs',
            validRefs    = varargin{iarg + 1};
            useValidRefs = true;
        case 'wires',
            validWires = varargin{iarg + 1};
        case 'usewires',
            extractWires = true;
        case 'starttime',
            startTime = varargin{iarg + 1};
        case 'endtime',
            endTime = varargin{iarg + 1};
        case 'threshold',
            rel_threshold = varargin{iarg + 1};
        case 'numsigmasegments',
            numSigmaSegments = varargin{iarg + 1};
        case 'datatype',
            dataType = varargin{iarg + 1};
        case 'machineformat',
            machineFormat = varargin{iarg + 1};
        case 'upsampleratio',
            r_upsample = varargin{iarg + 1};
        case 'wavelength',
            waveLength = varargin{iarg + 1};
        case 'peakloc',
            peakLoc = varargin{iarg + 1};
        case 'deadtime',
            deadTime = varargin{iarg + 1};
        case 'overlaptolerance',
            overlapTolerance = varargin{iarg + 1};
        case 'maxsnle',
            maxSNLE = varargin{iarg + 1};
            
    end
    
end

maxLevel = r_upsample + 5;   % max wavelet filtering level = upsampling ratio + 5

[hsd_pn, ~, ~] = fileparts(hsdFile);
if isempty(hsd_pn)
    hsd_pn = pwd;
end
[rawDataPath, sessionName, ~] = fileparts(hsd_pn);
[subjectPath, ~, ~]           = fileparts(rawDataPath);
[~, subjectName, ~]           = fileparts(subjectPath);
% sessionHyphenIdx = strfind(sessionName, '_');
% subjectNameEnd = sessionHyphenIdx(1) - 1;
% subjectName = sessionName(1:subjectNameEnd);

processedPath                 = fullfile(subjectPath, [subjectName '-processed']);
% processedPath                 = fullfile(processedRoot, [subjectName '-processed']);
processedSessionPath          = fullfile(processedPath, sessionName);


if ~exist(processedSessionPath, 'dir')
    mkdir(processedSessionPath);
end

% get the hsd header
hsdHeader    = getHSDHeader(hsdFile);
num_channels = hsdHeader.main.num_channels;

wirelist = 1 : num_channels;
alltets  = channelTypeFromHeader(hsdHeader, 1);
allrefs  = channelTypeFromHeader(hsdHeader, 2);
tetrodes = unique(alltets);
refs     = unique(allrefs);

if isempty(validTets)
    if useValidTets
        validTets = validTets;
    else
        validTets = tetrodes;
    end
end
if isempty(validRefs)
    if useValidRefs
        validRefs = validRefs;
    else
        validRefs = refs;
    end
end
if isempty(validWires) && extractWires
    validWires = wirelist;
end

numTets        = length(validTets);
numRefs        = length(validRefs);
numSingleWires = length(validWires);

wirespertet = getChannelWires(hsdHeader, validTets, 1);
wiresperref = getChannelWires(hsdHeader, validRefs, 2);

% loop through all tetrodes, refs, and single wires. Get standard deviations for the signals on
% each wire
tetWireStd = zeros(numTets, 4);
for iTet = 1 : numTets
    disp(['calculating single wire standard deviations for tetrode ' num2str(validTets(iTet))]);
    tetWireStd(iTet, :) = extractSigma_snle(hsdFile, wirespertet(iTet, :), ...
        numSigmaSegments, sigmaChunkLength, r_upsample, 'datatype', dataType, ...
        'machineformat', machineFormat, 'snlewindow', snle_window, ...
        'maxlevel', maxLevel, 'maxsnle', maxSNLE);
end
refWireStd = zeros(numRefs, 2);
for iRef = 1 : numRefs
    disp(['calculating single wire standard deviations for ref ' num2str(validRefs(iRef))]);
    refWireStd(iRef, :) = extractSigma_snle(hsdFile, wiresperref(iRef, :), ...
        numSigmaSegments, sigmaChunkLength, r_upsample, 'datatype', dataType, ...
        'machineformat', machineFormat, 'snlewindow', snle_window, ...
        'maxlevel', maxLevel, 'maxsnle', maxSNLE);
end
singleWireStd = zeros(numSingleWires, 1);
for iWire = 1 : numSingleWires
    disp(['calculating single wire standard deviations for wire ' num2str(validWires(iWire))]);
    singleWireStd(iWire, 1) = extractSigma_snle(hsdFile, validWires(iWire), ...
        numSigmaSegments, sigmaChunkLength, r_upsample, 'datatype', dataType, ...
        'machineformat', machineFormat, 'snlewindow', snle_window, ...
        'maxlevel', maxLevel, 'maxsnle', maxSNLE);
end

tet_thresholds  = rel_threshold * tetWireStd;
ref_thresholds  = rel_threshold * refWireStd;
wire_thresholds = rel_threshold * singleWireStd;
%%%%%%%%%%%%%%%%%%%
% at this point, should have standard deviations for the wavelet filtered
% signal on each relevant wire - now time to do the thresholding!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iTet = 1 : numTets
    extract_PLXtimestamps_sincInterp( hsdFile, processedSessionPath, wirespertet(iTet, :), tet_thresholds(iTet, :), ...
                                      'datatype', dataType, ...
                                      'wavelength', waveLength, ...
                                      'peakloc', peakLoc, ...
                                      'deadtime', deadTime, ...
                                      'upsampleratio', r_upsample, ...
                                      'overlaptolerance', overlapTolerance);
end
%%%%%%%%%%%%%%%
% ref_thresholds = 1e3 * [3.4568, 1.5629];
% this is just to speed things up for debugging; kill the above line later
for iRef = 1 : numRefs
    extract_PLXtimestamps_sincInterp( hsdFile, processedSessionPath, wiresperref(iRef, :), ref_thresholds(iRef, :), ...
                                      'datatype', dataType, ...
                                      'wavelength', waveLength, ...
                                      'peakloc', peakLoc, ...
                                      'deadtime', deadTime, ...
                                      'upsampleratio', r_upsample, ...
                                      'overlaptolerance', overlapTolerance);
end
for iWire = 1 : numSingleWires
    extract_PLXtimestamps_sincInterp( hsdFile, processedSessionPath, validWires(iWire), wire_thresholds(iWire, :), ...
                                      'datatype', dataType, ...
                                      'wavelength', waveLength, ...
                                      'peakloc', peakLoc, ...
                                      'deadtime', deadTime, ...
                                      'upsampleratio', r_upsample, ...
                                      'overlaptolerance', overlapTolerance);
end
%read HSD, user input = file, wires = all, wire# or tetrode#, starttime, endtime)
%alter wirelist to include all, defined wire channels, or 4 channels

