function [sev,header]=ezSEV()
    [f,p]=uigetfile({'*.sev'},'Select File...','~/Documents/Data');
    [sev,header] = read_tdt_sev(fullfile(p,f));
end