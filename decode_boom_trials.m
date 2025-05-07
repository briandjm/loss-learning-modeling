% Recreate Craig's Figure for ONE session

addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/functions');

% STEP 1: Load one session
load('/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Boom/Experiment-Boom_Train-12-08-2017.mat');
BHV = data;

% STEP 2: Filter good trials
good_trials = find(BHV.TrialError == 0);
if length(good_trials) > 1080
    good_trials = good_trials(1:1080);
end

cond = BHV.ConditionNumber(good_trials);
react = BHV.ReactionTime(good_trials)';
data = [good_trials cond react];

% STEP 3: Extract event codes
for t = 1:size(data,1)
    trial_idx = data(t,1);
    data(t,4) = BHV.CodeNumbers{1,trial_idx}(5,1);   % condition code
    data(t,5) = BHV.CodeNumbers{1,trial_idx}(6,1);   % block ID
    data(t,6) = BHV.CodeNumbers{1,trial_idx}(11,1);  % choice code
    data(t,7) = BHV.CodeNumbers{1,trial_idx}(12,1);  % outcome code
end

% STEP 4: Keep only complete blocks (108 trials) 
nb = data(:,2) > 9;  % Craig only uses conds 10-12
nb = data(nb,:);
n_uq = unique(nb(:,2));

nb_comp = zeros(size(n_uq));
for ct = 1:length(n_uq)
    nb_comp(ct) = sum(nb(:,2) == n_uq(ct));
end

nb_complete = n_uq(nb_comp == 108);

% STEP 5: Allocate learning curve matrices
uq = nb_complete;  % complete condition numbers
a_choice = zeros(length(uq),18);
b_choice = zeros(length(uq),18);
c_choice = zeros(length(uq),18);
d_choice = zeros(length(uq),18);
e_choice = zeros(length(uq),18);
f_choice = zeros(length(uq),18);

% STEP 6: Run getcondition for each block 
for ct = 1:length(uq)
    [a, b, c, d, e, f] = getcondition(data, uq(ct));

    a_choice(ct,:) = (a(:,7) == 600)';
    b_choice(ct,:) = (b(:,7) == 600)';
    c_choice(ct,:) = (c(:,7) == 599)';
    d_choice(ct,:) = (d(:,7) == 600)';
    e_choice(ct,:) = (e(:,7) == 599)';
    f_choice(ct,:) = (f(:,7) == 597)';
end

% STEP 7: Plot the 6 learning curves 
x = 1:18;
figure;
subplot(2,3,1); plot(x, mean(a_choice)); ylim([0 1]); title('0 v -1');
subplot(2,3,2); plot(x, mean(b_choice)); ylim([0 1]); title('0 v -3');
subplot(2,3,3); plot(x, mean(c_choice)); ylim([0 1]); title('-1 v -3');
subplot(2,3,4); plot(x, mean(d_choice)); ylim([0 1]); title('0 v -4');
subplot(2,3,5); plot(x, mean(e_choice)); ylim([0 1]); title('-1 v -4');
subplot(2,3,6); plot(x, mean(f_choice)); ylim([0 1]); title('-3 v -4');

sgtitle('Learning Curves - Boom 12-08-2017');
