function locs = getSpikeLocations(data,validMask,Fs,varargin)
% pre-process data: high pass -> artifact removal
% data = nCh x nSamples
% [] save figures? Configs?
% [] align actual spike peaks after getting y_snle

onlyGoing = 'none';

windowSize = round(Fs/2400); %snle
snlePeriod = round(Fs/8000); %snle
minpeakdist = Fs/1000; %hardcoded deadtime
threshGain = 15;
showMe = 1;

for iarg = 1 : 2 : nargin - 3
    switch varargin{iarg}
        case 'onlyGoing'
            onlyGoing = varargin{iarg + 1};
        case 'windowSize'
            windowSize = varargin{iarg + 1};
        case 'minpeakdist'
            minpeakdist = varargin{iarg + 1};
        case 'threshGain'
            threshGain = varargin{iarg + 1};
        case 'showMe'
            showMe = varargin{iarg + 1};
    end
end

% calculate SNLE and threshold seperately
% 

disp('Calculating SNLE data...')
%Find smooth non-linear energy
y_snle = snle(data,validMask,'windowSize',windowSize,'snlePeriod',snlePeriod);
%subtract the mean snle value from the snle value
y_snle = bsxfun(@minus,y_snle,mean(y_snle,2)); %zero mean

%Calculate the minimum peak height for each wire and extract peaks
%individually first, then the detectVector will combine locations
locs = {};
allLocs = [];
for ii=1:size(y_snle,1)
    minpeakh(ii) = threshGain * mean(median(abs(y_snle(ii,:)),2));
    disp(['Extracting peaks of SNLE ch',num2str(ii),'...']);
    locs{ii} = peakseek(y_snle(ii,:),minpeakdist,minpeakh(ii));
    allLocs = [allLocs locs{ii}];
    disp([num2str(length(locs{ii})),' spikes found...']);
end
% put all locations in sequential order
allLocs = sort(allLocs);
% make zero vector of data length
detectVector = zeros(1,size(y_snle(1,:),2));
% set spike locations to 1
detectVector(allLocs) = 1;
% use peakseek to eliminate deadtime spikes: if we have spikes at 5-10-15
% and a deadtime of 7, it will remove the spike at 10 (it's smart!)
allLocs = peakseek(detectVector,minpeakdist,0);

if(strcmpi(onlyGoing,'positive') || strcmpi(onlyGoing,'negative'))
    sumData = sum(data,1);
    if(strcmp(onlyGoing,'positive'))
        locsGoing = sumData(:,locs) > 0; %positive spikes
    elseif(strcmp(onlyGoing,'negative'))
        locsGoing = sumData(:,locs) < 0; %negative spikes
    end
    locs = locs(locsGoing);
    disp([num2str(round(length(locs)/length(locsGoing)*100)),'% spikes going ',onlyGoing,'...']);
end

if(showMe)
    disp('Showing you...')
    nSamples = min([400 length(locs)]);
    locWindow = 40;
    t = linspace(0,(locWindow*2)/Fs,locWindow*2)*1e3;
    someLocs = datasample(locs,nSamples); % random samples
    for i=1:size(data,1)
        figure;
        for j=1:length(someLocs)
            plot(t,data(i,someLocs(j)-locWindow:someLocs(j)+locWindow-1));
            hold on;
        end
        title(['data row',num2str(i),' - ',num2str(nSamples),' samples']);
        xlabel('time (ms)')
        ylabel('uV')
        xlim([0 max(t)]);
    end
end