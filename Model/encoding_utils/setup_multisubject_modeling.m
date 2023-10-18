function [alleeg,allstim,sub_tag] = setup_multisubject_modeling(all_sbj_eegs,stim)
% Setup the stimulus and eeg structures for multisubject modeling by
% transforming data cell arrays into row arrays that are # subjects x #
% trials long. This makes it easier for the mTRF code to fit to data from
% multiple subjects simultaneously.
% Inputs:
% - all_sbj_eegs = cell array of structures containing EEG data for each
% subject (see the CND data format)
% - stim = cell array of stimuli for each trial
% Outputs:
% - alleeg = rearranged eeg cell arrays into a row (length: # subjects x #
% trials)
% - allstim = cell array of stimuli so that each cell of allenv is paired
% with a cell of alleeg
% - sub_tag = numerical array that is the same length as alleeg and allenv,
% with labels for which cell corresponds to which subject (labels from 1 to
% # subjects). The cells corresponding to a specific subject can then be
% identified by using find(sub_tag==s) for subject s (see
% MultiSubjectEncoding.m for an example)
% Nate Zuk (2021)

% Create the new alleeg structure, and concatenate the data into a 2-D cell
% array that's # trials x # subjects
alleeg.data = {};
nSubs = length(all_sbj_eegs);
for n = 1:nSubs
    alleeg.data = [alleeg.data; all_sbj_eegs{n}.data];
end
% Save the sampling rate (assumed the same for all subjects)
alleeg.fs = all_sbj_eegs{1,1}.fs;
% Repeat the stimulus data for each subject (when we fit the model, each
% subject x trial will be treated as a separate trial in the multi-subject
% data set) 

% ntrials = size(stim,2); % This is for one stim
ntrials = size(stim{1},2); % This is for n stim
alleeg.data = reshape(alleeg.data',[1 nSubs*ntrials]);
% 1= single stim 2=different stim for each subject

% 1
% allstim = repmat(stim,1,nSubs);

% 2
allstim.data = {};
for n = 1:nSubs
    allstim.data= [allstim.data, stim{n}];
end
allstim=allstim.data;


% Create a subject index array, for selecting specific subject data
sub_tag = repelem((1:nSubs),1,ntrials);