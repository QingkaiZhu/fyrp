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
rootDirs = {'D:\data\preprocessed_data\LTA\',...
            'D:\data\preprocessed_data\MTA\',...
            'D:\data\preprocessed_data\HTA\'};

% Define the subjects cell arrays
subjectCells = {lta_subjects, mta_subjects, hta_subjects};

%% Create study for each group
% % Define the study names
% studyNames = {'study_LTA.study', 'study_MTA.study', 'study_HTA.study'};
% 
% % Iterate over each root directory
% for j = 1:length(rootDirs)
%     % Extract the current root directory and corresponding subjects
%     rootDir = rootDirs{j};
%     subjects = subjectCells{j};
%     splitRootDir = split(rootDirs(1),'\');
%     groupName = splitRootDir(end - 1);
% 
%     % Initialize the commands array
%     commands = {};
% 
%     % Iterate over each subject
%     for i = 1:length(subjects)
%         % Get the subject name
%         subjectName = subjects{i}.name;
% 
%         % Define the subject file pattern
%         subjectFilePattern = fullfile(rootDir, subjectName, 'preprocessed_epoched*.set');
% 
%         % Get a list of files that match the pattern
%         subjectFiles = dir(subjectFilePattern);
% 
%         % Iterate over each file and add it to the STUDY
%         for k = 1:length(subjectFiles)
%             % Load the dataset
%             EEG = pop_loadset('filename', subjectFiles(k).name, 'filepath', subjectFiles(k).folder);
% 
%             % Add the dataset to the ALLEEG structure
%             [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG);
% 
%             % Extract the condition from the filename
%             [~, fileName, ~] = fileparts(subjectFiles(k).name);
%             splitFileName = split(fileName, '-');
%             condition = splitFileName{1}(length('preprocessed_epoched_')+1:end);
% 
%             % Add the command to the commands array
%             commands = [commands, {'index', CURRENTSET, 'load', fullfile(subjectFiles(k).folder, subjectFiles(k).name), 'subject', subjectName, 'condition', condition, 'group', groupName}];
%         end
%     end
% 
%     % Create the STUDY structure
%     STUDY = [];
%     [STUDY, ALLEEG] = std_editset(STUDY, [], 'name', studyNames{j}(1:end-6), 'task', 'AX-CPT task', 'filename', studyNames{j}, 'filepath', script_path, 'commands', commands, 'updatedat', 'on');
% 
% end

%% Create a study for all groups: HTA, LTA, and MTA
% create study designs
% use command line to do pre-compute
% use command line to

% Define the study name
studyName = 'all_groups.study';

% Initialize the commands array
commands = {};

% Create the STUDY structure
STUDY = [];
% STUDY.datasetinfo = struct();

% Iterate over each root directory
for j = 1:length(rootDirs)
    % Extract the current root directory and corresponding subjects
    rootDir = rootDirs{j};
    subjects = subjectCells{j};
    splitRootDir = split(rootDir,'\');
    groupName = splitRootDir{end - 1};

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
            commands = [commands, {'index', CURRENTSET, 'load', fullfile(subjectFiles(k).folder, subjectFiles(k).name), 'subject', [groupName, '_', subjectName], 'condition', [groupName, '_', condition], 'group', groupName}];
        end
    end
end

% Edit the STUDY structure with all the commands
[STUDY, ALLEEG] = std_editset(STUDY, ALLEEG, 'name', studyName(1:end-6), 'task', 'AX-CPT task', 'filename', studyName, 'filepath', script_path, 'commands', commands, 'updatedat', 'on', 'savedat', 'on', 'rmclust', 'off');
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'name','AX','delfiles','off','defaultdesign','on','variable1','condition','values1',{'HTA_AXc','LTA_AXc','MTA_AXc'},'vartype1','categorical');
STUDY = std_makedesign(STUDY, ALLEEG, 2, 'name','AY','delfiles','off','defaultdesign','off','variable1','condition','values1',{'HTA_AYc','LTA_AYc','MTA_AYc'},'vartype1','categorical');
STUDY = std_makedesign(STUDY, ALLEEG, 3, 'name','BX','delfiles','off','defaultdesign','off','variable1','condition','values1',{'HTA_BXc','LTA_BXc','MTA_BXc'},'vartype1','categorical');
STUDY = std_makedesign(STUDY, ALLEEG, 4, 'name','BY','delfiles','off','defaultdesign','off','variable1','condition','values1',{'HTA_BYc','LTA_BYc','MTA_BYc'},'vartype1','categorical');
STUDY = std_makedesign(STUDY, ALLEEG, 5, 'name','LTA_BX-HTA_AY','delfiles','off','defaultdesign','off','variable1','condition','values1',{'HTA_AYc','LTA_BXc'},'vartype1','categorical');
STUDY = std_makedesign(STUDY, ALLEEG, 6, 'name','LTA_BX-HTA_AX','delfiles','off','defaultdesign','off','variable1','condition','values1',{'HTA_AXc','LTA_BXc'},'vartype1','categorical');
STUDY = std_makedesign(STUDY, ALLEEG, 7, 'name','LTA_BY-HTA_AY','delfiles','off','defaultdesign','off','variable1','condition','values1',{'HTA_AYc','LTA_BYc'},'vartype1','categorical');
STUDY = std_makedesign(STUDY, ALLEEG, 8, 'name','LTA_BY-HTA_AX','delfiles','off','defaultdesign','off','variable1','condition','values1',{'HTA_AXc','LTA_BYc'},'vartype1','categorical');
STUDY = std_makedesign(STUDY, ALLEEG, 9, 'name','LTA_AX-HTA_BY','delfiles','off','defaultdesign','off','variable1','condition','values1',{'HTA_BYc','LTA_AXc'},'vartype1','categorical');
STUDY = std_makedesign(STUDY, ALLEEG, 10, 'name','LTA_AX-HTA_BX','delfiles','off','defaultdesign','off','variable1','condition','values1',{'HTA_BXc','LTA_AXc'},'vartype1','categorical');
STUDY = std_makedesign(STUDY, ALLEEG, 11, 'name','LTA_AY-HTA_BY','delfiles','off','defaultdesign','off','variable1','condition','values1',{'HTA_BYc','LTA_AYc'},'vartype1','categorical');
STUDY = std_makedesign(STUDY, ALLEEG, 12, 'name','LTA_AY-HTA_BX','delfiles','off','defaultdesign','off','variable1','condition','values1',{'HTA_BXc','LTA_AYc'},'vartype1','categorical');

[STUDY EEG] = pop_savestudy( STUDY, EEG, 'savemode','resave');

% 'cycles', [3 10], 'freqs', [2 100],  'nfreqs', 99, 'baseline', [-300 0], 'ntimesout', 100
% 4mins
% 'cycles', [3 10], 'freqs', [2 30],  'nfreqs', 29, 'baseline', [-300 0], 'ntimesout', 60
% 10mins
% 'cycles', [3 0.5], 'freqs', [2 100], 'nfreqs', 40, 'ntimesout', 60
% 
% 'cycles', [3 0.5], 'freqs', [2 100], 'nfreqs', 25, 'ntimesout', 60