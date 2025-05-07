clear; clc;

addpath(genpath('/Users/briandjm/Desktop/MATLAB/WangGit_Codes_MATLAB'))
addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/functions')
addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/josephine_analysis/oldfunctions')
savepath

load('data_filtered.mat');

% Optional: create save dir
fig_save_dir = fullfile(pwd, 'nicefigs');
if ~exist(fig_save_dir, 'dir')
    mkdir(fig_save_dir);
end

% Unique sessions
session_ids = unique(data_filtered.sessionID);
n_sessions = length(session_ids);

% Init storage
alphas = nan(n_sessions,1);
betas  = nan(n_sessions,1);
lls    = nan(n_sessions,1);
aics   = nan(n_sessions,1);
bics   = nan(n_sessions,1);

% Loop through each session
for s = 1:n_sessions
    sid = session_ids(s);
    session_data = data_filtered(data_filtered.sessionID == sid, :);
    
    choices  = session_data.("choice no side");
    outcomes = session_data.change_in_tokens;
    n_trials = length(choices);
    
    if n_trials < 20
        fprintf('Skipping session %d (too few trials)\n', sid);
        continue
    end
    
    % Fit Q-learning model
    negloglik = @(params) qlearn_loglik(params, choices, outcomes);
    init_params = [0.2, 2.0];
    lb = [0.01, 0.01]; ub = [1, 20];
    
    try
        [opt_params, nll] = fmincon(negloglik, init_params, [], [], [], [], lb, ub);
    catch
        fprintf('Fit failed for session %d\n', sid);
        continue
    end
    
    alphas(s) = opt_params(1);
    betas(s)  = opt_params(2);
    lls(s)    = -nll;
    
    k = 2;  % num params
    aics(s) = 2*k - 2*lls(s);
    bics(s) = k*log(n_trials) - 2*lls(s);
end

%% Plotting parameter distributions
figure('Name','Q-learning Parameters','Color','w','Position',[100 100 800 300]);

subplot(1,2,1)
boxplot(alphas, 'Notch','on');
ylabel('Alpha (learning rate)');
title('Distribution of \alpha');

subplot(1,2,2)
boxplot(betas, 'Notch','on');
ylabel('Beta (inverse temperature)');
title('Distribution of \beta');

saveas(gcf, fullfile(fig_save_dir, 'QLearn_Param_Boxplots.png'));

%% Summary comparison
fprintf('\nAvg alpha: %.3f ± %.3f\n', nanmean(alphas), nanstd(alphas));
fprintf('Avg beta : %.3f ± %.3f\n', nanmean(betas),  nanstd(betas));
fprintf('Avg LL   : %.1f\n', nanmean(lls));
fprintf('Avg AIC  : %.1f\n', nanmean(aics));
fprintf('Avg BIC  : %.1f\n', nanmean(bics));
