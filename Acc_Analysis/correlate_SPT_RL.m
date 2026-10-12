%% Correlate SPT (trained) vs RL (untrained) reaction-time change in EXCOG group
% -------------------------------------------------------------------------
% For each participant in the EXCOG group:
%   dRT_SPT = RT_S2 - RT_S1   (from results_table_RTT.mat)
%   dRT_RL  = Mean_RT_Learning_S2 - Mean_RT_Learning_S1  (from Excel)
% Then: match participants across the two files by ID and correlate.
%
% Negative dRT = faster post-training (the desirable direction).
% -------------------------------------------------------------------------

clear; clc; close all;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();
accOutputDir = fullfile(cfg.outputDir, 'Acc_Analysis');
if ~isfolder(accOutputDir), mkdir(accOutputDir); end

%% ---------- 1. SET FILE PATHS ------------------------------------------
sptFile = fullfile(accOutputDir, 'results_table_RTT.mat');
xlsFile = fullfile(cfg.behavioralGroupDataDir, ...
    'SPSS_Table_learning_1vs2ndSession_V5.xlsx');

xlsSheet  = 'Sheet1';
outFigure = fullfile(accOutputDir, 'corr_SPT_RL_RT_new.png');
outCsv = fullfile(accOutputDir, 'corr_SPT_RL_RT_data_new.csv');

%% ---------- 2. LOAD SPT FILE & COMPUTE dRT_SPT -------------------------
S = load(sptFile);                       
sptTbl = S.results_table_RTT;

% Required columns
reqSpt = {'ParticipantID','RT_all_S1','RT_all_S2'};
assert(all(ismember(reqSpt, sptTbl.Properties.VariableNames)), ...
    'SPT table is missing one of: %s', strjoin(reqSpt, ', '));

sptIDs   = double(sptTbl.ParticipantID(:));
baseSPT  = sptTbl.RT_all_S1(:);
dRT_SPT  = sptTbl.RT_all_S2(:) - sptTbl.RT_all_S1(:);

% Drop NaNs from SPT
keepSpt  = ~isnan(sptIDs) & ~isnan(baseSPT) & ~isnan(dRT_SPT);
sptIDs   = sptIDs(keepSpt);
baseSPT  = baseSPT(keepSpt);
dRT_SPT  = dRT_SPT(keepSpt);

fprintf('SPT  : %d participants with valid RT_S2-RT_S1\n', numel(sptIDs));

sptChangeTbl = table(sptIDs, baseSPT, dRT_SPT, ...
    'VariableNames', {'ParticipantID','BaseRT_SPT','dRT_SPT'});

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

% Drop NaNs from RL
keepRl = ~isnan(rlIDs) & ~isnan(baseRL) & ~isnan(dRT_RL);
rlIDs  = rlIDs(keepRl);
baseRL = baseRL(keepRl);
dRT_RL = dRT_RL(keepRl);

fprintf('RL   : %d EXCOG participants with valid RT change\n', numel(rlIDs));

rlChangeTbl = table(rlIDs, baseRL, dRT_RL, ...
    'VariableNames', {'ParticipantID','BaseRT_RL','dRT_RL'});

%% ---------- 4. MATCH PARTICIPANTS ACROSS THE TWO FILES -----------------
[commonIDs, iSpt, iRl] = intersect( ...
    sptChangeTbl.ParticipantID, ...
    rlChangeTbl.ParticipantID, ...
    'stable');

x = sptChangeTbl.dRT_SPT(iSpt);     % delta RT for SPT, trained task
y = rlChangeTbl.dRT_RL(iRl);        % delta RT for RL, untrained task

baseSPT_match = sptChangeTbl.BaseRT_SPT(iSpt);
baseRL_match  = rlChangeTbl.BaseRT_RL(iRl);

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
fprintf('   dRT_SPT : h = %d, p = %.3f\n', hX, pX);
fprintf('   dRT_RL  : h = %d, p = %.3f\n', hY, pY);

%% ---------- 6. PEARSON & SPEARMAN CORRELATIONS -------------------------
[rP, pP, rPlo, rPhi] = corrcoef(x, y);

r_pearson  = rP(1,2);
p_pearson  = pP(1,2);
ci_pearson = [rPlo(1,2), rPhi(1,2)];

[r_spearman, p_spearman] = corr(x, y, 'Type', 'Spearman');

fprintf('\nCorrelation between dRT_SPT and dRT_RL in EXCOG group, n = %d:\n', n);
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
    plot(xx, polyval(b, xx), 'k-', 'LineWidth', 1.5);
end

xline(0, '--', 'Color', [0.5 0.5 0.5]);
yline(0, '--', 'Color', [0.5 0.5 0.5]);

xlim([-200 200]);
ylim([-500 500]);

axis square;

xlabel('\DeltaRT SPT (S2 - S1, ms)', 'FontName', 'Arial', 'FontSize', 24);
ylabel('\DeltaRT RL (S2 - S1, ms)',  'FontName', 'Arial', 'FontSize', 24);

% title(sprintf(['EXCOG group: trained SPT vs untrained RL  (n = %d)\n', ...
%                'Pearson r = %.2f, p = %.3f   |   Spearman \\rho = %.2f, p = %.3f'], ...
%                n, r_pearson, p_pearson, r_spearman, p_spearman), ...
%       'FontWeight', 'bold');

grid off;
box on;

ax = gca;
ax.LineWidth = 2.5;
ax.FontName = 'Arial';
ax.FontSize = 24;



exportgraphics(gcf, outFigure, 'Resolution', 300);
fprintf('\nFigure saved to: %s\n', outFigure);

%% ---------- 8. SAVE PER-PARTICIPANT TABLE ------------------------------
outTbl = table(commonIDs, x, y, baseSPT_match, baseRL_match, ...
    'VariableNames', {'ParticipantID','dRT_SPT','dRT_RL','BaseRT_SPT','BaseRT_RL'});

writetable(outTbl, outCsv);
fprintf('Per-participant data saved to: %s\n', outCsv);

%% ---------- 9. OPTIONAL PARTIAL CORRELATION CONTROLLING FOR BASELINE ----
% Change scores can be confounded by baseline performance.
% Here we control for SPT baseline RT and RL baseline RT.

[rPart, pPart] = partialcorr(x, y, [baseSPT_match, baseRL_match]);

fprintf('\nPartial correlation controlling for SPT and RL baselines:\n');
fprintf('  r_partial = %.3f, p = %.4f\n', rPart, pPart);
