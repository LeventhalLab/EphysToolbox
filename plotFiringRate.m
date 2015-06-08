function plotFiringRate(firingRate, time, binSize)
%Function to plot the firing rate in a histogram format
%
% Inputs:
%   firingRate - vector from getFiringRate function
%   time - length of session in minutes
%   binSize - bin size in seconds

t = linspace(0,time,(time*60)/binSize);
figure
bar(t, firingRate, 'hist')
xlabel('time (min)');
ylabel('Firing Rate (spikes/sec)');
end