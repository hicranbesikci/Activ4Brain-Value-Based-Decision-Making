%% =========================================================
%  ACCURACY: BL vs FU AND DELTA ACC OF TRAINED TASKS CORRELATION WITH DELTA RT OF RL TASK
%  Tasks: RTT, MTT, WMT (only statistically significant ones)
%% =========================================================

clear; clc; close all;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();
accOutputDir = fullfile(cfg.outputDir, 'Acc_Analysis');
if ~isfolder(accOutputDir), mkdir(accOutputDir); end

%% File names
file_RTT = fullfile(accOutputDir, 'results_table_RTT.mat');
file_MTT = fullfile(accOutputDir, 'results_table_MTT.mat');
file_WMT = fullfile(accOutputDir, 'results_table_WMT.mat');

%% Load tables
tbl_RTT = load_first_table_from_mat(file_RTT);
tbl_MTT = load_first_table_from_mat(file_MTT);
tbl_WMT = load_first_table_from_mat(file_WMT);

%% Extract BL-FU Accuracy pairs
ACC_RTT = get_pair(tbl_RTT, 'Accuracy_S1', 'Accuracy_S2');
ACC_MTT = get_pair(tbl_MTT, 'Accuracy_S1', 'Accuracy_S2');
ACC_WMT = get_pair(tbl_WMT, 'Accuracy_S1', 'Accuracy_S2');

taskNames = {'SPT','SAT','WMT'};
accDataCell = {ACC_RTT, ACC_MTT, ACC_WMT};

%% Calculate mean delta values of accuracy of trained tasks
deltaACC_RTT = ACC_RTT(:,2) - ACC_RTT(:,1);
deltaACC_MTT = ACC_MTT(:,2) - ACC_MTT(:,1);
deltaACC_WMT = ACC_WMT(:,2) - ACC_WMT(:,1);

mean_deltaACC_RTT = mean(deltaACC_RTT);
mean_deltaACC_MTT = mean(deltaACC_MTT);
mean_deltaACC_WMT = mean(deltaACC_WMT);

% Store mean delta values in a structured format for further analysis
meanDeltaACC = struct('RTT', mean_deltaACC_RTT, 'MTT', mean_deltaACC_MTT, ...
    'WMT', mean_deltaACC_WMT);


%% =================== 1) RL VERISINI YUKLE ============================
rl_file = fullfile(cfg.behavioralGroupDataDir, ...
    'SPSS_Table_learning_1vs2ndSession_V5.xlsx');

% Activ4Brain group label 
group_label_excog = 'EXCOG';

% Which RL phase for correlation? 'Learning' or 'Transfer'
rl_phase = 'Learning';

% Trained tasks (for ACC data)
tasks = {'SPT', 'SAT', 'WMT'};

RL = readtable(rl_file);
RL(end,:) = []; %EX076 excluded from the analysis

% Only EXCOG group
RL = RL(strcmp(RL.Group, group_label_excog), :);

% Katilimci ID sutununu standardize et: Parts_Code (learning) varsa onu,
% yoksa Parts_Code2 (transfer) sutununu kullan
if ismember('Parts_Code', RL.Properties.VariableNames)
    RL.ID = RL.Parts_Code;
elseif ismember('Parts_Code2', RL.Properties.VariableNames)
    RL.ID = RL.Parts_Code2;
else
    error('Parts_Code or Parts_Code2 coloumn could not be found in RL file.');
end

% Select RT coloumn according to the phase
rt_s1_col = sprintf('Mean_RT_%s_S1', rl_phase);
rt_s2_col = sprintf('Mean_RT_%s_S2', rl_phase);
RL.RT_S1 = RL.(rt_s1_col);
RL.RT_S2 = RL.(rt_s2_col);

fprintf('RL (%s phase): %d EXCOG participant was loaded.\n', rl_phase, height(RL));

% RL RT change (post - pre)
dRT_RL = RL.RT_S2 - RL.RT_S1;
dRT_RL4MTT(:,1) = dRT_RL(1:20,1); %excluded EX70 bcs we dont have MTT data of that participant
%% =================== 7) NORMALITY (Lilliefors) =======================
[h_acc_rtt, p_rtt] = lillietest(deltaACC_RTT);
[h_acc_mtt, p_mtt] = lillietest(deltaACC_MTT);
[h_acc_wmt, p_wmt] = lillietest(deltaACC_WMT);

[h_rl, p_rl] = lillietest(dRT_RL);
[h_rlmtt, p_rlmtt] = lillietest(dRT_RL4MTT);

fprintf('Normality (Lilliefors):\n');

fprintf('  dACC_RTT: h=%d, p=%.3f\n', h_acc_rtt, p_rtt);
fprintf('  dACC_MTT: h=%d, p=%.3f\n', h_acc_mtt, p_mtt);
fprintf('  dACC_WMT: h=%d, p=%.3f\n', h_acc_wmt, p_wmt);

fprintf('  dRT_RL : h=%d, p=%.3f\n\n', h_rl, p_rl);
fprintf('  dRT_RL4MTT : h=%d, p=%.3f\n\n', h_rlmtt, p_rlmtt);

%% =================== 8) CORRELATIONS ================================
% RTT - RT
[r_rtt,   p_pearson_rtt]  = corr(deltaACC_RTT, dRT_RL, 'Type', 'Pearson',  'Rows', 'complete');
[rho_rtt, p_spearman_rtt] = corr(deltaACC_RTT, dRT_RL, 'Type', 'Spearman', 'Rows', 'complete');

% For Pearson %95 CI (Fisher z)
ok     = ~isnan(deltaACC_RTT) & ~isnan(dRT_RL);
n_rtt  = sum(ok);
se     = 1 / sqrt(n_rtt - 3);
z      = atanh(r_rtt);
r_lo_rtt = tanh(z - 1.96*se);
r_hi_rtt = tanh(z + 1.96*se);

fprintf('Correlation between dACC_RTT and dRT_RL (EXCOG, n=%d):\n', n_rtt);
fprintf('  Pearson  r   = %.3f, 95%% CI [%.3f, %.3f], p = %.4f\n', ...
    r_rtt, r_lo_rtt, r_hi_rtt, p_pearson_rtt);
fprintf('  Spearman rho = %.3f, p = %.4f\n\n', rho_rtt, p_spearman_rtt);


% MTT - RT
[r_mtt,   p_pearson_mtt]  = corr(deltaACC_MTT, dRT_RL4MTT, 'Type', 'Pearson',  'Rows', 'complete');
[rho_mtt, p_spearman_mtt] = corr(deltaACC_MTT, dRT_RL4MTT, 'Type', 'Spearman', 'Rows', 'complete');

% For Pearson %95 CI (Fisher z)
ok     = ~isnan(deltaACC_MTT) & ~isnan(dRT_RL4MTT);
n_mtt  = sum(ok);
z    = atanh(r_mtt);
se   = 1 / sqrt(n_mtt - 3);
r_lo_mtt = tanh(z - 1.96 * se);
r_hi_mtt = tanh(z + 1.96 * se);

fprintf('Correlation between dACC_MTT and dRT_RL (EXCOG, n=%d):\n', n_mtt);
fprintf('  Pearson  r   = %.3f, 95%% CI [%.3f, %.3f], p = %.4f\n', ...
    r_mtt, r_lo_mtt, r_hi_mtt, p_pearson_mtt);
fprintf('  Spearman rho = %.3f, p = %.4f\n\n', rho_mtt, p_spearman_mtt);

% WMT - RT
[r_wmt,   p_pearson_wmt]  = corr(deltaACC_WMT, dRT_RL, 'Type', 'Pearson',  'Rows', 'complete');
[rho_wmt, p_spearman_wmt] = corr(deltaACC_WMT, dRT_RL, 'Type', 'Spearman', 'Rows', 'complete');

% For Pearson %95 CI (Fisher z)
ok     = ~isnan(deltaACC_WMT) & ~isnan(dRT_RL);
n_wmt  = sum(ok);
z    = atanh(r_wmt);
se   = 1 / sqrt(n_wmt - 3);
r_lo_wmt = tanh(z - 1.96 * se);
r_hi_wmt = tanh(z + 1.96 * se);

fprintf('Correlation between dACC_WMT and dRT_RL (EXCOG, n=%d):\n', n_wmt);
fprintf('  Pearson  r   = %.3f, 95%% CI [%.3f, %.3f], p = %.4f\n', ...
    r_wmt, r_lo_wmt, r_hi_wmt, p_pearson_wmt);
fprintf('  Spearman rho = %.3f, p = %.4f\n\n', rho_wmt, p_spearman_wmt);

% Correlation significance treshold
alphaCorr = 0.05;
%% =================== 10) SCATTER PLOT =============================

% RTT - RT
figure('Color', 'w', 'Position', [100 100 620 520]);
scatter(deltaACC_RTT, dRT_RL, 80, 'filled', ...
    'MarkerFaceColor', [0.20 0.45 0.75], ...
    'MarkerFaceAlpha', 0.75, ...
    'MarkerEdgeColor', 'k');
hold on;

ok = ~isnan(deltaACC_RTT) & ~isnan(dRT_RL);
if sum(ok) >= 3 && p_pearson_rtt < alphaCorr
    p_fit = polyfit(deltaACC_RTT(ok), dRT_RL(ok), 1);
    x_fit = linspace(min(deltaACC_RTT(ok)), max(deltaACC_RTT(ok)), 100);
    plot(x_fit, polyval(p_fit, x_fit), 'r-', 'LineWidth', 2);
end

xlabel('\Delta ACC SPT [post - pre]', 'FontSize', 12);
ylabel(sprintf('\\Delta RT (RL %s) [post - pre]', lower(rl_phase)), ...
    'FontSize', 12);
title(sprintf('Activ4Brain (n=%d): Pearson r = %.3f, p = %.3f', ...
    n_rtt, r_rtt, p_pearson_rtt), 'FontSize', 13);
grid on; box on;
set(gca, 'FontSize', 12);

% saveas(gcf, out_fig_name);

% MTT - RT

figure('Color', 'w', 'Position', [100 100 620 520]);
scatter(deltaACC_MTT, dRT_RL4MTT, 80, 'filled', ...
    'MarkerFaceColor', [0.20 0.45 0.75], ...
    'MarkerFaceAlpha', 0.75, ...
    'MarkerEdgeColor', 'k');
hold on;

ok = ~isnan(deltaACC_MTT) & ~isnan(dRT_RL4MTT);
if sum(ok) >= 3 && p_pearson_mtt < alphaCorr
    p_fit = polyfit(deltaACC_MTT(ok), dRT_RL4MTT(ok), 1);
    x_fit = linspace(min(deltaACC_MTT(ok)), max(deltaACC_MTT(ok)), 100);
    y_fit = polyval(p_fit, x_fit);
    plot(x_fit, y_fit, 'r-', 'LineWidth', 2);
end

xlabel('\Delta ACC SAT [post - pre]', 'FontSize', 12);
ylabel(sprintf('\\Delta RT (RL %s) [post - pre]', lower(rl_phase)), ...
    'FontSize', 12);
title(sprintf('Activ4Brain (n=%d): Pearson r = %.3f, p = %.3f', ...
    n_mtt, r_mtt, p_pearson_mtt), 'FontSize', 13);
grid on; box on;
set(gca, 'FontSize', 12);

% WMT - RT

figure('Color', 'w', 'Position', [100 100 620 520]);
scatter(deltaACC_WMT, dRT_RL, 80, 'filled', ...
    'MarkerFaceColor', [0.20 0.45 0.75], ...
    'MarkerFaceAlpha', 0.75, ...
    'MarkerEdgeColor', 'k');
hold on;

ok = ~isnan(deltaACC_WMT) & ~isnan(dRT_RL);
if sum(ok) >= 3 && p_pearson_wmt < alphaCorr
    p_fit = polyfit(deltaACC_WMT(ok), dRT_RL(ok), 1);
    x_fit = linspace(min(deltaACC_WMT(ok)), max(deltaACC_WMT(ok)), 100);
    y_fit = polyval(p_fit, x_fit);
    plot(x_fit, y_fit, 'r-', 'LineWidth', 2);
end

xlabel('\Delta ACC WMT [post - pre]', 'FontSize', 12);
ylabel(sprintf('\\Delta RT (RL %s) [post - pre]', lower(rl_phase)), ...
    'FontSize', 12);
title(sprintf('Activ4Brain (n=%d): Pearson r = %.3f, p = %.3f', ...
    n_wmt, r_wmt, p_pearson_wmt), 'FontSize', 13);
grid on; box on;
set(gca, 'FontSize', 12);
%% =========================================================
% LOCAL FUNCTIONS
%% =========================================================

function tbl = load_first_table_from_mat(matFile)
    S = load(matFile);
    fns = fieldnames(S);

    tbl = [];
    for i = 1:numel(fns)
        if istable(S.(fns{i}))
            tbl = S.(fns{i});
            return;
        end
    end

    error('No table variable found in file: %s', matFile);
end

function pairData = get_pair(tbl, colBL, colFU)

    if ~ismember(colBL, tbl.Properties.VariableNames)
        error('Column "%s" not found.', colBL);
    end
    if ~ismember(colFU, tbl.Properties.VariableNames)
        error('Column "%s" not found.', colFU);
    end

    x1 = force_numeric_column(tbl.(colBL));
    x2 = force_numeric_column(tbl.(colFU));

    pairData = [x1 x2];
end

function x = force_numeric_column(x)

    if istable(x)
        x = table2array(x);
    end

    if iscell(x)
        x = cellfun(@double, x);
    end

    if isstring(x) || ischar(x)
        x = str2double(x);
    end

    x = double(x(:));
end
