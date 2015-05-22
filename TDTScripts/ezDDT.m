function sev=ezDDT()
[b,a] = butter(4, [0.02 0.2]);

[f,p]=uigetfile({'*.sev'},'Select File...','~/Documents/Data');
[sev,header] = read_tdt_sev(fullfile(p,f));
sev = filtfilt(b,a,double(sev));
sev = artifactThresh(sev,1,600);
ddt_write_v(fullfile(p,[f,'.ddt']),1,length(sev),header.Fs,sev/1000);