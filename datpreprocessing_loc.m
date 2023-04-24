% tic
% Set path
% data_path = 'C:\Users\chuch\Documents\GitHub\fyrp\data\';
% cd(data_path);

% Load existing data set provided by eeglab
% EEG = pop_loadset( 'naseem_evt.set', fullfile(data_path, 'LTA\LTA_raw_xlsx\Naseem'));
% EEG = pop_loadset('filename', 'eeglab_data.set', 'filepath', data_path);
% EEG = eeg_checkset(EEG);

% Load the channle location file
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

% High pass filtering the data at 0.5Hz
EEG = pop_eegfiltnew(EEG, 'locutoff',0.5);
% EEG.setname='LTA_naseem_highpass01';
EEG = eeg_checkset( EEG );
EEG = pop_saveset( EEG, 'filename','naseem_highpass_script.set','filepath',fullfile(data_path, lta_path, 'Naseem/'));

% Notch filtering at 50Hz
EEG = pop_cleanline(EEG, 'bandwidth',2,'chanlist',[1:128] ,'computepower',1,'linefreqs',[50 100] ,'newversion',0,'normSpectrum',0,'p',0.01,'pad',2,'plotfigures',0,'scanforlines',0,'sigtype','Channels','taperbandwidth',2,'tau',100,'verb',1,'winsize',4,'winstep',2);EEG = eeg_checkset( EEG );
EEG = eeg_checkset( EEG );
EEG = pop_saveset( EEG, 'filename','naseem_notch_cleanline.set','filepath',fullfile(data_path, lta_path, 'Naseem/'));

% todo: Doesn't work with eeglab v2023.0, file an upstream issue for this
% Rereference the data to average reference and retain Cz
EEG = pop_reref( EEG, [],'refloc',struct('labels',{'Cz'},'Y',{0},'X',{6.2205e-16},'Z',{10.1588},'sph_theta',{0},'sph_phi',{90},'sph_radius',{10.1588},'theta',{0},'radius',{0},'type',{''},'ref',{'Cz'},'urchan',{132},'datachan',{0}));
EEG = eeg_checkset( EEG );
% Save for rereference
[ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET); % Store dataset
EEG = pop_saveset( EEG, 'filename','naseem_reref_script.set','filepath',fullfile(data_path, lta_path, 'Naseem/'));
% 
% % ICA
% EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1);
% EEG = eeg_checkset( EEG );
% 
% EEG = pop_saveset( EEG, 'filename','naseem_ica.set','filepath',fullfile(data_path, lta_path, 'Naseem/'));
% eeglab redraw % Redraw the main EEGLAB window
% 
% timeElapsed = toc;