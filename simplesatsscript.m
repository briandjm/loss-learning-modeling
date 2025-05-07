clear; clc;

clear; clc;

% Load the saved alpha/beta vectors from batch fitting
load('batch_fit_results.mat');  % This brings in tkll_alphas, tkll_betas, tkd_alphas, tkd_betas

%% TKLL Boxplot with p-values
[h_a,p_a] = ttest2(tkll_alpha, tkd_alpha);
[h_b,p_b] = ttest2(tkll_beta, tkd_beta);

figure('Name','Alpha Comparison','Color','w');
boxplot([tkll_alpha(:), tkd_alpha(:)], {'TkLL','TkD'}, 'Colors', 'k');
ylabel('\alpha (alpha)', 'FontSize', 14, 'FontWeight','bold');
title(['Alpha Comparison (p = ' num2str(p_a, '%.3f') ')'], 'FontSize', 16);
set(gca, 'FontSize', 12, 'LineWidth', 1.5);
saveas(gcf, 'nicefigs/Alpha_Comparison_Boxplot.png');

figure('Name','Beta Comparison','Color','w');
boxplot([tkll_beta(:), tkd_beta(:)], {'TkLL','TkD'}, 'Colors', 'k');
ylabel('\beta (beta)', 'FontSize', 14, 'FontWeight','bold');
title(['Beta Comparison (p = ' num2str(p_b, '%.3f') ')'], 'FontSize', 16);
set(gca, 'FontSize', 12, 'LineWidth', 1.5);
saveas(gcf, 'nicefigs/Beta_Comparison_Boxplot.png');
