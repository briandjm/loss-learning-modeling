%% fit model and make model comparison figure for both tasks

clear; clc;

%% === SETTINGS ===
include_titles = false;  % <<<< Toggle this: true = paper version, false = poster version

%% === PATH SETUP ===
addpath(genpath('/Users/briandjm/Desktop/MATLAB/WangGit_Codes_MATLAB'))
addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/functions')
savepath

fig_save_dir = fullfile(pwd, 'nicefigs');
if ~exist(fig_save_dir, 'dir'); mkdir(fig_save_dir); end

model_labels = {'Random', 'WSLS', 'Q-Learning'};
fontsize = 13;


% shove this into my skull please
%% === FUNCTION TO FIT 3 MODELS AND RETURN METRICS ===
function [lls, aic, bic] = fit_models(choices, outcomes)
    valid = ismember(choices, 1:1000) & ~isnan(outcomes); 
    choices = choices(valid);
    outcomes = outcomes(valid);
    n_trials = length(choices);
    if n_trials == 0
        error('No valid trials!');
    end
    unique_choices = unique(choices);
    n_options = length(unique_choices); 
    cue_map = containers.Map(unique_choices, 1:n_options);
    choices = arrayfun(@(x) cue_map(x), choices);

    %% === Model 1: Random Choice ===
    ll1 = n_trials * log(1 / n_options);  % <- LL is negative, correctly scaled to number of options
    k1 = 0;

    %% === Model 2: Soft WSLS ===
    [~, nll2] = fmincon(@(eps) wsls_loglik(eps, choices, outcomes), 0.1, [], [], [], [], 0.001, 0.999);
    ll2 = -nll2;
    k2 = 1;

    %% === Model 3: Q-Learning ===
    negloglik = @(params) qlearn_loglik(params, choices, outcomes);
    [~, nll3] = fmincon(negloglik, [0.2, 2.0], [], [], [], [], [0.01, 0.01], [1, 20]);
    ll3 = -nll3;
    k3 = 2;

    %% === Output Metrics ===
    lls = [ll1, ll2, ll3];
    aic = [2*k1 - 2*ll1, 2*k2 - 2*ll2, 2*k3 - 2*ll3];
    bic = [k1*log(n_trials) - 2*ll1, k2*log(n_trials) - 2*ll2, k3*log(n_trials) - 2*ll3];
end

% lower AIC/BIC = better model
%% === TKLL PARSE + FIT ===
boom_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Boom/';
sparkles_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Sparkles/';
monkey_paths = {boom_path, sparkles_path};
monkey_files = {
    dir(fullfile(boom_path, 'Experiment-Boom_Train-*.mat')), ...
    dir(fullfile(sparkles_path, 'Experiment-Sparkles-*.mat'))}; % define file location and grab each .mat file

all_choices = []; % collect all choices and outcomes in these two vectors
all_outcomes = [];

for m = 1:2 % loop over both monkeys and each session file
    files = monkey_files{m};
    path = monkey_paths{m};
    for f = 1:length(files)
        try
            load(fullfile(path, files(f).name)); BHV = data; % load the .mat file
            goodtrials = find(BHV.TrialError == 0);
            if length(goodtrials) > 1080, goodtrials = goodtrials(1:1080); end % cap 1080 to standardize
            for t = 1:length(goodtrials)
                trial = goodtrials(t);
                if size(BHV.CodeNumbers{1,trial},1) >= 12
                    ch = BHV.CodeNumbers{1,trial}(11,1); % which cue the monkey chose
                    out = BHV.CodeNumbers{1,trial}(12,1); % numeric code for outcome
                    if ismember(ch, 1:1000)
                        all_choices(end+1) = ch;
                        if out == 600 % assign reward values based on event codes, everything else NaN
                            all_outcomes(end+1) = 1;
                        elseif out == 599
                            all_outcomes(end+1) = -1;
                        elseif out == 597
                            all_outcomes(end+1) = -3;
                        else
                            all_outcomes(end+1) = NaN;
                        end
                    end
                end
            end
        catch
            fprintf('Skipping file: %s\n', files(f).name);
        end
    end
end
% data cleanup
choices = all_choices(:); outcomes = all_outcomes(:); % now that i aggregated across sessions, filter again
valid = ismember(choices, 1:1000) & ~isnan(outcomes); % filter for valid trials, flatten into column vectors
choices = choices(valid); outcomes = outcomes(valid);
cue_map = containers.Map(unique(choices), 1:length(unique(choices))); % remaps cue codes (301) to 1:N system for modeling
choices = arrayfun(@(x) cue_map(x), choices);
[tkll_lls, tkll_aic, tkll_bic] = fit_models(choices, outcomes); % run fit_models function, return LL AIC BIC for 3 models

%% === FIGURE SETTINGS ===
colors_tkd = [0.8 0.4 0.4];   % soft red
colors_tkll = [0.4 0.6 0.8];  % soft blue
fontsize = 18;

%% === TKLL FIGURE — LOSS-ONLY TASK ===
figure('Color','w','Position',[100 100 900 300]);

subplot(1,3,1); 
bar(tkll_lls, 'FaceColor', colors_tkll); 
title('-Log-Likelihood');
xticklabels(model_labels); xtickangle(30); 
set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);

ax = gca;
ax.YAxis.Exponent = 0;  % removes scientific notation altogether
ax.XRuler.TickLabelGapOffset = -4;  % nudges exponent down to avoid title clash

subplot(1,3,2); 
bar(tkll_aic, 'FaceColor', colors_tkll); 
title('AIC');
xticklabels(model_labels); xtickangle(30); 
set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);

subplot(1,3,3); 
bar(tkll_bic, 'FaceColor', colors_tkll); 
title('BIC');
xticklabels(model_labels); xtickangle(30); 
set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);

if include_titles
    sgtitle('Model Comparison — Loss-Only Task', 'FontSize', fontsize+2, 'FontWeight','bold');
    exportgraphics(gcf, fullfile(fig_save_dir, 'Model_Comparison_LossOnly_WithTitle.png'), 'Resolution', 300);
else
    exportgraphics(gcf, fullfile(fig_save_dir, 'Model_Comparison_LossOnly_NoTitle.png'), 'Resolution', 300);
end

%% === TKD LOAD + FIT ===
load('data_filtered.mat');
tkd_data = sortrows(data_filtered, 'TrialID'); % sort trials in adcending order by TrialID
tkd_choices = tkd_data.("choice no side"); % what option monkey chose on each trial
tkd_outcomes = tkd_data.change_in_tokens; % how many tokens they gained or lost after choice
[tkd_lls, tkd_aic, tkd_bic] = fit_models(tkd_choices, tkd_outcomes); % call my fit_models function, fit all 3 models,

%% === TKD FIGURE — GAIN/LOSS TASK ===
figure('Color','w','Position',[100 100 900 300]);

subplot(1,3,1); 
bar(tkd_lls, 'FaceColor', colors_tkd); 
title('–Log-Likelihood');  % <<<<<<<< and here
xticklabels(model_labels); xtickangle(30); 
set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);
ax = gca;
ax.YAxis.Exponent = 0;  
ax.XRuler.TickLabelGapOffset = -4;

subplot(1,3,2); 
bar(tkd_aic, 'FaceColor', colors_tkd); 
title('AIC');
xticklabels(model_labels); xtickangle(30); 
set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);

subplot(1,3,3); 
bar(tkd_bic, 'FaceColor', colors_tkd); 
title('BIC');
xticklabels(model_labels); xtickangle(30); 
set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);

if include_titles
    sgtitle('Model Comparison — Gain/Loss Task', 'FontSize', fontsize+2, 'FontWeight','bold');
    exportgraphics(gcf, fullfile(fig_save_dir, 'Model_Comparison_Reward_WithTitle.png'), 'Resolution', 300);
else
    exportgraphics(gcf, fullfile(fig_save_dir, 'Model_Comparison_Reward_NoTitle.png'), 'Resolution', 300);
end