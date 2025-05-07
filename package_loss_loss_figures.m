% package_loss_loss_figures.m
% Run this after your final averaged figure is visible

% 1. Define folder
output_folder = 'loss_loss_figures_for_siyu';

% 2. Make folder if it doesn’t exist
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% 3. Save figure as .fig and .png
fig_filename = fullfile(output_folder, 'loss_loss_averaged.fig');
png_filename = fullfile(output_folder, 'loss_loss_averaged.png');

savefig(gcf, fig_filename);
saveas(gcf, png_filename);

fprintf('\n✅ Saved averaged loss-loss figure to:\n%s\n%s\n', fig_filename, png_filename);

% 4. Optional: zip it up
zip('loss_loss_figures_for_siyu.zip', output_folder);
fprintf('\n🗜️ Zipped everything into loss_loss_figures_for_siyu.zip\n');
