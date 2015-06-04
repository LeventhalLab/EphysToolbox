function createBarGraph(filename)
%Create a histogram for the hour long session with bin size of 30 seconds
% Inputs:
%   filename -  NEX file path
%
%
% possible variable inputs: length of session, bin size

%Get the timestamps for each channel
tsCell = leventhalNexTs(filename);
for ii = 1:size(tsCell,1)
    firingRate = [];
    for x = 1:30:3600
        %Find the number of spikes in the 30 sec range and find the firing
        %rate
        numSpikes = length(find(tsCell{ii,2} < x+30 & tsCell{ii,2}>=x));
        firingRate = [firingRate numSpikes/30];
    end
    
    %plot in the histogram format
    t = linspace(0,60,120);
    figure
    bar(t, firingRate, 'hist')
    xlabel('time (min)');
    ylabel('Firing Rate (spikes/sec)');
end
end
