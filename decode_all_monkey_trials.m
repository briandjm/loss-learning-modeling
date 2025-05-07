 
% function path
addpath('/Users/briandjm/beck-rl-nn/modeling_stuff/functions');

% Folder paths
boom_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Boom/';
sparkles_path = '/Users/briandjm/beck-rl-nn/modeling_stuff/B_S_data/Sparkles/';

% Grab all session files 
boom_files = dir(fullfile(boom_path, 'Experiment-Boom_Train-*.mat'));
sparkles_files = dir(fullfile(sparkles_path, 'Experiment-Sparkles-*.mat'));

% Initialize master matrices
a_all = []; b_all = []; c_all = [];
d_all = []; e_all = []; f_all = [];

monkeys = {'Boom', 'Sparkles'};
monkey_paths = {boom_path, sparkles_path};
monkey_files = {boom_files, sparkles_files};

% LOOP: All sessions for both monkeys
for m = 1:length(monkeys)
    monkey = monkeys{m};
    files = monkey_files{m};
    folder = monkey_paths{m};

    for f = 1:length(files)
        filename = files(f).name;
        fprintf('\n %s | Session %d/%d: %s\n', monkey, f, length(files), filename);

        try
            load(fullfile(folder, filename));
            BHV = data;

            % Step 1: Filter good trials
            goodtrials = find(BHV.TrialError == 0);
            if length(goodtrials) > 1080
                goodtrials = goodtrials(1:1080);
            end

            % Step 2: Build matrix of good trial info
            cond = BHV.ConditionNumber(goodtrials);
            react = BHV.ReactionTime(goodtrials)';
            dat = [goodtrials cond react];

            for t = 1:size(dat,1)
                dat(t,4) = BHV.CodeNumbers{1,dat(t,1)}(5,1);   % cond code
                dat(t,5) = BHV.CodeNumbers{1,dat(t,1)}(6,1);   % block ID
                dat(t,6) = BHV.CodeNumbers{1,dat(t,1)}(11,1);  % choice code
                dat(t,7) = BHV.CodeNumbers{1,dat(t,1)}(12,1);  % outcome
            end

            % Step 3: Filter for novel blocks (conditions 10-12)
            nb = dat(dat(:,2) > 9, :);
            n_uq = unique(nb(:,2));

            % Step 4: Only keep blocks with 108 trials
            nb_comp = arrayfun(@(c) sum(nb(:,2) == c), n_uq);
            nb_complete = n_uq(nb_comp == 108);

            % Step 5: Decode condition-wise choices
            for ct = 1:length(nb_complete)
                [a, b, c, d, e, f] = getcondition(nb, nb_complete(ct));
                a_all = [a_all; (a(:,7) == 600)'];
                b_all = [b_all; (b(:,7) == 600)'];
                c_all = [c_all; (c(:,7) == 599)'];
                d_all = [d_all; (d(:,7) == 600)'];
                e_all = [e_all; (e(:,7) == 599)'];
                f_all = [f_all; (f(:,7) == 597)'];
            end

        catch ME
            fprintf('Error in file %s: %s\n', filename, ME.message);
        end
    end
end

% Plotting Mean Learning Curves 
x = 1:18;
figure('Name','Loss-Loss Learning Curves Across All Sessions');

subplot(2,3,1); plot(x, mean(a_all,1)); title('0 vs -1'); ylim([0 1]);
subplot(2,3,2); plot(x, mean(b_all,1)); title('0 vs -3'); ylim([0 1]);
subplot(2,3,3); plot(x, mean(c_all,1)); title('-1 vs -3'); ylim([0 1]);
subplot(2,3,4); plot(x, mean(d_all,1)); title('0 vs -4'); ylim([0 1]);
subplot(2,3,5); plot(x, mean(e_all,1)); title('-1 vs -4'); ylim([0 1]);
subplot(2,3,6); plot(x, mean(f_all,1)); title('-3 vs -4'); ylim([0 1]);

sgtitle('Avg Loss-Loss Learning Curves (Boom + Sparkles)');
