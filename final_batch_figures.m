clear; clc;
include_titles = false;  % Set to true for paper figs, false for poster (no sgtitle)

%% PATH SETUP
addpath(genpath('/Users/briandjm/Desktop/MATLAB/WangGit_Codes_MATLAB'))
addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/functions')
savepath

fig_save_dir = fullfile(pwd, 'nicefigs');
if ~exist(fig_save_dir, 'dir'); mkdir(fig_save_dir); end

fontsize = 18;
label_font = 'Helvetica';
linewidth = 2;

%% === 1. TKD BATCH FITTING ===
load('data_filtered.mat');
session_ids = unique(data_filtered.sessionID);
n_sessions = length(session_ids);

tkd_alphas = nan(n_sessions,1);
tkd_betas  = nan(n_sessions,1);
tkd_lls    = nan(n_sessions,1);
tkd_aics   = nan(n_sessions,1);
tkd_bics   = nan(n_sessions,1);

for s = 1:n_sessions
    sid = session_ids(s);
    session_data = data_filtered(data_filtered.sessionID == sid, :);
    
    choices  = session_data.("choice no side");
    outcomes = session_data.change_in_tokens;
    n_trials = length(choices);
    
    if n_trials < 20
        fprintf('Skipping TkD session %d (too few trials)\n', sid);
        continue
    end
    
    negloglik = @(params) qlearn_loglik(params, choices, outcomes);
    try
        [opt_params, nll] = fmincon(negloglik, [0.2, 2.0], [], [], [], [], [0.01, 0.01], [1, 20]);
        tkd_alphas(s) = opt_params(1);
        tkd_betas(s)  = opt_params(2);
        tkd_lls(s)    = -nll;
        k = 2;
        tkd_aics(s)   = 2*k - 2*tkd_lls(s);
        tkd_bics(s)   = k*log(n_trials) - 2*tkd_lls(s);
    catch
        fprintf('TkD fit failed for session %d\n', sid);
        continue
    end
end

%% === 2. TKLL BATCH FITTING ===
boom_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Boom/';
sparkles_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Sparkles/';
monkey_paths = {boom_path, sparkles_path};
monkey_files = {
    dir(fullfile(boom_path, 'Experiment-Boom_Train-*.mat')), ...
    dir(fullfile(sparkles_path, 'Experiment-Sparkles-*.mat'))};

tkll_alphas = [];
tkll_betas  = [];
tkll_lls    = [];
tkll_aics   = [];
tkll_bics   = [];

for m = 1:2
    files = monkey_files{m};
    folder = monkey_paths{m};
    for f = 1:length(files)
        try
            load(fullfile(folder, files(f).name));
            BHV = data;

            goodtrials = find(BHV.TrialError == 0);
            if length(goodtrials) > 1080
                goodtrials = goodtrials(1:1080);
            end

            choices = nan(length(goodtrials), 1);
            outcomes = nan(length(goodtrials), 1);
            for t = 1:length(goodtrials)
                codes = BHV.CodeNumbers{1, goodtrials(t)};
                choices(t)  = codes(11);
                code = codes(12);
                if code == 600
                    outcomes(t) = 1;
                elseif code == 599
                    outcomes(t) = -1;
                elseif code == 597
                    outcomes(t) = -3;
                else
                    outcomes(t) = NaN;
                end
            end

            valid = ~isnan(outcomes);
            choices = choices(valid); outcomes = outcomes(valid);
            uq = unique(choices);
            map = containers.Map(uq, 1:length(uq));
            choices = arrayfun(@(x) map(x), choices);

            if length(choices) < 20, continue; end
            negloglik = @(params) qlearn_loglik(params, choices, outcomes);
            [opt_params, nll] = fmincon(negloglik, [0.2, 2.0], [], [], [], [], [0.01, 0.01], [1, 20]);

            tkll_alphas(end+1,1) = opt_params(1);
            tkll_betas(end+1,1)  = opt_params(2);
            tkll_lls(end+1,1)    = -nll;
            k = 2;
            tkll_aics(end+1,1)   = 2*k - 2*tkll_lls(end);
            tkll_bics(end+1,1)   = k*log(length(choices)) - 2*tkll_lls(end);
        catch ME
            fprintf('Error in %s: %s\n', files(f).name, ME.message);
        end
    end
end

%% === TKD PARAM PLOT ===
fig1 = figure('Name','Reward Task Parameters','Color','w','Position',[100 100 1000 500]);

subplot(1,2,1)
pos = get(gca, 'Position');
pos(2) = pos(2) - 0.05;
set(gca, 'Position', pos);
boxplot(tkd_alphas, 'Colors','r', 'Widths', 0.4);
ylabel('\alpha (Learning Rate)', 'FontSize', fontsize+2, 'FontWeight','bold', 'FontName', label_font);
title('Reward Task Learning Rate (\alpha)', 'FontSize', fontsize+2, 'FontWeight','bold');
set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);
boxes = findobj(gca,'Tag','Box');
for j = 1:length(boxes)
    patch(get(boxes(j),'XData'), get(boxes(j),'YData'), 'r', 'FaceAlpha', 0.1, 'EdgeColor','none');
end
set(findall(gca,'Type','Line'),'LineWidth',linewidth);

subplot(1,2,2)
pos = get(gca, 'Position');
pos(2) = pos(2) - 0.05;
set(gca, 'Position', pos);
boxplot(tkd_betas, 'Colors','r', 'Widths', 0.4);
ylabel('\beta (Inverse Temperature)', 'FontSize', fontsize+2, 'FontWeight','bold', 'FontName', label_font);
title('Reward Task Inverse Temp (\beta)', 'FontSize', fontsize+2, 'FontWeight','bold');
set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);
boxes = findobj(gca,'Tag','Box');
for j = 1:length(boxes)
    patch(get(boxes(j),'XData'), get(boxes(j),'YData'), 'r', 'FaceAlpha', 0.1, 'EdgeColor','none');
end
set(findall(gca,'Type','Line'),'LineWidth',linewidth);

if include_titles
    sgtitle('Q-Learning Parameters — Reward Task', 'FontSize', fontsize+4, 'FontWeight','bold');
    exportgraphics(fig1, fullfile(fig_save_dir, 'RewardTask_Qlearning_Parameters_WithTitle.png'), 'Resolution', 300);
else
    exportgraphics(fig1, fullfile(fig_save_dir, 'RewardTask_Qlearning_Parameters_NoTitle.png'), 'Resolution', 300);
end

%% === TKLL PARAM PLOT ===
fig2 = figure('Name','Loss-Only Task Parameters','Color','w','Position',[100 100 1000 500]);

subplot(1,2,1)
pos = get(gca, 'Position');
pos(2) = pos(2) - 0.05;
set(gca, 'Position', pos);
boxplot(tkll_alphas, 'Colors','b', 'Widths', 0.4);
ylabel('\alpha (Learning Rate)', 'FontSize', fontsize+2, 'FontWeight','bold', 'FontName', label_font);
title('Loss-Only Task Learning Rate (\alpha)', 'FontSize', fontsize+2, 'FontWeight','bold');
set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);
boxes = findobj(gca,'Tag','Box');
for j = 1:length(boxes)
    patch(get(boxes(j),'XData'), get(boxes(j),'YData'), 'b', 'FaceAlpha', 0.1, 'EdgeColor','none');
end
set(findall(gca,'Type','Line'),'LineWidth',linewidth);

subplot(1,2,2)
pos = get(gca, 'Position');
pos(2) = pos(2) - 0.05;
set(gca, 'Position', pos);
boxplot(tkll_betas, 'Colors','b', 'Widths', 0.4);
ylabel('\beta (Inverse Temperature)', 'FontSize', fontsize+2, 'FontWeight','bold', 'FontName', label_font);
title('Loss-Only Task Inverse Temp (\beta)', 'FontSize', fontsize+2, 'FontWeight','bold');
set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);
boxes = findobj(gca,'Tag','Box');
for j = 1:length(boxes)
    patch(get(boxes(j),'XData'), get(boxes(j),'YData'), 'b', 'FaceAlpha', 0.1, 'EdgeColor','none');
end
set(findall(gca,'Type','Line'),'LineWidth',linewidth);

if include_titles
    sgtitle('Q-Learning Parameters — Loss-Only Task', 'FontSize', fontsize+4, 'FontWeight','bold');
    exportgraphics(fig2, fullfile(fig_save_dir, 'LossOnlyTask_Qlearning_Parameters_WithTitle.png'), 'Resolution', 300);
else
    exportgraphics(fig2, fullfile(fig_save_dir, 'LossOnlyTask_Qlearning_Parameters_NoTitle.png'), 'Resolution', 300);
end

%% === OPTIONAL STATS ===
fprintf('\n=== Reward Task Model Summary ===\n');
fprintf('Alpha: %.3f ± %.3f\n', mean(tkd_alphas), std(tkd_alphas));
fprintf('Beta : %.3f ± %.3f\n', mean(tkd_betas),  std(tkd_betas));

fprintf('\n=== Loss-Only Task Model Summary ===\n');
fprintf('Alpha: %.3f ± %.3f\n', mean(tkll_alphas), std(tkll_alphas));
fprintf('Beta : %.3f ± %.3f\n', mean(tkll_betas),  std(tkll_betas));
save('batch_fit_results.mat', ...
     'tkll_alphas', 'tkll_betas', ...
     'tkd_alphas', 'tkd_betas');

%% === 3. GROUP COMPARISON: STATS + PLOTS ===

% Clean NaNs
tkd_alphas_clean  = tkd_alphas(~isnan(tkd_alphas));
tkd_betas_clean   = tkd_betas(~isnan(tkd_betas));
tkll_alphas_clean = tkll_alphas(~isnan(tkll_alphas));
tkll_betas_clean  = tkll_betas(~isnan(tkll_betas));

% Welch's t-tests (handles unequal variances)
[~, p_alpha] = ttest2(tkll_alphas_clean, tkd_alphas_clean);
[~, p_beta]  = ttest2(tkll_betas_clean,  tkd_betas_clean);

% Updated group labels for plotting
group_labels_alpha = [repmat({'Loss-Only'}, length(tkll_alphas_clean), 1); ...
                      repmat({'Reward'},    length(tkd_alphas_clean),  1)];
group_labels_beta  = [repmat({'Loss-Only'}, length(tkll_betas_clean), 1); ...
                      repmat({'Reward'},    length(tkd_betas_clean),  1)];

% === Alpha Comparison Figure ===
figure('Name','Alpha Comparison','Color','w','Position',[100 100 600 500]);
boxplot([tkll_alphas_clean; tkd_alphas_clean], group_labels_alpha, ...
        'Colors', 'k', 'Widths', 0.4, 'Symbol', 'o');
ylabel('\alpha (Learning Rate)', 'FontSize', fontsize, 'FontWeight','bold');
title(sprintf('\\alpha Comparison (p = %.3g)', p_alpha), ...
      'FontSize', fontsize+2, 'FontWeight','bold');
set(gca, 'FontSize', fontsize-2, 'LineWidth', 1.5);
set(findall(gca, 'Type', 'Line'), 'LineWidth', linewidth);
exportgraphics(gcf, fullfile(fig_save_dir, 'Alpha_Comparison_LossOnly_vs_Reward.png'), 'Resolution', 300);

% === Beta Comparison Figure ===
figure('Name','Beta Comparison','Color','w','Position',[100 100 600 500]);
boxplot([tkll_betas_clean; tkd_betas_clean], group_labels_beta, ...
        'Colors', 'k', 'Widths', 0.4, 'Symbol', 'o');
ylabel('\beta (Inverse Temperature)', 'FontSize', fontsize, 'FontWeight','bold');
title(sprintf('\\beta Comparison (p = %.3g)', p_beta), ...
      'FontSize', fontsize+2, 'FontWeight','bold');
set(gca, 'FontSize', fontsize-2, 'LineWidth', 1.5);
set(findall(gca, 'Type', 'Line'), 'LineWidth', linewidth);
exportgraphics(gcf, fullfile(fig_save_dir, 'Beta_Comparison_LossOnly_vs_Reward.png'), 'Resolution', 300);
