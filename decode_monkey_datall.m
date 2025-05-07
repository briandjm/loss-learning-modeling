clear; clc;
addpath(genpath('/Users/briandjm/Desktop/MATLAB/WangGit_Codes_MATLAB'))
addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/josephine_analysis/oldfunctions')
savepath

% Load and filter
load('dataall.mat')
data.iscorrect = calculate_iscorrect(data);
data = data(strcmp(data.experimentID, 'TkD') & data.isNovel == 1, :);

% Token group (optional but included for completeness)
data.block_token_before = zeros(size(data,1),1);
unique_blocks = unique(data.block_unique_ID);
for i = 1:length(unique_blocks)
    rowid = data.block_unique_ID == unique_blocks(i);
    td = data(rowid,:);
    data.block_token_before(rowid) = td.tokens_before(1);
end

token_group = zeros(size(data, 1), 1);
for i = 1:size(data, 1)
    tokens_before = data.block_token_before(i);
    if tokens_before == 0 
        token_group(i) = 1;
    elseif tokens_before > -1 && tokens_before <= 2
        token_group(i) = 2;
    else
        token_group(i) = 3;
    end
end
data.token_group = token_group;

% Plot learning curves averaged over all sessions/monkeys
figure('Name','TkD Learning Curves (Loss-Loss Style)');
conditions = 1:6;
x = 1:18;

for ci = conditions
    [curve, ~] = se_av_group(data, ci);  % curve = 18x1 avg acc over trials
    subplot(2, 3, ci);
    plot(x, curve, 'LineWidth', 2);
    ylim([0.4 1]);
    xlim([1 18]);
    title(sprintf('Condition %d', ci));
    xlabel('Trial');
    ylabel('Accuracy');
end

sgtitle('Avg Loss-Loss Learning Curves (TkD All Sessions)');
