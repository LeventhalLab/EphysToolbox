function createHistogram(filename)
%Create a histogram for the hour long session with bin size of 30 seconds

[nvar, names, types] = nex_info(filename);
for i = 1:nvar
    varname = names(i);
    [n, ts] = nex_ts(filename, varname);
    firingRate = [];
    for ii = 1:30:3600
        numSpikes = 0;
        a = 1;
        while ts(ii) < a+30
            numSpikes = numSpikes + 1;
            a = a+1;
        end
        firingRate = [firingRate numSpikes/30];
    end
    t = linspace(0:60:61);
    figure
    bar(t, firingRate, 'hist')
    xlabel('time (min)');
    ylabel('Firing Rate (spikes/sec)');
end
end
