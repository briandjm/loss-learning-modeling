clear; clc;

addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/josephine_analysis/oldfunctions')
savepath

load('dataall.mat')

data.iscorrect = calculate_iscorrect(data);
data.previousblocknovel = 1 - data.('previous blk novel');

% sanity check: get all unique tasks


disp('Unique experiment IDs:');
disp(unique({data.experimentID}));