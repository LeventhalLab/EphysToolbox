function [burstEpochs,burstFreqs]=findBursts(ts)
% [] intraburst frequency
% [] allow for multiple classes of bursting?
histBin = 100;

figure('position',[0 0 800 400]);
subplot(211);
[counts,centers] = hist(diff(ts),histBin);
bar(centers,counts,'edgeColor','none');
xlim([0 max(centers)]);
xlabel('ISI');
ylabel('events');

subplot(212);
[logCounts,logCenters] = hist(log(diff(ts)),histBin);
semilogx(exp(logCenters),logCounts);
grid on;
xlim([0 max(exp(logCenters))]);
xlabel('log(ISI)');
ylabel('events');

disp('Select burst peak-valley-peak...')
[xBursts,~] = ginput

hold on;
plot([xBursts(1) xBursts(1)],[0 max(logCounts)],'r','lineWidth',3);
plot([xBursts(2) xBursts(2)],[0 max(logCounts)],':','color','k','lineWidth',3);
plot([xBursts(3) xBursts(3)],[0 max(logCounts)],'r','lineWidth',3);

bursts = find(diff(ts) > 0 & diff(ts) <= xBursts(2));

burstEpochs = [];
burstCount = 1;
for ii=1:length(bursts)
    if ii == 1
        burstEpochs(burstCount,1) = bursts(ii);
    else
        if bursts(ii) == bursts(ii-1) + 1
            continue;
        else
            burstEpochs(burstCount,2) = bursts(ii-1) + 1;
            burstCount = burstCount + 1;
            burstEpochs(burstCount,1) = bursts(ii);
        end
    end
    if ii == length(bursts)
        burstEpochs(burstCount,2) = burstEpochs(burstCount,1) + 1;
    end
end

tsBursts = ts(burstEpochs);
tsDiff = tsBursts(:,2) - tsBursts(:,1);
burstPeriods = tsDiff ./ (burstEpochs(:,2)-burstEpochs(:,1));
burstFreqs = 1 ./ burstPeriods;

figure('position',[500 500 800 150]);
plotSpikeRaster({ts},'PlotType','vertline');
for ii=1:length(burstEpochs)
    hold on;
    plot([ts(burstEpochs(ii,1)) ts(burstEpochs(ii,2))],[1 1],'r','lineWidth',3);
end

disp(char(repmat(46,1,20)));
disp('BURST SUMMARY');
disp(['Bursts detected: ',num2str(length(burstEpochs))]);
disp(['Mean burst ISI: ',num2str(mean(burstEpochs(:,2)-burstEpochs(:,1)))]);
disp(['Mean burst frequency: ',num2str(mean(burstFreqs))]);
disp(['Void parameter: ',num2str(1-(xBurst(2)/sqrt(xBurst(1)*xBurst(3))))]);
disp(char(repmat(46,1,20)));