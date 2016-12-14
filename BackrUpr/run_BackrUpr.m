% find testDirs in testPaths

% import these
% these are the "drives"
testPaths = {'/Users/mattgaidica/Documents/Data/ChoiceTask/R0117','/Users/mattgaidica/Documents/Data/ChoiceTask/R0088'};
% these are animal-specific data folders to look for across drives
testDirs = {'R0117-processed','R0088-processed'};

% find all matches for testDir
for itestDirs = 1:length(testDirs)
    % find all testDirs
    testDir = testDirs{itestDirs};
    matches = {};
    matchCount = 1;
    for itestPaths = 1:length(testPaths)
        testPath = testPaths{itestPaths};
        l2 = dir2(testPath,'-r');
        l2 = l2([l2(:).isdir]); % no files
        % find all matching
        for ii = 1:length(l2)
            [~,name,~] = fileparts(l2(ii).name);
            if strcmp(testDir,name)
                % get subfolders for match
                matches{matchCount,1} = fullfile(l2(ii).folder,testDir);
                d = dir(matches{matchCount,1});
                d(ismember({d.name},{'.','..'})) = [];
                d(~[d.isdir]) = [];
                matches{matchCount,2} = {d(:).name};
                matchCount = matchCount + 1;
            end
        end
    end
    
    allRows = sort(unique(flatten(matches(:,2))));
    reportTable = [{''} matches(:,1)'];
    iRow = 1;
    for iRow = 1:length(allRows)
        reportTable{iRow+1,1} = allRows{iRow};
        for iCol = 1:size(matches,1)
            reportTable{iRow+1,iCol+1} = ismember(allRows{iRow},matches{iCol,2});
        end
    end
    
    T = cell2table(reportTable);
    
end