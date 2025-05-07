%% Load data
load('dataall.mat')
data = data(data.isNovel ==1, :);
%% find last occurence of each cashoutblk

data.end_cashoutblk = zeros(size(data.cashoutblk));

prev_value = data.cashoutblk(1);
last_index = 1;

for i = 2:length(data.cashoutblk)
    current_value = data.cashoutblk(i);
    
    if current_value ~= prev_value
        data.end_cashoutblk(last_index) = 1;
        prev_value = current_value;
    end
    
    last_index = i;  
end

data.end_cashoutblk(last_index) = 1;

%% sum total juice 

data.total_juice = data.end_cashoutblk .* data.tokens_after;


%%

% loop over every block
% see how much juice per block, every 108 trials

unique_block_ids = unique(data.block_unique_ID);
block_juice_sum = zeros(length(unique_block_ids), 1);

for i = 1:length(unique_block_ids)
    block_id = unique_block_ids(i);
    block_indices = find(data.block_unique_ID == block_id);
    block_juice_sum(i) = sum(data.total_juice(block_indices));
end

%%
prob_values = [0.05, 0.50, 0.95];

quantiles = quantile(block_juice_sum, prob_values);

%%
experiments = {'TkD', 'TkL', 'TkS'};
groups = [1, 2, 3];
quantiles = zeros(9, 3);

row = 1; % start at row 1

for e = 1:length(experiments)
    for g = 1:length(groups)
        experiment = experiments{e};
        group = groups(g);
        
        filtered_data = data(data.experimentID == experiment & data.group == group, :);
        block_juice_sum = zeros(size(filtered_data, 1), 1);
        
        unique_blocks = unique(filtered_data.block_unique_ID);
        for b = 1:length(unique_blocks)
            block_id = unique_blocks(b);
            block_indices = filtered_data.block_unique_ID == block_id;
            block_juice_sum(block_indices) = sum(filtered_data.total_juice(block_indices));
        end
        
        quantiles(row, :) = quantile(block_juice_sum, [0.05, 0.50, 0.95]);
        row = row + 1;
    end
end
