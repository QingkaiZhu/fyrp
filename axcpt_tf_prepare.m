%% Clear the workspace
clear
clc
close all

script_path = 'C:\Users\chuch\Documents\GitHub\fyrp\fyrp';
cd(script_path);
%% Set data path
saved_raw_xlsx_name = 'raw_xlsx_filenames.mat';
load(fullfile(script_path, saved_raw_xlsx_name));

% Define the root directory
rootDirs = {'C:\Users\chuch\Documents\GitHub\fyrp\data\preprocessed_data\LTA\',...
            'C:\Users\chuch\Documents\GitHub\fyrp\data\preprocessed_data\MTA\',...
            'C:\Users\chuch\Documents\GitHub\fyrp\data\preprocessed_data\HTA\'};

% Define the subjects cell arrays
subjectCells = {lta_subjects, mta_subjects, hta_subjects};

% Iterate over each root directory
for j = 1:length(rootDirs)
    % Extract the current root directory and corresponding subjects
    rootDir = rootDirs{j};
    subjects = subjectCells{j};

    % Iterate over each subject
    for i = 1:length(subjects)
        % Get the subject name
        subjectName = subjects{i}.name;
        
        % Create the full directory path
        fullPath = fullfile(rootDir, subjectName);
        
        % Check if the directory already exists
        if ~isfolder(fullPath)
            % If the directory does not exist, create it
            mkdir(fullPath);
        else
            fprintf('Directory %s already exists\n', fullPath);
        end

                % Define the subject file pattern
        subjectFilePattern = fullfile(rootDir, ['preprocessed_epoched*', subjectName, '.set']);

        % Get a list of files that match the pattern
        subjectFiles = dir(subjectFilePattern);

        % Iterate over each file and move it to the new directory
        for k = 1:length(subjectFiles)
            oldFilePath = fullfile(subjectFiles(k).folder, subjectFiles(k).name);
            newFilePath = fullfile(fullPath, subjectFiles(k).name);
            movefile(oldFilePath, newFilePath);
        end

                % Define the patterns for files to move back to the parent directory
        moveBackPatterns = {'preprocessed_epoched_AXp*', 'preprocessed_epoched_AYp*'};

        % Iterate over each pattern
        for m = 1:length(moveBackPatterns)
            % Get a list of files that match the pattern
            moveBackFiles = dir(fullfile(fullPath, moveBackPatterns{m}));

            % Iterate over each file and move it back to the parent directory
            for n = 1:length(moveBackFiles)
                oldFilePath = fullfile(moveBackFiles(n).folder, moveBackFiles(n).name);
                newFilePath = fullfile(rootDir, moveBackFiles(n).name);
                movefile(oldFilePath, newFilePath);
            end
        end
    end
end
