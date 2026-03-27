% Computation of Time–Frequency Power and ITPC
% using EEGLAB's newtimef with Morlet wavelets
%
% Optional: Time-shuffled ITPC control analysis; 
% set nShuffle to non-zero to generate Figure 4
%
% Author: Ankit Yadav

clear; clc;
eeglab nogui;

%% 
%Data directory
dir = 'D:\cardiff data'; %your path
cd(dir);

%Participants to include
sub = [3 4 5 6 7 8 9 23 24 26];

%% 
%Parameters
freqrange = [5 30];        
baseline = [-300 -100];           
cycles = [3 0.5]; %using 3 cycles at lowest frequency and increase linearly.

%Shuffling parameters (optional)
nShuffle = 0;

%Containers
all_ersp = [];
all_itpc = [];
all_erp = [];
all_itpc_null = [];

%%
%Loop over participants
for s = 1:length(sub)
   
    %Load metadata
    load(sprintf('part%d_sleep_manual_cleaned_N3.mat', sub(s)));
    t  = other_data.time; 
    Fs = 1 / mean(diff(t)); %sampling rate

    %Load EEG data
    eeg = h5read(sprintf('part%d_sleep_manual_cleaned_N3.h5', sub(s)), '/trial');

    %Average across channels
    eeg_avg = squeeze(mean(eeg,2));   
    data    = eeg_avg';

    tlimits = [t(1) t(end)] * 1000;

    %Observed TF and ITPC
    [ersp, itc, ~, times, freqs] = newtimef( ...
        data, ...
        size(data,1), ...
        tlimits, ...
        Fs, ...
        'cycles', cycles, ...
        'freqs', freqrange, ...
        'baseline', baseline, ...
        'plotersp','off', ...
        'plotitc','off' ...
        );

    ersp_percentchange = (10.^(ersp/10) - 1) * 100; %dB to percentage change

    all_ersp(s,:,:) = ersp_percentchange;
    all_itpc(s,:,:) = abs(itc);

    %% 
    %ERP computation 
    base_idx = t >= -0.3 & t <= -0.1;
    baseline_erp = mean(eeg_avg(:,base_idx),2);
    eeg_bc = eeg_avg - baseline_erp;

    erp_sub = mean(eeg_bc,1); %average over trials
    all_erp(s,:) = erp_sub;


    %%
    %OPTIONAL: Time-shuffled ITPC (null distribution)
    if nShuffle > 0

        itpc_shuff = zeros([nShuffle size(itc)]);

        for sh = 1:nShuffle

            data_shuff = data;

            %Circularly shift each trial independently
            for tr = 1:size(data,2)
                shift = randi(size(data,1));
                data_shuff(:,tr) = circshift(data(:,tr), shift);
            end

            [~, itc_null, ~] = newtimef( ...
                data_shuff, ...
                size(data_shuff,1), ...
                tlimits, ...
                Fs, ...
                'cycles', cycles, ...
                'freqs', freqrange, ...
                'baseline', baseline, ...
                'plotersp','off', ...
                'plotitc','off' ...
                );

            itpc_shuff(sh,:,:) = abs(itc_null);
        end

        %Average across shuffles
        all_itpc_null(s,:,:) = squeeze(mean(itpc_shuff,1));

    end

end

%%
%Grand averages across participants
paravg_ersp = squeeze(mean(all_ersp,1));
paravg_itpc = squeeze(mean(all_itpc,1));
grand_erp = mean(all_erp,1);
sem_erp   = std(all_erp,[],1) / sqrt(size(all_erp,1));

if nShuffle > 0
    paravg_itpc_null = squeeze(mean(all_itpc_null,1));
    itpc_diff = paravg_itpc - paravg_itpc_null;
end

%%
%Plot Time–frequency power, Figure 1
figure;
imagesc(t, freqs, paravg_ersp);
axis xy;
set(gca,'YScale','log')
ylim([5 30])
xlim([-0.3 4])
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Grand-averaged time–frequency');
h = colorbar;
ylabel(h, 'Percentage change from baseline');
clim([-30 30]);
xline(0,'k--');
set(gca,'FontSize',18);

%%
%Plot ITPC, Figure 2
figure;
imagesc(t, freqs, paravg_itpc);
axis xy;
set(gca,'YScale','log')
ylim([5 30])
xlim([-0.3 4])
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Inter-Trial Phase Consistency');
h = colorbar;
ylabel(h, 'ITPC');
xline(0,'k--');
set(gca,'FontSize',18);

%% 
%Plot ERP, Figure 3
figure; hold on;

fill([t fliplr(t)], ...
     [grand_erp + sem_erp fliplr(grand_erp - sem_erp)], ...
     [0.8 0.8 0.8], ...
     'EdgeColor','none', ...
     'FaceAlpha',0.5);

plot(t, grand_erp,'k','LineWidth',2);
xlim([-0.3 4])
xlabel('Time (s)');
ylabel('Amplitude (µV)');
title('Grand-averaged ERP (mean ± SEM, all channels)');
xline(0,'k--');
yline(0,'k:');
set(gca,'FontSize',18);

%% 
%OPTIONAL: Plot ITPC difference (Observed – Shuffled), Figure 4
if nShuffle > 0

    figure;
    imagesc(t, freqs, itpc_diff);
    axis xy;
    set(gca,'YScale','log')
    ylim([5 30])
    xlim([-0.3 4])
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    title('ITPC difference (Observed – Time-shuffled)');
    h = colorbar;
    ylabel(h, '\Delta ITPC');
    clim([-0.05 0.05]);
    xline(0,'k--');
    set(gca,'FontSize',18);

end
