%% Clear the workspace
clear
clc
close all

script_path = 'C:\Users\chuch\Documents\GitHub\fyrp\fyrp';
cd(script_path);
%% Set data path
saved_raw_xlsx_name = 'raw_xlsx_filenames.mat';
load(fullfile(script_path, saved_raw_xlsx_name));

eeglab_path = fileparts(which('eeglab.m')); % get EEGLAB path
% Start eeglab
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;


% Define the root directory
rootDirs = {'C:\Users\chuch\Documents\GitHub\fyrp\data\preprocessed_data\LTA\',...
            'C:\Users\chuch\Documents\GitHub\fyrp\data\preprocessed_data\MTA\',...
            'C:\Users\chuch\Documents\GitHub\fyrp\data\preprocessed_data\HTA\'};

% Define the subjects cell arrays
subjectCells = {lta_subjects, mta_subjects, hta_subjects};

% Define the study names
studyNames = {'study_LTA.study', 'study_MTA.study', 'study_HTA.study'};

% Iterate over each root directory
for j = 1:length(rootDirs)
    % Extract the current root directory and corresponding subjects
    rootDir = rootDirs{j};
    subjects = subjectCells{j};
    splitRootDir = split(rootDirs(1),'\');
    groupName = splitRootDir(end - 1);

    % Initialize the commands array
    commands = {};

    % Iterate over each subject
    for i = 1:length(subjects)
        % Get the subject name
        subjectName = subjects{i}.name;

        % Define the subject file pattern
        subjectFilePattern = fullfile(rootDir, subjectName, 'preprocessed_epoched*.set');

        % Get a list of files that match the pattern
        subjectFiles = dir(subjectFilePattern);

        % Iterate over each file and add it to the STUDY
        for k = 1:length(subjectFiles)
            % Load the dataset
            EEG = pop_loadset('filename', subjectFiles(k).name, 'filepath', subjectFiles(k).folder);

            % Add the dataset to the ALLEEG structure
            [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);

            % Extract the condition from the filename
            [~, fileName, ~] = fileparts(subjectFiles(k).name);
            splitFileName = split(fileName, '-');
            condition = splitFileName{1}(length('preprocessed_epoched_')+1:end);

            % Add the command to the commands array
            commands = [commands, {'index', CURRENTSET, 'load', fullfile(subjectFiles(k).folder, subjectFiles(k).name), 'subject', subjectName, 'condition', condition, 'group', groupName}];
        end
    end

    % Create the STUDY structure
    STUDY = [];
    [STUDY, ALLEEG] = std_editset(STUDY, [], 'name', studyNames{j}(1:end-6), 'task', 'AX-CPT task', 'filename', studyNames{j}, 'filepath', script_path, 'commands', commands, 'updatedat', 'on');

end
