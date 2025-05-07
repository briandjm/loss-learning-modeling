clear; clc; % start fresh

addpath(genpath('/Users/briandjm/Desktop/MATLAB/WangGit_Codes_MATLAB'))
addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/functions')
addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/josephine_analysis/oldfunctions')
savepath

% Set figure save path
fig_save_dir = fullfile(pwd, 'nicefigs');
if ~exist(fig_save_dir, 'dir')
    mkdir(fig_save_dir);
end
%% 1. Load Data
load('data_filtered.mat');

data = sortrows(data_filtered, 'TrialID');
choices = data.("choice no side");
outcomes = data.change_in_tokens;
n_trials = length(choices);

fprintf('Loaded %d trials.\n', n_trials);

%% 2. Model 1: Random (coin flip)
ll_m1 = -n_trials * log(0.5);  % no params
k1 = 0;  % number of free params

%% 3. Model 2: WSLS (deterministic)
was_rewarded = outcomes > 0;
pred_choices = nan(n_trials, 1);
pred_choices(1) = randi([1 4]);

for t = 2:n_trials
    if was_rewarded(t-1)
        pred_choices(t) = choices(t-1);
    else
        options = setdiff(1:4, choices(t-1));
        pred_choices(t) = options(randi(length(options)));
    end
end

ll_m2 = sum(log(0.5 + 0.5*(pred_choices == choices)));  % pseudo likelihood
k2 = 0;

%% 4. Model 3: Q-learning
negloglik = @(params) qlearn_loglik(params, choices, outcomes);
init_params = [0.2, 2.0];
lb = [0.01, 0.01]; ub = [1, 20];

[opt_params, nll_m3] = fmincon(negloglik, init_params, [], [], [], [], lb, ub);
ll_m3 = -nll_m3;
k3 = 2;

%% 5. AIC + BIC
aic = [2*k1 - 2*ll_m1, 2*k2 - 2*ll_m2, 2*k3 - 2*ll_m3];
bic = [k1*log(n_trials) - 2*ll_m1, k2*log(n_trials) - 2*ll_m2, k3*log(n_trials) - 2*ll_m3];
lls = [ll_m1, ll_m2, ll_m3];

%% 6. Plot Comparison
model_labels = {'Random', 'WSLS', 'Q-Learning'};

figure('Color','w','Name','Model Comparison','Position',[100 100 800 300]);

subplot(1,3,1)
bar(lls); title('Log-Likelihood');
ylabel('LL'); xticklabels(model_labels); xtickangle(30);

subplot(1,3,2)
bar(aic); title('AIC');
ylabel('AIC'); xticklabels(model_labels); xtickangle(30);

subplot(1,3,3)
bar(bic); title('BIC');
ylabel('BIC'); xticklabels(model_labels); xtickangle(30);
saveas(gcf, fullfile(fig_save_dir, 'BICAICtest.png'));