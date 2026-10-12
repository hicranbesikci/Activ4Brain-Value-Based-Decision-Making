%% Correlate average MT change (trained tasks) vs RL RT change (untrained) in EXCOG group
% -------------------------------------------------------------------------
% For each participant in the EXCOG (Activ4Brain) group:
%   dMT_AVG = mean across trained tasks of (MT_S2 - MT_S1)
%             tasks: SPT, ICT, SAT, NDT      (from MTdata_cogtraining.mat)
%   dRT_RL  = Mean_RT_Learning_S2 - Mean_RT_Learning_S1   (from Excel)
% Then: match participants across the two files by ID and correlate.
%
% Negative dMT / dRT = faster post-training (the desirable direction).
% -------------------------------------------------------------------------

clear; clc; close all;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();
accOutputDir = fullfile(cfg.outputDir, 'Acc_Analysis');
if ~isfolder(accOutputDir), mkdir(accOutputDir); end

%% ---------- 1. SET FILE PATHS ------------------------------------------
mtFile = fullfile(cfg.accAnalysisDataDir, 'MTdata_cogtraining.mat');
xlsFile = fullfile(cfg.behavioralGroupDataDir, ...
    'SPSS_Table_learning_1vs2ndSession_V5.xlsx');

xlsSheet  = 'Sheet1';
outFigure = fullfile(accOutputDir, 'corr_MTavg_RL_RT_new.png');
outCsv = fullfile(accOutputDir, 'corr_MTavg_RL_RT_data_new.csv');

% Trained tasks to average across
tasks = {'SPT', 'ICT', 'SAT', 'NDT'};

% Column-name pattern in the MT table: 'MT_<TASK>_S1' / 'MT_<TASK>_S2'
fmt_s1 = 'MT_%s_S1';
fmt_s2 = 'MT_%s_S2';

%% ---------- 2. LOAD MT FILE & COMPUTE dMT_AVG --------------------------
S = load(mtFile);
var_names = fieldnames(S);

% Find the MATLAB table inside the .mat file
mtTbl = [];
for i = 1:numel(var_names)
    if istable(S.(var_names{i}))
        mtTbl = S.(var_names{i});
        fprintf('MT table loaded from variable: %s\n', var_names{i});
        break;
    end
end

assert(~isempty(mtTbl), 'No MATLAB table found inside %s', mtFile);

% Diagnostic: print column names on first run
fprintf('\n--- MT table columns ---\n');
disp(mtTbl.Properties.VariableNames');

% Locate ID column
candidate_id_cols = {'Parts_Code', 'Parts_Code2', 'ParticipantID', 'label', 'ID'};
id_col = '';

for i = 1:numel(candidate_id_cols)
    if ismember(candidate_id_cols{i}, mtTbl.Properties.VariableNames)
        id_col = candidate_id_cols{i};
        break;
    end
end

assert(~isempty(id_col), 'Could not find an ID column in the MT table.');
fprintf('Using ID column: %s\n\n', id_col);

% Check that all expected MT columns exist
for k = 1:numel(tasks)
    s1_col = sprintf(fmt_s1, tasks{k});
    s2_col = sprintf(fmt_s2, tasks{k});

    assert(ismember(s1_col, mtTbl.Properties.VariableNames), ...
        'MT table is missing column: %s', s1_col);

    assert(ismember(s2_col, mtTbl.Properties.VariableNames), ...
        'MT table is missing column: %s', s2_col);
end

% Per-task dMT and baseline MT
nRows               = height(mtTbl);
dMT_perTask         = nan(nRows, numel(tasks));
MT_baseline_perTask = nan(nRows, numel(tasks));

for k = 1:numel(tasks)
    s1_col = sprintf(fmt_s1, tasks{k});
    s2_col = sprintf(fmt_s2, tasks{k});

    dMT_perTask(:, k)         = mtTbl.(s2_col) - mtTbl.(s1_col);
    MT_baseline_perTask(:, k) = mtTbl.(s1_col);
end

mtIDs           = double(mtTbl.(id_col)(:));
dMT_AVG         = mean(dMT_perTask, 2, 'omitnan');
MT_baseline_avg = mean(MT_baseline_perTask, 2, 'omitnan');

% Drop NaNs from MT side
keepMT          = ~isnan(mtIDs) & ~isnan(dMT_AVG) & ~isnan(MT_baseline_avg);
mtIDs           = mtIDs(keepMT);
dMT_AVG         = dMT_AVG(keepMT);
MT_baseline_avg = MT_baseline_avg(keepMT);
dMT_perTask     = dMT_perTask(keepMT, :);

fprintf('MT   : %d participants with valid dMT averaged across %d tasks\n', ...
    numel(mtIDs), numel(tasks));

mtChangeTbl = table(mtIDs, dMT_AVG, MT_baseline_avg, ...
    'VariableNames', {'ParticipantID','dMT_AVG','BaseMT_AVG'});

%% ---------- 3. LOAD EXCEL & COMPUTE dRT_RL FOR EXCOG GROUP -------------
opts = detectImportOptions(xlsFile, 'Sheet', xlsSheet);

% Force the columns we care about to the right types
opts = setvartype(opts, 'Parts_Code',          'double');
opts = setvartype(opts, 'Group',               'string');
opts = setvartype(opts, 'Mean_RT_Learning_S1', 'double');
opts = setvartype(opts, 'Mean_RT_Learning_S2', 'double');

rlTbl = readtable(xlsFile, opts);

% Keep EXCOG only
grp     = upper(strtrim(string(rlTbl.Group)));
isExcog = grp == "EXCOG";
rlTbl   = rlTbl(isExcog, :);

rlIDs  = double(rlTbl.Parts_Code(:));
baseRL = rlTbl.Mean_RT_Learning_S1(:);
dRT_RL = rlTbl.Mean_RT_Learning_S2(:) - rlTbl.Mean_RT_Learning_S1(:);

% Drop NaNs from RL side
keepRL = ~isnan(rlIDs) & ~isnan(baseRL) & ~isnan(dRT_RL);
rlIDs  = rlIDs(keepRL);
baseRL = baseRL(keepRL);
dRT_RL = dRT_RL(keepRL);

fprintf('RL   : %d EXCOG participants with valid RT change\n', numel(rlIDs));

rlChangeTbl = table(rlIDs, baseRL, dRT_RL, ...
    'VariableNames', {'ParticipantID','BaseRT_RL','dRT_RL'});

%% ---------- 4. MATCH PARTICIPANTS ACROSS THE TWO FILES -----------------
[commonIDs, iMt, iRl] = intersect( ...
    mtChangeTbl.ParticipantID, ...
    rlChangeTbl.ParticipantID, ...
    'stable');

x = mtChangeTbl.dMT_AVG(iMt);       % delta MT, mean across trained tasks
y = rlChangeTbl.dRT_RL(iRl);        % delta RT for RL, untrained task

baseMT_match = mtChangeTbl.BaseMT_AVG(iMt);
baseRL_match = rlChangeTbl.BaseRT_RL(iRl);

dMT_matched = dMT_perTask(iMt, :);

n = numel(commonIDs);

fprintf('Matched participants in both files and EXCOG group: n = %d\n\n', n);

if n < 3
    error('Not enough matched participants (n=%d) to run a correlation.', n);
end

%% ---------- 5. NORMALITY CHECK -----------------------------------------
% Lilliefors test is appropriate when mean and SD are estimated from data.
[hX, pX] = lillietest(x);
[hY, pY] = lillietest(y);

fprintf('Normality check with Lilliefors test:\n');
fprintf('   dMT_AVG : h = %d, p = %.3f\n', hX, pX);
fprintf('   dRT_RL  : h = %d, p = %.3f\n', hY, pY);

%% ---------- 6. PEARSON & SPEARMAN CORRELATIONS -------------------------
[rP, pP, rPlo, rPhi] = corrcoef(x, y);

r_pearson  = rP(1,2);
p_pearson  = pP(1,2);
ci_pearson = [rPlo(1,2), rPhi(1,2)];

[r_spearman, p_spearman] = corr(x, y, 'Type', 'Spearman');

fprintf('\nCorrelation between dMT_AVG and dRT_RL in EXCOG group, n = %d:\n', n);
fprintf('  Pearson r = %.3f, 95%% CI [%.3f, %.3f], p = %.4f\n', ...
        r_pearson, ci_pearson(1), ci_pearson(2), p_pearson);
fprintf('  Spearman rho = %.3f, p = %.4f\n', ...
        r_spearman, p_spearman);

%% ---------- 6b. DRAW TREND LINE ONLY IF SIGNIFICANT --------------------
alphaCorr = 0.05;
drawTrend = p_pearson < alphaCorr;

if drawTrend
    fprintf('\nPearson correlation is significant. Trend line will be drawn.\n');
else
    fprintf('\nPearson correlation is not significant. Trend line will NOT be drawn.\n');
end

%% ---------- 7. SCATTER PLOT --------------------------------------------
figure('Color','w','Position',[100 100 720 620]);

scatter(x, y, 105, 'filled', 'MarkerFaceAlpha', 0.7);
hold on;

% Draw trend line only if Pearson correlation is significant
if drawTrend
    b  = polyfit(x, y, 1);
    xx = linspace(min(x), max(x), 100);
    plot(xx, polyval(b, xx), 'k-', 'LineWidth', 2.5);
end

xline(0, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5);
yline(0, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5);

xlim([-200 200]);
ylim([-500 500]);
axis square;

xlabel('\DeltaMT mean trained tasks (S2 - S1, ms)', ...
    'FontName', 'Arial', ...
    'FontSize', 24);

ylabel('\DeltaRT RL (S2 - S1, ms)', ...
    'FontName', 'Arial', ...
    'FontSize', 24);

% title(sprintf(['EXCOG group: trained tasks mean \\DeltaMT vs untrained RL  (n = %d)\n', ...
%                'Pearson r = %.2f, p = %.3f   |   Spearman \\rho = %.2f, p = %.3f'], ...
%                n, r_pearson, p_pearson, r_spearman, p_spearman), ...
%       'FontWeight', 'bold', ...
%       'FontName', 'Arial', ...
%       'FontSize', 18);

grid off;
box on;

ax = gca;
ax.LineWidth = 2.5;
ax.FontName = 'Arial';
ax.FontSize = 24;

exportgraphics(gcf, outFigure, 'Resolution', 300);
fprintf('\nFigure saved to: %s\n', outFigure);

%% ---------- 8. SAVE PER-PARTICIPANT TABLE ------------------------------
outTbl = table(commonIDs, x, y, baseMT_match, baseRL_match, ...
    'VariableNames', {'ParticipantID','dMT_AVG','dRT_RL','BaseMT_AVG','BaseRT_RL'});

% Also include per-task dMT for downstream sanity checks
for k = 1:numel(tasks)
    outTbl.(sprintf('dMT_%s', tasks{k})) = dMT_matched(:, k);
end

writetable(outTbl, outCsv);
fprintf('Per-participant data saved to: %s\n', outCsv);

%% ---------- 9. OPTIONAL PARTIAL CORRELATION CONTROLLING FOR BASELINE ----
% Change scores can be confounded by baseline performance.
% Here we control for mean baseline MT and RL baseline RT.

[rPart, pPart] = partialcorr(x, y, [baseMT_match, baseRL_match]);

fprintf('\nPartial correlation controlling for mean MT baseline and RL baseline:\n');
fprintf('  r_partial = %.3f, p = %.4f\n', rPart, pPart);
