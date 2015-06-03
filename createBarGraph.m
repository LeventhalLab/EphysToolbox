function createHistogram(filename)
%Create a histogram for the hour long session with bin size of 30 seconds

[nvar, names, types] = nex_info(filename);
for i = 1:nvar
    %not sure if this will work if there is more than one name?
    varname = names;
    [n, ts] = nex_ts(filename, varname);
    firingRate = [];
    a = 1;
    for ii = 1:30:3600
        numSpikes = 0;
        while ts(a) < ii+30
            numSpikes = numSpikes + 1;
            a = a+1;
        end
        firingRate = [firingRate numSpikes/30];
    end
    t = linspace(0,60,120);
    figure
    bar(t, firingRate, 'hist')
    xlabel('time (min)');
    ylabel('Firing Rate (spikes/sec)');
end
end
