read_Intan_RHD2000_file;

%create filter
[b,a] = butter(4, [0.02 0.2]);

%filter all channels
f_amplifier_data = zeros(length(amplifier_channels), length(t_amplifier));
for channel = 1:length(amplifier_channels)
    f_amplifier_data(channel,:) = filtfilt(b,a,amplifier_data(channel,:));
end

%write individual channels to .ddt (replace X with channel number)
%ddt_write_v2('channel_X.ddt',1,length(f_amplifier_data(X,:)),frequency_parameters.amplifier_sample_rate,f_amplifier_data(X,:)/1000)

