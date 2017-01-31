function dout = findEmptySevFiles(searchDir)

disp('Performing recursive listing...');
dout = dir2(searchDir,'*.sev','-r');
temp = {};
doutCount = 0;
allBytes = [];
h = waitbar(0,'Finding empty SEV files...');
for iFile = 1:size(dout,1)
    h = waitbar(iFile/size(dout,1));
    curFile = fullfile(searchDir,dout(iFile).name);
    header = getSEVHeader(curFile);
    if sum(header.dataSnippet) == 0
        doutCount = doutCount + 1;
        temp{doutCount} = char(curFile);
        allBytes(doutCount) = dout(iFile).bytes;
    end
end
close(h);

[dout,ndx] = natsort(temp'); % rows

if doutCount > 0
    deleteBytes = formatBytes(sum(allBytes));

    button = questdlg(['Proceed to selecting SEV files for deletion?',' (',deleteBytes,')'],'findEmptySevFiles','Yes','No','No');
    if strcmp(button,'Yes')
        [Selection,ok] = listdlg('PromptString','Select files to delete:',...
            'SelectionMode','multiple','ListSize',[800 500],'ListString',char(dout));

        if ok
            dout = dout(Selection);
            deleteBytes = formatBytes(sum(allBytes(ndx(Selection))));
            h = waitbar(0,['Deleting ',deleteBytes,' of SEV files...']);
            for iFile = 1:size(Selection,2)
                waitbar(iFile/size(Selection,2));
                delFile = dout{Selection(iFile)};
                delete(char(delFile));
            end
            close(h);
            disp(['Deleted ',deleteBytes]);
        end
    end
else
    disp(['No empty files (of ',num2str(iFile),'). Exiting...']);
end