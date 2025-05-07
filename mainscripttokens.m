%% Load data
load('dataall.mat')
data = data(data.isNovel ==1, :);
%% Find first trial, tokens_before
% 
% % initialize for first trials in each block
% firstTrials = [];
% 
% % start the trial count at 1
% trialCount = 1;
% 
% % initialize a column to mark the first trials
% data.is_first_trial = zeros(size(data, 1), 1);
% 
% % loop through the data
% for i = 1:size(data, 1)
%     if mod(i, 108) == 1
%         firstTrials = [firstTrials; data(i, :)]; % check if its the first trial in each block
%     end
% 
%     % assign the 'is_first_trial' value based on whether it's the first trial
%     data.is_first_trial(i) = (mod(i, 108) == 1);
% end

%%
% b = zeros(1,11);
% a = [1 1 1 2 2 2 3 3 3 3 3];
% for i = 1:11
%     if i == 1
%     b(i) = 1;
%     else
%         if a(i)== a(i-1)
%             b(i) = 0;
%         else
%             b(i) = 1;
%         end
% 
% 
%     % b(i) = a(i) ~= a(i-1);
%     end
% end
%%
% data.block_unique_ID(2:end);
% data.block_unique_ID(1:end-1);

check_equals = [1;data.block_unique_ID(2:end) ~= data.block_unique_ID(1:end-1)];

data.is_first_trial = check_equals;

%% Find the values in 'tokens_before' for rows where 'is_first_trial' is 1
firstTrialTokens = data.tokens_before(data.is_first_trial == 1);
[count] = hist(firstTrialTokens, [0.5:1:14.5])
%%
data.block_token_before = zeros(size(data,1),1);
unique_blocks = unique(data.block_unique_ID);
for i = 1:length(unique_blocks)
    rowid = data.block_unique_ID == unique_blocks(i);
    td = data(rowid,:);
    data.block_token_before(rowid) = td.tokens_before(1);
end

%% 

% make sure numbers are all accounted for

% sum all numbers based on token group, maybe 2 groups for tkL

token_group = zeros(size(data, 1), 1);

for i = 1:size(data, 1)
    experiment = data.experimentID{i};
    tokens_before = data.block_token_before(i);

    if experiment == 'TkD'
        if tokens_before == 0
            token_group(i) = 1;
        elseif tokens_before >= 1 && tokens_before <= 2
            token_group(i) = 2;
        else
            token_group(i) = 3;
        end
    elseif experiment == 'TkL'
        if tokens_before <= 3
            token_group(i) = 1;
        elseif tokens_before > 3 && tokens_before <= 5
            token_group(i) = 2;
        else
            token_group(i) = 3;
        end
    elseif experiment == 'TkS'
        if tokens_before == 0
            token_group(i) = 1;
        elseif tokens_before >= 1 && tokens_before <= 2
            token_group(i) = 2;
        else
            token_group(i) = 3;
        end
    end
end

data.token_group = token_group;

%% for specific group/experiment 

% seperate by group & experiment, for group & experiment subset, should sum
% up to 3000

% firstTrialTokens = data.tokens_before(data.is_first_trial == 1);

sampledata = data(data.is_first_trial == 1,:);

groups = length(unique(data.group));
experiments = unique(data.experimentID);

histogram_results = cell(groups, length(experiments));

for gi = 1:groups
    for ei = 1:length(experiments)
        group_data = sampledata.group == gi;
        experiment_data = sampledata.experimentID == experiments{ei};
        
        filtered_data = sampledata(group_data & experiment_data,:);
        filtered_token_groups = filtered_data.tokens_before;
        
        [count] = hist(filtered_token_groups, [0.5:1:14.5]);

        histogram_results{gi, ei} = count;
    end
end





%% Create a column to indicate the group of token amounts

% start_tokens = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]; % possible starting amounts
% 
% % initialize a column to store the group assignments
% data.token_group = zeros(size(data, 1), 1);
% 
% % loop through each possible token amount
% for i = 1:length(start_tokens)
%     token_amount = start_tokens(i);
%     % assign group number to each possible value of tokens in tokens_before
%     data.token_group(data.tokens_before == token_amount) = i;
% end

%% Call the function to compute average curves for each group of token amounts
% group_avg_curves = average_by_start_tokens(data, 1);

% av_grp_array = cell(1,3);
% se_grp_array = cell(1,3);
% 
% av_grp_1_array = cell(9, 3);
% av_grp_2_array = cell(9, 3);
% av_grp_3_array = cell(9, 3);
% 
% se_grp_1_array = cell(9, 3);
% se_grp_2_array = cell(9, 3);
% se_grp_3_array = cell(9, 3);
% 
% row_i_want = data.token_group == 1;
% td = data(row_i_want,:);
% [av_grp1,se_grp1] = se_av_all(td);
% avg_grp_1_array(1,:) = av_grp1(1,:);
% se_grp_1_array(1,:) = se_grp1(1,:);
% av_grp_array{1} = grp_1_array;
% 
% 
% row_i_want2 = data.token_group == 2;
% td2 = data(row_i_want2,:);
% [av_grp2,se_grp2] = se_av_all(td2);
% grp_2_array(1,:) = 


num_token_groups = size(unique(data.token_group),1);
num_groups = size(unique(data.group),1);

unique_tokens = unique(data.token_group);

av_grp_array = cell(1, num_groups);
se_grp_array = cell(1, num_groups);

for group = 1:num_groups
    av_grp_group_array = cell(num_token_groups, num_groups);
    se_grp_group_array = cell(num_token_groups, num_groups);
    
    for i = 1:num_token_groups
        row_i_want = data.token_group == unique_tokens(i) & data.group == group;
        td = data(row_i_want, :);
        
        [av_grp, se_grp] = se_av_all(td);
        
        av_grp_group_array(i, :) = av_grp;
        se_grp_group_array(i, :) = se_grp;
    end
    
    av_grp_array{1, group} = av_grp_group_array;
    se_grp_array{1, group} = se_grp_group_array;
end
%%
plottokens(av_grp_array{1}, se_grp_array{1}, ('group 1')); % Group 1
plottokens(av_grp_array{2}, se_grp_array{2}, ('group 2')); % Group 2
plottokens(av_grp_array{3}, se_grp_array{3}, ('group 3')); % Group 3
