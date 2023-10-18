 % CNSP workshop tutorial - Multi-subject (generic model) encoding
% This script describes the series of steps to:
% 0) Load the EEG and stimulus envelope data using the
% CND format
% 1) Fit an multi-subject encoding (or forward) model using the mTRF-Toolbox
% 2) Estimate a null distribution for determining the effect size of
% reconstruction accuracy on a left-out subject
% * Note: You will need to make a folder named 'MultiSubTRFs' in the same
% directory as the dataCND folder in order for the results to be saved.
% * To compare the prediction accuracies of the multi-subject (generic)
% model with the single-subject models, run the script
% CmpMultiIndivModels.m

clear;clc;
close all

addpath ../libs/cnsp_utils
addpath ../libs/cnsp_utils/cnd
addpath ../libs/mTRF-Toolbox_v2/mtrf
addpath encoding_utils/

% Directory names
condition = 't46_11n_WF/'; % t50_n_WordFreq t49_p_WordFreq t43_p_AE t44_n_AE
dataMainFolder = '../datasets/EbrahimpourMultimedia/';
dataCNDSubfolder = ['dataCND/',condition];
msubtrfFolder = ['MultiSubTRFs/',condition];

% Use an individual subject for testing
nSubs = length(dir([dataMainFolder dataCNDSubfolder 'dataStim*.mat']));
ntrials = 10; % restrict the number of trials (generic models can be used with less data)
niter = 100; % number of iterations to compute the null distribution

%% Load data

dataStim_files = dir([dataMainFolder dataCNDSubfolder 'dataStim*']);
dataSub_files = dir([dataMainFolder dataCNDSubfolder 'dataSub*']);

nan_subs =[];
all_sbj_eegs = cell(nSubs,1);
for sub = 1:nSubs % iterate over subjects
    
    % Loading Stim data
    stimFilename = [dataStim_files(sub).folder,'\',dataStim_files(sub).name];
    fprintf('Loading stimulus data: %s ', dataStim_files(sub).name);
    
    load(stimFilename,'stim')
    
    env = stim.data(1,:);
    % restrict the number of trials
    env = env(1:ntrials);
    % add to the all-subject Stim structure
    all_sbj_stim{sub} = env;
    
    % Loading preprocessed EEG
    preproc_eeg_fl = dataSub_files(sub).name; % preprocessed EEG filename
    eegPreFilename = [dataSub_files(sub).folder,'\',dataSub_files(sub).name];
    disp(['Loading preprocessed EEG data: ' preproc_eeg_fl])
    load(eegPreFilename,'eeg')
    % restrict the number of trials
    eeg.data = eeg.data(1:ntrials);
    % add to the all-subject EEG structure
    all_sbj_eegs{sub} = eeg;
end
% Setup the envelopes and EEG for multi-subject modeling
disp('Preparing the data for multi-subject modeling...');
% 1 stim
% [alleeg,env,sub_tag] = setup_multisubject_modeling(all_sbj_eegs,env); 
% n stim
[alleeg,env,sub_tag] = setup_multisubject_modeling(all_sbj_eegs,all_sbj_stim);
% get the number of channels
% nchan = length(eeg.chanlocs);
nchan = 29;

%% Truncation and normalization
% Truncate the trial lengths so that, in each trial, the EEG and envelope
% are the same length
disp('Truncating EEG and stimulus so they are the same length...');
for tr = 1:length(env)
    envLen = size(env{tr},1);
    eegLen = size(alleeg.data{tr},1);
    minLen = min(envLen,eegLen);
    env{tr} = double(env{tr}(1:minLen,:));
    alleeg.data{tr} = double(alleeg.data{tr}(1:minLen,:));
end

% % Filter the envelope above 1 Hz
% disp('Filtering the envelope...');
% hd = getHPFilt(eeg.fs,1);
% % Filtering stim data
% env = cellfun(@(x) filtfilthd(hd,x),env,'UniformOutput',false);
% 
% % Filter the envelope below 10 Hz
% disp('Filtering the envelope...');
% ld = getHPFilt(eeg.fs,10);
% % Filtering stim data
% env = cellfun(@(x) filtfilthd(ld,x),env,'UniformOutput',false);

clear eeg stim all_sbj_eegs

% Normalising EEG data by subject
clear tmpEnv tmpEeg
disp('Normalizing the eeg data...');
for sub = 1:nSubs
    % get the trials for a particular subject
    sub_idx = find(sub_tag==sub);
    % concatenate the data together for this subject
    tmpEnv = env{sub_idx(1)};
    tmpEeg = alleeg.data{sub_idx(1)};
    for tr = 2:length(sub_idx) % getting all values
        tmpEnv = cat(1,tmpEnv,env{sub_idx(tr)});
        tmpEeg = cat(1,tmpEeg,alleeg.data{sub_idx(tr)});
    end
    normFactorEnv = std(tmpEnv(:)); clear tmpEnv;
    normFactorEeg = std(tmpEeg(:)); clear tmpEeg;
    for tr = 1:length(sub_idx) % normalisation
        env{sub_idx(tr)} = env{sub_idx(tr)}/normFactorEnv;
        alleeg.data{sub_idx(tr)} = alleeg.data{sub_idx(tr)}/normFactorEeg;
    end
end

%% Model setup
% TRF hyperparameters
tmin = -200;
tmax = 1000;
lambdas = 10.^(-7:0.5:7);
dirTRF = 1; % Forward TRF model

% Use leave-one-out to get testing accuracies
disp('Leave-one-subject-out testing...');
model = cell(nSubs,1);
test_r = NaN(ntrials,nchan,nSubs);
nullr = NaN(niter,nchan,nSubs);
dpr = NaN(nSubs,nchan);
for sub = 1:nSubs
    %% mTRFcrossval and mTRFtrain on all subjects with one left out
%     sound(sin(1:600));
    fprintf('** Leaving out subject %d\n',sub);
    % Get the testing trials (the trials for the particular subject)
    test_trials = find(sub_tag==sub);
    % The rest are training trials
    train_trials = setxor(1:length(env),test_trials);
    
    % TRF - Compute model weights
    disp('Running mTRFcrossval')
    [stats_cv,t] = mTRFcrossval(env(train_trials),alleeg.data(train_trials),alleeg.fs,...
        dirTRF,tmin,tmax,lambdas,'verbose',0,'fast',1);
    % average r across channels and trial to find the optimal lambda value
    [maxR,bestLambda] = max(squeeze(mean(mean(stats_cv.r,1,'omitnan'),3)));
    fprintf('Best r = %.3f\n',maxR);
    if isnan(maxR)
        nan_subs = [nan_subs, sub];
    end
    disp('Running mTRFtrain')
    model{sub} = mTRFtrain(env(train_trials),alleeg.data(train_trials),alleeg.fs,...
        dirTRF,tmin,tmax,lambdas(bestLambda),'verbose',0);
    
    %% mTRFpredict on left-out subject
    % Testing on left-out trial
    [pred,stats] = mTRFpredict(env(test_trials),alleeg.data(test_trials),model{sub});
    test_r(:,:,sub) = stats.r;
    
    % Compute the null distribution for this subjecg
    nullr(:,:,sub) = compute_null_predacc(pred,alleeg.data(test_trials),tmin,tmax,alleeg.fs,...
        'circshift',niter);
end
fprintf('\n');

% See just one TRF
% plot(linspace(-200,1000,301),model{4}.w(:,:,21))

% Save the multisubject models
save([dataMainFolder msubtrfFolder 'MultiSubTRF'],'model','test_r','nullr',...
    'nSubs','ntrials','tmin','tmax');
% %% Plotting
% % Plot the TRF fit to the training trials
% chan_to_plot = [21]; % this corresponds to Fz in the Natural Speech dataset
% figure
% hold on
% for sub = 1:nSubs
%     plot(model{sub}.t,squeeze(model{sub}.w(:,:,chan_to_plot)),'k','LineWidth',2);
% end
% set(gca,'FontSize',14);
% xlabel('Delay (ms)');
% ylabel('Model weight');
% tle = sprintf('Subject %d, channel %s',sub,strjoin(string(chan_to_plot),', '));
% title(tle);
disp("Nan subjects are: ");
nan_subs
sound(sin(1:6000)) 