% SUS Score Visualization Graph
clear; clc;

% --- Data Inputs ---
score_mean = 85.90;        % Mean score from SUS analysis
score_std = 9.02;          % Standard Deviation from SUS analysis
global_avg_benchmark = 68; % Global standard average for SUS
% Standard Error
N = 40; % Number of total participant
score_se = score_std / sqrt(N);


% --- Figure Setup ---
figure('Color', 'w', 'Position', [100, 100, 800, 120]);
hold on;

% 1. Drawing Background Color Zones (Quality Categories)
% Poor (0-51), OK (51-71), Good (71-80), Excellent (80-100)
patch([0 51 51 0], [0 0 1 1], [1 0.9 0.9], 'EdgeColor', 'none');    % Soft Red
patch([51 71 71 51], [0 0 1 1], [1 0.95 0.9], 'EdgeColor', 'none'); % Soft Orange
patch([71 80 80 71], [0 0 1 1], [1 1 0.9], 'EdgeColor', 'none');    % Soft Yellow
patch([80 100 100 80], [0 0 1 1], [0.9 1 0.9], 'EdgeColor', 'none'); % Soft Green

% 2. Global Average Benchmark Line (Dashed Red)
line([global_avg_benchmark global_avg_benchmark], [0 1], 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1.5);
text(global_avg_benchmark-1.5, 0.5, 'Global Avg (68)', 'Rotation', 90, 'Color', 'r', 'HorizontalAlignment', 'center', 'FontSize', 8);

% 3. Sus Score and Error Bar (Horizontal)
errorbar(score_mean, 0.4, score_se, 'horizontal', 'ko', 'LineWidth', 2, 'MarkerFaceColor', 'k', 'MarkerSize', 5);

% 4. Quality Labels
text(25.5, 0.90, 'Poor', 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(61, 0.90, 'OK', 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(75.5, 0.90, 'Good', 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
text(90, 0.90, 'Excellent', 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

% Result Label and Pointer
text(score_mean, 0.70, sprintf('Score: %.2f', score_mean), 'FontSize', 10, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
% Adding a small downward arrow using annotation
% [x_start x_end], [y_start y_end] in normalized units
annotation('arrow', [0.796 0.796], [0.68 0.54]); 

% 5. Axis Formatting
set(gca, 'XLim', [0 100], 'YLim', [0 1], 'YTick', [], 'Box', 'on', 'LineWidth', 1.2);
xlabel('SUS Score', 'FontSize', 10, 'FontWeight', 'bold');
% title('System Usability Scale (SUS) Score Results', 'FontSize', 14, 'FontWeight', 'bold');

hold off;