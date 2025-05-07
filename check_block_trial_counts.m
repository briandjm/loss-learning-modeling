addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/functions');

% -------------------- LOAD CLEANED TRIAL DATA ---------------------
load('/Users/briandjm/beck-rl-nn/modeling_stuff/josephine_analysis/all_trials.mat');

% -------------------- (RE)ASSIGN BLOCK TYPE ---------------------
if ~ismember('BlockType', all_trials.Properties.VariableNames)
    all_trials.BlockType = repmat("Unknown", height(all_trials), 1);
    [G, ~] = findgroups(all_trials.Monkey, all_trials.Session, all_trials.Block);

    for g = 1:max(G)
        idx = (G == g);
        conditions = unique(all_trials.Condition(idx));
        if length(conditions) == 12
            all_trials.BlockType(idx) = "Novel";
        else
            all_trials.BlockType(idx) = "Familiar";
        end
    end
end

% -------------------- COMPUTE TRIAL COUNTS PER BLOCK ---------------------
[G_block, monkey, session, block] = findgroups(all_trials.Monkey, all_trials.Session, all_trials.Block);
block_sizes = splitapply(@numel, all_trials.Trial, G_block);

% Create summary table
block_table = table(monkey, session, block, block_sizes);
block_table.BlockType = splitapply(@(bt) bt(1), all_trials.BlockType, G_block);

% -------------------- DISPLAY UNIQUE COUNTS ---------------------
fprintf('\n🧪 Unique trial counts for Familiar blocks:\n');
tabulate(block_table.block_sizes(block_table.BlockType == "Familiar"))

fprintf('\n🧪 Unique trial counts for Novel blocks:\n');
tabulate(block_table.block_sizes(block_table.BlockType == "Novel"))

