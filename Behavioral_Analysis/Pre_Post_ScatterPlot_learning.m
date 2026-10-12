% Learning-phase pre/post scatter plots
clc; clear; close all;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();

dataFile = fullfile(cfg.behavioralGroupDataDir, ...
    'SPSS_Table_learning_1vs2ndSession_V5.xlsx');
data_learning = readtable(dataFile, "Sheet", "Sheet1");
data_learning (62, :) = [];

group = string(data_learning.Group);
groupcode = {'EXCOG','EX','CNT'};

% Okabe–Ito (colorblind-safe)
colors = [0 114 178;    % EXCOG - blue
          230 159 0;    % EX    - orange
          0 158 115] / 255; % CNT  - green

% Common figure formatting
figPos = [100 100 650 650];
axPos  = [0.18 0.18 0.72 0.72];
Fontname = 'Arial';
FontsizeAxis = 24;
FontsizeLabel = 12;

% --- ACCURACY ---
plot_prepost_corr_by_group( ...
    data_learning.Mean_Accuracy_Learning_S1, ...
    data_learning.Mean_Accuracy_Learning_S2, ...
    group, groupcode, colors, ...
    'Baseline Accuracy (%)', ['Follow-up' newline 'Accuracy (%)'], ...   % 2-line legend-like ylabel if needed
    'Learning Phase', ...
    [20 100], [20 100], ...
    figPos, axPos, Fontname, FontsizeAxis, FontsizeLabel);

% --- RT ---
preRT  = data_learning.Mean_RT_Learning_S1 / 1000;
postRT = data_learning.Mean_RT_Learning_S2 / 1000;

plot_prepost_corr_by_group( ...
    preRT, postRT, ...
    group, groupcode, colors, ...
    'Baseline Reaction Time (s)', ['Follow-up' newline 'Reaction Time (s)'], ...
    'Learning Phase', ...
    [0.5 2.5], [0.5 2.5], ...
    figPos, axPos, Fontname, FontsizeAxis, FontsizeLabel);

% --- stdRT ---
preStdRT  = data_learning.Mean_stdRT_Learning_S1 / 1000;
postStdRT = data_learning.Mean_stdRT_Learning_S2 / 1000;

plot_prepost_corr_by_group( ...
    preStdRT, postStdRT, ...
    group, groupcode, colors, ...
    'Baseline RT SD (s)', ['Follow-up' newline 'RT SD (s)'], ...
    'Learning Phase', ...
    [0.1 0.8], [0.1 0.8], ...
    figPos, axPos, Fontname, FontsizeAxis, FontsizeLabel);


%% =========================
% FUNCTION
% =========================
function plot_prepost_corr_by_group(xPre, yPost, group, groupcode, colors, ...
    xlab, ylab2line, ttl, xlims, ylims, figPos, axPos, Fontname, FontsizeAxis, FontsizeLabel)

figure('Position', figPos, 'Color','w'); hold on;

% Axes limits first (so we can place text relative to them)
xlim(xlims);
ylim(ylims);

% We'll build legend handles explicitly (scatter + y=x)
hScat = gobjects(numel(groupcode),1);

% Plot per group
for i = 1:numel(groupcode)
    g = groupcode{i};
    idx = (group == g);

    x = xPre(idx);
    y = yPost(idx);

    % remove missing pairs
    ok = ~isnan(x) & ~isnan(y);
    x = x(ok);
    y = y(ok);

    % Scatter
    hScat(i) = scatter(x, y, 70, ...
        'MarkerFaceColor', colors(i,:), ...
        'MarkerEdgeColor', 'k', ...
        'LineWidth', 0.5);

    % Correlation (Pearson)
    if numel(x) >= 3
        [r,p] = corr(x, y, 'Type','Pearson');
    else
        r = NaN; p = NaN;
    end

    % Only plot trend line if correlation is significant
    if ~isnan(p) && p < 0.05
        P = polyfit(x, y, 1);
        xx = xlims; % use full axis span
        yy = polyval(P, xx);
        plot(xx, yy, 'Color', colors(i,:), 'LineWidth', 2);
    end

    % % Add text (r, p) inside the graph
    % % Place text in the bottom-right region with vertical spacing upward
    % xr = xlims(2) - 0.03*range(xlims);   % right margin
    % yrBot = ylims(1) + 0.06*range(ylims);% bottom margin
    % yStep = 0.07*range(ylims);          % line spacing
    % 
    % if isnan(r)
    %     txt = sprintf('%s: r=NA, p=NA', g);
    % else
    %     txt = sprintf('%s: r=%.2f, p=%.3f', g, r, p);
    %     if p < 0.001
    %         txt = sprintf('%s: r=%.2f, p<.001', g, r);
    %     end
    % end
    % 
    % % Put first line at bottom, next lines above it
    % text(xr, yrBot + (i-1)*yStep, txt, ...
    %     'FontName', Fontname, 'FontSize', 14, ...
    %     'Color', colors(i,:), 'FontWeight','bold', ...
    %     'HorizontalAlignment','right', ...
    %     'VerticalAlignment','bottom');
end

% Reference line: y = x
hRef = plot(xlims, xlims, 'k--', 'LineWidth', 2);

% Labels / title
xlabel(xlab, 'FontSize', FontsizeLabel, 'FontName', Fontname);
ylabel(ylab2line, 'FontSize', FontsizeLabel, 'FontName', Fontname);
title(ttl, 'FontSize', FontsizeLabel, 'FontName', Fontname);

% Ax style
ax = gca;
ax.Position = axPos;
ax.LineWidth = 2.5;
ax.FontName  = Fontname;
ax.FontSize  = FontsizeAxis;
grid off;
axis square;

% % 2-row legend text (MATLAB uses newline inside strings)
% % Example requested style: legend {'Follow-up', 'Accuracy (%)'} is a 2-row label.
% % Here: show group dots + reference line.
% lg = legend([hScat(:); hRef], ...
%     { 'EXCOG', 'EX', 'CNT', ['Follow-up' newline 'Baseline (y=x)'] }, ...
%     'Location','southoutside', 'Orientation','horizontal');
% lg.Box = 'off';

hold off;

end
