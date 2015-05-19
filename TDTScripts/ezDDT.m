function sev=ezDDT()

[f,p]=uigetfile({'*.sev'},'Select File...','~/Documents/Data');
[sev,header] = read_tdt_sev(fullfile(p,f));
sev = wavefilter(sev,6);
sev = artifactThresh(sev,1,600);
ddt_write_v(fullfile(p,[f,'.ddt']),1,length(sev),header.Fs,sev/1000);