addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/functions');
load('/Users/briandjm/beck-rl-nn/modeling_stuff/josephine_analysis/all_trials.mat');

fprintf('\n Sanity Check: Block Overview\n');

% assign blocktype by size (might be wrong)
if ~ismember('BlockType', all_trials.Properties.VariableNames)
    all_trials.BlockType = repmat("Unknown", height(all_trials), 1);
    [G, block_keys] = findgroups(all_trials.Monkey, all_trials.Session, all_trials.Block);
    block_sizes = splitapply(@numel, all_trials.Trial, G);

    % Add blockType
    for g = 1:max(G)
        idx = (G == g);
        sz = block_sizes(g);
        if sz == 79
            all_trials.BlockType(idx) = "Familiar";
        elseif sz == 114
            all_trials.BlockType(idx) = "Novel";
        else
            all_trials.BlockType(idx) = "Unknown";
        end
    end

    % save updated version just in case
    save('/Users/briandjm/beck-rl-nn/modeling_stuff/josephine_analysis/all_trials_updated.mat', 'all_trials');
end

% block size histogram
figure;
histogram(block_sizes);
title('Block Sizes Across Dataset');
xlabel('Trial Count per Block');
ylabel('Number of Blocks');

% check cue values across blocks
fprintf('\n Cue Value Mapping Across Blocks\n');

[G2, monkey, session, block] = findgroups(all_trials.Monkey, all_trials.Session, all_trials.Block); % grouping from this
[~, first_idx] = unique(G2, 'stable');  % one row per block
sample_blocks = all_trials(first_idx, :);

cue_variability = table();
for i = 1:height(sample_blocks)
    row = sample_blocks(i, :);
    cond = row.Condition;
    limg = row.LeftImage{1};
    rimg = row.RightImage{1};
    lval = cue_value_from_condition(cond, limg);
    rval = cue_value_from_condition(cond, rimg);

    cue_variability = [cue_variability; {
        row.Monkey, row.Session, row.Block, cond, limg, lval, rimg, rval
    }];
end
cue_variability.Properties.VariableNames = {'Monkey', 'Session', 'Block', 'Condition', 'LeftImage', 'LeftValue', 'RightImage', 'RightValue'};

disp(head(cue_variability, 10));

% focus on group 3 and group 5, deep dive group 3
fprintf('\n--- deep dive: group 3 (-1 vs -3) ---\n');
group3 = all_trials(condition_to_group(all_trials.Condition) == 3 & all_trials.BlockType == "Novel", :);
disp(group3(1:5, {'Condition', 'LeftImage', 'RightImage', 'Choice'}));

for i = 1:min(5, height(group3))
    row = group3(i, :);
    cond = row.Condition;
    lval = cue_value_from_condition(cond, row.LeftImage{1});
    rval = cue_value_from_condition(cond, row.RightImage{1});
    [~, expected_choice] = max([lval, rval]);
    expected = row.LeftImage{1}; if expected_choice == 2, expected = row.RightImage{1}; end

    fprintf('Trial %d | Cond: %d | ChoiceCode: %d\n', ...
        i, cond, row.ChoiceCode);
    fprintf('   L: %s (%+d) | R: %s (%+d) | Chose: %s → Expected: %s | Match: %d\n', ...
        row.LeftImage{1}, lval, row.RightImage{1}, rval, ...
        row.Choice{1}, expected, strcmp(row.Choice{1}, expected));
end

% deep dive group 5
fprintf('\n--- deep dive: Group 5 (-1 vs -4) ---\n');
group5 = all_trials(condition_to_group(all_trials.Condition) == 5 & all_trials.BlockType == "Novel", :);
disp(group5(1:5, {'Condition', 'LeftImage', 'RightImage', 'Choice'}));

for i = 1:min(5, height(group5))
    row = group5(i, :);
    cond = row.Condition;
    lval = cue_value_from_condition(cond, row.LeftImage{1});
    rval = cue_value_from_condition(cond, row.RightImage{1});
    [~, expected_choice] = max([lval, rval]);
    expected = row.LeftImage{1}; if expected_choice == 2, expected = row.RightImage{1}; end

    fprintf('Trial %d | Cond: %d | ChoiceCode: %d\n', ...
        i, cond, row.ChoiceCode);
    fprintf('   L: %s (%+d) | R: %s (%+d) | Chose: %s → Expected: %s | Match: %d\n', ...
        row.LeftImage{1}, lval, row.RightImage{1}, rval, ...
        row.Choice{1}, expected, strcmp(row.Choice{1}, expected));
end
