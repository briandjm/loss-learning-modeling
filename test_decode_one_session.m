%%
% Step 1: Load a single Boom session and extract the Craig-style data matrix

addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/functions');

% Load one session manually
load('/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Boom/Experiment-Boom_Train-12-08-2017.mat');
BHV = data;

% Filter for good trials only
goodtrials = find(BHV.TrialError == 0);
if length(goodtrials) > 1080
    goodtrials = goodtrials(1:1080);
end

% Build Craig-style data matrix: [trial#, condition#, reaction time]
cond = BHV.ConditionNumber(goodtrials);
rt = BHV.ReactionTime(goodtrials)';
data = [goodtrials, cond, rt];

% Fill in Craig's event code columns
for t = 1:size(data,1)
    trialnum = data(t,1);
    data(t,4) = BHV.CodeNumbers{1,trialnum}(5,1);  % Condition code
    data(t,5) = BHV.CodeNumbers{1,trialnum}(6,1);  % Block ID
    data(t,6) = BHV.CodeNumbers{1,trialnum}(11,1); % Choice code
    data(t,7) = BHV.CodeNumbers{1,trialnum}(12,1); % Outcome
end

disp('✅ Step 1 complete: Craig-style data matrix built');
disp(data(1:5, :));  % Preview first few rows

%%
% Step 2: Extract full 108-trial blocks for conditions > 9 (Craig style)

% Only keep trials with condition 10–12 (novel)
nb = data(:,2) > 9;
nb = data(nb,:);  % Filtered down to just those rows

% Find unique condition numbers (usually 10, 11, 12)
n_uq = unique(nb(:,2));

% Count how many trials are in each condition
nb_comp = zeros(size(n_uq));
for ct = 1:length(n_uq)
    nb_comp(ct) = sum(nb(:,2) == n_uq(ct));
end

% Only keep the fully complete blocks (108 trials)
nb_complete = n_uq(nb_comp == 108);

% Confirm
disp('✅ Step 2 complete: Found completed blocks (108 trials) for conditions:');
disp(nb_complete);

%%
% Step 3: Build learning curves for each condition group

uq = nb_complete;  % [10 11 12]
n_blocks = length(uq);

% Preallocate 6 matrices (rows = blocks, columns = trials 1–18)
a_choice = zeros(n_blocks,18);  % 0 vs -1
b_choice = zeros(n_blocks,18);  % 0 vs -3
c_choice = zeros(n_blocks,18);  % -1 vs -3
d_choice = zeros(n_blocks,18);  % 0 vs -4
e_choice = zeros(n_blocks,18);  % -1 vs -4
f_choice = zeros(n_blocks,18);  % -4 vs -3

% Loop over all fully completed blocks and extract curves
for ct = 1:n_blocks
    [a, b, c, d, e, f] = getcondition(data, uq(ct));  % Craig’s function
    
    a_choice(ct,:) = (a(:,7) == 600)';  % Event code 600 = choice left (for 0 vs -1)
    b_choice(ct,:) = (b(:,7) == 600)';
    c_choice(ct,:) = (c(:,7) == 599)';
    d_choice(ct,:) = (d(:,7) == 600)';
    e_choice(ct,:) = (e(:,7) == 599)';
    f_choice(ct,:) = (f(:,7) == 597)';
end

disp('✅ Step 3 complete: 6 learning curve matrices generated');


%% 
x = 1:18;  % Trial bins

figure('Name', 'Monkey Loss-Loss Learning Curves', 'Color', 'w');
titles = {'0 vs -1', '0 vs -3', '-1 vs -3', '0 vs -4', '-1 vs -4', '-4 vs -3'};
curve_data = {a_choice, b_choice, c_choice, d_choice, e_choice, f_choice};

for i = 1:6
    subplot(2,3,i)
    plot(x, mean(curve_data{i}, 1), 'LineWidth', 2);
    ylim([0 1])
    title(titles{i}, 'FontWeight', 'bold')
    xlabel('Trial Bin')
    ylabel('P(Correct)')
end

sgtitle('Novel Loss-Loss Conditions — Session Averages')