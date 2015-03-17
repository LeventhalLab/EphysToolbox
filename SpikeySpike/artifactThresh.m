function data = artifactThresh(data,validMask,thresh)
    % finds peaks above thresh of combined channels
    seekData = zeros(1,size(data,2));
    seekCount = 1;
    for ii=1:size(data,1)
        if ~validMask(ii)
            continue;
        end
        if seekCount == 1
            seekData = abs(data(ii,:));
        else
            seekData = mean([seekData;abs(data(ii,:))]);
        end
        seekCount = seekCount + 1;
    end
    locs = peakseek(seekData,1,thresh);

    % waveform has to come back to baseline
    baseline = 50;
    for ii=1:size(data,1)
        if ~validMask(ii)
            continue;
        end
        for iLoc=1:length(locs)
            % get quiet locations before/after artifact peak, this if/else
            % structure reduce computation time significantly
            if(iLoc==1)
                zeroBefore = find(abs(data(ii,1:locs(iLoc)))<baseline,1,'last');
                % if signal starts out over thresh
                if(isempty(zeroBefore))
                    zeroBefore = 1;
                end
            else
                zeroBefore = locs(iLoc-1) + find(abs(data(ii,locs(iLoc-1):locs(iLoc)))<baseline,1,'last');
                % no zero crossing between last peak and this peak
                if(isempty(zeroBefore))
                    zeroBefore = locs(iLoc-1);
                end
            end
            if(iLoc==length(locs))
                zeroAfter = locs(iLoc) + find(abs(data(ii,locs(iLoc):end))<baseline,1,'first');
                % if signal ends up over thresh
                if(isempty(zeroAfter))
                    zeroAfter = size(data,2);
                end
            else
                % minus one doesn't fill in next peak
                zeroAfter = locs(iLoc) + find(abs(data(ii,locs(iLoc):locs(iLoc+1)))<baseline,1,'first') - 1;
                % no zero crossing between this peak and next peak
                if(isempty(zeroAfter))
                    zeroAfter = locs(iLoc+1) - 1;
                end
            end
            % apply zeros to the entire area that the artifact contains, try to
            % minimize amount of operations performed
            if(~isempty(zeroBefore) || ~isempty(zeroAfter))
                if(~isempty(zeroBefore) && isempty(zeroAfter))
                    data(ii,zeroBefore:locs(iLoc)) = 0;
                elseif(isempty(zeroBefore) && ~isempty(zeroAfter))
                    data(ii,locs(iLoc):zeroAfter) = 0;
                else
                    data(ii,zeroBefore:zeroAfter) = 0;
                end
            end
        end
    end
    disp([num2str(length(locs)),' artifacts cured...']);
end