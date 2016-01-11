function [burstEpochs,burstFreqs]=findBursts(ts,xBursts)
% [] intraburst frequency
% [] allow for multiple classes of bursting?
% 1) [nvar, names, types] = nex_info(filename)
% 2) [n, ts] = nex_ts(filename, varname)
histBin = 200;

h = figure('position',[0 0 800 900]);
subplot(511);
[counts,centers] = hist(diff(ts),histBin);
bar(centers,counts,'edgeColor','none');
% xlim([0 max(centers)]);
xlim([0 0.5]);
xlabel('ISI');
ylabel('events');
title('diff(ts)');

subplot(512);
[logCounts,logCenters] = hist(log(diff(ts)),histBin);
semilogx(exp(logCenters),logCounts);
grid on;
xlim([0 max(exp(logCenters))]);
xlabel('log(ISI)');
ylabel('events');
title('log(diff(ts))');

% allow user to override manual input
if ~exist('xBursts','var')
    disp('Select burst peak-valley-peak...')
    figure(h)
    [xBursts,~] = ginput(3)
end

hold on;
plot([xBursts(1) xBursts(1)],[0 max(logCounts)],'r','lineWidth',3);
plot([xBursts(2) xBursts(2)],[0 max(logCounts)],':','color','k','lineWidth',3);
plot([xBursts(3) xBursts(3)],[0 max(logCounts)],'r','lineWidth',3);

bursts = find(diff(ts) > 0 & diff(ts) <= xBursts(2));

burstEpochs = [];
burstCount = 1;
for ii=1:length(bursts)
%     disp(ii);
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
    if(ii>1000)
%         disp(ii)
    end
end

if burstEpochs(burstCount,2) == 0
    burstEpochs(burstCount,2) = burstEpochs(burstCount,1) + 1;
end

tsBursts = ts(burstEpochs);
tsDiff = tsBursts(:,2) - tsBursts(:,1);
burstPeriods = tsDiff ./ (burstEpochs(:,2)-burstEpochs(:,1));
burstFreqs = 1 ./ burstPeriods;

hs(1) = subplot(513);
plotSpikeRaster({ts},'PlotType','vertline');
for ii=1:length(burstEpochs)
    hold on;
    plot([ts(burstEpochs(ii,1)) ts(burstEpochs(ii,2))],[1 1],'r','lineWidth',3);
end
xlabel('time (s)');
ylabel('unit');
title('spike raster');

hs(2) = subplot(514);
bar(ts(burstEpochs(:,1)),burstFreqs);
xlabel('time (s)');
ylabel('frequency (Hz)');
title('intra-burst firing frequency');
ylim([0 500]);


hs(3) = subplot(515);
histBin = histBin * 3;
[counts,centers] = hist(ts,histBin);
bar(centers,counts/(max(ts)/histBin),'edgeColor','none');
tsMinusBursts = ts;
tsMinusBursts(bursts) = [];
[counts,centers] = hist(tsMinusBursts,histBin);
hold on;
bar(centers,counts/(max(ts)/histBin),'edgeColor','none','faceColor','red');
xlim([0 max(centers)]);
xlabel('time (s)');
ylabel('frequency (Hz)');
title('raw firing frequency');
legend('all data','minus bursts');

linkaxes(hs,'x');

str = {['Bursts detected: ',num2str(length(burstEpochs))],...
    ['Mean spikes per burst: ',num2str(mean((burstEpochs(:,2)-burstEpochs(:,1))+1))],...
    ['Std spikes per burst: ',num2str(std((burstEpochs(:,2)-burstEpochs(:,1))+1))],...
    ['Mean burst frequency: ',num2str(mean(burstFreqs)),' Hz'],...
    ['Void parameter: ',num2str(1-(xBursts(2)/sqrt(xBursts(1)*xBursts(3))))]};
annotation('textbox', [.1 .9 .9 .1],'String', str, 'edgeColor','none');

disp(char(repmat(46,1,20)));
disp('BURST SUMMARY');
disp(['Bursts detected: ',num2str(length(burstEpochs))]);
disp(['Mean spikes per burst: ',num2str(mean((burstEpochs(:,2)-burstEpochs(:,1))+1))]);
disp(['Std spikes per burst: ',num2str(std((burstEpochs(:,2)-burstEpochs(:,1))+1))]);
disp(['Mean burst frequency: ',num2str(mean(burstFreqs)),' Hz']);
disp(['Void parameter: ',num2str(1-(xBursts(2)/sqrt(xBursts(1)*xBursts(3))))]);
disp(char(repmat(46,1,20)));