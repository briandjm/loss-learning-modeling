clear; clc;

%% PATHS
addpath(genpath('/Users/briandjm/Desktop/MATLAB/WangGit_Codes_MATLAB'))
addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/functions')
savepath

fig_save_dir = fullfile(pwd, 'nicefigs');
if ~exist(fig_save_dir, 'dir')
    mkdir(fig_save_dir);
end

%% Load Session Files
boom_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Boom/';
sparkles_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Sparkles/';

boom_files = dir(fullfile(boom_path, 'Experiment-Boom_Train-*.mat'));
sparkles_files = dir(fullfile(sparkles_path, 'Experiment-Sparkles-*.mat'));

monkey_paths = {boom_path, sparkles_path};
monkey_files = {boom_files, sparkles_files};
monkeys = {'Boom', 'Sparkles'};

%% Initialize storage
alphas = [];
betas  = [];
lls    = [];
aics   = [];
bics   = [];

%% Loop through Boom & Sparkles sessions
for m = 1:2
    files = monkey_files{m};
    folder = monkey_paths{m};

    for f = 1:length(files)
        try
            load(fullfile(folder, files(f).name));
            BHV = data;

            goodtrials = find(BHV.TrialError == 0);
            if length(goodtrials) > 1080
                goodtrials = goodtrials(1:1080);
            end

            % Extract CHOICES and OUTCOMES from code numbers
            choices  = nan(length(goodtrials), 1);
            outcomes = nan(length(goodtrials), 1);
            for t = 1:length(goodtrials)
                codes = BHV.CodeNumbers{1, goodtrials(t)};
                choices(t)  = codes(11); % Choice code
                outcomes(t) = codes(12); % Outcome code (e.g. token change)
            end

            % Normalize choices to be 1–4 if needed
            unique_choices = unique(choices(~isnan(choices)));
            map = containers.Map(unique_choices, 1:length(unique_choices));
            for i = 1:length(choices)
                if ~isnan(choices(i)) && isKey(map, choices(i))
                    choices(i) = map(choices(i));
                end
            end

            % Fit Q-learning
            if length(choices) < 20, continue; end
            negloglik = @(params) qlearn_loglik(params, choices, outcomes);
            init_params = [0.2, 2.0];
            lb = [0.01, 0.01]; ub = [1, 20];

            [opt_params, nll] = fmincon(negloglik, init_params, [], [], [], [], lb, ub);

            alphas(end+1,1) = opt_params(1);
            betas(end+1,1)  = opt_params(2);
            lls(end+1,1)    = -nll;
            k = 2;
            aics(end+1,1)   = 2*k - 2*lls(end);
            bics(end+1,1)   = k*log(length(choices)) - 2*lls(end);

        catch ME
            fprintf('Error in %s: %s\n', files(f).name, ME.message);
        end
    end
end

%% Plot α and β boxplots
figure('Name','TkLL Q-learning Params','Color','w','Position',[100 100 800 300]);

subplot(1,2,1)
boxplot(alphas); ylabel('Alpha'); title('TkLL: Learning Rate (\alpha)');

subplot(1,2,2)
boxplot(betas); ylabel('Beta'); title('TkLL: Inverse Temp (\beta)');

saveas(gcf, fullfile(fig_save_dir, 'TkLL_Param_Boxplots.png'));

%% Print summary
fprintf('\n=== TkLL Model Fit Summary ===\n');
fprintf('Alpha: %.3f ± %.3f\n', mean(alphas), std(alphas));
fprintf('Beta : %.3f ± %.3f\n', mean(betas),  std(betas));
fprintf('LL   : %.1f\n', mean(lls));
fprintf('AIC  : %.1f\n', mean(aics));
fprintf('BIC  : %.1f\n', mean(bics));
