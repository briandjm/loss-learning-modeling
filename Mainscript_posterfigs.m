%% Load data
data = importdata('./dataall.mat');
data.is_correct = calculate_iscorrect(data);
data.previousblocknovel = 1-data.('previous blk novel');
save("dataall.mat","data");

%% previous block novel current block novel
row_prevblock_novel = find(data.previousblocknovel == 1 & data.isNovel == 1);
dprevnovel_currnovel = data(row_prevblock_novel,:);

[avg_prevcurrnovel, se_prevcurrnovel] = se_av_all(dprevnovel_currnovel);
plot3by6(avg_prevcurrnovel, se_prevcurrnovel,'prevcurrnovel')

%% previous block familiar current block novel
row_prevblock_fam_currnovel= find(data.previousblocknovel == 0 & data.isNovel == 1);
dprevfam_currnovel = data(row_prevblock_fam_currnovel,:);

[avg_prevfamcurrnovel, se_prevfamcurrnovel] = se_av_all(dprevfam_currnovel);
plot3by6(avg_prevfamcurrnovel, se_prevfamcurrnovel,'prevfamcurrnovel')

%% previous block novel current block familiar
row_prevblock_novel_currfam = find(data.previousblocknovel == 1 & data.isNovel == 0);
dprevnovel_currfam = data(row_prevblock_novel_currfam,:);

[avg_prevnovelcurrfam, se_prevnovelcurrfam] = se_av_all(dprevnovel_currfam);
plot3by6(avg_prevnovelcurrfam,se_prevnovelcurrfam,'prevnovelcurrfam')

%% previous block familiar current block familiar
row_prevblockfam_currfam = find(data.previousblocknovel == 0 & data.isNovel == 0);
dprevfam_currfam = data(row_prevblockfam_currfam,:);

[avg_prevfamcurrfam, se_prevfamcurrfam] = se_av_all(dprevfam_currfam);
plot3by6(avg_prevfamcurrfam,se_prevfamcurrfam,'prevfamcurrfam')


%% individual groups, current block novel
names = ["group 1 novel","group 2 novel","group 3 novel"];
for i = 1:3

    avg_group1novelfamiliar = cell(2,3); % initializing cells
    se_group1novelfamiliar = cell(2,3);

    avg_group1novelfamiliar(1,:) = avg_prevcurrnovel(i,:); % gp 1 avg previous novel/current novel
    avg_group1novelfamiliar(2,:) = avg_prevfamcurrnovel(i,:); % previous familiar/current novel

    se_group1novelfamiliar(1,:) = se_prevcurrnovel(i,:); % gp 1 se previous novel current novel
    se_group1novelfamiliar(2,:) = se_prevfamcurrnovel(i,:); % se previous familiar current novel

    plotdiffgroups(avg_group1novelfamiliar,se_group1novelfamiliar,names(i))

end


%% individual groups, current block familiar

names = ["group 1 familiar","group 2 familiar","group 3 familiar"];
for i = 1:3

    avg_group1novelfamiliar = cell(2,3); % initializing cells
    se_group1novelfamiliar = cell(2,3);

    avg_group1novelfamiliar(1,:) = avg_prevnovelcurrfam(i,:); % gp 1 avg previous novel/current novel
    avg_group1novelfamiliar(2,:) = avg_prevfamcurrfam(i,:); % previous familiar/current novel

    se_group1novelfamiliar(1,:) = se_prevnovelcurrfam(i,:); % gp 1 se previous novel current novel
    se_group1novelfamiliar(2,:) = se_prevfamcurrfam(i,:); % se previous familiar current novel

    plotdiffgroups(avg_group1novelfamiliar,se_group1novelfamiliar,names(i))

end

%% Token Group figures %%

%% Preprocessing
load('dataall.mat')
data = data(data.isNovel ==1, :);

data.block_token_before = zeros(size(data,1),1);
unique_blocks = unique(data.block_unique_ID);
for i = 1:length(unique_blocks)
    rowid = data.block_unique_ID == unique_blocks(i);
    td = data(rowid,:);
    data.block_token_before(rowid) = td.tokens_before(1);
end

%% Find the values in 'tokens_before' for rows where 'is_first_trial' is 1
check_equals = [1;data.block_unique_ID(2:end) ~= data.block_unique_ID(1:end-1)];

data.is_first_trial = check_equals;

firstTrialTokens = data.tokens_before(data.is_first_trial == 1);
[count] = hist(firstTrialTokens, [0.5:1:14.5]);

%% Grouping tokens

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

%% token group figures

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
%% Actual plotting for each group
plottokens(av_grp_array{1}, se_grp_array{1}, ('group 1')); % Group 1
plottokens(av_grp_array{2}, se_grp_array{2}, ('group 2')); % Group 2
plottokens(av_grp_array{3}, se_grp_array{3}, ('group 3')); % Group 3
