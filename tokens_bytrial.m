%% Load data
load('dataall.mat')
data = data(data.isNovel ==1, :);

%% 
% 5 groups, tokens 0 1 2 3 4+

data.token_group = data.block_token_before;
for i = 1:length(data.block_token_before)
    if data.block_token_before(i) == 0 
    data.token_group(i) = 1;
    elseif data.block_token_before(i) == 1 
    data.token_group(i) = 2;
    elseif data.block_token_before(i) == 2
    data.token_group(i) = 3;
    elseif data.block_token_before(i) == 3
    data.token_group(i) = 4;
    elseif data.block_token_before(i) >= 4
    data.token_group(i) = 5;
    end
end

[count] = hist(data.token_group, [0.5:1:4.5]);

%%
data.block_token_before = zeros(size(data,1),1);
unique_blocks = unique(data.block_unique_ID);
for i = 1:length(unique_blocks)
    rowid = data.block_unique_ID == unique_blocks(i);
    td = data(rowid,:);
    data.block_token_before(rowid) = td.tokens_before;
end