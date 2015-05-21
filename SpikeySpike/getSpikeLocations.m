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

disp('Calculating SNLE data...')
%Find smooth non-linear energy
y_snle = snle(data,validMask,'windowSize',windowSize,'snlePeriod',snlePeriod);

%subtract the mean snle value from the snle value
y_snle_zeroed = bsxfun(@minus,y_snle,mean(y_snle,2)); %zero mean

ave = mean(y_snle, 2);
standardDev = std(y_snle,0, 2);


%Calculate the minimum peak height
minpeakhmed = threshGain * median(abs(y_snle_zeroed),2);

minpeakhstd = standardDev*4 + ave;


%rawLocs = cell(4,1);
disp('Extracting peaks of SNLE data...')
for i = 1:4
    rawLocsstd{i} = peakseek(abs(y_snle(i,:)),minpeakdist,minpeakhstd(i,1));
    rawLocsmed{i} = peakseek(abs(y_snle_zeroed(i, :)), minpeakdist, minpeakhmed(i, 1));
end

%disp([num2str(length(rawLocs{1})+length(rawLocs{2})+length(rawLocs{3})+length(rawLocs{4})),' spikes found...']);

t = linspace(0, length(data(1,:))/Fs, length(data(1,:)));

% plot the raw data and smooth non linear energy
 figure;
 zoom on
 a(1) = subplot(221);
 plot(t, data(1,:)); 
 hold on
 plot((rawLocsstd{1}(1,:))/Fs, data(1,(rawLocsstd{1}(1,:))), '*')
 title('Tetrode 4 Wire 1 Raw Data (standard deviation)');
 xlabel('time');
 ylabel('uV');
 %ylim([-400, 200]);
 b(1) = subplot(223);
 plot(t, y_snle(1,:));
 hold on
 plot((rawLocsstd{1}(1,:)/Fs),y_snle(1,(rawLocsstd{1}(1,:))), '*')
 title('Tetrode 4 Wire 1 SNLE (standard deviation)');
 xlabel('time');
 a(2) = subplot(222);
 plot(t, data(1,:)); 
 hold on
 plot((rawLocsmed{1}(1,:))/Fs, data(1,(rawLocsmed{1}(1,:))), '*')
 title('Tetrode 4 Wire 1 Raw Data (median)');
 xlabel('time');
 ylabel('uV');
 %ylim([-400, 200]);
 b(2) = subplot(224);
 plot(t, y_snle_zeroed(1,:));
 hold on
 plot((rawLocsmed{1}(1,:)/Fs),y_snle_zeroed(1,(rawLocsmed{1}(1,:))), '*')
 title('Tetrode 4 Wire 1 SNLE (using median)');
 xlabel('time');
 linkaxes(a);
 linkaxes(b);
 linkaxes([a,b],'x');
 
  
 figure;
 zoom on
 a(1) = subplot(221);
 plot(t, data(2,:)); 
 hold on
 plot((rawLocsstd{2}(1,:))/Fs, data(2,(rawLocsstd{2}(1,:))), '*')
 title('Tetrode 4 Wire 2 Raw Data (standard deviation)');
 xlabel('time');
 ylabel('uV');
 %ylim([-400, 200]);
 b(1) = subplot(223);
 plot(t, y_snle(2,:));
 hold on
 plot((rawLocsstd{2}(1,:)/Fs),y_snle(2,(rawLocsstd{2}(1,:))), '*')
 title('Tetrode 4 Wire 2 SNLE (standard deviation)');
 xlabel('time');
 a(2) = subplot(222);
 plot(t, data(2,:)); 
 hold on
 plot((rawLocsmed{2}(1,:))/Fs, data(2,(rawLocsmed{2}(1,:))), '*')
 title('Tetrode 4 Wire 2 Raw Data (median)');
 xlabel('time');
 ylabel('uV');
 %ylim([-400, 200]);
 b(2) = subplot(224);
 plot(t, y_snle_zeroed(2,:));
 hold on
 plot((rawLocsmed{2}(1,:)/Fs),y_snle_zeroed(2,(rawLocsmed{2}(1,:))), '*')
 title('Tetrode 4 Wire 2 SNLE (using median)');
 xlabel('time');
 linkaxes(a);
 linkaxes(b);
 linkaxes([a,b],'x');
  
 figure;
 zoom on
 a(1) = subplot(221);
 plot(t, data(3,:)); 
 hold on
 plot((rawLocsstd{3}(1,:))/Fs, data(3,(rawLocsstd{3}(1,:))), '*')
 title('Tetrode 4 Wire 3 Raw Data (standard deviation)');
 xlabel('time');
 ylabel('uV');
 %ylim([-400, 200]);
 b(1) = subplot(223);
 plot(t, y_snle(3,:));
 hold on
 plot((rawLocsstd{3}(1,:)/Fs),y_snle(3,(rawLocsstd{3}(1,:))), '*')
 title('Tetrode 4 Wire 3 SNLE (standard deviation)');
 xlabel('time');
 a(2) = subplot(222);
 plot(t, data(1,:)); 
 hold on
 plot((rawLocsmed{3}(1,:))/Fs, data(3,(rawLocsmed{3}(1,:))), '*')
 title('Tetrode 4 Wire 3 Raw Data (median)');
 xlabel('time');
 ylabel('uV');
 %ylim([-400, 200]);
 b(2) = subplot(224);
 plot(t, y_snle_zeroed(3,:));
 hold on
 plot((rawLocsmed{3}(1,:)/Fs),y_snle_zeroed(3,(rawLocsmed{3}(1,:))), '*')
 title('Tetrode 4 Wire 3 SNLE (using median)');
 xlabel('time');
 linkaxes(a);
 linkaxes(b);
 linkaxes([a,b],'x');
 
 figure;
 zoom on
 a(1) = subplot(221);
 plot(t, data(4,:)); 
 hold on
 plot((rawLocsstd{4}(1,:))/Fs, data(4,(rawLocsstd{4}(1,:))), '*')
 title('Tetrode 4 Wire 4 Raw Data (standard deviation)');
 xlabel('time');
 ylabel('uV');
 %ylim([-400, 200]);
 b(1) = subplot(223);
 plot(t, y_snle(4,:));
 hold on
 plot((rawLocsstd{4}(1,:)/Fs),y_snle(4,(rawLocsstd{4}(1,:))), '*')
 title('Tetrode 4 Wire 4 SNLE (standard deviation)');
 xlabel('time');
 a(2) = subplot(222);
 plot(t, data(4,:)); 
 hold on
 plot((rawLocsmed{4}(1,:))/Fs, data(4,(rawLocsmed{4}(1,:))), '*')
 title('Tetrode 4 Wire 4 Raw Data (median)');
 xlabel('time');
 ylabel('uV');
 %ylim([-400, 200]);
 b(2) = subplot(224);
 plot(t, y_snle_zeroed(4,:));
 hold on
 plot((rawLocsmed{4}(1,:)/Fs),y_snle_zeroed(4,(rawLocsmed{4}(1,:))), '*')
 title('Tetrode 4 Wire 4 SNLE (using median)');
 xlabel('time');
 linkaxes(a);
 linkaxes(b);
 linkaxes([a,b],'x');

 
 
 %minLength = min([length(rawLocs{1}(1,:)) length(rawLocs{2}(1,:)) length(rawLocs{3}(1,:)) length(rawLocs{4}(1,:))]);
 %locs = [];
 %endElements = [];
 %make vectors same length to more easily compare locations
 %set ends to one if there is no location
 %for ii = 1:4
 %    if length(rawLocs{ii}(1,:)) > minLength
         %difference = maxLength - length(rawLocs{ii}(1,:));
 %        rawLocs{ii} = rawLocs{ii}(1,1:minLength);
 %        endElements = rawLocs{ii}(1, minLength:end);
         %addones = ones(1,difference); 
         %rawLocs{ii} = [rawLocs{ii} addones];
 %    end
 %    if ~isempty(endElements)
 %       locs = [locs endElements];
 %       locs = sort(locs);
 %    end
 %end
 
 %compLocs12 = rawLocs{1}(1,:) - rawLocs{2}(1,:);
 %compLocs13 = rawLocs{1}(1,:) - rawLocs{3}(1,:);
 %compLocs14 = rawLocs{1}(1,:) - rawLocs{4}(1,:);
 %compLocs23 = rawLocs{2}(1,:) - rawLocs{3}(1,:);
 %compLocs24 = rawLocs{2}(1,:) - rawLocs{4}(1,:);
 %compLocs34 = rawLocs{3}(1,:) - rawLocs{4}(1,:);
 
% tlocs = [];
 
 %for k = 1:length(compLocs12)
 %    if abs(compLocs12(k)) < 2
 %        if abs(data(1, rawLocs{1}(k))) > abs(data(2, rawLocs{2}(k)))
 %            tlocs = [tlocs rawLocs{1}(k)];
 %        else
 %            tlocs = [tlocs rawLocs{2}(k)];
 %        end
 %    end
 %    if abs(compLocs13(k)) < 2 
 %        if abs(data(1, rawLocs{1}(k))) > abs(data(3, rawLocs{3}(k)))
 %            tlocs = [tlocs rawLocs{1}(k)];
 %        else
 %            tlocs = [tlocs rawLocs{3}(k)];
 %        end
 %    end
 %    if abs(compLocs14(k)) < 2
 %        if abs(data(1, rawLocs{1}(k))) > abs(data(4, rawLocs{4}(k)))
 %            tlocs = [tlocs rawLocs{1}(k)];
 %        else
 %            tlocs = [tlocs rawLocs{4}(k)];
 %        end
 %    end
 %    if abs(compLocs23(k)) < 2
 %        if abs(data(2, rawLocs{2}(k))) > abs(data(3, rawLocs{3}(k)))
 %            tlocs = [tlocs rawLocs{2}(k)];
 %        else
 %            tlocs = [tlocs rawLocs{3}(k)];
 %        end
 %    end
 %    if abs(compLocs24(k)) < 2
 %        if abs(data(2, rawLocs{2}(k))) > abs(data(4, rawLocs{4}(k)))
 %            tlocs = [tlocs rawLocs{2}(k)];
 %        else
 %            tlocs = [tlocs rawLocs{4}(k)];
 %        end
 %    end
 %    if abs(compLocs34(k)) < 2
 %        if abs(data(3, rawLocs{3}(k))) > abs(data(4, rawLocs{4}(k)))
 %            tlocs = [tlocs rawLocs{3}(k)];
 %        else
 %            tlocs = [tlocs rawLocs{4}(k)];
 %        end
 %    end
 %    if abs(compLocs34(k)) < 2 && abs(compLocs12(k)) < 2 && abs(compLocs13(k)) < 2 ...
 %        && abs(compLocs14(k)) < 2 && abs(compLocs23(k)) < 2 && abs(compLocs24(k)) < 2
 %        tlocs = [tlocs rawLocs{1}(1,k) rawLocs{2}(1,k) rawLocs{3}(1,k) rawLocs{4}(1,k)];
 %    end
 %    locs = [locs tlocs];
 %end
 %locs = unique(locs);
 %locs = sort(locs);
 
%  figure;
% zoom on
% hs(1) = subplot(211);
% plot(t, data(1,:)); 
% hold on
% plot((locs(1,:))/Fs, data(1,(locs(1,:))), '*')
% title('Wire 1 Raw Data');
% xlabel('time');
% ylabel('uV');
% ylim([-200, 200]);
% hs(2) = subplot(212);
% plot(t, y_snle(1,:));
% hold on
% plot((locs(1,:)/Fs),y_snle(1,(locs(1,:))), '*')
% title('Wire 1 SNLE');
% xlabel('time');
% linkaxes(hs, 'x');

%locs = [];
 %for k = 1:(maxLength-1)
     %if (rawLocs{1}(1, k)==rawLocs{2}(1,k)) || (abs(rawLocs{1}(1, k)-rawLocs{2}(1,k))<=1)
     %    tloc = max([abs(data(1, rawLocs{1}(k))),abs(data(2, rawLocs{2}(k)))]);
    % else
   %      tloc = [rawLocs{1}(1,k), rawLocs{2}(1,k)];
  %   end        
 %   locs = [locs tloc];
 %end    
    


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