function data=artifactThresh(data,thresh)
    % finds peaks above thresh
    locs = peakseek(abs(data),1,thresh);
    disp([num2str(length(locs)),' artifacts found...']);
    baseline = 50;
    for i=1:length(locs)
        if(mod(i,round(length(locs)/10))==0)
            disp([num2str(i),'/',num2str(length(locs)),' artifacts cured...']);
        end
        % get quiet locations before/after artifact peak, this if/else
        % structure reduce computation time significantly
        if(i==1)
            zeroBefore = find(abs(data(1:locs(i)))<baseline,1,'last');
            % if signal starts out over thresh
            if(isempty(zeroBefore))
                zeroBefore = 1;
            end
        else
            zeroBefore = locs(i-1) + find(abs(data(locs(i-1):locs(i)))<baseline,1,'last');
            % no zero crossing between last peak and this peak
            if(isempty(zeroBefore))
                zeroBefore = locs(i-1);
            end
        end
        if(i==length(locs))
            zeroAfter = locs(i) + find(abs(data(locs(i):end))<baseline,1,'first');
            % if signal ends up over thresh
            if(isempty(zeroAfter))
                zeroAfter = length(data);
            end
        else
            % minus one doesn't fill in next peak
            zeroAfter = locs(i) + find(abs(data(locs(i):locs(i+1)))<baseline,1,'first') - 1;
            % no zero crossing between this peak and next peak
            if(isempty(zeroAfter))
                zeroAfter = locs(i+1) - 1;
            end
        end
        % apply zeros to the entire area that the artifact contains, try to
        % minimize amount of operations performed
        if(~isempty(zeroBefore) || ~isempty(zeroAfter))
            if(~isempty(zeroBefore) && isempty(zeroAfter))
                data(zeroBefore:locs(i)) = 0;
            elseif(isempty(zeroBefore) && ~isempty(zeroAfter))
                data(locs(i):zeroAfter) = 0;
            else
                data(zeroBefore:zeroAfter) = 0;
            end
        end
    end
end