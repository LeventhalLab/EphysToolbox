function ysnleLocs = getSpikeLocations(data,validMask,Fs,varargin)
    % pre-process data: bandpass -> artifact removal
    % data = nCh x nSamples
    % [] save figures? Configs?

    onlyGoing = 'none';

    windowSize = round(Fs/2400); %snle
    snlePeriod = round(Fs/8000); %snle
    minpeakdist = Fs/1000; %hardcoded deadtime
    threshGain = 15;
    showMe = 0;

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
    ysnleLocs = {};
    dataLocs = {};
    allLocs = [];
    for ii=1:size(y_snle,1)
        if validMask(ii)  
            minpeakh(ii) = threshGain * mean(median(abs(y_snle(ii,:)),2));
            disp(['Extracting peaks of SNLE wire',num2str(ii),'...']);
            ysnleLocs{ii} = peakseek(y_snle(ii,:),minpeakdist,minpeakh(ii));
            % shift locs as needed based on data (sometimes SNLE peaks are
            % a few samples off of the real spike peak)
            dataLocs{ii} = findDataLocs(data(ii,:),ysnleLocs{ii});
            if(strcmpi(onlyGoing,'positive') || strcmpi(onlyGoing,'negative'))
                if(strcmp(onlyGoing,'positive'))
                    locsGoing = data(ii,dataLocs{ii}) > 0; %positive spikes
                elseif(strcmp(onlyGoing,'negative'))
                    locsGoing = data(ii,dataLocs{ii}) < 0; %negative spikes
                end
                % reapply locations
                dataLocs{ii} = dataLocs{ii}(locsGoing);
                disp([num2str(round(length(dataLocs{ii})/length(locsGoing)*100)),'% spikes going ',onlyGoing,'...']);
            end
        else
            dataLocs{ii} = []; % no spikes for invalidated channels
        end
        disp([num2str(length(dataLocs{ii})),' spikes found...']);
        allLocs = [allLocs dataLocs{ii}];
    end
    % put all locations in sequential order and eliminate doubles
    allLocs = unique(sort(allLocs));
    % make zero vector of data length
    detectVector = zeros(1,size(y_snle(1,:),2));
    % set spike locations to 1
    detectVector(allLocs) = 1;
    % use peakseek to eliminate deadtime spikes: if we have spikes at 5-10-15
    % and a deadtime of 7, it will remove the spike at 10 (it's smart!)
    allLocs = peakseek(detectVector,minpeakdist,0);

    figure('position',[200 200 800 800]);
    defaultColors = get(gca,'colororder');
    legendText = {};
    validWireCount = 1;
    for ii=1:size(data,1)
        if ~validMask(ii)
            continue;
        end
        acceptedLocs = ismember(dataLocs{ii},allLocs);
        rejectedLocs = ~acceptedLocs;
        legendText{validWireCount} = ['wire',num2str(ii)];

        hs(1) = subplot(211);
        title('Filtered Data');
        xlabel('samples');
        ylabel('uV')
        hold on;
        h(validWireCount) = plot(data(ii,:),'color',defaultColors(validWireCount,:));
        plot(dataLocs{ii}(acceptedLocs),data(ii,dataLocs{ii}(acceptedLocs)),'o','color','k');
        plot(dataLocs{ii}(rejectedLocs),data(ii,dataLocs{ii}(rejectedLocs)),'x','color','red');

        hs(2) = subplot(212);
        title('SNLE');
        xlabel('samples');
        ylabel('SNLE')
        hold on;
        plot(y_snle(ii,:),'color',defaultColors(validWireCount,:));
        plot([0 size(y_snle,2)],[minpeakh(ii) minpeakh(ii)],'--','color',defaultColors(validWireCount,:));
        plot(dataLocs{ii}(acceptedLocs),y_snle(ii,dataLocs{ii}(acceptedLocs)),'o','color','k');
        plot(dataLocs{ii}(rejectedLocs),y_snle(ii,dataLocs{ii}(rejectedLocs)),'x','color','red');

        validWireCount = validWireCount + 1;
    end
    linkaxes(hs,'x');
    subplot(211);
    legend(h,legendText);
    
    figure('position',[300 300 300 800]);
    validWireCount = 1;
    preSpike = 16; %samples
    postSpike = 32; %samples
    for ii=1:size(data,1)
        if ~validMask(ii)
            continue;
        end
        
        subplot(length(find(validMask>0)),1,validWireCount);
        title(['Wire ',num2str(ii)]);
        xlabel('samples');
        ylabel('uV')
        hold on;
        plotSpikes = min([length(allLocs) 400]);
        randomLocs = datasample(allLocs,plotSpikes);
        for jj=1:plotSpikes
            plot(data(ii,randomLocs(jj)-preSpike:randomLocs(jj)+postSpike));
        end
        
        validWireCount = validWireCount + 1;
    end
end

function dataLocs = findDataLocs(data,ysnleLocs)
    halfWindow = 5; % samples
    dataLocs = [];
    for ii=1:length(ysnleLocs)
        % extract a very small snippet of real data around SNLE peak
        snippet = data(ysnleLocs(ii)-halfWindow:ysnleLocs(ii)+halfWindow);
        % find peak in snippet of actual data
        snippetLoc = peakseek(abs(snippet),halfWindow);
        % make adjustment
        dataLocs(ii) = ysnleLocs(ii) + (snippetLoc - halfWindow) - 1;
    end
end