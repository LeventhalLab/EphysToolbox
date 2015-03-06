function cma=commonModeSEV(dataDir,exclude)
% generates a single common mode averaged array that can be subtracted from
% other data arrays to reduce system-wide artifact

sevFiles = dir(fullfile(dataDir,'*.sev'));
count = 1;
for i=1:length(sevFiles)
    ch = getSEVChFromFilename(sevFiles(i).name);
    if(ismember(ch,exclude))
        disp(['Skipping ',sevFiles(i).name]);
        continue;
    end
    [sev, ~] = read_tdt_sev(fullfile(dataDir,sevFiles(i).name));
    if(count == 1)
        cma = sev;
    else
        cma = mean([cma sev]);
    end
end