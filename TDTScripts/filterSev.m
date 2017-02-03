function [sevFilt,header] = filterSev(sevFile)

[b,a] = butter(4, [0.02 0.5]); % high pass
[sev,header] = read_tdt_sev(sevFile);
sevFilt = filtfilt(b,a,double(sev));