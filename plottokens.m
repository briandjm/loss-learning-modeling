function plottokens(av_grp_array, se_grp_array, savename)
    plt = W_plt('savedir','../Figure', 'extension', 'jpg', 'issave', 1); % start plotting
    name_condition = {'cond1','cond2','cond3','cond4','cond5','cond6'}; % all conditions
    name_experiments = {'TkD','TkL','TkS'};
    plt.figure(3,6);
    plt.param_plt.fontsize_leg = 15;
    plt.param_plt.fontsize_axes = 13;
    plt.param_plt.fontsize_title = 15;
    c1 = [[0, 0.4470, 0.7410]]; % color names
    c2 = [0.8500, 0.3250, 0.0980];
    c3 = [0.4940, 0.1840, 0.5560];
    cols = {c1,c2,c3};
    
    % Loop through conditions
    for ci = 1:6 % for conditions 1-6
        for ei = 1:3 % for experiments 1-3
            plt.ax(ei, ci); % axes, experiments on rows and conditions on columns
            if ci == 6
            plt.setfig_ax('legloc','NE')
            end
            if ei == 1
                plt.setfig_ax('title',name_condition{ci})
            end
            if ei == 1
                plt.setfig_ax('xlabel','trial',...
                'xlim',[0.5 18.5],'ylim',[0.4 1],...
                'legend',{'0','1 & 2','3+'},'legloc','SE')
            elseif ei == 2
                plt.setfig_ax('xlabel','trial',...
                'xlim',[0.5 18.5],'ylim',[0.4 1],...
                'legend',{'0-3','4 & 5','5+'},'legloc','SE')
            elseif ei == 3
                plt.setfig_ax('xlabel','trial',...
                'xlim',[0.5 18.5],'ylim',[0.4 1],...
                'legend',{'0','1 & 2','3+'},'legloc','SE')
            end
            if ci == 1
                plt.param_plt.fontsize_label = 15;
                plt.setfig_ax('ylabel',{name_experiments{ei}});
            else
                plt.param_plt.fontsize_label = 15;
                plt.setfig_ax('ylabel',{'accuracy'});
            end
            for tg = 1:3 % for token groups 1-9, don't hardcode
                tav = av_grp_array{tg, ei}(:, ci); % average for that group/experiment/tokengroup combo, and the 'ci'th condition
                tse = se_grp_array{tg, ei}(:, ci); % standard error for that group/experiment/tokengroup combo, and the 'ci'th condition
                plt.plot(1:18, tav', tse', 'shade','color',cols{tg}); % for trials 1-18 of given condition, plot accuracy and SE
            end
        end
    end
    plt.update(savename);
end
