header = getSEVHeader(filename);
if sum(header.dataSnippet) == 0
    % no data file
end