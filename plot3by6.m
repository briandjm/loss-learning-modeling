function plot3by6(gpav, gpse, savename)
    plt = W_plt('savedir','../Figure', 'extension', 'jpg', 'issave', 1); % start plotting
    name_condition = {'cond1','cond2','cond3','cond4','cond5','cond6'}; % all conditions
    groups = 1;
    experiments = 1;
    c1 = [0.5, 0.5, 0.5]; % color names
    c2 = [0.49, 0.18, 0.56];
    c3 = [0,0.75,0.75];
    cols = {c1,c2,c3};
    plt.figure(length(groups),6); % parameters of the figure, 3x6 for now
    plt.param_plt.fontsize_leg = 15;
    plt.param_plt.fontsize_axes = 14;
    for gi = 1:length(groups) % for groups 1-3
        for ci = 1:6 % for conditions 1-6
            plt.ax(gi, ci); % axes, groups on rows and conditions on columns, for now
            if gi == 1 % just for the first row
                plt.setfig_ax('title', name_condition{ci}) % set the title for the columns as conditions
                plt.param_plt.fontsize_title = 14;
            end
            plt.setfig_ax('xlabel', 'trial', ... % set x axis label as trial numbers
                'xlim', [0.5 18.5], 'ylim', [0.4 1], ... % set the limits of the x and y axes
                'legend', {'TkD','TkL','TkS'}, 'legloc', 'SE') % set the legend and the legend location
            if ci == 1 % just for the first column
                plt.setfig_ax('ylabel', {num2str(gi), 'accuracy'}); % show the group number and accuracy on y axis
                plt.param_plt.fontsize_label = 14;
            else
                plt.setfig_ax('ylabel', {'accuracy'}); % for all other columns, just put accuracy on y axis
            end
            for ei = 1:length(experiments) % for experiments 1-3
                tav = gpav{gi, ei}(:, ci); % average for that group/experiment combo, and the 'ci'th condition
                tse = gpse{gi, ei}(:, ci); % same thing but for standard error
                plt.plot(1:18, tav', tse', 'shade', ... % for trials 1-18 of given condition, plot accuracy and SE
                    'color', cols{ei}); 
            end
        end
    end
    plt.update(savename);
end