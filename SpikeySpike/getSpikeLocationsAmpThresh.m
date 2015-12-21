 function allLocs = getSpikeLocationsAmpThresh(data,validMask,Fs,rawData,varargin)
    % data = nCh x nSamples
    % allLocs = 1 x nLocs, in samples

    onlyGoing = 'none';

    windowSize = round(Fs/2400); %snle
    snlePeriod = round(Fs/8000); %snle
    minpeakdist = 40; %hardcoded deadtime
    threshGain = 15;
    recordStart = 500000; %samples, discard any spikes before this time
    
    
    for iarg = 1 : 2 : nargin - 4
        switch varargin{iarg}
            case 'onlyGoing'
                onlyGoing = varargin{iarg + 1};
            case 'windowSize'
                windowSize = varargin{iarg + 1};
            case 'minpeakdist'
                minpeakdist = varargin{iarg + 1};
            case 'threshGain'
                threshGain = varargin{iarg + 1};
            case 'saveDir'
                saveDir = varargin{iarg + 1};
            case 'savePrefix'
                savePrefix = varargin{iarg + 1};
        end
    end

    % calculate SNLE and threshold seperately
    % 
%     disp('Calculating SNLE data...')
%     %Find smooth non-linear energy
%     y_snle = snle(data,validMask,'windowSize',windowSize,'snlePeriod',snlePeriod);
     %subtract the mean snle value from the snle value
 %    y_snle = bsxfun(@minus,y_snle,mean(y_snle,2)); %zero mean

    %Calculate the minimum peak height for each wire and extract peaks
    %individually first, then the detectVector will combine locations
%    ysnleLocs = {};
    dataLocs = {};
    allLocs = [];
    for ii=1:size(data,1)
        if validMask(ii)  
            %minpeakh = threshold for spike detection
            
            %Generate moving window amplitude threshold
            minpeakh(ii,:) = getThreshold(5,data(ii,:));
%            constantThresh = 5.*median((abs(data(ii,:))./0.6745));
 %           SNLEthresh = threshGain * mean(median(abs(y_snle(ii,:)),2));
            disp(['Extracting peaks of  wire' ,num2str(ii),'...']);
         
%            ysnleLocs{ii} = peakseek(y_snle(ii,:),minpeakdist,SNLEthresh); 
            
            %get index of data that is LESS than thrshold and zero it out
            IDX = abs(data(ii,:))<minpeakh(ii,:);
            filtData = abs(data(ii,:));
            filtData(IDX) = 0;
            dataLocs{ii} = peakseek(filtData,minpeakdist); 
            
            %Remove all spike ts before 30s
            idx = find(dataLocs{ii}<recordStart);
            dataLocs{ii}(idx) = [] ;
            
         %   t=250000:450000;idx = dataLocs{ii}>t(1) & dataLocs{ii}<t(end);
         %   figure();plot(t,data(ii,t),t,minpeakh(ii,t),t,-minpeakh(ii,t));hold on;plot(dataLocs{ii}(idx),0,'*')

            if(strcmpi(onlyGoing,'positive') || strcmpi(onlyGoing,'negative'))
                if(strcmp(onlyGoing,'positive'))
                    locsGoing = data(ii,dataLocs{ii}) > 0; %positive spikes
                elseif(strcmp(onlyGoing,'negative'))
                    locsGoing = data(ii,dataLocs{ii}) < 0; %negative spikes
                end
                % reapply locations
                dataLocs{ii} = dataLocs{ii}(locsGoing);
                disp([num2str(length(dataLocs{ii})),' spikes found...']);
                disp([num2str(round(length(dataLocs{ii})/length(locsGoing)*100)),'% spikes going ',onlyGoing,'...']);
            end
        else
            dataLocs{ii} = []; % no spikes for invalidated channels
           
        end
        allLocs = [allLocs dataLocs{ii}];
  %      ysnleLocs = [ysnleLocs{ii}]
    end
    % put all locations in sequential order and eliminate doubles
    allLocs = unique(sort(allLocs));
    % make zero vector of data length
    detectVector = zeros(1,size(data(1,:),2));
    % set spike locations to 1
    detectVector(allLocs) = 1;
    % use peakseek to eliminate deadtime spikes: if we have spikes at 5-10-15
    % and a deadtime of 7, it will remove the spike at 10
    allLocs = peakseek(detectVector,minpeakdist,0);

    if exist('saveDir','var') && exist('savePrefix','var')
        % we don't want to plot all data, in case it's long
        dataHalfWindow = round(min(size(data,2)/2,1e5));
        dataMiddle = round(size(data,2)/2);
        dataRange = (dataMiddle - dataHalfWindow + 1):(dataMiddle + dataHalfWindow);
        % extract all locations in data range and then zero the vector to
        % the beginning of the data (the plot starts at zero)
        locsInSpan = allLocs(allLocs >= min(dataRange) & allLocs < max(dataRange)) - min(dataRange);
       % ylocsInSpan = ysnleLocs(ysnleLocs >= min(dataRange) & ysnleLocs < max(dataRange)) - min(dataRange);
        fig = figure('position',[200 200 800 800]);
        defaultColors = get(gca,'colororder');
        legendText = {};
        validWireCount = 1;
        for ii=1:size(data,1)
            if ~validMask(ii)
                continue;
            end
            legendText{validWireCount} = ['wire',num2str(ii)];

            hs(1) = subplot(211);
            title('Filtered Data');
            xlabel('time (s)');
            ylabel('uV')
            hold on; grid on;
            t = linspace(0,length(data(ii,dataRange))./Fs,length(data(ii,dataRange)));
            h(validWireCount) = plot(t,data(ii,dataRange),'-*','color',defaultColors(validWireCount,:));
            plot(t,minpeakh(ii,dataRange),t,-minpeakh(ii,dataRange));
            plot(locsInSpan/Fs,zeros(1,length(locsInSpan)),'x','color','k','MarkerSize',10);
  %          plot(t,constantThresh.*ones(1,length(t)),t,-constantThresh.*ones(1,length(t)))
            xlim([0 max(t)]);

            hs(2) = subplot(212);
            title('Raw Data');
            xlabel('time (s)');
            ylabel('uV')
            hold on; grid on;
            t = linspace(0,length(rawData(ii,dataRange))./Fs,length(rawData(ii,dataRange)));
            plot(t,rawData(ii,dataRange),'color',defaultColors(validWireCount,:));
            
%             hs(3) = subplot(313);
%             title('SNLE');
%             xlabel('time (s)');
%             ylabel('SNLE')
%             hold on; grid on;
%             plot(t,y_snle(ii,dataRange),'color',defaultColors(validWireCount,:));
%             plot([0 (dataHalfWindow*2)/Fs],[SNLEthresh SNLEthresh],'--','color',defaultColors(validWireCount,:));
%             plot(ylocsInSpan/Fs,zeros(1,length(ylocsInSpan)),'x','color','k','MarkerSize',10);
%             xlim([0 max(t)]);
            
            validWireCount = validWireCount + 1;
        end
        linkaxes(hs,'x');
       % subplot(211);
        legend(h,legendText);
        
%         [b,a] = butter(2, [0.03 0.6]);
%         BPdata =  filtfilt(b,a,double(rawData));
%         
%         waveData = wavefilter(double(rawData),5);
%         t =allLocs(600)-1000:allLocs(600)+1000;figure();
%         t2 = allLocs(600)-1000:.1:allLocs(600)+1000
%         %sincData = sinc_interp(data(ii,t),t,t2)
%         figure();testp1 = subplot(211);
%         plot(t,data(ii,t),'-*');hold on;plot(t,minpeakh(ii,t));plot(t,-minpeakh(ii,t));
%         %plot(t2,sincData);
%         plot(t,BPdata(ii,t),'-x');plot(t,waveData(ii,t),'-o')
%         testp2=subplot(212); 
%         plot(t,rawData(:,t))
%         linkaxes([testp1,testp2],'x')
        

        
        savefig(fig,fullfile(saveDir,[savePrefix,'_SNLE']),'compact');
        close(fig);

        fig = figure('position',[300 300 300 800]);
        validWireCount = 1;
        preSpike = 20; %samples
        postSpike = 28; %samples
        for ii=1:size(data,1)
            if ~validMask(ii)
                continue;
            end

            subplot(length(find(validMask>0)),1,validWireCount);
            title(['Wire ',num2str(ii)]);
            xlabel('sample');
            ylabel('uV');
            hold on;
            plotSpikes = min([length(allLocs) 400]);
            randomLocs = datasample(allLocs,plotSpikes);
            for jj=1:plotSpikes
                plot(data(ii,randomLocs(jj)-preSpike:randomLocs(jj)+postSpike));
            end
            xlim([1 preSpike+postSpike]);
            validWireCount = validWireCount + 1;
        end
        savefig(fig,fullfile(saveDir,[savePrefix,'_waveforms']),'compact');
        close(fig);
    end
end

function dataLocs = findDataLocs(data,ysnleLocs)
%%Wrote some code for SINC interpolation here. Decided it wasn't worth it.
%%Too computationally expensive to marginally correct alignments by <40 us
%% -fys 08/06/2015

    halfWindow = 20; % samples
    dataLocs = [];
    %dt = 0.1;                
    for ii=1:length(ysnleLocs)
        %Sinc Interpolate data before extracting peak in real data
        %Take 100 samples before and after for interpolation
        %t = ysnleLocs(ii)-24:ysnleLocs(ii)+24;
       % t2 = ysnleLocs(ii) -24:0.1:ysnleLocs(ii)+24;
        
        %sincData = sinc_interp(data(t),t,t2)
        % extract a very small snippet of real data around SNLE peak
        snippet = data(ysnleLocs(ii)-halfWindow:ysnleLocs(ii)+halfWindow);       
        % find peak in snippet of actual data
        snippetLoc = peakseek(abs(snippet),2*halfWindow);
        % make adjustment
        if isempty(snippetLoc) %this happens when no peak is found
            dataLocs(ii) = ysnleLocs(ii);
        else
            dataLocs(ii) = ysnleLocs(ii) + (snippetLoc - halfWindow) - 1;
        end
    end
end