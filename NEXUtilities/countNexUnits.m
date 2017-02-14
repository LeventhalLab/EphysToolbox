function totalVar = countNexUnits(searchPath)

% searchPath = '/Volumes/RecordingsLeventhal2/ChoiceTask/R0142/R0142-processed';
nexFiles = dir2(searchPath,'*.nex','-r');

totalVar = 0;
for iFile = 1:length(nexFiles)
    [nvar, ~, ~, ~] = nex_info(fullfile(searchPath,nexFiles(iFile).name));
    totalVar = totalVar + nvar;
end

disp([num2str(totalVar),' total units found.']);