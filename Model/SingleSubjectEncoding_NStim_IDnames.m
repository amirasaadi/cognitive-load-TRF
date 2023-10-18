% CNSP workshop tutorial - Encoding
% This script describes the series of steps to:
% 0) Load the EEG and stimulus envelope using the CND format
% 1) Fit an encoding (or forward) model using the mTRF-Toolbox
% 2) Test the model on left-out data
% 3) Estimate a null distribution for determining the effect size of
% reconstruction accuracy
% * This script should be run on each subject separately. You can change
% the subject being analyzed by editing the value in the 'sub' variable below.
% * Note: You will need to make a folder named 'TRFs' in the same directory
% containing the dataCND folder in order for the results to be saved
% * Run this on each subject, then the data for all subjects together can
% be plotted using 'PlotAllTRFs_byacc.m'

clc;
clear;
close all;
% rng(0);

addpath ../libs/cnsp_utils
addpath ../libs/cnsp_utils/cnd
addpath ../libs/mTRF-Toolbox_v2/mtrf
addpath encoding_utils/

% Parameters
condition  = 't49_p_WF/';
mkdir(['../datasets/EbrahimpourMultimedia/MultiSubTRFs/',condition]);
mkdir(['../datasets/EbrahimpourMultimedia/TRFs/',condition]);
mkdir(['../datasets/EbrahimpourMultimedia/TRFs_LOO/',condition]);

dataCNDSubfolder = ['dataCND/',condition];
trfsSubfolder = ['TRFs/',condition];
dataMainFolder = '../datasets/EbrahimpourMultimedia/';


nSub = length(dir([dataMainFolder dataCNDSubfolder 'dataStim*.mat']));
verbose_flag = 0;
NaN_sub = [];

dataStim_files = dir([dataMainFolder dataCNDSubfolder 'dataStim*']);
dataSub_files = dir([dataMainFolder dataCNDSubfolder 'dataSub*']);

for sub = 1 :nSub
    niter = 100; % number of iterations to compute the null distribution

    %% Load data

    % Loading Stim data
    stimFilename = [dataStim_files(sub).folder,'\',dataStim_files(sub).name];
    fprintf('Loading stimulus data: %s\n', dataStim_files(sub).name);
    load(stimFilename, 'stim');

    n_trial = size(stim.data, 2);

    % Loading preprocessed EEG
    preproc_eeg_fl = dataSub_files(sub).name; % preprocessed EEG filename
    eegPreFilename = [dataSub_files(sub).folder,'\',dataSub_files(sub).name];
    disp(['Loading preprocessed EEG data: ', num2str(preproc_eeg_fl)])
    load(eegPreFilename, 'eeg')

    % Making sure that stim and neural data have the same length
    env = stim.data(1, :);
    if eeg.fs ~= stim.fs
        disp('Error: EEG and STIM have different sampling frequency')
        return
    end
    if length(eeg.data) ~= length(env)
        disp('Error: EEG.data and STIM.data have different number of trials')
        return
    end

    for tr = 1:length(env)
        envLen = size(env{tr}, 1);
        eegLen = size(eeg.data{tr}, 1);
        minLen = min(envLen, eegLen);
        env{tr} = double(env{tr}(1:minLen, :));
        eeg.data{tr} = double(eeg.data{tr}(1:minLen, :));
    end

    % Normalising EEG data and envelope
    clear tmpEnv tmpEeg
    tmpEnv = env{1};
    tmpEeg = eeg.data{1};
    for tr = 2:length(env) % getting all values
        tmpEnv = cat(1, tmpEnv, env{tr});
        tmpEeg = cat(1, tmpEeg, eeg.data{tr});
    end
    normFactorEnv = std(tmpEnv(:));
    clear tmpEnv;
    normFactorEeg = std(tmpEeg(:));
    clear tmpEeg;
    for tr = 1:length(env) % normalisation
        env{tr} = env{tr} / normFactorEnv;
        eeg.data{tr} = eeg.data{tr} / normFactorEeg;
    end

    %% Model Setup
    
    % get the number of channels
    % In random mode
    % training_trials =  randsample(1:n_trial,ceil(train_test_split_ratio*n_trial));
    training_trials = [1,3,4,5,6,7,8,10];

    % TRF hyperparameters
    tmin = -200;
    tmax = 1000;
    % lambdas = [0,1e-6,1e-4,1e-2,1e0,1e2,1e4,1e6];
    lambdas = 10.^(-7:0.5:7);
    dirTRF = 1; % Forward TRF model

    %% mTRFcrossval to identify optimal lambda
    % TRF - Compute model weights
    disp('Running mTRFcrossval')
    [stats_cv, t] = mTRFcrossval(env(training_trials), eeg.data(training_trials), eeg.fs, dirTRF, ...
        tmin, tmax, lambdas, 'verbose', verbose_flag);
    % average r across channels
    [maxR, bestLambda] = max(squeeze(mean(mean(stats_cv.r, 1,'omitnan'), 3)));
    
    % mTRFplotTuningCurve(stats_cv,lambdas,dirTRF);
    
    fprintf('Best r = %.3f\n', maxR);
    if isnan(maxR)
        NaN_sub = [NaN_sub,sub];
    end
    % If optimizing based on the minimum mean-squared error (MSE) instead...
    % [minMSE,bestLambda] = min(squeeze(mean(mean(stats.err,1),3)));
    % fprintf('Best mse = %.3f\n',minMSE);

    %% Train model with mTRFtrain
    disp('Running mTRFtrain')
    model = mTRFtrain(env(training_trials), eeg.data(training_trials), eeg.fs, dirTRF, ...
        tmin, tmax, lambdas(bestLambda), 'verbose', verbose_flag);

    test_trials = [2, 9];

    % Get the testing trials
    disp('Running mTRFpredict');
    [pred, stats] = mTRFpredict(env(test_trials), eeg.data(test_trials), model);
    
    % pred = actual model predictions for each trial
    % stats = prediction accuracies
    
    %% Compute the null distribution of prediction accuracies
    % Create a null distribution of prediction accuracies by
    % circularly-shifting the envelope
    [nullr, nullerr] = compute_null_predacc(pred, eeg.data(test_trials), tmin, tmax, ...
        eeg.fs, 'circshift', niter);
    

    %% Save the results
    sv_fl = sprintf('FrwdTRF_Sbj_%d.mat', sscanf(dataSub_files(sub).name,'dataSub%d.mat'));
    % If you don't have chan_info go with second save hope you don't have
    % trouble in future

    %% save([dataMainFolder trfsSubfolder sv_fl],'model','bestLambda','lambdas','dirTRF',...

    %%     'training_trials','test_trials','stats','nullr','nullerr','chan_info');

    save([dataMainFolder, trfsSubfolder, sv_fl], 'model', 'bestLambda', 'lambdas', 'dirTRF', ...
        'training_trials', 'test_trials', 'stats', 'nullr', 'nullerr');

end

% %% Plotting
% % Plot the TRF fit to the training trials
% chan_to_plot = [21]; 
% 
% plot_trf(model,chan_to_plot);
% tle = sprintf('Subject %d, channel %s',sub,strjoin(string(chan_to_plot),', '));
% title(tle);
% 
% % Butterfly plot of all channels
% plot_trf(model);
% tle = sprintf('Subject %d',sub);
% title(tle);
% 
% % Plot the r-values and null distribution values and
% % show d-prime, for the specific channel
% plot_true_null(stats.r(:,chan_to_plot),nullr(:,chan_to_plot));
% % calculate the d-prime
% dpr = calculate_dprime(stats.r(:,chan_to_plot),nullr(:,chan_to_plot));
% tle = sprintf('Subject %d, channel %s: d-prime = %.3s',sub,strjoin(string(chan_to_plot),', '),string(mean(dpr)));
% title(tle);
% 
% % Plot the r-values and null distribution values, and show d-prime, after
% % averaging accuracies across channels
% plot_true_null(mean(stats.r,2),mean(nullr,2));
% % calculate the d-prime
% dpr = calculate_dprime(mean(stats.r,2),mean(nullr,2));
% tle = sprintf('Subject %d, avg all channels: d-prime = %.3f',sub,dpr);
% title(tle);
% disp("nan subjects");NaN_sub;
%%
% sound(sin(1:6000))
display("finish");