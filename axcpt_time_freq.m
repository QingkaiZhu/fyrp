%% Clear the workspace
clear
clc
close all

script_path = 'C:\Users\chuch\Documents\GitHub\fyrp\fyrp';
cd(script_path);
%% Set data path
saved_raw_xlsx_name = 'raw_xlsx_filenames.mat';
load(fullfile(script_path, saved_raw_xlsx_name));

% figure; pop_spectopo(EEG, 1, [-1000  1996], 'EEG' , 'freq', [4 6 10], 'freqrange',[2 25],'electrodes','on', 'winsize', 250, 'overlap', 125);
% Note: change subjs and processed_path before running the script
% which group you want to analyse
subjs = lta_subjects;
processed_path = lta_processed_path;
% Set the parameters
freqs = linspace(2, 25, 24); % Frequencies from 2 to 25 Hz, linearly spaced
cycles = linspace(3, 10, 25); % Cycles from 3 at 1 Hz to 10 at 25 Hz, linearly spaced
baseline = [-300 0]; % Baseline period in ms
channels = [6, 11, 129]; % Channels for analysis

%% activate eeglab v2022.1
eeglab_path = fileparts(which('eeglab.m')); % get EEGLAB path
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % start EEGLAB, make sure you have egilegacy and cleanline plugins installed

epochingEvts = {'AYc', 'BXc', 'AXc', 'BYc'};

for iEvt = 1:length(epochingEvts)
    all_ersp = zeros(24, 200);
    i = 0;
    epochingEvt = epochingEvts{iEvt};
    for iSubjs = 1 : length(subjs)
        % Create new EEG set
        STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG = []; CURRENTSET = []; ALLCOM = [];
        filename = ['preprocessed_epoched_' epochingEvt '-' subjs{iSubjs}.name '.set'];
        EEG = pop_loadset('filename', filename, 'filepath', fullfile(data_path, processed_path));
        
        % Run time-frequency analysis for specified channels and collect ERSPs
        for ch = channels
%             [ersp, itc, powbase, times, freqs] = newtimef(EEG.data(ch, :, :), ...
%             EEG.pnts, [EEG.xmin EEG.xmax]*1000, EEG.srate, cycles, ...
%             'freqs', freqs, ...
%             'baseline', baseline, ...
%             'plotitc', 'off', 'plotersp', 'off');
            [ersp, itc, powbase, times, freqs, erspboot, itcboot] = newtimef( EEG.data(ch, :, :), EEG.pnts, [EEG.xmin EEG.xmax]*1000, EEG.srate, cycles , 'baseline', baseline, 'freqs', freqs, 'plotphase', 'off', 'padratio', 1, 'plotitc', 'off', 'plotersp', 'off');

            % figure; pop_newtimef( EEG, 1, 6, [-1000  1996], [3      3.29167      3.58333        3.875      4.16667      4.45833         4.75      5.04167      5.33333        5.625      5.91667      6.20833          6.5      6.79167      7.08333        7.375      7.66667      7.95833         8.25      8.54167      8.83333        9.125      9.41667      9.70833           10] , 'topovec', 6, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', 'E6', 'baseline',[-300 0], 'freqs', [linspace(2, 25, 25)], 'plottype', 'curve', 'plotphase', 'off', 'padratio', 1);
            % figure; pop_newtimef( EEG, 1, 6, [-1000  1996], [3         0.8] , 'topovec', 6, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', 'E6', 'baseline',[-300 0], 'freqs', [linspace(4, 8, 5)], 'plotphase', 'off', 'padratio', 1);

            % Add the ERSP to the collection
            all_ersp = all_ersp + ersp;
            i = i+1;
        end
    end
    avg_ersp = all_ersp/i;
    disp(i);
    folder_name = split(processed_path, filesep);
    group_name = folder_name{end-1};  % Get the second last part
    save(fullfile(data_path, '\preprocessed_data\', ['TimeFreq_' group_name '_' epochingEvt '.mat']), 'times', 'freqs', 'avg_ersp');
    
    % Create the figure and plot the data
    fig = figure;
    tftopo(avg_ersp, times, freqs);
    clim([-2.5 2.5]); % Set color range
    colorbar;  % To show the color scale
    xlabel('Time (ms)');  % Label x-axis
    ylabel('Frequency (Hz)');  % Label y-axis
    title([group_name, ' ', epochingEvt, ' Average ERSP']);  % Title
    
    % Save the figure
    saveas(fig, fullfile(data_path, '\preprocessed_data\', [group_name, '_', epochingEvt, '_Average_ERSP.png']));
end

% Calculate the average ERSP across all subjects
% avg_ersp = mean(all_ersp, 4);
% folder_name = split(processed_path, filesep);
% group_name = folder_name{end-1};  % Get the second last part
% save(['TimeFreq_' group_name '.mat'], 'avg_ersp');
% 
% % Assume times and freqs are the output from the newtimef() function
% figure; tftopo(ersp, times, freqs);
% colorbar;  % To show the color scale
% xlabel('Time (ms)');  % Label x-axis
% ylabel('Frequency (Hz)');  % Label y-axis
% title('Average ERSP');  % Title


% % Load the data
% EEG = pop_loadset('your_file.set');
% 
% % Set the parameters
% freqs = linspace(1, 25, 25); % Frequencies from 1 to 25 Hz, linearly spaced
% cycles = linspace(3, 10, 25); % Cycles from 3 at 1 Hz to 10 at 25 Hz, linearly spaced
% baseline = [-300 0]; % Baseline period in ms
% channels = [6, 11, 129]; % Channels for analysis
% 
% % Run time-frequency analysis for specified channels
% for ch = channels
%     [spectra, times, freqs, ersp, itc] = newtimef(EEG.data(ch, :, :), ...
%         EEG.pnts, [EEG.xmin EEG.xmax]*1000, EEG.srate, cycles, ...
%         'freqs', freqs, ...
%         'baseline', baseline, ...
%         'plotitc', 'off', 'plotersp', 'on');
%     
%     % Save all your results for each channel
%     save(['TimeFreq_channel_' num2str(ch) '.mat'], 'spectra', 'times', 'freqs', 'ersp', 'itc');
% end
