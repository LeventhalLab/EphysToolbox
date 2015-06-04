function createBarGraph(filename)
%Create a histogram for the hour long session with bin size of 30 seconds

tsCell = leventhalNexTs(filename);
for ii = 1:size(tsCell,1)
    firingRate = [];
    for t = 1:30:3600
        numSpikes = length(find(tsCell{ii,2} < t+30));
        firingRate = [firingRate numSpikes/30];
    end
    t = linspace(0,60,120);
    figure
    bar(t, firingRate, 'hist')
    xlabel('time (min)');
    ylabel('Firing Rate (spikes/sec)');
end
end
