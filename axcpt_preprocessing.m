%{
MATLAB Script to read and preprocess NetStation EGI raw Data
1. Unzip three data files in the same directory, three groups should be
   placed in the subfolders of LTA, HTA, MTA respectively
2. In section 'Set data path': Change the data_path as the path which contains
   three unziped folders
3. Make sure the location file is stored in data_path
4. In section 'Load trial information from the E-prime xlsx file': Set
   variables subjs and processed_path to the group you want to preprocess
5. Make sure you are using eeglab v2023.0 with egilegacy and cleanline plugins
   installed
Author:
- The event importing part was initially wrote by Garima Joshi
  garima AT cbcs.ac.in, Centre of Behavioural and Cognitive Sciences (CBCS) of
  University of Allahabad.
- The current version and remaining parts were revised by Kai
%}

%% Clear the workspace
clear
clc
close all

%% Set data path
% The location file should be placed under the data_path
% Note: set the data_path for your system
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
% There a 960 trials in totoal for each subject(160 trials/per block, 6 blocks)
% Kai's update:
% xlsread is not recommended in MATLAB R2019a or later for compatibility
% considerations, use readtable instead, all we need is
% column 23: Trial number
% column 24: CellNumber, cue probe pair AX 1, AY 2, BX 3, BY 4
% column 45: probe.ACC modified to probe_ACC by importing

% Note: change subjs and processed_path before running the script
% which group you want to pre-process, run the three groups one by one
subjs = hta_subjects;
% subjs = lta_subjects;
% subjs = mta_subjects;
processed_path = hta_processed_path;

%% activate eeglab v2022.1, it seems there is a bug in v2023.0
% Notes: Double check the bug and report to upstream
eeglab_path = fileparts(which('eeglab.m')); % get EEGLAB path
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % start EEGLAB, make sure you have egilegacy and cleanline plugins installed

for iSubjs = 1 : length(subjs)
    % To calculate the runtime of this subject
    tic
    X = ['Pre-processing ' hta_subjects{1}.name ' which is the ' num2str(iSubjs) ' of the group'];
    disp(X);

    % Create new EEG set
    STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG = []; CURRENTSET = []; ALLCOM = [];

    opts = detectImportOptions(subjs{iSubjs}.xlsx);
    opts.SelectedVariableNames = {'Trial', 'CellNumber', 'probe_ACC'};
    T = readtable(subjs{iSubjs}.xlsx, opts);
    % summary(T)
    
    % Export trial information from the xlsx file and store in datTrialInfo
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
    pop_editoptions( 'option_storedisk', 0); % Change option to process multiple datasets
    % load data
    EEG = pop_readegi(subjs{iSubjs}.raw, [],[],'auto');
    % EEG.setname = subjs{iSubjs}.name;
    EEG = eeg_checkset( EEG );
    
    % Inspect events before modification
    % List event types
    evtList = unique({EEG.event.type});
    evt = struct2table(EEG.event);
    for i = 1 : length(evtList)
        fprintf("The number of event %s is %d.\n", evtList{i}, sum(ismember(evt.type(:), evtList{i})));
    end
    
    %% Add new cue events to a loaded dataset 0.1 second before time-locking event
    % The old method changed the urevent which contains the index of the event
    % in the original (= wurh) urevent table, this supposed to remain unchanged.
    % This method is from: https://eeglab.org/tutorials/11_Scripting/Event_Processing_command_line.html#scripts-for-creating-or-modifying-events
    nevents = length(EEG.event);
    iTrial = 0; % index for trial number
    for iEvents = 1 : nevents
        % Notes:
        % For most of the trial, there are two resp events, left arraw key or
        % right arrow key, so why should we insert new events after the first
        % resp event in the initial script, what's the different between the
        % two resp events? And why 0.1s was chosen as the event latency after
        % the first resp event in every trial in the initial script?
        
        % In this version, we will insert the trial specific event 200ms before
        % the cue+ and probe events
        if ischar(EEG.event(iEvents).type) && (strcmpi(EEG.event(iEvents).type, 'cue+') || strcmpi(EEG.event(iEvents).type, 'prob')) % find the cue+ or prob events in every trial 
            if strcmpi(EEG.event(iEvents).type, 'cue+')
                iTrial = iTrial + 1;
            end
            % Add events relative to existing events
            EEG.event(end+1) = EEG.event(iEvents); % Add event to end of event list
            % Specifying the event latency to be 0.2 sec before cue+ or
            % prob
            EEG.event(end).latency = EEG.event(iEvents).latency - 0.2*EEG.srate;
            % Change the trial type accordingly
            if ischar(datTrialInfo{iTrial}.trialType)
                trialType = upper(datTrialInfo{iTrial}.trialType);
                response = datTrialInfo{iTrial}.response;
                eventType = EEG.event(iEvents).type;
        
                % This could be:
                % AXc: cue for correct AX trials
                % AXp: prob for correct AX trials
                % AXcI: cue for incorrect AX trials
                % AXpI: prob for incorrect AX trials
                EEG.event(end).type = get_event_type(trialType, response, eventType);
            end
        end
    end
    
    % Adjust the order for all cue events
    EEG = eeg_checkset(EEG, 'eventconsistency'); % Check all events for consistency
    % eeglab redraw % Redraw the main EEGLAB window
    
    % Inspect events after modification
    % List event types
    evtList = unique({EEG.event.type});
    evt = struct2table(EEG.event);
    for i = 1 : length(evtList)
        fprintf("The number of event %s is %d.\n", evtList{i}, sum(ismember(evt.type(:), evtList{i})));
    end 
    
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
    
    %% High pass filtering the data at 0.5Hz
    EEG = pop_eegfiltnew(EEG, 'locutoff',0.5);
    EEG = eeg_checkset( EEG );
    
    %% Notch filtering at 50Hz and 100Hz
    EEG = pop_cleanline(EEG, 'bandwidth',2,'chanlist',[1:128] ,'computepower',1,'linefreqs',[50 100] ,'newversion',0,'normSpectrum',0,'p',0.01,'pad',2,'plotfigures',0,'scanforlines',0,'sigtype','Channels','taperbandwidth',2,'tau',100,'verb',1,'winsize',4,'winstep',2);EEG = eeg_checkset( EEG );
    EEG = eeg_checkset( EEG );
    
    %% Rereference the data to average reference and retain Cz
    % Notes: Doesn't work with eeglab v2023.0, file an upstream issue for this
    EEG = pop_reref( EEG, [],'refloc',struct('labels',{'Cz'},'Y',{0},'X',{6.2205e-16},'Z',{10.1588},'sph_theta',{0},'sph_phi',{90},'sph_radius',{10.1588},'theta',{0},'radius',{0},'type',{''},'ref',{'Cz'},'urchan',{132},'datachan',{0}));
    EEG = eeg_checkset( EEG );
    % Save for rereference
    EEG = pop_saveset( EEG, 'filename', ['preprocessed_filtered-' subjs{iSubjs}.name '.set'], 'filepath', fullfile(data_path, processed_path));
    
    %% ICA
    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1);
    EEG = eeg_checkset( EEG );
    
    EEG = pop_saveset( EEG, 'filename', ['preprocessed_ica-' subjs{iSubjs}.name '.set'], 'filepath', fullfile(data_path, processed_path));
    eeglab redraw % Redraw the main EEGLAB window
    
    % To calculate the runtime of this subject
    timeElapsed = toc;
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