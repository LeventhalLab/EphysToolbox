read_Intan_RHD2000_file;

% create filter
[b,a] = butter(4, [0.02 0.5]); % cutoff frequencies: 200Hz - 5kHz

% filter all channels, write all channels to .ddt
%{
save_name = 'Mthal_071917_5mW_10mW';
f_amplifier_data = zeros(length(amplifier_channels), length(t_amplifier));
for channel = 0:length(amplifier_channels)-1
    f_amplifier_data(channel+1,:) = filtfilt(b,a,amplifier_data(channel+1,:));
    ddt_write_v2([save_name '_channel_' num2str(channel) '.ddt'],1,length(f_amplifier_data(channel+1,:)),frequency_parameters.amplifier_sample_rate,f_amplifier_data(channel+1,:)/1000);
end
%}

% write individual channels to .ddt
%{
channel=12;
save_name = 'Mthal_071917_5mW_10mW_tetrode3';
f_amplifier_data = filtfilt(b,a,amplifier_data(channel+1,:));
ddt_write_v2([save_name '_channel_' num2str(channel) '.ddt'],1,length(f_amplifier_data),frequency_parameters.amplifier_sample_rate,f_amplifier_data/1000)
%}


% write 4 tetrode channels to .ddt
channels = [12 13 14 15];
save_name = 'Mthal_071917_20mW_30mW_tetrode5';
for i=1:length(channels)
    f_tetrode(i,:) = filtfilt(b,a,amplifier_data(channels(i)+1,:)); % filter
end

ddt_write_v([save_name '.ddt'], length(channels), length(f_tetrode(1,:)), frequency_parameters.amplifier_sample_rate, f_tetrode/1000);


