function [nullr,nullerr] = compute_null_predacc(pred,orig,tmin,tmax,fs,method,niter)
% Compute a distribution of null prediction accuracies by circularly
% shifting the original data relative to the prediction in each trial
% and/or randomly permuting trials.
% Inputs:
% - pred = cell array of predictions, one per trial
% - orig = cell array of the original data that is being predicted, one
% cell per trial
% - tmin = minimum delay of the model used for computing the prediction
% (in ms, not necessary if doing permute, set to [])
% - tmax = maximum delay of the model (in ms; if doing permute or both, set to [])
% - Fs = sampling rate of the data (in Hz; if doing permute or both, set to [])
% - method = method of getting the null distribution ('circshift',
% 'permute', or 'both'; default: circshift)
% - niter = # of iterations in the null distribution (default: 1000)
% Outputs:
% - nullr = Pearson's r values for each iteration
% - nullerr = mean-squared errors for each iteration
% Nate Zuk (2021)

% Set niter if not specified
if nargin<7 || isempty(niter)
    niter = 1000;
end

% Set method if not specified
if nargin<6 || isempty(method)
    method = 'circshift';
end

nchan = size(orig{1},2); % number of output channels, assumed to be the same for all trials

fprintf('Computing the null distribution of accuracies (%d iterations)\n',niter);
nullcmp_timer = tic; % keep track of how long it takes to run
nullr = NaN(niter,nchan);
nullerr = NaN(niter,nchan);
for n = 1:niter
    % display a . every 10 trials
    if mod(n,100)==0, fprintf('(%d/%d)\n',n,niter); end
    % Circular shifting
    if strcmp(method,'circshift') || strcmp(method,'both')
        % When there is only 1 trial for test
        if length(orig) == 1 && n==1   
            pred = {pred};
        end
        % randomly select a testing trial
        tr_idx = randi(length(pred),1);
        % get the prediction and orig for this trial
        p = pred{tr_idx};
        s = orig{tr_idx};
        % circularly shift the testing trial (min shift is tmax, max shift is
        % length(s)+tmin, where tmin and tmax are the min and max delays of the
        % model)
        shift_range = [ceil(tmax/1000*fs) size(s,1)+floor(tmin/1000*fs)];
        k = randi(shift_range); % randomly select the amount of shift, in indexes
        s = circshift(s,k);
    elseif strcmp(method,'permute') || strcmp(method,'both')
        % randomly select a pair of trials
        pidx = randi(length(pred),1);
        sidx = randi(length(orig),1);
        % get the prediction and orig
        p = pred{pidx};
        s = orig{sidx};
        % make them the same length
        len = min([size(p,1) size(s,1)]);
        p = p(1:len,:); s = s(1:len,:);
    else
        error('Method must be circshift, permute, or both');
    end
    % compute the fit
    for c = 1:nchan, nullr(n,c) = corr(s(:,c),p(:,c)); end
    nullerr(n,:) = mean((p-s).^2);
end
% insert a new line in the command window when this is completed
fprintf('-- Completed @ %.3f s\n',toc(nullcmp_timer));
