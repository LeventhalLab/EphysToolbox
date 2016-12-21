% [ ] does source file exist?
% [ ] easy way to copy files from one source to another?
% [ ] notify user of end

sourceFile = 'backrupr_sources.txt';
testFile = 'backrupr_tests.txt';
sources = importdata(sourceFile);
tests = importdata(testFile);
% find all matches for testDir
for itestDirs = 1:length(tests)
    % find all testDirs
    testDir = tests{itestDirs};
    matches = {};
    matchCount = 1;
    for itestPaths = 1:length(sources)
        testPath = sources{itestPaths};
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
    writetable(T,['REPORT_',testDir]);
end