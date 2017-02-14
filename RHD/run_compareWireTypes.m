% read_Intan_RHD2000_file
params.Fs = 20000;
params.fpass = [1 80];
params.pad = 0;
params.tapers = [3 5];

chsTet = [32 33 34 35 40 41 42 43];
chs50 = [8 9 10 11 14 15 56 57];

figure('position',[0 0 1100 600]);
for ii = 1:8
    disp(ii);
    
    subplot(2,4,ii);
    data = amplifier_data(chsTet(ii),:)';
    [S,f] = mtspectrumc(data,params);
    plot_vector(smooth(S,300),f,'l',[],'b');
    
    hold on;
    
    data = amplifier_data(chs50(ii),:)';
    [S,f] = mtspectrumc(data,params);
    plot_vector(smooth(S,300),f,'l',[],'r');
    
    ylim([-10 40]);
    title(['Tetrode ch',num2str(chsTet(ii)),'; 50um ch',num2str(chs50(ii))]);
    legend('Tetrode','50um','Location','southwest');
end