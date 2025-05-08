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
load('data_filtered.mat'); % extract alpha, beta, and model fit metrics for each TkD session
session_ids = unique(data_filtered.sessionID); % get list of all unique session IDs
n_sessions = length(session_ids); % how many sessions total, used for loop + preallocation

tkd_alphas = nan(n_sessions,1); % placeholder vectors filled with NaN
tkd_betas  = nan(n_sessions,1); % i will populate with best-fit alpha and beta, LL, AIC BIC for each session
tkd_lls    = nan(n_sessions,1);
tkd_aics   = nan(n_sessions,1);
tkd_bics   = nan(n_sessions,1);

for s = 1:n_sessions % loop over every unique session
    sid = session_ids(s);
    session_data = data_filtered(data_filtered.sessionID == sid, :); % get just rows (trials) from session
    
    choices  = session_data.("choice no side"); % what was selected on each trial
    outcomes = session_data.change_in_tokens; % outcomes, how many tokens were gained/lost
    n_trials = length(choices); % number of usable trials in this session
    
    if n_trials < 20 % if fewer than 20 trials in a session, skip, not enough data to reliably fit parameters
        fprintf('Skipping TkD session %d (too few trials)\n', sid);
        continue
    end
    
 % negloglik defines function handle takes in [α, β] and returns negative
 % log-likelihood of that session's behavior
    negloglik = @(params) qlearn_loglik(params, choices, outcomes);
    try % start from alpha = 0.2 beta = 2.0, bounds α ∈ [0.01, 1], β ∈ [0.01, 20]
        [opt_params, nll] = fmincon(negloglik, [0.2, 2.0], [], [], [], [], [0.01, 0.01], [1, 20]); % use fmincon to minimize negative log likelihood
        tkd_alphas(s) = opt_params(1); % save fitted alpha nad beta
        tkd_betas(s)  = opt_params(2);
        tkd_lls(s)    = -nll; % stores the LL (from fmincon LL)
        k = 2; % number of params (alpha and beta)
        tkd_aics(s)   = 2*k - 2*tkd_lls(s); % standard AIC = 2k - 2LL
        tkd_bics(s)   = k*log(n_trials) - 2*tkd_lls(s); % standard BIC - k*log(n) - 2LL
    catch
        fprintf('TkD fit failed for session %d\n', sid); % handle any errors
        continue
    end
end

%% === 2. TKLL BATCH FITTING ===
boom_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Boom/';
sparkles_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Sparkles/';
monkey_paths = {boom_path, sparkles_path};
monkey_files = {
    dir(fullfile(boom_path, 'Experiment-Boom_Train-*.mat')), ...
    dir(fullfile(sparkles_path, 'Experiment-Sparkles-*.mat'))}; % collect.matfiles and put into monkey_files
% monkey_files{1} holds boom's files monkey_files{2} holds sparkles'
tkll_alphas = []; % initialize containers from fitting each TkLL session
tkll_betas  = [];
tkll_lls    = [];
tkll_aics   = [];
tkll_bics   = [];

for m = 1:2 % loop through each monkey and their sessions
    files = monkey_files{m};
    folder = monkey_paths{m};
    for f = 1:length(files)
        try
            load(fullfile(folder, files(f).name));
            BHV = data; % for each session file, load and assign to BHV

            goodtrials = find(BHV.TrialError == 0); % only keep completed trials, if more than 1080 trim to standardize across sessions
            if length(goodtrials) > 1080
                goodtrials = goodtrials(1:1080);
            end

            choices = nan(length(goodtrials), 1); % preallocate vectors
            outcomes = nan(length(goodtrials), 1);
            for t = 1:length(goodtrials)
                codes = BHV.CodeNumbers{1, goodtrials(t)};
                choices(t)  = codes(11); % key event code: chosen cue code
                code = codes(12); % key event code: outcome code
                if code == 600
                    outcomes(t) = 1; % 600 -> 1, 599-> -1 597-> -3, others NaN
                elseif code == 599
                    outcomes(t) = -1;
                elseif code == 597
                    outcomes(t) = -3;
                else
                    outcomes(t) = NaN;
                end
            end

            valid = ~isnan(outcomes); % clean up data, keep only valid trials with usable outcomes
            choices = choices(valid); outcomes = outcomes(valid);
            uq = unique(choices); % maps whateer cue IDs were to a contiguous range startin from 1. model needs relative options
            map = containers.Map(uq, 1:length(uq));
            choices = arrayfun(@(x) map(x), choices);

            if length(choices) < 20, continue; end % skip if not enough trials
            negloglik = @(params) qlearn_loglik(params, choices, outcomes); % fit qlearn using fmincon with standard init. val. & bounds
            [opt_params, nll] = fmincon(negloglik, [0.2, 2.0], [], [], [], [], [0.01, 0.01], [1, 20]);

            tkll_alphas(end+1,1) = opt_params(1); % store fitted alpha and beta, and convert -LL to actual LL
            tkll_betas(end+1,1)  = opt_params(2);
            tkll_lls(end+1,1)    = -nll;
            k = 2;
            tkll_aics(end+1,1)   = 2*k - 2*tkll_lls(end); % compute AIC and BIC for this session
            tkll_bics(end+1,1)   = k*log(length(choices)) - 2*tkll_lls(end);
        catch ME
            fprintf('Error in %s: %s\n', files(f).name, ME.message); % catch if anything breaks
        end
    end
end

% %% === TKD PARAM PLOT ===
% fig1 = figure('Name','Reward Task Parameters','Color','w','Position',[100 100 1000 500]); % new fig for TkD task, wide layout
% 
% subplot(1,2,1) % first subplot, left side for alpha
% pos = get(gca, 'Position');
% pos(2) = pos(2) - 0.05; % nudge plot down for balance
% set(gca, 'Position', pos);
% boxplot(tkd_alphas, 'Colors','r', 'Widths', 0.4); % plot boxplot of all session-level alpha estimates (LR) in rd
% ylabel('\alpha (Learning Rate)', 'FontSize', fontsize+2, 'FontWeight','bold', 'FontName', label_font); % greek letter formatting
% title('Reward Task Learning Rate (\alpha)', 'FontSize', fontsize+2, 'FontWeight','bold');
% set(gca, 'FontSize', fontsize, 'LineWidth', 1.5); % axis styling consistent
% boxes = findobj(gca,'Tag','Box');
% for j = 1:length(boxes) % just makes the transparent red fill to boxplot to make it prettier
%     patch(get(boxes(j),'XData'), get(boxes(j),'YData'), 'r', 'FaceAlpha', 0.1, 'EdgeColor','none');
% end
% set(findall(gca,'Type','Line'),'LineWidth',linewidth); % uniform line widths for visibility
% 
% subplot(1,2,2) % same steps as above, but now we plot inverse temp estimates for TkD sessions
% pos = get(gca, 'Position');
% pos(2) = pos(2) - 0.05;
% set(gca, 'Position', pos);
% boxplot(tkd_betas, 'Colors','r', 'Widths', 0.4);
% ylabel('\beta (Inverse Temperature)', 'FontSize', fontsize+2, 'FontWeight','bold', 'FontName', label_font);
% title('Reward Task Inverse Temp (\beta)', 'FontSize', fontsize+2, 'FontWeight','bold');
% set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);
% boxes = findobj(gca,'Tag','Box');
% for j = 1:length(boxes)
%     patch(get(boxes(j),'XData'), get(boxes(j),'YData'), 'r', 'FaceAlpha', 0.1, 'EdgeColor','none');
% end
% set(findall(gca,'Type','Line'),'LineWidth',linewidth);
% 
% if include_titles
%     sgtitle('Q-Learning Parameters — Reward Task', 'FontSize', fontsize+4, 'FontWeight','bold');
%     exportgraphics(fig1, fullfile(fig_save_dir, 'RewardTask_Qlearning_Parameters_WithTitle.png'), 'Resolution', 300);
% else
%     exportgraphics(fig1, fullfile(fig_save_dir, 'RewardTask_Qlearning_Parameters_NoTitle.png'), 'Resolution', 300);
% end % save figure to file with or without title

% %% === TKLL PARAM PLOT ===
% % this is the same for TkD, just blue for box color and reference to Loss
% % only task
% fig2 = figure('Name','Loss-Only Task Parameters','Color','w','Position',[100 100 1000 500]);
% 
% subplot(1,2,1)
% pos = get(gca, 'Position');
% pos(2) = pos(2) - 0.05;
% set(gca, 'Position', pos);
% boxplot(tkll_alphas, 'Colors','b', 'Widths', 0.4);
% ylabel('\alpha (Learning Rate)', 'FontSize', fontsize+2, 'FontWeight','bold', 'FontName', label_font);
% title('Loss-Only Task Learning Rate (\alpha)', 'FontSize', fontsize+2, 'FontWeight','bold');
% set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);
% boxes = findobj(gca,'Tag','Box');
% for j = 1:length(boxes)
%     patch(get(boxes(j),'XData'), get(boxes(j),'YData'), 'b', 'FaceAlpha', 0.1, 'EdgeColor','none');
% end
% set(findall(gca,'Type','Line'),'LineWidth',linewidth);
% 
% subplot(1,2,2)
% pos = get(gca, 'Position');
% pos(2) = pos(2) - 0.05;
% set(gca, 'Position', pos);
% boxplot(tkll_betas, 'Colors','b', 'Widths', 0.4);
% ylabel('\beta (Inverse Temperature)', 'FontSize', fontsize+2, 'FontWeight','bold', 'FontName', label_font);
% title('Loss-Only Task Inverse Temp (\beta)', 'FontSize', fontsize+2, 'FontWeight','bold');
% set(gca, 'FontSize', fontsize, 'LineWidth', 1.5);
% boxes = findobj(gca,'Tag','Box');
% for j = 1:length(boxes)
%     patch(get(boxes(j),'XData'), get(boxes(j),'YData'), 'b', 'FaceAlpha', 0.1, 'EdgeColor','none');
% end
% set(findall(gca,'Type','Line'),'LineWidth',linewidth);
% 
% if include_titles
%     sgtitle('Q-Learning Parameters — Loss-Only Task', 'FontSize', fontsize+4, 'FontWeight','bold');
%     exportgraphics(fig2, fullfile(fig_save_dir, 'LossOnlyTask_Qlearning_Parameters_WithTitle.png'), 'Resolution', 300);
% else
%     exportgraphics(fig2, fullfile(fig_save_dir, 'LossOnlyTask_Qlearning_Parameters_NoTitle.png'), 'Resolution', 300);
% end

%% === OPTIONAL STATS ===
fprintf('\n=== Reward Task Model Summary ===\n'); % prints the mean +/- the SD of alpha and beta from TkD into command window
fprintf('Alpha: %.3f ± %.3f\n', mean(tkd_alphas), std(tkd_alphas));
fprintf('Beta : %.3f ± %.3f\n', mean(tkd_betas),  std(tkd_betas));

fprintf('\n=== Loss-Only Task Model Summary ===\n'); % same as above for loss loss task
fprintf('Alpha: %.3f ± %.3f\n', mean(tkll_alphas), std(tkll_alphas));
fprintf('Beta : %.3f ± %.3f\n', mean(tkll_betas),  std(tkll_betas));
save('batch_fit_results.mat', ...
     'tkll_alphas', 'tkll_betas', ...
     'tkd_alphas', 'tkd_betas');

%% === FINAL GROUP COMPARISON: α & β STATS FIGURE ===

% Clean NaNs
tkd_alphas_clean  = tkd_alphas(~isnan(tkd_alphas));
tkd_betas_clean   = tkd_betas(~isnan(tkd_betas));
tkll_alphas_clean = tkll_alphas(~isnan(tkll_alphas));
tkll_betas_clean  = tkll_betas(~isnan(tkll_betas));

% Welch’s t-tests
[~, p_alpha] = ttest2(tkll_alphas_clean, tkd_alphas_clean);
[~, p_beta]  = ttest2(tkll_betas_clean,  tkd_betas_clean);

% Final figure
fig = figure('Name','Q-Learning Parameter Comparison','Color','w','Position',[100 100 1000 400]);

% Colors
colors = [0.2 0.4 0.8; 0.8 0.2 0.2];  % blue (Loss-Only), red (Gain/Loss)
group_order = {'Loss-Only Task', 'Gain/Loss Task'};

fontsize = 14;
linewidth = 1.5;

%% α boxplot
subplot(1,2,1)
box_data_alpha = [tkll_alphas_clean; tkd_alphas_clean];
group_alpha = [repmat({'Loss-Only Task'}, length(tkll_alphas_clean), 1); ...
               repmat({'Gain/Loss Task'}, length(tkd_alphas_clean),  1)];
boxplot(box_data_alpha, group_alpha, 'Colors', 'k', 'Widths', 0.4, 'Symbol', 'o');
ylabel('\alpha', 'FontSize', fontsize, 'FontWeight','bold');
title(sprintf('p = %.2g', p_alpha), 'FontSize', fontsize, 'FontWeight','bold', ...
      'Units', 'normalized', 'Position', [0.5, 1.02, 0]);  % Lowered title to avoid cutoff
set(gca, 'YLim', [0 max(box_data_alpha)*1.2], 'FontSize', fontsize-2, 'LineWidth', linewidth);
set(gca, 'XTickLabel', group_order);
set(findall(gca, 'Type', 'Line'), 'LineWidth', linewidth);
grid off;
hold on
fill_boxplot_colors(colors);

%% β boxplot
subplot(1,2,2)
box_data_beta = [tkll_betas_clean; tkd_betas_clean];
group_beta = [repmat({'Loss-Only Task'}, length(tkll_betas_clean), 1); ...
              repmat({'Gain/Loss Task'}, length(tkd_betas_clean),  1)];
boxplot(box_data_beta, group_beta, 'Colors', 'k', 'Widths', 0.4, 'Symbol', 'o');
ylabel('\beta', 'FontSize', fontsize, 'FontWeight','bold');
title(sprintf('p = %.2g', p_beta), 'FontSize', fontsize, 'FontWeight','bold', ...
      'Units', 'normalized', 'Position', [0.5, 1.02, 0]);  % Lowered title to avoid cutoff
set(gca, 'YLim', [0 max(box_data_beta)*1.2], 'FontSize', fontsize-2, 'LineWidth', linewidth);
set(gca, 'XTickLabel', group_order);
set(findall(gca, 'Type', 'Line'), 'LineWidth', linewidth);
grid off;
hold on
fill_boxplot_colors(colors([1 2], :));

% Export
exportgraphics(fig, fullfile(fig_save_dir, 'Qlearning_Parameter_Comparison_LossOnly_vs_Reward.png'), 'Resolution', 300);

%% === FILL COLOR HELPER FUNCTION ===
function fill_boxplot_colors(color_array)
    h = findobj(gca, 'Tag', 'Box');
    for j = 1:length(h)
        patch(get(h(j), 'XData'), get(h(j), 'YData'), color_array(j,:), ...
              'FaceAlpha', 0.2, 'EdgeColor', 'none');
    end
end

