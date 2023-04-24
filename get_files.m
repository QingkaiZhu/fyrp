%% Clear the workspace
clear
clc
close all
data_path = 'C:\Users\chuch\Documents\GitHub\fyrp\data\';
lta_path = 'LTA\LTA_raw_xlsx\';
lta_processed_path = 'preprocessed_data\LTA\';
mta_path = 'MTA\MTA_raw_xlsx\';
mta_processed_path = 'preprocessed_data\MTA\';
hta_path = 'HTA\HTA_raw_xlsx\';
hta_processed_path = 'preprocessed_data\HTA\';

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
