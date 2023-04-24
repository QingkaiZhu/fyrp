% The event importing part was initially wrote by Garima Joshi
% garima@cbcs.ac.in, Centre of Behavioural and Cognitive Sciences (CBCS) of
% University of Allahabad.
% The current version was revised by Kai

%% Clear the workspace
clear
clc
close all

% To calculate the runtime of this script
tic

%% Add eeglab to the matlab path
% Or add eeglab directory to the MATLAB search path permanently via cmd `pathtool`
% addpath('C:\Users\chuch\Documents\MATLAB\eeglab2022.1')

%% Set data path
data_path = 'C:\Users\chuch\Documents\GitHub\fyrp\data\';
lta_path = 'LTA\LTA_raw_xlsx\';
lta_processed_path = 'preprocessed_data\LTA\';
mta_path = 'MTA\MTA_raw_xlsx\';
mta_processed_path = 'preprocessed_data\MTA\';
hta_path = 'HTA\HTA_raw_xlsx\';
hta_processed_path = 'preprocessed_data\HTA\';

script_path = 'C:\Users\chuch\Documents\GitHub\fyrp\fyrp';
cd(script_path);

%% Get all the raw and xlsx files
folders = {fullfile(data_path, lta_path), fullfile(data_path, hta_path), fullfile(data_path, mta_path)}; % List of subfolders
file_ext_xlsx = '.xlsx'; % File extension for the xlsx files
file_ext_raw = '.raw'; % File extension for the corresponding raw files

% Store raw and xlsx file for each group in three variables
hta_subjects = cell(1, 19);
lta_subjects = cell(1, 14);
mta_subjects = cell(1, 20);

% Iterate through each subfolder to get the files
for i = 1:length(folders)
    folder = folders{i};
    
    % Recursively search for xlsx files in the current subfolder and its subfolders
    xlsx_files = rdir(folder, ['**/*' file_ext_xlsx]);
    
    % Recursively search for raw files in the current subfolder and its subfolders
    raw_files = rdir(folder, ['**/*' file_ext_raw]);
    
    % Filter out raw files starting with ".", junk files of the MacOS
    % filesystem
    raw_files = raw_files(arrayfun(@(x) ~startsWith(get_filename(x{1}), '.'), raw_files));
    
    % Ensure the number of xlsx and raw files match
    if length(xlsx_files) ~= length(raw_files)
        warning(['The number of xlsx and raw files in folder ' folder ' do not match']);
        continue;
    end
    
    % Iterate through each xlsx file and its corresponding raw file
    for j = 1:length(xlsx_files)
        xlsx_file = xlsx_files{j};
        raw_file = raw_files{j};
        
        subject_files = struct('xlsx', xlsx_file, 'raw', raw_file);
        
        switch true
            case strcmp(folder, fullfile(data_path, hta_path))
                hta_subjects{j} = subject_files;
            case strcmp(folder, fullfile(data_path, lta_path))
                lta_subjects{j} = subject_files;
            case strcmp(folder, fullfile(data_path, mta_path))
                mta_subjects{j} = subject_files;
        end
    end
end

%% Load trial information from the E-prime xlsx file
% There a 960 trials in totoal for each subject(160 trials/per block, 6 blocks)
% Kai's update:
% xlsread is not recommended in MATLAB R2019a or later for compatibility
% considerations, use readtable instead, all we need is
% column 23: Trial number
% column 24: CellNumber, cue probe pair AX 1, AY 2, BX 3, BY 4
% column 45: probe.ACC modified to probe_ACC by importing
opts = detectImportOptions(fullfile(data_path, lta_path, 'Naseem/naseem.xlsx'));
opts.SelectedVariableNames = {'Trial', 'CellNumber', 'probe_ACC'};
T = readtable(fullfile(data_path, lta_path, 'Naseem/naseem.xlsx'), opts);
% summary(T)

% Kai's update:
% Some subjects don't have exactly 960 trials, so don't hardcode this
datTrialInfo = cell(1, length(T.Trial));
for i = 1 : length(T.Trial)
    datTrialInfo{i}.trialNum = T.Trial(i);
    if T.CellNumber(i) == 1
        datTrialInfo{i}.trialType = 'AX';
    elseif T.CellNumber(i) == 2
        datTrialInfo{i}.trialType = 'AY';
    elseif T.CellNumber(i) == 3
        datTrialInfo{i}.trialType = 'BX';
    else
        datTrialInfo{i}.trialType = 'BY';
    end

    % Correct/Incorrect
    if T.probe_ACC(i) == 0
        datTrialInfo{i}.response = 0;
    else
        datTrialInfo{i}.response = 1;
    end
end

%% Import the raw data
% eeglab_path = fileparts(which('eeglab.m'));
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % start EEGLAB
pop_editoptions( 'option_storedisk', 0); % Change option to process multiple datasets
% load data
EEG = pop_readegi(fullfile(data_path, lta_path, 'Naseem/naseem_AXCPT 20181114 0949.raw'), [],[],'auto');
EEG.setname='LTA_naseem';
EEG = eeg_checkset( EEG );

% Inspect events before modification
% List event types
% The number of event CELL is 1.
% The number of event SESS is 1.
% The number of event TRSP is 1918.
% The number of event bgin is 960.
% The number of event cue+ is 960.
% The number of event epoc is 6.
% The number of event fixa is 960.
% The number of event prob is 960.
% The number of event resp is 1871.
evtList = unique({EEG.event.type});
evt = struct2table(EEG.event);
for i = 1 : length(evtList)
    fprintf("The number of event %s is %d.\n", evtList{i}, sum(ismember(evt.type(:), evtList{i})));
end

%% Add new cue events to a loaded dataset 0.1 second before time-locking event
% Kai's update:
% The old method changed the urevent which contains the index of the event
% in the original (= wurh) urevent table, this supposed to remain unchanged.
% This method is from: https://eeglab.org/tutorials/11_Scripting/Event_Processing_command_line.html#scripts-for-creating-or-modifying-events
nevents = length(EEG.event);
iTrial = 0; % index for trial number
for index = 1 : nevents
    % todo
    % For most of the trial, there are two resp events, left arraw key or
    % right arrow key, so why should we insert new events after the first
    % resp event, what's the different between the two resp events
    if ischar(EEG.event(index).type) && strcmpi(EEG.event(index).type, 'resp') && ~strcmpi(EEG.event(index - 1).type, 'resp') % find the first or only resp event in every trial 
        iTrial = iTrial + 1;
        % Add events relative to existing events
        EEG.event(end+1) = EEG.event(index); % Add event to end of event list
        % Specifying the event latency to be 0.1 sec after the first resp
        % event in every trial, 0.1 is an arbitary number.
        % todo
        EEG.event(end).latency = EEG.event(index).latency + 0.1*EEG.srate;
        % Change the trial type accordingly
        if ischar(datTrialInfo{iTrial}.trialType) && strcmpi(datTrialInfo{iTrial}.trialType, 'AX')
            if datTrialInfo{iTrial}.response == 1                  
                EEG.event(end).type = 'C1C';
            else
                EEG.event(end).type = 'C1I';
            end
        elseif ischar(datTrialInfo{iTrial}.trialType) && strcmpi(datTrialInfo{iTrial}.trialType, 'AY')  
            if datTrialInfo{iTrial}.response == 1
                EEG.event(end).type = 'C2C';
            else
                EEG.event(end).type = 'C2I';
            end
        elseif ischar(datTrialInfo{iTrial}.trialType) && strcmpi(datTrialInfo{iTrial}.trialType, 'BX')
            if datTrialInfo{iTrial}.response == 1
                EEG.event(end).type = 'C3C';
            else
               EEG.event(end).type = 'C3I';
            end
        elseif ischar(datTrialInfo{iTrial}.trialType) && strcmpi(datTrialInfo{iTrial}.trialType, 'BY')
            if datTrialInfo{iTrial}.response == 1  
              EEG.event(end).type = 'C4C';
            else
                EEG.event(end).type = 'C4I';
            end    
        end
    end
end

% Adjust the order for all cue events
EEG = eeg_checkset(EEG, 'eventconsistency'); % Check all events for consistency
[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET); % Store dataset
eeglab redraw % Redraw the main EEGLAB window

% Inspect events after modification
% List event types
% The number of event C1C is 619.
% The number of event C1I is 19.
% The number of event C2C is 79.
% The number of event C2I is 11.
% The number of event C3C is 84.
% The number of event C3I is 7.
% The number of event C4C is 84.
% The number of event C4I is 8.
% The number of event CELL is 1.
% The number of event SESS is 1.
% The number of event TRSP is 1918.
% The number of event bgin is 960.
% The number of event cue+ is 960.
% The number of event epoc is 6.
% The number of event fixa is 960.
% The number of event prob is 960.
% The number of event resp is 1871.
evtList = unique({EEG.event.type});
evt = struct2table(EEG.event);
for i = 1 : length(evtList)
    fprintf("The number of event %s is %d.\n", evtList{i}, sum(ismember(evt.type(:), evtList{i})));
end 

%% Saving the new dataset.
EEG = pop_saveset( EEG, 'filename','naseem_evt.set','filepath',fullfile(data_path, lta_path, 'Naseem/'));
eeglab redraw % Redraw the main EEGLAB window

%% Load the channle location file
EEG.chanlocs=readlocs(fullfile(data_path, 'Hydrocel GSN 128 1.0.sfp'));
% Remove the first three channels: FidNz, FidT9, FidT10, and the last empty Cz
EEG.chanlocs = EEG.chanlocs(4:end-1);

% Set Cz as the original reference channel
% EEG.chanlocs=pop_chanedit(EEG.chanlocs, 'load',{ fullfile(data_path, 'Hydrocel GSN 128 1.0.sfp'), 'filetype', 'sfp'});
% [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET); % Store dataset
for c = 1:EEG.nbchan
    EEG.chanlocs(c).ref = 'Cz';
end
EEG = pop_saveset( EEG, 'filename','naseem_chan_script.set','filepath',fullfile(data_path, lta_path, 'Naseem/'));

%% High pass filtering the data at 0.5Hz
EEG = pop_eegfiltnew(EEG, 'locutoff',0.5);
EEG = eeg_checkset( EEG );
EEG = pop_saveset( EEG, 'filename','naseem_highpass_script.set','filepath',fullfile(data_path, lta_path, 'Naseem/'));

%% Notch filtering at 50Hz and 100Hz
EEG = pop_cleanline(EEG, 'bandwidth',2,'chanlist',[1:128] ,'computepower',1,'linefreqs',[50 100] ,'newversion',0,'normSpectrum',0,'p',0.01,'pad',2,'plotfigures',0,'scanforlines',0,'sigtype','Channels','taperbandwidth',2,'tau',100,'verb',1,'winsize',4,'winstep',2);EEG = eeg_checkset( EEG );
EEG = eeg_checkset( EEG );
EEG = pop_saveset( EEG, 'filename','naseem_notch_cleanline.set','filepath',fullfile(data_path, lta_path, 'Naseem/'));

%% Rereference the data to average reference and retain Cz
% todo: Doesn't work with eeglab v2023.0, file an upstream issue for this
EEG = pop_reref( EEG, [],'refloc',struct('labels',{'Cz'},'Y',{0},'X',{6.2205e-16},'Z',{10.1588},'sph_theta',{0},'sph_phi',{90},'sph_radius',{10.1588},'theta',{0},'radius',{0},'type',{''},'ref',{'Cz'},'urchan',{132},'datachan',{0}));
EEG = eeg_checkset( EEG );
% Save for rereference
[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET); % Store dataset
EEG = pop_saveset( EEG, 'filename','naseem_reref_script.set','filepath',fullfile(data_path, lta_path, 'Naseem/'));

%% ICA
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1);
EEG = eeg_checkset( EEG );

EEG = pop_saveset( EEG, 'filename','naseem_ica.set','filepath',fullfile(data_path, lta_path, 'Naseem/'));
eeglab redraw % Redraw the main EEGLAB window

% To calculate the runtime of this script
timeElapsed = toc;

% Function to get the filename from a file path
function filename = get_filename(filepath)
    [~, filename, ~] = fileparts(filepath);
end

% rdir function definition
function file_list = rdir(base_dir, file_pattern)
    if nargin < 2
        file_pattern = '';
    end
    d = dir(fullfile(base_dir, file_pattern));
    is_dir = [d.isdir];
    files = {d(~is_dir).name};  % Files
    dirs = {d(is_dir).name};  % Directories
    file_list = cellfun(@(x) fullfile(base_dir, x), files, 'UniformOutput', false);
    
    % Recursive call for subdirectories
    for i = 1:numel(dirs)
        dirname = dirs{i};
        if ~strcmp(dirname, '.') && ~strcmp(dirname, '..')
            subdir = fullfile(base_dir, dirname);
            file_list = [file_list; rdir(subdir, file_pattern)]; %#ok<AGROW>
        end
    end
end