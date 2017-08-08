file='\\172.20.138.142\RecordingsLeventhal3\OptoEphys\R0206\072117\Mthal_170721_135226.rhd';

if false % set to true to load file, false if file is already loaded
    read_Intan_RHD2000_file(file);
end

type = 0; % 1: single, 0: tetrode
save_name = 'R0201_072117';

% channels: num_tetrodes x 4 array, change based on channel mapping! (only used for
% tetrodes)
channels = [24 25 30 31; 26 27 28 29; 20 21 22 23; 16 17 18 19; 12 13 14 15; 8 9 10 11; 2 3 4 5; 0 1 6 7; 40 41 46 47; 42 43 44 45; 36 37 38 39; 32 33 34 35; 60 61 62 63; 56 57 58 59; 50 51 52 53; 48 49 54 55];



% create filter
[b,a] = butter(4, [0.02 0.5]); % cutoff frequencies: 200Hz - 5kHz


% filter all single channels, write all channels to .ddt
if type

    f_amplifier_data = zeros(length(amplifier_channels), length(t_amplifier));
    for channel = 0:length(amplifier_channels)-1
        f_amplifier_data(channel+1,:) = filtfilt(b,a,amplifier_data(channel+1,:));
        ddt_write_v([save_name '_channel_' num2str(channel) '.ddt'],1,length(f_amplifier_data(channel+1,:)),frequency_parameters.amplifier_sample_rate,f_amplifier_data(channel+1,:)/1000);
    end





% write tetrode (4 channels) to .ddt (all 16 tetrodes)
else
    f_tetrode = zeros(4, length(amplifier_data(1,:)));
    for j=1:16
        for i=1:4
            f_tetrode(i,:) = filtfilt(b,a,amplifier_data(channels(j,i)+1,:)); % filter
        end
        ddt_write_v([save_name '_tetrode' num2str(j) '_ch_' num2str(channels(j,1)) '_' num2str(channels(j,2)) '_' num2str(channels(j,3)) '_' num2str(channels(j,4)) '.ddt'], 4, length(f_tetrode(1,:)), frequency_parameters.amplifier_sample_rate, f_tetrode/1000);
    end
end
