%% === COMPUTATIONAL MEASURES: LOAD DATA ===
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();

dataFile = fullfile(cfg.computationalFittedDataDir, ...
    'All_FittedParameters_Merged_withGroups.csv');
T = readtable(dataFile);
T(62, :) = []; % Exclusion of EX020_2

% Boş satır / boş grup varsa temizle
groupCol = 'Group';
grpStr = string(T.(groupCol));
T = T(~ismissing(grpStr) & strlength(strtrim(grpStr)) > 0, :);

% Grup sırası
if ~iscategorical(T.(groupCol))
    T.(groupCol) = categorical(string(T.(groupCol)));
end

desiredOrder = {'CNT','EX','EXCOG'};
presentCats  = intersect(desiredOrder, categories(T.(groupCol)), 'stable');
T.(groupCol) = reordercats(T.(groupCol), presentCats);

% Outlier ayarları
doZscoreExclusion = true;
zThr = 3;   % |z| > 3 outlier


%% === alpha_gain (log10 transform + custom y tick labels) ===
s1Col = 'alpha_gain_S1';
s2Col = 'alpha_gain_S2';

plot_3groups_2conditions_box(T, groupCol, s1Col, s2Col, ...
    "\alpha_{gain}", "alpha gain by Groups (log10)", ...
    "log10", [-4 0], doZscoreExclusion, zThr);


%% === alpha_loss (log10 transform + custom y tick labels) ===
s1Col = 'alpha_loss_S1';
s2Col = 'alpha_loss_S2';

plot_3groups_2conditions_box(T, groupCol, s1Col, s2Col, ...
    "\alpha_{loss}", "alpha loss by Groups (log10)", ...
    "log10",[-12 0], doZscoreExclusion, zThr)
% plot_alpha_loss_split_with_pairs(T, groupCol, s1Col, s2Col, ...
%     "\alpha_{loss}", "alpha loss by Groups (log10)", ...
%     [-12 0], doZscoreExclusion, zThr);

%% === beta (raw + linear axis) ===
s1Col = 'beta_S1';
s2Col = 'beta_S2';

plot_3groups_2conditions_box(T, groupCol, s1Col, s2Col, ...
    "Beta", "Beta by Groups", ...
    "none", [0 26], doZscoreExclusion, zThr);


%% ================= LOCAL FUNCTIONS =================

function plot_3groups_2conditions_box(T, groupCol, s1Col, s2Col, yLabel, ttl, transformType, yLims, doZscoreExclusion, zThr)

    if ~iscategorical(T.(groupCol))
        T.(groupCol) = categorical(T.(groupCol));
    end

    groups = categories(T.(groupCol));

    figure('Color','w');
    hold on;
    box off;

    xticks_all = [];
    xticklabels_all = {};

    fprintf('\n==============================\n');
    fprintf('%s\n', ttl);
    fprintf('==============================\n');

    for g = 1:numel(groups)

        base = 3*(g-1);
        x1 = base + 1;   % Pre
        x2 = base + 2;   % Post

        % Grup verisi
        mask = (T.(groupCol) == groups{g});
        dS1  = double(T.(s1Col)(mask));
        dS2  = double(T.(s2Col)(mask));

        % Transform
        dS1 = apply_transform(dS1, transformType);
        dS2 = apply_transform(dS2, transformType);

        % Outlier exclusion
        nOut1 = 0;
        nOut2 = 0;
        if doZscoreExclusion
            [dS1, nOut1] = exclude_outliers_zscore(dS1, zThr);
            [dS2, nOut2] = exclude_outliers_zscore(dS2, zThr);
        end

        fprintf('%s | %s: excluded = %d\n', groups{g}, s1Col, nOut1);
        fprintf('%s | %s: excluded = %d\n', groups{g}, s2Col, nOut2);

        % -------- Paired subject lines --------
        nSubj = min(numel(dS1), numel(dS2));
        for k = 1:nSubj
            if ~isnan(dS1(k)) && ~isnan(dS2(k))
                j1 = x1 + (rand - 0.5) * 0.16;
                j2 = x2 + (rand - 0.5) * 0.16;

                plot([j1 j2], [dS1(k) dS2(k)], '-', ...
                    'Color', [0.85 0.85 0.85], ...
                    'LineWidth', 1);

                plot(j1, dS1(k), 'o', ...
                    'MarkerSize', 5, ...
                    'MarkerFaceColor', [0.82 0.82 0.82], ...
                    'MarkerEdgeColor', [0.82 0.82 0.82]);

                plot(j2, dS2(k), 'o', ...
                    'MarkerSize', 5, ...
                    'MarkerFaceColor', [0.82 0.82 0.82], ...
                    'MarkerEdgeColor', [0.82 0.82 0.82]);
            end
        end

        % -------- Box plot --------
        yBox = [dS1; dS2];
        xBox = [repmat(x1, numel(dS1), 1); repmat(x2, numel(dS2), 1)];

        valid = ~isnan(yBox);
        yBox = yBox(valid);
        xBox = xBox(valid);

        if ~isempty(yBox)
            boxchart(xBox, yBox, ...
                'BoxFaceColor', 'none', ...
                'BoxEdgeColor', 'k', ...
                'WhiskerLineColor', 'k', ...
                'MarkerStyle', 'none', ...
                'LineWidth', 1.5);
        end

        % Median noktası
        if any(~isnan(dS1))
            m1 = median(dS1(~isnan(dS1)));
            plot(x1, m1, 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
        end

        if any(~isnan(dS2))
            m2 = median(dS2(~isnan(dS2)));
            plot(x2, m2, 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
        end

        % X tick labels
        xticks_all = [xticks_all, x1, x2];
        xticklabels_all{end+1} = 'Pre';
        xticklabels_all{end+1} = 'Post';
    end

    ax = gca;
    ax.LineWidth = 2.5;
    ax.FontName = 'Arial';
    ax.FontSize = 24;
    ax.TickLabelInterpreter = 'tex';

    xticks(sort(xticks_all));
    xticklabels(xticklabels_all);
    xlim([0, 3*(numel(groups)-1)+3]);

    if ~isempty(yLims)
        ylim(yLims);
    else
        ylim padded;
    end

    % Eğer veri log10-transform edildiyse, tick label'ları 10^x olarak göster
    if strcmpi(transformType, 'log10')
        if isequal(yLims, [-12 0])
            yticks([-12 -10 -8 -6 -4 -2 0])
            yticklabels({'10^{-12}','10^{-10}','10^{-8}','10^{-6}','10^{-4}','10^{-2}','10^{0}'})
        else
            yticks([-4 -3 -2 -1 0])
            yticklabels({'10^{-4}','10^{-3}','10^{-2}','10^{-1}','10^{0}'})
        end
    end

    ylabel(yLabel, 'FontSize', 24, 'FontName', 'Arial', 'Interpreter', 'tex');
    title(ttl, 'FontSize', 24, 'FontName', 'Arial');

    hold off;
end


function vOut = apply_transform(vIn, transformType)

    vOut = vIn(:);

    switch lower(transformType)
        case 'none'
            % no transform

        case 'log10'
            vOut(vOut <= 0) = NaN;
            vOut = log10(vOut);

        case 'log10_plus'
            offset = 1e-4;
            vOut(vOut < 0) = NaN;
            vOut = log10(vOut + offset);

        otherwise
            error('Unknown transformType: %s', transformType);
    end
end


function [vOut, nOut] = exclude_outliers_zscore(vIn, zThr)

    vOut = vIn(:);
    validMask = ~isnan(vOut);

    if sum(validMask) < 3
        nOut = 0;
        return;
    end

    zVals = zscore(vOut(validMask));
    outMaskLocal = abs(zVals) > zThr;

    idxValid = find(validMask);
    idxOut   = idxValid(outMaskLocal);

    vOut(idxOut) = NaN;
    nOut = numel(idxOut);
end

function plot_alpha_loss_split_with_pairs(T, groupCol, s1Col, s2Col, yLabel, ttl, yLims, doZscoreExclusion, zThr)

    if ~iscategorical(T.(groupCol))
        T.(groupCol) = categorical(string(T.(groupCol)));
    end

    groups = categories(T.(groupCol));

    figure('Color','w');
    hold on;
    box off;

    xticks_all = [];
    xticklabels_all = {};

    fprintf('\n==============================\n');
    fprintf('%s\n', ttl);
    fprintf('==============================\n');

    xOffset = 0.25;   % low vs high subgroup separation
    jitterW = 0.10;   % point jitter width

    for g = 1:numel(groups)

        base = 3*(g-1);
        x1 = base + 1;   % Pre
        x2 = base + 2;   % Post

        % subgroup x positions
        x1_low  = x1;
        x2_low  = x2 - xOffset;
        x1_high = x1;
        x2_high = x2 + xOffset;

        % -----------------------------
        % Raw group data
        % -----------------------------
        mask = (T.(groupCol) == groups{g});
        dS1 = double(T.(s1Col)(mask));
        dS2 = double(T.(s2Col)(mask));

        % -----------------------------
        % Log10 transform
        % -----------------------------
        dS1(dS1 <= 0) = NaN;
        dS2(dS2 <= 0) = NaN;

        dS1 = log10(dS1);
        dS2 = log10(dS2);

        % -----------------------------
        % Split by BASELINE (S1)
        % low  = <= -6
        % high = >  -6
        % -----------------------------
        idxLow  = dS1 <= -6;
        idxHigh = dS1 > -6;

        dS1_low  = dS1(idxLow);
        dS2_low  = dS2(idxLow);

        dS1_high = dS1(idxHigh);
        dS2_high = dS2(idxHigh);

        % -----------------------------
        % Outlier removal WITHIN each subgroup
        % -----------------------------
        nOut_low_S1  = 0;
        nOut_low_S2  = 0;
        nOut_high_S1 = 0;
        nOut_high_S2 = 0;

        if doZscoreExclusion
            [dS1_low,  nOut_low_S1]  = exclude_outliers_zscore(dS1_low,  zThr);
            [dS2_low,  nOut_low_S2]  = exclude_outliers_zscore(dS2_low,  zThr);
            [dS1_high, nOut_high_S1] = exclude_outliers_zscore(dS1_high, zThr);
            [dS2_high, nOut_high_S2] = exclude_outliers_zscore(dS2_high, zThr);
        end

        fprintf('%s | LOW  | %s excluded = %d\n', groups{g}, s1Col, nOut_low_S1);
        fprintf('%s | LOW  | %s excluded = %d\n', groups{g}, s2Col, nOut_low_S2);
        fprintf('%s | HIGH | %s excluded = %d\n', groups{g}, s1Col, nOut_high_S1);
        fprintf('%s | HIGH | %s excluded = %d\n', groups{g}, s2Col, nOut_high_S2);

        % -----------------------------
        % Paired lines + individual points
        % Here we use subgroup-specific arrays after outlier removal.
        % Pairing is preserved by position within each subgroup.
        % -----------------------------

        % LOW subgroup
        nLow = min(numel(dS1_low), numel(dS2_low));
        for k = 1:nLow
            if ~isnan(dS1_low(k)) && ~isnan(dS2_low(k))
                j1 = x1_low + (rand - 0.5) * jitterW;
                j2 = x2_low + (rand - 0.5) * jitterW;

                plot([j1 j2], [dS1_low(k) dS2_low(k)], '-', ...
                    'Color', [255 116 108]./ 255, ...
                    'LineWidth', 1);

                plot(j1, dS1_low(k), 'o', ...
                    'MarkerSize', 5, ...
                    'MarkerFaceColor', [255 116 108]./ 255, ...
                    'MarkerEdgeColor', [255 116 108]./ 255);

                plot(j2, dS2_low(k), 'o', ...
                    'MarkerSize', 5, ...
                    'MarkerFaceColor', [255 116 108]./ 255, ...
                    'MarkerEdgeColor', [255 116 108]./ 255);
            end
        end

        % HIGH subgroup
        nHigh = min(numel(dS1_high), numel(dS2_high));
        for k = 1:nHigh
            if ~isnan(dS1_high(k)) && ~isnan(dS2_high(k))
                j1 = x1_high + (rand - 0.5) * jitterW;
                j2 = x2_high + (rand - 0.5) * jitterW;

                plot([j1 j2], [dS1_high(k) dS2_high(k)], '-', ...
                    'Color', [0.85 0.85 0.85], ...
                    'LineWidth', 1);

                plot(j1, dS1_high(k), 'o', ...
                    'MarkerSize', 5, ...
                    'MarkerFaceColor', [0.82 0.82 0.82], ...
                    'MarkerEdgeColor', [0.82 0.82 0.82]);

                plot(j2, dS2_high(k), 'o', ...
                    'MarkerSize', 5, ...
                    'MarkerFaceColor', [0.82 0.82 0.82], ...
                    'MarkerEdgeColor', [0.82 0.82 0.82]);
            end
        end

        % -----------------------------
        % Box plots
        % -----------------------------
        if any(~isnan(dS1_low))
            boxchart(repmat(x1_low, sum(~isnan(dS1_low)), 1), dS1_low(~isnan(dS1_low)), ...
                'BoxFaceColor', 'none', ...
                'BoxEdgeColor', 'k', ...
                'WhiskerLineColor', 'k', ...
                'MarkerStyle', 'none', ...
                'LineWidth', 1.5);
        end

        if any(~isnan(dS2_low))
            boxchart(repmat(x2_low, sum(~isnan(dS2_low)), 1), dS2_low(~isnan(dS2_low)), ...
                'BoxFaceColor', 'none', ...
                'BoxEdgeColor', 'k', ...
                'WhiskerLineColor', 'k', ...
                'MarkerStyle', 'none', ...
                'LineWidth', 1.5);
        end

        if any(~isnan(dS1_high))
            boxchart(repmat(x1_high, sum(~isnan(dS1_high)), 1), dS1_high(~isnan(dS1_high)), ...
                'BoxFaceColor', 'none', ...
                'BoxEdgeColor', 'k', ...
                'WhiskerLineColor', 'k', ...
                'MarkerStyle', 'none', ...
                'LineWidth', 1.5);
        end

        if any(~isnan(dS2_high))
            boxchart(repmat(x2_high, sum(~isnan(dS2_high)), 1), dS2_high(~isnan(dS2_high)), ...
                'BoxFaceColor', 'none', ...
                'BoxEdgeColor', 'k', ...
                'WhiskerLineColor', 'k', ...
                'MarkerStyle', 'none', ...
                'LineWidth', 1.5);
        end

        % -----------------------------
        % Median points
        % -----------------------------
        if any(~isnan(dS1_low))
            plot(x1_low, median(dS1_low(~isnan(dS1_low))), 'ks', ...
                'MarkerFaceColor', 'k', 'MarkerSize', 7);
        end

        if any(~isnan(dS2_low))
            plot(x2_low, median(dS2_low(~isnan(dS2_low))), 'ks', ...
                'MarkerFaceColor', 'k', 'MarkerSize', 7);
        end

        if any(~isnan(dS1_high))
            plot(x1_high, median(dS1_high(~isnan(dS1_high))), 'ks', ...
                'MarkerFaceColor', 'k', 'MarkerSize', 7);
        end

        if any(~isnan(dS2_high))
            plot(x2_high, median(dS2_high(~isnan(dS2_high))), 'ks', ...
                'MarkerFaceColor', 'k', 'MarkerSize', 7);
        end

        % -----------------------------
        % Main x tick labels stay centered
        % -----------------------------
        xticks_all = [xticks_all, x1, x2];
        xticklabels_all{end+1} = 'Pre';
        xticklabels_all{end+1} = 'Post';
    end

    ax = gca;
    ax.LineWidth = 2.5;
    ax.FontName = 'Arial';
    ax.FontSize = 24;
    ax.TickLabelInterpreter = 'tex';

    xticks(sort(xticks_all));
    xticklabels(xticklabels_all);
    xlim([0, 3*(numel(groups)-1)+3]);

    if ~isempty(yLims)
        ylim(yLims);
    else
        ylim padded;
    end

    yticks([-12 -10 -8 -6 -4 -2 0])
    yticklabels({'10^{-12}','10^{-10}','10^{-8}','10^{-6}','10^{-4}','10^{-2}','10^{0}'})

    ylabel(yLabel, 'FontSize', 24, 'FontName', 'Arial', 'Interpreter', 'tex');
    title(ttl, 'FontSize', 24, 'FontName', 'Arial');

    hold off;
end
