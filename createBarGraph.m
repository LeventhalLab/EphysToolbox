function createBarGraph(filename, varargin)
%Create a histogram for the hour long session with bin size of 30 seconds
% Inputs:
%   filename -  NEX file path
%
%
% possible variable inputs: length of session (in minutes), bin size (in
% seconds)

%Get the timestamps for each channel
for iarg = 1 : 2 : nargin - 1
    switch varargin{iarg}
        case 'time'
            time = varargin{iarg + 1};
        case 'binSize'
            binSize = varargin{iarg + 1};
    end
end
        
tsCell = leventhalNexTs(filename);
for ii = 1:size(tsCell,1)
    firingRate = [];
    for x = 1 : binSize : time * 60
        %Find the number of spikes in the 30 sec range and find the firing
        %rate
        numSpikes = length(find(tsCell{ii,2} < x+binSize & tsCell{ii,2}>=x));
        firingRate = [firingRate numSpikes/binSize];
    end
    
    %plot in the histogram format
    t = linspace(0,time,(time*60)/binSize);
    figure
    bar(t, firingRate, 'hist')
    xlabel('time (min)');
    ylabel('Firing Rate (spikes/sec)');
end
end
