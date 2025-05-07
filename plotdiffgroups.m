function plotdiffgroups(gpav, gpse, savename)
    plt = W_plt('savedir','../Figure', 'extension', 'jpg', 'issave', 1); % start plotting
    name_condition = {'cond1','cond2','cond3','cond4','cond5','cond6'}; % all conditions
    name_experiments = {'TkD','TkL','TkS'};
    c1 = [0.5, 0.5, 0.5]; % color names
    c2 = [0,0.75,0.75];
    c3 = [0.49, 0.18, 0.56];
    cols = {c1,c2,c3};
    plt.figure(3,6); % parameters of the figure, 3x6 for now
    plt.param_plt.fontsize_leg = 15;
    experiment_order = [1, 3, 2];
    for eii = 1:3
        ei = experiment_order(eii);
        for ci = 1:6
            plt.ax(ei,ci);
            if ei == 1
                plt.setfig_ax('title', name_condition{ci})
                plt.param_plt.fontsize_title = 15;
            end
            plt.setfig_ax('xlabel','trial', ...
                'xlim',[0.5 18.5],'ylim', [0.4 1], ...
                'legend',{'Novel','Familiar'})
            if ci == 6
                plt.setfig_ax('legloc','NE')
            else
                plt.setfig_ax('legloc','SE')

            end

            if ci == 1
                plt.param_plt.fontsize_label = 15;
                plt.setfig_ax('ylabel',{name_experiments{ei}});
            else
                plt.param_plt.fontsize_label = 15;
                plt.setfig_ax('ylabel',{'accuracy'});
            end

            novelav = gpav{1,ei}(:,ci);
            novelse = gpse{1,ei}(:,ci);

            famav = gpav{2,ei}(:,ci);
            famse = gpse{2,ei}(:,ci);
               
            plt.plot(1:18, novelav', novelse','shade', ... % for trials 1-18 of given condition, plot accuracy and SE
                 'color', 'red');
            plt.plot(1:18, famav', famse','shade', ... % for trials 1-18 of given condition, plot accuracy and SE
                 'color', 'blue');
           
        end
    end
    plt.update(savename);
end


 % for gi = 1:3 % for groups 1-3
 %        for ci = 1:6 % for conditions 1-6
 %            plt.ax(gi, ci); % axes, groups on rows and conditions on columns, for now
 %            if gi == 1 % just for the first row
 %                plt.setfig_ax('title', name_condition{ci}) % set the title for the columns as conditions
 %            end
 %            plt.setfig_ax('xlabel', 'trial', ... % set x axis label as trial numbers
 %                'xlim', [0.5 18.5], 'ylim', [0.4 1], ... % set the limits of the x and y axes
 %                'legend', {'TkD','TkL','TkS'}, 'legloc', 'SE') % set the legend and the legend location
 %            if ci == 1 % just for the first column
 %                plt.setfig_ax('ylabel', {num2str(gi), 'accuracy'}); % show the group number and accuracy on y axis
 %            else
 %                plt.setfig_ax('ylabel', {'accuracy'}); % for all other columns, just put accuracy on y axis
 %            end
 % 
 %            novelav = gpav{gi, ei}(:, ci); % average for that group/experiment combo, and the 'ci'th condition
 %            novelse = gpse{gi, ei}(:, ci); % same thing but for standard error
 % 
 %            famav = gpav{gi, ei}(:, ci); % average for that group/experiment combo, and the 'ci'th condition
 %            famse = gpse{gi, ei}(:, ci); % same thing but for standard error
 % 
 %            plt.plot(1:18, tav', tse', 'shade', ... % for trials 1-18 of given condition, plot accuracy and SE
 %                'color', cols{ei});
 %        end
 %    end