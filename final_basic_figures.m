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

    ll1 = -n_trials * log(1 / n_options); k1 = 0;
    was_rewarded = outcomes > 0;
    pred_choices = nan(n_trials, 1);
    pred_choices(1) = randi(n_options);
    for t = 2:n_trials
        if was_rewarded(t-1)
            pred_choices(t) = choices(t-1);
        else
            opts = setdiff(1:n_options, choices(t-1));
            pred_choices(t) = opts(randi(length(opts)));
        end
    end
    ll2 = sum(log(0.5 + 0.5 * (pred_choices == choices))); k2 = 0;
    negloglik = @(params) qlearn_loglik(params, choices, outcomes);
    [~, nll3] = fmincon(negloglik, [0.2, 2.0], [], [], [], [], [0.01, 0.01], [1, 20]);
    ll3 = -nll3; k3 = 2;

    lls = [ll1, ll2, ll3];
    aic = [2*k1 - 2*ll1, 2*k2 - 2*ll2, 2*k3 - 2*ll3];
    bic = [k1*log(n_trials) - 2*ll1, k2*log(n_trials) - 2*ll2, k3*log(n_trials) - 2*ll3];
end

%% === TKLL PARSE + FIT ===
boom_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Boom/';
sparkles_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Sparkles/';
monkey_paths = {boom_path, sparkles_path};
monkey_files = {
    dir(fullfile(boom_path, 'Experiment-Boom_Train-*.mat')), ...
    dir(fullfile(sparkles_path, 'Experiment-Sparkles-*.mat'))};

all_choices = [];
all_outcomes = [];

for m = 1:2
    files = monkey_files{m};
    path = monkey_paths{m};
    for f = 1:length(files)
        try
            load(fullfile(path, files(f).name)); BHV = data;
            goodtrials = find(BHV.TrialError == 0);
            if length(goodtrials) > 1080, goodtrials = goodtrials(1:1080); end
            for t = 1:length(goodtrials)
                trial = goodtrials(t);
                if size(BHV.CodeNumbers{1,trial},1) >= 12
                    ch = BHV.CodeNumbers{1,trial}(11,1);
                    out = BHV.CodeNumbers{1,trial}(12,1);
                    if ismember(ch, 1:1000)
                        all_choices(end+1) = ch;
                        if out == 600
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

choices = all_choices(:); outcomes = all_outcomes(:);
valid = ismember(choices, 1:1000) & ~isnan(outcomes);
choices = choices(valid); outcomes = outcomes(valid);
cue_map = containers.Map(unique(choices), 1:length(unique(choices)));
choices = arrayfun(@(x) cue_map(x), choices);
[tkll_lls, tkll_aic, tkll_bic] = fit_models(choices, outcomes);

colors_tkll = [0.2 0.4 0.8];
colors_tkd  = [0.8 0.2 0.2];

% === TKLL FIGURE ===
figure('Color','w','Position',[100 100 900 300]);
subplot(1,3,1); bar(tkll_lls, 'FaceColor', colors_tkll); title('Log-Likelihood'); ylabel('LL');
xticklabels(model_labels); xtickangle(30); set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);
subplot(1,3,2); bar(tkll_aic, 'FaceColor', colors_tkll); title('AIC'); ylabel('AIC');
xticklabels(model_labels); xtickangle(30); set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);
subplot(1,3,3); bar(tkll_bic, 'FaceColor', colors_tkll); title('BIC'); ylabel('BIC');
xticklabels(model_labels); xtickangle(30); set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);

if include_titles
    sgtitle('Model Comparison — Loss-Only Task', 'FontSize', fontsize+2, 'FontWeight','bold');
    exportgraphics(gcf, fullfile(fig_save_dir, 'Model_Comparison_LossOnly_WithTitle.png'), 'Resolution', 300);
else
    exportgraphics(gcf, fullfile(fig_save_dir, 'Model_Comparison_LossOnly_NoTitle.png'), 'Resolution', 300);
end

%% === TKD LOAD + FIT ===
load('data_filtered.mat');
tkd_data = sortrows(data_filtered, 'TrialID');
tkd_choices = tkd_data.("choice no side");
tkd_outcomes = tkd_data.change_in_tokens;
[tkd_lls, tkd_aic, tkd_bic] = fit_models(tkd_choices, tkd_outcomes);

% === TKD FIGURE ===
figure('Color','w','Position',[100 100 900 300]);
subplot(1,3,1); bar(tkd_lls, 'FaceColor', colors_tkd); title('Log-Likelihood'); ylabel('LL');
xticklabels(model_labels); xtickangle(30); set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);
subplot(1,3,2); bar(tkd_aic, 'FaceColor', colors_tkd); title('AIC'); ylabel('AIC');
xticklabels(model_labels); xtickangle(30); set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);
subplot(1,3,3); bar(tkd_bic, 'FaceColor', colors_tkd); title('BIC'); ylabel('BIC');
xticklabels(model_labels); xtickangle(30); set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);

if include_titles
    sgtitle('Model Comparison — Reward Task', 'FontSize', fontsize+2, 'FontWeight','bold');
    exportgraphics(gcf, fullfile(fig_save_dir, 'Model_Comparison_Reward_WithTitle.png'), 'Resolution', 300);
else
    exportgraphics(gcf, fullfile(fig_save_dir, 'Model_Comparison_Reward_NoTitle.png'), 'Resolution', 300);
end
