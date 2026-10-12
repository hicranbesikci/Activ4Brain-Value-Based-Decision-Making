clear; clc; close all;
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(projectRoot);
cfg = load_project_config();
behavioralOutputDir = fullfile(cfg.outputDir, 'Behavioral_Analysis');

%% =========================
% LOAD DATA
% =========================
S1 = load(fullfile(behavioralOutputDir, 'Baseline_data_by_diflvl_learning.mat'));
S2 = load(fullfile(behavioralOutputDir, 'Baseline_data_by_diflvl_transfer.mat'));
L = S1.taskdata;
T = S2.taskdata;
%% =========================
% STYLE
% =========================
diffLabels = {'Large','Medium','Small'};
runSize = 30; % learning
runSize_Largevd = 12; % transfer
runSize_Mediumvd = 20;
runSize_Smallvd = 28;
set(groot, 'defaultAxesFontName', 'Arial');
set(groot, 'defaultAxesFontSize', 12);
%% =========================
% SUMMARY DATA
% =========================
% Learning
accLearn = [L.meanaccuracyeasypair(:), ...
            L.meanaccuracymediumpair(:), ...
            L.meanaccuracydifficultpair(:)];
rtLearn  = [L.easypairmeanRT(:), ...
            L.mediumpairmeanRT(:), ...
            L.difficultpairmeanRT(:)];
% Transfer
accTransfer = [T.meanaccuracylargevd(:), ...
               T.meanaccuracymediumvd(:), ...
               T.meanaccuracysmallvd(:)];
rtTransfer  = [T.largevdmeanRT(:), ...
               T.mediumvdmeanRT(:), ...
               T.smallvdmeanRT(:)];
%% =========================
% RUN-WISE DATA
% =========================
% Learning
easyAccRun = get_run_means(L.accuracyeasypair, runSize) * 100;
medAccRun  = get_run_means(L.accuracymediumpair, runSize) * 100;
diffAccRun = get_run_means(L.accuracydifficultpair, runSize) * 100;
easyRTRun = get_run_means(L.easypairRT, runSize) ;
medRTRun  = get_run_means(L.mediumpairRT, runSize) ;
diffRTRun = get_run_means(L.difficultpairRT, runSize) ;
% Transfer
easyAccRun_T = get_run_means_transfer(T.accuracylargevd, runSize_Largevd) * 100;
medAccRun_T  = get_run_means_transfer(T.accuracymediumvd, runSize_Mediumvd) * 100;
diffAccRun_T = get_run_means_transfer(T.accuracysmallvd, runSize_Smallvd) * 100;
easyRTRun_T = get_run_means_transfer(T.largevdRT, runSize_Largevd) ;
medRTRun_T  = get_run_means_transfer(T.mediumvdRT, runSize_Mediumvd) ;
diffRTRun_T = get_run_means_transfer(T.smallvdRT, runSize_Smallvd) ;
%% =========================
% COMBINE DIFFICULTY LEVELS
% Her subject için her run'da 3 zorluk seviyesinin ortalaması
% =========================
Data_across_runs_learning = readtable(fullfile(behavioralOutputDir, ...
    'Baseline_data_acrossRuns_learning.xlsx'));
Data_across_runs_transfer = readtable(fullfile(behavioralOutputDir, ...
    'Baseline_data_acrossRuns_transfer.xlsx'));

accRunLearn_all = [ Data_across_runs_learning.Accuracy_Learning_Run1_S1  Data_across_runs_learning.Accuracy_Learning_Run2_S1  Data_across_runs_learning.Accuracy_Learning_Run3_S1  Data_across_runs_learning.Accuracy_Learning_Run4_S1];
rtRunLearn_all  = [ Data_across_runs_learning.RT_Learning_Run1_S1 Data_across_runs_learning.RT_Learning_Run2_S1  Data_across_runs_learning.RT_Learning_Run3_S1  Data_across_runs_learning.RT_Learning_Run4_S1];

accRunTransfer_all = [Data_across_runs_transfer.Accuracy_Transfer_Run1_S1 Data_across_runs_transfer.Accuracy_Transfer_Run2_S1  Data_across_runs_transfer.Accuracy_Transfer_Run3_S1];
rtRunTransfer_all  = [Data_across_runs_transfer.RT_Transfer_Run1_S1 Data_across_runs_transfer.RT_Transfer_Run2_S1 Data_across_runs_transfer.RT_Transfer_Run3_S1];
%% =========================
% FIGURE 1: Learning phase
% Accuracy + RT in one figure (dual y-axis)
% =========================
plot_dual_axis_difficulty(accLearn, rtLearn/1000, diffLabels, ...
'Learning phase');
%% =========================
% FIGURE 2: Transfer phase
% Accuracy + RT in one figure (dual y-axis)
% =========================
plot_dual_axis_difficulty(accTransfer, rtTransfer/1000, diffLabels, ...
'Transfer phase');
%% =========================
% FIGURE 3: Learning phase across runs
% Accuracy + RT in one figure (dual y-axis)
% =========================
plot_run_dual_axis_with_dots( ...
    accRunLearn_all', ...
    rtRunLearn_all'/1000, ...
'Learning phase', ...
    [0 100], ...
    [0.350 2.400]);
%% =========================
% FIGURE 4: Transfer phase across runs
% Accuracy + RT in one figure (dual y-axis)
% =========================
plot_run_dual_axis_with_dots( ...
    accRunTransfer_all', ...
    rtRunTransfer_all'/1000, ...
'Transfer phase', ...
    [0 100], ...
    [0.350 2.400]);
%% =========================
% % FIGURE 5: Learning Accuracy across runs
% % =========================
% plot_run_single_with_dots( ...
%     accRunLearn_all, ...
%     'Accuracy (%)', ...
%     'Learning phase', ...
%     [0 100]);
%
% %% =========================
% % FIGURE 6: Learning RT across runs
% % =========================
% plot_run_single_with_dots( ...
%     rtRunLearn_all, ...
%     'Reaction time (s)', ...
%     'Learning phase', ...
%     [.350 2.400]);
%
% %% =========================
% % FIGURE 7: Transfer Accuracy across runs
% % =========================
% plot_run_single_with_dots( ...
%     accRunTransfer_all, ...
%     'Accuracy (%)', ...
%     'Transfer phase', ...
%     [0 100]);
%
% %% =========================
% % FIGURE 8: Transfer RT across runs
% % =========================
% plot_run_single_with_dots( ...
%     rtRunTransfer_all, ...
%     'Reaction time (s)', ...
%     'Transfer phase', ...
%     [.350 2.400]);
%% ============================================================
% LOCAL FUNCTIONS
% ============================================================
function plot_dual_axis_difficulty(accData, rtData, xlabels, figTitleText)
    colAcc    = [0.00 0.35 0.80];
    colAccPts = [0.65 0.80 1.00];
    colRT     = [0.80 0.10 0.10];
    colRTPts  = [1.00 0.70 0.70];
    x = 1:3;
    mAcc = median(accData, 1, 'omitnan');
    %lowAcc = mAcc - Q1 
    lowAcc = mAcc - quantile(accData, 0.25, 1);
    %uppAcc = Q3 - mAcc
    uppAcc = quantile(accData, 0.75, 1) - mAcc;
    mRT = median(rtData, 1, 'omitnan');
    lowRT = mRT - quantile(rtData, 0.25, 1);
    uppRT = quantile(rtData, 0.75, 1) - mRT;
    figure('Color','w','Position',[100 100 760 480]);
    hold on;
    yyaxis left
for i = 1:3
        xi = x(i) - 0.08 + (rand(size(accData,1),1)-0.5)*0.08;
        scatter(xi, accData(:,i), 20, ...
'MarkerEdgeColor', colAccPts, ...
'MarkerFaceColor', 'none', ...
'LineWidth', 0.8);
        hold on;
end
    errorbar(x - 0.08, mAcc, lowAcc, uppAcc, '-o', ...
'Color', colAcc, ...
'LineWidth', 2, ...
'MarkerSize', 6, ...
'MarkerFaceColor', 'w');
    ylabel('Accuracy (%)', 'Color', colAcc);
    ylim([0 100]);
    yyaxis right
for i = 1:3
        xi = x(i) + 0.08 + (rand(size(rtData,1),1)-0.5)*0.08;
        scatter(xi, rtData(:,i), 20, ...
'MarkerEdgeColor', colRTPts, ...
'MarkerFaceColor', 'none', ...
'LineWidth', 0.8);
        hold on;
end
    errorbar(x + 0.08, mRT, lowRT, uppRT, '-s', ...
'Color', colRT, ...
'LineWidth', 2, ...
'MarkerSize', 6, ...
'MarkerFaceColor', 'w');
    ylabel('Reaction time (s)', 'Color', colRT);
    rtMin = min(rtData(:), [], 'omitnan');
    rtMax = max(rtData(:), [], 'omitnan');
    pad = 0.08 * (rtMax - rtMin);
    ylim([rtMin-pad, rtMax+pad]);
    ax = gca;
    ax.LineWidth = 2.5;
    ax.FontName = 'Arial';
    ax.FontSize  = 24;
    ax.XLim = [0.6 3.4];
    ax.XTick = x;
    ax.XTickLabel = xlabels;
    % [ax.Box](http://ax.Box) = 'off';
    ax.TickDir = 'out';
    xlabel('Option Value Difference');
    title(figTitleText, 'FontWeight', 'bold');
end
function plot_run_single_with_dots(dataRun, yLabelText, figTitleText, yLimits)
% dataRun = [nRuns x nSubjects]
    colLine = [0.15 0.15 0.15];
    colDots = [0.70 0.70 0.70];
    runs = 1:size(dataRun,1);
    mData = median(dataRun, 2, 'omitnan');
    lowData = mData - quantile(dataRun, 0.25, 2);
    uppData = quantile(dataRun, 0.75, 2) - mData;
    figure('Color','w','Position',[120 120 720 460]);
    hold on;
% individual dots
for r = 1:length(runs)
        xjitter = runs(r) + (rand(size(dataRun,2),1)-0.5)*0.18;
        scatter(xjitter, dataRun(r,:)', 28, ...
'MarkerEdgeColor', colDots, ...
'MarkerFaceColor', 'none', ...
'LineWidth', 0.8);
end
% median + IQR
    errorbar(runs, mData, lowData, uppData, '-o', ...
'Color', colLine, ...
'LineWidth', 2.2, ...
'MarkerSize', 6, ...
'MarkerFaceColor', 'w');
    xlim([0.7 runs(end)+0.3]);
    xticks(runs);
    xlabel('Run');
    ylabel(yLabelText);
    title(figTitleText, 'FontWeight', 'bold');
    ax = gca;
    ax.LineWidth = 2.5;
    ax.FontName = 'Arial';
    ax.FontSize  = 24;
    % [ax.Box](http://ax.Box) = 'off';
    ax.TickDir = 'out';
if ~isempty(yLimits)
        ylim(yLimits);
else
        yAll = dataRun(:);
        yMin = min(yAll, [], 'omitnan');
        yMax = max(yAll, [], 'omitnan');
        pad = 0.08 * (yMax - yMin);
        ylim([yMin-pad, yMax+pad]);
end
end
function out = get_run_means(data, runSize)
    data = double(data);
    [nTrials, nSub] = size(data);
    nRuns = nTrials / runSize;
    out = nan(nRuns, nSub);
for r = 1:nRuns
        idx = (r-1)*runSize + 1 : r*runSize;
        out(r,:) = mean(data(idx,:), 1, 'omitnan');
end
end
function out = get_run_means_transfer(data, runsize_transfer)
    data = double(data);
    [nTrials, nSub] = size(data);
    nRuns = nTrials / runsize_transfer;
    out = nan(nRuns, nSub);
for r = 1:nRuns
        idx = (r-1)*runsize_transfer + 1 : r*runsize_transfer;
        out(r,:) = mean(data(idx,:), 1, 'omitnan');
end
end
function plot_run_dual_axis_with_dots(accRun, rtRun, figTitleText, accLimits, rtLimits)
% accRun' = [nRuns x nSubjects]
% rtRun'  = [nRuns x nSubjects]
    colAcc    = [0.00 0.35 0.80];
    colAccPts = [0.65 0.80 1.00];
    colRT     = [0.80 0.10 0.10];
    colRTPts  = [1.00 0.70 0.70];
    runs = 1:size(accRun,1);
    mAcc = median(accRun, 2, 'omitnan');
    lowAcc = mAcc - quantile(accRun, 0.25, 2);
    uppAcc = quantile(accRun, 0.75, 2) - mAcc;
    mRT = median(rtRun, 2, 'omitnan');
    lowRT = mRT - quantile(rtRun, 0.25, 2);
    uppRT = quantile(rtRun, 0.75, 2) - mRT;
    figure('Color','w','Position',[120 120 780 500]);
    hold on;
% -------------------------
% LEFT AXIS = ACCURACY
% -------------------------
    yyaxis left
for r = 1:length(runs)
        xjitter = runs(r) - 0.08 + (rand(size(accRun,2),1)-0.5)*0.12;
        scatter(xjitter, accRun(r,:)', 24, ...
'MarkerEdgeColor', colAccPts, ...
'MarkerFaceColor', 'none', ...
'LineWidth', 0.8);
        hold on;
end
    errorbar(runs - 0.08, mAcc, lowAcc, uppAcc, '-o', ...
'Color', colAcc, ...
'LineWidth', 2, ...
'MarkerSize', 6, ...
'MarkerFaceColor', 'w');
    ylabel('Accuracy (%)', 'Color', colAcc);
    ylim(accLimits);
% -------------------------
% RIGHT AXIS = RT
% -------------------------
    yyaxis right
for r = 1:length(runs)
        xjitter = runs(r) + 0.08 + (rand(size(rtRun,2),1)-0.5)*0.12;
        scatter(xjitter, rtRun(r,:)', 24, ...
'MarkerEdgeColor', colRTPts, ...
'MarkerFaceColor', 'none', ...
'LineWidth', 0.8);
        hold on;
end
    errorbar(runs + 0.08, mRT, lowRT, uppRT, '-s', ...
'Color', colRT, ...
'LineWidth', 2, ...
'MarkerSize', 6, ...
'MarkerFaceColor', 'w');
    ylabel('Reaction time (s)', 'Color', colRT);
    ylim(rtLimits);
% -------------------------
% AXIS STYLE
% -------------------------
    ax = gca;
    ax.LineWidth = 2.5;
    ax.FontName = 'Arial';
    ax.FontSize = 24;
    % [ax.Box](http://ax.Box) = 'off';
    ax.TickDir = 'out';
    ax.XLim = [0.7 runs(end)+0.3];
    ax.XTick = runs;
    xlabel('Run');
    title(figTitleText, 'FontWeight', 'bold');
end
