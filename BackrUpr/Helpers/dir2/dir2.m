function dout = dir2(dn,varargin)
%DIR2 List directory.
%   DIR2('directory_name') lists the files in a directory. Pathnames and
%   wildcards may be used.  For example, DIR *.m lists all program files
%   in the current directory.
%
%   DIR2('directory_name','-r') Lists the files in a directory, and it's
%   subdirectories.
%
%   DIR2('directory_name',filter1,filter2,...) Applies the filters FILTER1
%   and FILTER2, etc to the directory search. These filters are treated as
%   an OR. Thus a file must only match atleast one filter to be included.
%   Filters may be strings, or cell arrays of strings.
%
%   DIR2('directory_name','-r',filter1,filter2,...) The recursive flag and
%   the filters may be in any order.
%
%   D = DIR2('directory_name') output the results in an M-by-1
%   structure with the fields:
%       name    -- Filename
%       date    -- Modification date
%       bytes   -- Number of bytes allocated to the file
%       isdir   -- 1 if name is a directory and 0 if not
%       datenum -- Modification date as a MATLAB serial date number.
%                  This value is locale-dependent.
%
%   EXAMPLES:
%       Example 1: Recursive directory listing of the current directory
%           d = dir2(pwd,'-r')
%           {d.name}'
%
%       Example 2: Using multiple filters
%           d = dir2(pwd,'*.mat','*.m')
%           {d.name}'
%
%       Example 3: Using multiple filters w/ a recursive search
%           d1 = dir2(pwd,'*.mat','*.m','-r')
%           d2 = dir2(pwd,'-r','*.mat','*.m')
%           % Notice order of the flags doesn't matter
%           isequal(d1,d2)
%
%   See also DIR, WHAT, CD, TYPE, DELETE, LS, RMDIR, MKDIR, DATENUM.
%
% By: J Sullivan
% January 2013

if ispc
    
    if isempty(which('dir2_mex'))
        install_dir2_mex;
    end
    
    if ~isempty(which('dir2_mex'))
        
        if nargin > 0
            dout = dir2_mex(dn,varargin{:});
        else
            dout = dir2_mex;
        end
        
        % Only print the results if nargout == 0
        if nargout == 0
            printAsTable({dout(:).name});
            clear dout
        end
        
        return;
    end
end
% Parse the inputs
if nargin == 0; dn = pwd; end
[dn, recursive, filter] = parseInputs(dn,varargin{:});

% Loop through the filters in this directory
dout = [];
for ii = 1:length(filter)
    dout = [dout; dir([dn filesep filter{ii}])];
end

% Put them in alphabetical order
if ii > 1
    [~,ind] = sort({dout.name});
    dout = dout(ind);
end

% Remove the self and parent directory listings in recursive calls
if isRec
    dout(ismember({dout.name},{'.','..'})) = [];
end


% If recursive...
if recursive
    
    % Find all the directories
    d = dir(dn);
    
    % Remove the references to itself and its parent
    d(ismember({d.name},{'.','..'})) = [];
    d(~[d.isdir]) = [];
    dout_rec = [];
    
    % Loop over child directories
    if ~isempty(d)
        drs = strcat({dn},filesep,{d.name});
        for ii = 1:length(drs)
            
            dout_this = dir2(drs{ii},varargin{:});
            if isempty(dout_this); continue; end
            
            % Append the child directory
            C = strcat(d(ii).name,filesep,{dout_this.name});
            [dout_this(:).name] = deal(C{:});
            dout_rec = [dout_rec; dout_this];
        end
        
    end
    % Append the two sets
    dout = [dout; dout_rec];
end

% Only print the results if nargout == 0
if nargout == 0
    printAsTable({dout(:).name});
    clear dout
end

function [dn, recursive, filter] = parseInputs(dn,varargin)

% Defaults
filter = {};
recursive = false;

% Loop over inputs
for ii = 1:length(varargin)
    
    
    v = varargin{ii};
    
    % Is it a recursive flag?
    if strcmpi(v,'-r')
        recursive = true;
    else
        % Must be a filter
        if ~iscell(v)
            filter = [filter {v}];
        else
            filter = [filter reshape(v,1,[])];
        end
    end
end

% If no filter specified, give them all
if isempty(filter)
    filter = {'*'};
end

isStar = dn == '*';
if any(isStar)
    [dn, add1, add2] = fileparts(dn);
    filter = {strcat(add1,add2)};
end

function out = isRec
a = dbstack;
out = length(a) > 2 && strcmpi(a(2).name,a(3).name);

function printAsTable(C)

% Get the screen size (in charecters)
uOld = get(0,'units');
set(0,'units','characters');
sz = get(0,'CommandWindowSize');
set(0,'units',uOld);

% What's the widest?
w = sz(1);
nl = cellfun(@numel,C);
nc = numel(C);
mxl = max(nl);
mxls = num2str(mxl);

% Find out home many rows and column to take
nCol = max(floor(w./(mxl + 2)),1);
nRow = ceil(nc./nCol);

% Print it
for ii = 1:nRow
    x = C(ii:nRow:end);
    nThis = numel(x);
    fprintf([repmat(['%-' mxls 's  '],1,nThis) '\n'],x{:});
end

function install_dir2_mex
try
    fileloc = which('dir2_mex.c');
    curdir = pwd;
    cd(fileparts(fileloc));
    mex dir2_mex.c;
    cd(curdir);
catch err
    printf('COuld not install the mex file. Switch to the .m version\n');
    warning(err.getReport);
end