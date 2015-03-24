function [burstEpochs,burstFreqs]=findBursts(ts)
% [] intraburst frequency
% [] allow for multiple classes of bursting?
histBin = 100;

figure('position',[0 0 800 900]);
subplot(411);
[counts,centers] = hist(diff(ts),histBin);
bar(centers,counts,'edgeColor','none');
xlim([0 max(centers)]);
xlabel('ISI');
ylabel('events');
title('diff(ts)');

subplot(412);
[logCounts,logCenters] = hist(log(diff(ts)),histBin);
semilogx(exp(logCenters),logCounts);
grid on;
xlim([0 max(exp(logCenters))]);
xlabel('log(ISI)');
ylabel('events');
title('log(diff(ts))');

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

hs(1) = subplot(413);
plotSpikeRaster({ts},'PlotType','vertline');
for ii=1:length(burstEpochs)
    hold on;
    plot([ts(burstEpochs(ii,1)) ts(burstEpochs(ii,2))],[1 1],'r','lineWidth',3);
end
xlabel('time');
ylabel('unit');
title('spike raster');

hs(2) = subplot(414);
bar(ts(burstEpochs(:,1)),burstFreqs);
xlabel('time');
ylabel('frequency (Hz)');
title('intra-burst frequency');

linkaxes(hs,'x');

disp(char(repmat(46,1,20)));
disp('BURST SUMMARY');
disp(['Bursts detected: ',num2str(length(burstEpochs))]);
disp(['Mean spikes per burst: ',num2str(mean(burstEpochs(:,2)-burstEpochs(:,1)))]);
disp(['Mean burst frequency: ',num2str(mean(burstFreqs)),' Hz']);
disp(['Void parameter: ',num2str(1-(xBursts(2)/sqrt(xBursts(1)*xBursts(3))))]);
disp(char(repmat(46,1,20)));