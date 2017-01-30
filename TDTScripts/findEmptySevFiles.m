function dout = findEmptySevFiles(searchDir,varargin)

dout = dir2(searchDir,'*.sev','-r');
temp = {};
doutCount = 1;
for iFile = 1:size(dout,1)
    curFile = fullfile(dout(iFile).folder,dout(iFile).name);
    header = getSEVHeader(curFile);
    if sum(header.dataSnippet) == 0
        temp{doutCount} = char(curFile);
        doutCount = doutCount + 1;
    end
end

dout = temp;

if nargin > 1 && varargin{1}
    [Selection,ok] = listdlg('PromptString','Select files to delete:',...
        'SelectionMode','multiple','ListSize',[800 500],'ListString',char(temp));
    
    if ok
        h = waitbar(0,'Deleting files...');
        for iFile = 1:size(Selection,2)
            waitbar(iFile/size(Selection,2));
            delFile = dout{Selection(iFile)};
            delete(char(delFile));
        end
        close(h);
    end
end