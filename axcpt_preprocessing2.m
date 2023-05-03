%{
MATLAB Script to reject artificats components and extract epochs
1. This script should be ran after axcpt_preprocessing.m
2. In section 'Set data path': Change the data_path as the path which contains
   three unziped folders, and change the script_path
3. Make sure the location file is stored in data_path
4. In section 'Load trial information from the E-prime xlsx file': Set
   variables subjs and processed_path to the group you want to preprocess
5. Change epochingEvts in the Extract epochs section to the events list you
   want to export
6. Make sure you are using eeglab v2022.1 with egilegacy, ICLabel and 
   cleanline plugins installed
Author:
- Kai
%}

%% Clear the workspace
clear
clc
close all

%% Set data path
% The location file should be placed under the data_path
% Note: set the data_path and script_path for your system
data_path = 'C:\Users\chuch\Documents\GitHub\fyrp\data\';
lta_path = 'LTA\LTA_raw_xlsx\';
lta_processed_path = 'preprocessed_data\LTA\';
mta_path = 'MTA\MTA_raw_xlsx\';
mta_processed_path = 'preprocessed_data\MTA\';
hta_path = 'HTA\HTA_raw_xlsx\';
hta_processed_path = 'preprocessed_data\HTA\';

% Check if the preprocessed_data folder exists
processed_paths = {hta_processed_path, lta_processed_path, mta_processed_path};
for i = 1 : length(processed_paths)
    full_path = fullfile(data_path, processed_paths{i});

    % Check if the folder exists
    if ~exist(full_path, 'dir')
        % If the folder doesn't exist, create it
        mkdir(full_path);
    end
end

script_path = 'C:\Users\chuch\Documents\GitHub\fyrp\fyrp';
cd(script_path);

%% Get all the raw and xlsx files
folders = {fullfile(data_path, lta_path), fullfile(data_path, hta_path), fullfile(data_path, mta_path)}; % List of subfolders
file_ext_xlsx = '.xlsx'; % File extension for the xlsx files
file_ext_raw = '.raw'; % File extension for the corresponding raw files

hta_subjects = cell(1, 19);
lta_subjects = cell(1, 14);
mta_subjects = cell(1, 20);

% Iterate through each subfolder
for i = 1:length(folders)
    folder = folders{i};
    
    % Recursively search for xlsx files in the current subfolder and its subfolders
    xlsx_files = get_files_list(folder, ['**/*' file_ext_xlsx]);
    
    % Recursively search for raw files in the current subfolder and its subfolders
    raw_files = get_files_list(folder, ['**/*' file_ext_raw]);
    
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

        % Extract the subject name
        [~, file_name, ~] = fileparts(xlsx_file);
        
        subject_files = struct('xlsx', xlsx_file, 'raw', raw_file, 'name', file_name);
        
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
% Note: change subjs and processed_path before running the script
% which group you want to pre-process, run the three groups one by one
subjs = mta_subjects;
% subjs = lta_subjects;
% subjs = mta_subjects;
processed_path = mta_processed_path;

%% activate eeglab v2022.1, it seems there is a bug in v2023.0
% Notes: Double check the bug and report to upstream
eeglab_path = fileparts(which('eeglab.m')); % get EEGLAB path
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % start EEGLAB, make sure you have egilegacy and cleanline plugins installed

%% Remove artifacts ICs via ICLabel
for iSubjs = 1 : length(subjs)
    % Create new EEG set
    STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG = []; CURRENTSET = []; ALLCOM = [];
    
    %load the files after ICA
    EEG = pop_loadset('filename', ['preprocessed_ica-' subjs{iSubjs}.name '.set'], 'filepath', fullfile(data_path, processed_path));
    
    % The 6 categories are (in order) Brain, Muscle, Eye, Heart, Line Noise, Channel Noise, Other.
    % We are going to flag the Muscle, Eye, Line or Channel noise
    % channel which has a probility greater than 0.9 as artifact IC
    thresholds = [0 0; 0.9 1; 0.9 1; 0 0; 0.9 1; 0.9 1; 0 0];

    % run ICLabel classification
    EEG = iclabel(EEG);

    % Flag ICs
    EEG = pop_icflag(EEG, thresholds);
    % Get all the flagged ICs
    rejICs   = find(EEG.reject.gcompreject);
    % Remove flagged componnets
    EEG = pop_subcomp(EEG, rejICs);
    EEG = eeg_checkset( EEG );
    
    EEG = pop_saveset( EEG, 'filename', ['preprocessed_ica_removed-' subjs{iSubjs}.name '.set'], 'filepath', fullfile(data_path, processed_path));
    eeglab redraw % Redraw the main EEGLAB window
end

%% Extract epochs
% The time-locking events you want to extract
epochingEvts = {'AYc', 'BXc'};
for iSubjs = 1 : length(subjs)
    for iEvt = 1:length(epochingEvts)
        epochingEvt = epochingEvts{iEvt};

        % Create new EEG set
        STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG = []; CURRENTSET = []; ALLCOM = [];
        
        %load the files after ICA
        EEG = pop_loadset('filename', ['preprocessed_ica_removed-' subjs{iSubjs}.name '.set'], 'filepath', fullfile(data_path, processed_path));
        
        % Extract epochs for time-locking event (-1s to 2s)
        EEG = pop_epoch( EEG, {  epochingEvt  }, [-1  2], 'newname', 'EGI file pruned with ICA epochs', 'epochinfo', 'yes');
        EEG = eeg_checkset( EEG );
        
        EEG = pop_saveset( EEG, 'filename', ['preprocessed_epoched_' epochingEvt '-' subjs{iSubjs}.name '.set'], 'filepath', fullfile(data_path, processed_path));
        eeglab redraw % Redraw the main EEGLAB window
    end
end

%% Functions
% Function to get the filename from a file path
function filename = get_filename(filepath)
    [~, filename, ~] = fileparts(filepath);
end

% Function to get the file list under the base_dir
function file_list = get_files_list(base_dir, file_pattern)
    if nargin < 2
        file_pattern = '';
    end
    d = dir(fullfile(base_dir, file_pattern));
    is_dir = [d.isdir];
    files = {d(~is_dir).name};  % Files
    dirs = {d(is_dir).name};  % Directories
    relative_dirs = {d(~is_dir).folder}; % Relative directories
    file_list = cellfun(@(x, y) fullfile(y, x), files, relative_dirs, 'UniformOutput', false);
    
    % Recursive call for subdirectories
    for i = 1:numel(dirs)
        dirname = dirs{i};
        if ~strcmp(dirname, '.') && ~strcmp(dirname, '..')
            subdir = fullfile(base_dir, dirname);
            file_list = [file_list; get_files_list(subdir, file_pattern)]; %#ok<AGROW>
        end
    end
end

% Function to get the event type when inserting trial specific events
function event_type = get_event_type(trialType, response, eventType)
    if strcmpi(eventType, 'prob')
        p_or_c = 'p'; % prob
    else
        p_or_c = 'c'; % cue+
    end
    
    if response == 1 % correct or incorrect
        responseTag = '';
    else
        responseTag = 'I'; % incorrect
    end
    
    event_type = [trialType, p_or_c, responseTag];
end