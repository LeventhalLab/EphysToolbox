function peaks=get_peaks(x, s, peak_type)
%indeces=get_peaks(x, s, peak_type)
%Finds peaks of type peak_type (positive or negative) in the vector x at scale s. 
%The output vector peaks has the same size as x and is 1 at the peak locations and zero
%elsewhere. Scale s is the number of samples used in computing a moving average of the 
%data and to define a neighborhood in which to search local extrema. It is an odd 
%integer. Peak_type should be 'pos' or 'neg'.

%Author: Murat Okatan, 03/10/03

%version 3. Increased the search window to 2*s-1 from s.
%version 2. Modifying the function so it computes only positive or negative peaks
%   as specified by a third input. Changed the output variable name to peaks.
%version 1. Detect positive and negative going peaks. The algorithm first computes the
%s-point moving average of the data. Finds the peaks in the filtered data. Then, 
%searches for actual local minima in the original data around the peaks found.

% "s" has been fed in from eegrhythm as Fs / peak_filter_freq / 2 (Fs =
% sampling rate) - DL 7/27/2010

%Default output

% make sure x is a row vector
if size(x,1) > 1
    x = x';
end

peaks=[];

if isempty(x) || isempty(s) || isempty(peak_type),
    errordlg('Not enough inputs');
    return;
end

if numel(x)~=length(x(:)),
    errordlg('Data not a vector');
    return;
end

if s<=0 || ~isreal(s),
    errordlg('Invalid scale');
    return;
end

%Data length
Lx=length(x);

if s>=Lx,
    errordlg('Scale must be smaller than data length');
    return;
end

switch peak_type,
    case 'pos'
    	find_pos_peaks=1;
    case 'neg'
    	find_pos_peaks=0;
    otherwise
        disp('Unknown peak type');
        return;
end

%Make s an odd integer
s=round(s);
if ~rem(s, 2),
    s=s+1;
end

if s>1,
    y_holder=zeros(1, Lx+2*s);
    y_holder(1:s)=y_holder(1:s)+x(1);
    y_holder(s+(1:Lx))=x;
    y_holder(Lx+s+1:end)=y_holder(Lx+s+1:end)+x(end);
    
    y=filtfilt(ones(1, s)/s, 1, y_holder);
    %Take the part of interest
    y=y(s+(1:Lx));    
else
    y=x;
end

%Define the middle range
range=2:Lx-1;

if find_pos_peaks,
	%Label peaks
	peaks=y(range)>=y(range-1) & y(range)>=y(range+1);
else
	peaks=y(range)<=y(range-1) & y(range)<=y(range+1);
end
peaks=[0 peaks 0];

%We do not expect large numbers of equal adjacent values. Reduce them to a single
%point near their middle
diff=peaks(2:end)-peaks(1:end-1);
adj_start_indx=1+find(diff==1);
adj_end_indx=1+find(diff==-1);
if ~isempty(adj_start_indx),
    %Remove the single ticks
    singles_indx=find((adj_start_indx==adj_end_indx)==1);
    adj_start_indx(singles_indx)=adj_start_indx(singles_indx)*0-1;
    valids=find(adj_start_indx~=-1);
    adj_start_indx=adj_start_indx(valids);
    adj_end_indx=adj_end_indx(valids);
    
    %Now, zero peaks, and set the singles and the centers of groups to 1
    peaks=peaks*0;
    peaks(singles_indx)=peaks(singles_indx)|1;
    peaks(fix((adj_start_indx+adj_end_indx)/2))=...
        peaks(fix((adj_start_indx+adj_end_indx)/2))|1;
end
%At this point, peaks are at points where peaks is 1

%Now check whether each value is the extremum value in its s-neighborhood
%If not, choose the extremum
s=2*s-1;
done=0;
while ~done,
    done=1;
	if s>1,
		peakindx=find(peaks==1);
		for i=1:length(peakindx),
            rangemin=max(1,  peakindx(i)-(s-1)/2);
            rangemax=min(Lx, peakindx(i)+(s-1)/2);
            range=rangemin:rangemax;
            if find_pos_peaks,
                extremum=max(x(range));
            else
                extremum=min(x(range));
            end
            
            if extremum~=x(peakindx(i)),
                done=0;
                peaks(peakindx(i))=0;
                
                %Find the local extremum's indx
                if find_pos_peaks,
                    indx=min(find(x(range)==max(x(range))));
                else
                    indx=min(find(x(range)==min(x(range))));
                end
                %Where is the current value
                indxc=peakindx(i)-rangemin+1;
                
                %Mark the local extremum as peak
                peaks(peakindx(i)+indx-indxc)=1;
            end
		end %i=1:length(peakindx)
	end %s>1
end %~done
