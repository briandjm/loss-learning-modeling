%% make the learning curves for loss loss poster, both tasks

clear; clc;
include_titles = false;  % Toggle true = paper, false = poster (no sgtitle)

%% 1. PATH SETUP
addpath(genpath('/Users/briandjm/Desktop/MATLAB/WangGit_Codes_MATLAB'))
addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/functions')
addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/josephine_analysis/oldfunctions')
savepath
% Set figure save path
fig_save_dir = fullfile(pwd, 'nicefigs');
if ~exist(fig_save_dir, 'dir')
    mkdir(fig_save_dir);
end

x = 1:18;  
conditions = 1:6;
fontsize = 16;

%% 2. PROCESS TkLL DATA
% goal: build 6 matrices (a_all - f_all) trial by trial binary corectness (
% 1 = correxr 0 = incorrect) for each cue pair across n sessions
boom_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Boom/';
sparkles_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Sparkles/';

boom_files = dir(fullfile(boom_path, 'Experiment-Boom_Train-*.mat'));
sparkles_files = dir(fullfile(sparkles_path, 'Experiment-Sparkles-*.mat'));

a_all = []; b_all = []; c_all = []; d_all = []; e_all = []; f_all = []; % hold binay accuracy vectors
monkeys = {'Boom', 'Sparkles'};
monkey_paths = {boom_path, sparkles_path};
monkey_files = {boom_files, sparkles_files};

for m = 1:length(monkeys) % start looping over monks and sessions
    files = monkey_files{m};
    folder = monkey_paths{m};

    for f = 1:length(files)
        filename = files(f).name;
        try
            load(fullfile(folder, filename)); % load each file and extract trial info
            BHV = data; % load one .mat session file

            goodtrials = find(BHV.TrialError == 0); % keep only completed trials
            if length(goodtrials) > 1080 % each block capped 108 trials x 10 blocks
                goodtrials = goodtrials(1:1080);
            end

            cond = BHV.ConditionNumber(goodtrials); % build matrix of trial info, block #s
            react = BHV.ReactionTime(goodtrials)'; % RTs
            dat = [goodtrials cond react];% prelim matrix, dat = [trial index, block condition #, RT]

            for t = 1:size(dat,1) % extract event codes
                dat(t,4) = BHV.CodeNumbers{1,dat(t,1)}(5,1); % cue A
                dat(t,5) = BHV.CodeNumbers{1,dat(t,1)}(6,1); % cue B
                dat(t,6) = BHV.CodeNumbers{1,dat(t,1)}(11,1); % chosen cue
                dat(t,7) = BHV.CodeNumbers{1,dat(t,1)}(12,1); % outcome
            end % adding 4 more cols to dat, cues, choice, outcome

            nb = dat(dat(:,2) > 9, :); % only keep real not warmup blocks
            n_uq = unique(nb(:,2)); % get all cond #s
            nb_comp = arrayfun(@(c) sum(nb(:,2) == c), n_uq); % count trials per block
            nb_complete = n_uq(nb_comp == 108); % keep blocks with all 108 trls

            for ct = 1:length(nb_complete)
                [a, b, c, d, e, f_] = getcondition(nb, nb_complete(ct));
                a_all = [a_all; (a(:,7) == 600)']; % check if trial outcome = 600
                b_all = [b_all; (b(:,7) == 600)']; % returns binary vector for cue pair
                c_all = [c_all; (c(:,7) == 599)']; % extract trials for cue pair within block
                d_all = [d_all; (d(:,7) == 600)']; % collect across blocks -> matrix of accuracy
                e_all = [e_all; (e(:,7) == 599)'];
                f_all = [f_all; (f_(:,7) == 597)'];
            end
        catch ME
            fprintf('Error in %s: %s\n', filename, ME.message); % pause if error
        end
    end
end % repeat this all for each block, every session, both monkeys

%% 3. PROCESS TkD DATA
if exist('data_filtered.mat', 'file')
    load('data_filtered.mat'); % load the preprocessed one
else
    load('dataall.mat') % if not, start from scratch
    data.iscorrect = calculate_iscorrect(data);% use my function add column iscorrect (1 or 0)
    data = data(strcmp(data.experimentID, 'TkD') & data.isNovel == 1, :); % filter for only TkD novel blocks

    data.block_token_before = zeros(size(data,1),1); % preallocate
    unique_blocks = unique(data.block_unique_ID); % how many tokens at start of each block?
    for i = 1:length(unique_blocks)
        rowid = data.block_unique_ID == unique_blocks(i);
        td = data(rowid,:);
        data.block_token_before(rowid) = td.tokens_before(1); % get block_token_before column
    end

    token_group = zeros(size(data, 1), 1); % assign token starting state group
    for i = 1:size(data, 1)
        tokens_before = data.block_token_before(i);
        if tokens_before == 0 % started with 0 tokens
            token_group(i) = 1;
        elseif tokens_before > -1 && tokens_before <= 2 % started with 1-2 tokens
            token_group(i) = 2;
        else
            token_group(i) = 3; % started with >2 tokens
        end
    end
    data.token_group = token_group;

    data_filtered = data;
    save('data_filtered.mat', 'data_filtered'); % save cleaned data
end

loss_only_titles = {'0 vs -1','0 vs -3','-1 vs -3','0 vs -4','-1 vs -4','-3 vs -4'};
reward_titles = {'+1 vs +2', '+1 vs -1', '+2 vs -1', '+1 vs -2', '+2 vs -2', '-1 vs -2'};
a_mats = {a_all, b_all, c_all, d_all, e_all, f_all};  % define once data is fully populated

%% === Updated PLOTTING SETTINGS ===
fontsize_title = 24;
fontsize_label = 20;
fontsize_ticks = 18;
linewidth_curve = 2.5;

%% 4. PLOTTING: TkLL Learning Curves — LOSS-ONLY TASK
colors_tkll = [0.2 0.4 0.8];  % dark blue
fig1 = figure('Name','Loss-Only Learning Curves','Color','w','Position',[100, 100, 1400, 600]);

for ci = 1:6
    y = a_mats{ci};
    m_curve = mean(y, 1);
    sem_curve = std(y, [], 1) ./ sqrt(size(y,1));

    subplot(2, 3, ci);
    shadedErrorBar(x, m_curve, sem_curve, ...
        'lineprops', {'Color', colors_tkll, 'LineWidth', linewidth_curve}, ...
        'patchSaturation', 0.2);

    title(loss_only_titles{ci}, 'FontSize', fontsize_title, 'FontWeight', 'bold');
    ylim([0.4 1]); xlim([1 18]);
    xlabel('Trial', 'FontSize', fontsize_label, 'FontWeight', 'bold');
    ylabel('Accuracy', 'FontSize', fontsize_label, 'FontWeight', 'bold');
    set(gca, 'FontSize', fontsize_ticks, 'LineWidth', 1.5, 'TickDir', 'out', 'Box', 'on');
end

if include_titles
    sgtitle('Loss-Only Task: Behavioral Learning Curves', 'FontSize', fontsize_title, 'FontWeight', 'bold');
    exportgraphics(fig1, fullfile(fig_save_dir, 'LossOnly_Learning_Curves_WithTitle.png'), 'Resolution', 300);
else
    exportgraphics(fig1, fullfile(fig_save_dir, 'LossOnly_Learning_Curves_NoTitle.png'), 'Resolution', 300);
end
%% 5. PLOTTING: TkD Learning Curves — REWARD TASK
colors_tkd = [0.8 0.2 0.2];  % dark red
fig2 = figure('Name','Reward Learning Curves','Color','w','Position',[100, 100, 1400, 600]);

for ci = 1:6
    row_idx = data_filtered.condition == ci;
    [~, ~, block_idx] = unique(data_filtered.block_unique_ID(row_idx));
    trials = data_filtered.iscorrect(row_idx);
    blocks_trials = splitapply(@(x){x}, trials, block_idx);

    acc_matrix = cell2mat(cellfun(@(x) padarray(x(:)', [0, 18 - length(x)], NaN, 'post'), ...
        blocks_trials, 'UniformOutput', false));
    mean_curve = nanmean(acc_matrix, 1);
    sem_curve = nanstd(acc_matrix, 0, 1) ./ sqrt(sum(~isnan(acc_matrix), 1));

    subplot(2, 3, ci);
    shadedErrorBar(x, mean_curve, sem_curve, ...
        'lineprops', {'Color', colors_tkd, 'LineWidth', linewidth_curve}, ...
        'patchSaturation', 0.2);

    title(reward_titles{ci}, 'FontSize', fontsize_title, 'FontWeight', 'bold');
    ylim([0.4 1]); xlim([1 18]);
    xlabel('Trial', 'FontSize', fontsize_label, 'FontWeight', 'bold');
    ylabel('Accuracy', 'FontSize', fontsize_label, 'FontWeight', 'bold');
    set(gca, 'FontSize', fontsize_ticks, 'LineWidth', 1.5, 'TickDir', 'out', 'Box', 'on');
end

if include_titles
    sgtitle('Reward Task: Behavioral Learning Curves', 'FontSize', fontsize_title, 'FontWeight', 'bold');
    exportgraphics(fig2, fullfile(fig_save_dir, 'RewardTask_Learning_Curves_WithTitle.png'), 'Resolution', 300);
else
    exportgraphics(fig2, fullfile(fig_save_dir, 'RewardTask_Learning_Curves_NoTitle.png'), 'Resolution', 300);
end