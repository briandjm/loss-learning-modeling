clear; clc;

%% PATH SETUP
addpath(genpath('/Users/briandjm/Desktop/MATLAB/WangGit_Codes_MATLAB'))
addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/functions')
savepath

fig_save_dir = fullfile(pwd, 'nicefigs');
if ~exist(fig_save_dir, 'dir')
    mkdir(fig_save_dir);
end

%% Load TkLL Sessions
boom_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Boom/';
sparkles_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Sparkles/';
monkey_paths = {boom_path, sparkles_path};
monkey_files = {
    dir(fullfile(boom_path, 'Experiment-Boom_Train-*.mat')), ...
    dir(fullfile(sparkles_path, 'Experiment-Sparkles-*.mat'))};

all_choices = [];
all_outcomes = [];

for m = 1:2
    files = monkey_files{m};
    path = monkey_paths{m};
    for f = 1:length(files)
        try
            load(fullfile(path, files(f).name));
            BHV = data;

            goodtrials = find(BHV.TrialError == 0);
            if length(goodtrials) > 1080
                goodtrials = goodtrials(1:1080);
            end

            for t = 1:length(goodtrials)
                trial = goodtrials(t);
                if size(BHV.CodeNumbers{1,trial},1) >= 12
                    ch = BHV.CodeNumbers{1,trial}(11,1);
                    out = BHV.CodeNumbers{1,trial}(12,1);
                    if ismember(ch, 1:1000)
                        all_choices(end+1) = ch;
                        if out == 600
                            all_outcomes(end+1) = 1;
                        elseif out == 599
                            all_outcomes(end+1) = -1;
                        elseif out == 597
                            all_outcomes(end+1) = -3;
                        else
                            all_outcomes(end+1) = NaN;
                        end
                    end
                end
            end
        catch
            fprintf('Skipping file: %s\n', files(f).name);
        end
    end
end

%% Filter and Remap
choices = all_choices(:);
outcomes = all_outcomes(:);
valid = ismember(choices, 1:1000) & ~isnan(outcomes);
choices = choices(valid);
outcomes = outcomes(valid);

% Map choices to 1-4
unique_cues = unique(choices);
cue_map = containers.Map(unique_cues, 1:length(unique_cues));
choices = arrayfun(@(x) cue_map(x), choices);

n_trials = length(choices);
fprintf('Final: %d valid trials for TkLL\n', n_trials);

%% MODEL 1: Random
ll_m1 = -n_trials * log(1/length(unique(choices)));
k1 = 0;

%% MODEL 2: WSLS
was_rewarded = outcomes > 0;
pred_choices = nan(n_trials, 1);
pred_choices(1) = randi(length(unique(choices)));

for t = 2:n_trials
    if was_rewarded(t-1)
        pred_choices(t) = choices(t-1);
    else
        options = setdiff(1:length(unique(choices)), choices(t-1));
        pred_choices(t) = options(randi(length(options)));
    end
end

ll_m2 = sum(log(0.5 + 0.5*(pred_choices == choices)));
k2 = 0;

%% MODEL 3: Q-learning
negloglik = @(params) qlearn_loglik(params, choices, outcomes);
init_params = [0.2, 2.0];
lb = [0.01, 0.01]; ub = [1, 20];

[opt_params, nll_m3] = fmincon(negloglik, init_params, [], [], [], [], lb, ub);
ll_m3 = -nll_m3;
k3 = 2;

%% AIC/BIC
aic = [2*k1 - 2*ll_m1, 2*k2 - 2*ll_m2, 2*k3 - 2*ll_m3];
bic = [k1*log(n_trials) - 2*ll_m1, k2*log(n_trials) - 2*ll_m2, k3*log(n_trials) - 2*ll_m3];
lls = [ll_m1, ll_m2, ll_m3];

disp('--- LL / AIC / BIC ---')
disp(lls)
disp(aic)
disp(bic)

%% PLOT
model_labels = {'Random', 'WSLS', 'Q-Learning'};

figure('Color','w','Name','TkLL Model Comparison','Position',[100 100 900 300]);

subplot(1,3,1)
bar(lls); title('Log-Likelihood');
ylabel('LL'); xticklabels(model_labels); xtickangle(30);

subplot(1,3,2)
bar(aic); title('AIC');
ylabel('AIC'); xticklabels(model_labels); xtickangle(30);

subplot(1,3,3)
bar(bic); title('BIC');
ylabel('BIC'); xticklabels(model_labels); xtickangle(30);

sgtitle('Model Comparison: TkLL', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, fullfile(fig_save_dir, 'TkLL_Model_Comparison.png'));
