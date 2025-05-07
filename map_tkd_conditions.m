clear; clc;

% Load filtered data
load('data_filtered.mat');  % assumes 'data_filtered' is already saved

fprintf('=== Step 1: What cue IDs (choice no side) appear in each condition ===\n');
for cond = 1:6
    rows = data_filtered.condition == cond;
    cue_ids = unique(data_filtered.("choice no side")(rows));
    fprintf('Condition %d → cue IDs: %s\n', cond, mat2str(cue_ids'));
end

fprintf('\n=== Step 2: What token values each cue ID corresponds to ===\n');
for cue_id = 1:4
    idx = data_filtered.("choice no side") == cue_id;
    token_changes = unique(data_filtered.change_in_tokens(idx));
    fprintf('Cue ID %d → token values: %s\n', cue_id, mat2str(token_changes'));
end

% Assuming cue ID → token mapping:
% Cue 1 = +1
% Cue 2 = +2
% Cue 3 = -1
% Cue 4 = -2

cue_to_token = containers.Map({1, 2, 3, 4}, {'+1', '+2', '-1', '-2'});

fprintf('\n=== Step 3: Final mapping of conditions to token pairs ===\n');
for cond = 1:6
    rows = data_filtered.condition == cond;
    cue_ids = unique(data_filtered.("choice no side")(rows));
    tokens = cellfun(@(id) cue_to_token(id), num2cell(cue_ids), 'UniformOutput', false);
    fprintf('Condition %d → %s vs %s\n', cond, tokens{1}, tokens{2});
end

