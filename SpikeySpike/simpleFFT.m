function [A,f] = simpleFFT(data,Fs,varargin)
    p = inputParser;
    addOptional(p,'newFig',true,@islogical);
    addOptional(p,'nSmooth',10,@isscalar);
    parse(p,varargin{:});
    inputs = p.Results;

    if size(data,1) > 1
        allA = [];
        for ii=1:size(data)
            [A,f] = getFFT(data(ii,:),Fs);
            allA(ii,:) = A;
        end
        A = mean(allA);
    else
        [A,f] = getFFT(data,Fs);
    end

    if inputs.newFig
        figure;
    else
        hold on;
    end
    
    semilogy(f,smooth(A,inputs.nSmooth));
    xlim([1 100]);
    xlabel('Frequency (Hz)')
    ylabel('|Y(f)|')
    set(gcf,'color','w')
end

function [A,f] = getFFT(data,Fs)
    T = 1/Fs; % Sample time
    L = length(data); % Length of signal
    t = (0:L-1)*T; % Time vector
    NFFT = 2^nextpow2(L); % Next power of 2 from length of y
    f = Fs/2*linspace(0,1,NFFT/2+1);

    Y = fft(double(data),NFFT)/L;
    A = 2*abs(Y(1:NFFT/2+1));
end