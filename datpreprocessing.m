% The event importing part was initially wrote by Garima Joshi
% garima@cbcs.ac.in, Centre of Behavioural and Cognitive Sciences (CBCS) of
% University of Allahabad.
% The current version was revised by Kai

%% Clear the workspace
clear
clc
close all

%% Add eeglab to the matlab path
% Or add eeglab directory to the MATLAB search path permanently via cmd `pathtool`
% addpath('C:\Users\chuch\Documents\MATLAB\eeglab2022.1')

%% Set data path
data_path = 'C:\Users\chuch\Documents\MEGAsync\learning\CCS\2a\prj\data\';
cd(data_path);

%% Load trial information from the E-prime xlsx file
% There a 960 trials in totoal for each subject(160 trials/per block, 6 blocks)
% xlsread is not recommended in MATLAB R2019a or later for compatibility
% considerations, all we need is
% column 23: Trial number
% column 24: CellNumber, cue probe pair AX 1, AY 2, BX 3, BY 4
% column 45: probe.ACC modified to probe_ACC by importing
% [a,b,c] = xlsread('./preprocessing/naseem.xlsx');
opts = detectImportOptions('./preprocessing/naseem.xlsx');
opts.SelectedVariableNames = {'Trial', 'CellNumber', 'probe_ACC'};
T = readtable('./preprocessing/naseem.xlsx', opts);
% summary(T)

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
eeglab_path = fileparts(which('eeglab.m'));
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab; % start EEGLAB
pop_editoptions( 'option_storedisk', 0); % Change option to process multiple datasets
% load data
EEG = pop_readegi('C:\Users\chuch\Documents\MEGAsync\learning\CCS\2a\prj\data\preprocessing\naseem_AXCPT.raw', [],[],'auto');
EEG.setname='HTA_naseem';
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
% The old method changed the urevent which contains the index of the event
% in the original (= wurh) urevent table, this supposed to remain unchanged.
% This method is from: https://eeglab.org/tutorials/11_Scripting/Event_Processing_command_line.html#scripts-for-creating-or-modifying-events
nevents = length(EEG.event);
iTrial = 0; % index for trial number
for index = 1 : nevents
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
EEG = pop_saveset( EEG, 'filename','testsubj2.set','filepath','C:\\Users\\chuch\\Downloads\\');
eeglab redraw % Redraw the main EEGLAB window