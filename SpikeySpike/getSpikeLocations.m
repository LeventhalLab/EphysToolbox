function locs = getSpikeLocations(data,validMask,Fs,onlyGoing)
% pre-process data: high pass -> artifact removal
% data = nCh x nSamples
% [ ] save figures? Configs?

nStd = 3;
% suitable for action potentials
windowSize = round(Fs/2400);
snlePeriod = round(Fs/8000);

disp('Calculating SNLE data...')
y_snle = snle(data,validMask,'windowSize',windowSize,'snlePeriod',snlePeriod);
disp('Extracting peaks of summed SNLE data...')
minpeakdist = Fs/1000; %hardcoded deadtime
minpeakh = nStd * mean(std(y_snle,[],2)); %3 is good!
locs = peakseek(sum(y_snle),minpeakdist,minpeakh);

% this forces all lines to be negative for extracts, not sure that's a good
% way to think about this feature

if(strcmp(onlyGoing,'positive')) 
    locsGoing = min(data(:,locs)) > 0; %positive spikes
    locs = locs(locsGoing);
elseif(strcmp(onlyGoing,'negative'))
    locsGoing = max(data(:,locs)) < 0; %negative spikes
    locs = locs(locsGoing);
end
disp([num2str(round(length(locs)/length(locsGoing)*100)),'% spikes going your way...']);

showme = false;
if(showme)
    disp('Showing you...')
    nSamples = min([400 length(locs)]);
    locWindow = 20;
    someLocs = datasample(locs,nSamples); % random samples
    for i=1:size(data,1)
        figure;
        for j=1:length(someLocs)
            plot(data(i,someLocs(j)-locWindow:someLocs(j)+locWindow));
            hold on;
        end
        title(['data row',num2str(i),' - ',num2str(nSamples),' samples']);
        xlabel('samples')
        ylabel('amplitude')
    end
end