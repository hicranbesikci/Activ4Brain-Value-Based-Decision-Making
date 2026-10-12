clc; clear;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();
dataFile = fullfile(cfg.behavioralGroupDataDir, ...
    'SPSS_Table_learning_1vs2ndSession_V5.xlsx');

%% === VERİYİ YÜKLE ===
T = readtable(dataFile, "Sheet", "Sheet1");
T(62,:) = []; %Exclusion of EX020_2 (=EX076)
%% Accuracy

% Coloumn Names
groupCol = 'Group';
s1Col    = 'Mean_Accuracy_Learning_S1';
s2Col    = 'Mean_Accuracy_Learning_S2';
perfCol  = 'Performers_Accuracy';

% To fix Group order
if ~iscategorical(T.(groupCol)), T.(groupCol)=categorical(T.(groupCol)); end
T.(groupCol) = reordercats(T.(groupCol), {'CNT','EX','EXCOG'});  

% Plot
plot_3groups_2conditions(T, groupCol, s1Col, s2Col, perfCol, ...
    "Accuracy (%)", "Learning Phase Accuracy by Groups");


function plot_3groups_2conditions(T, groupCol, s1Col, s2Col, perfCol, yLabel, ttl)
    % Güvenlik: beklenen categorical
    if ~iscategorical(T.(groupCol)), T.(groupCol)=categorical(T.(groupCol)); end

    groups = categories(T.(groupCol));   % ex: {'CNT','EX','EXCOG'}

    figure('Color','w'); box off; hold on;

    % X positions: for each group Pre (x: base+1), Post (base+2)
    % base = 3*(g-1)  --> Group1: 1..2 / Group2: 4..5 / Group3: 7..8
    xticks_all = [];
    xticklabels_all = {};

    for g = 1:numel(groups)
        base = 3*(g-1);

        % Group data
        mask = (T.(groupCol)==groups{g});
        dS1  = T.(s1Col)(mask);
        dS2  = T.(s2Col)(mask);
        dPerf = T.(perfCol)(mask);

        % Mean/SEM
        [m1,se1] = mean_sem(dS1);
        [m2,se2] = mean_sem(dS2);

        % X positions (Pre, Post)
        x1 = base + 1;
        x2 = base + 2;

        % Participants' matching lines
        n = min([numel(dS1), numel(dS2), numel(dPerf)]);
        for k = 1:n
            if ~isnan(dS1(k)) && ~isnan(dS2(k))
                c = get_perf_color(dPerf(k));
                plot([x1+rand*0.2-0.1, x2+rand*0.2-0.1], [dS1(k), dS2(k)], '-o', ...
                    'Color', c, ...
                    'MarkerEdgeColor', c, ...
                    'MarkerFaceColor', c, ...
                    'MarkerSize', 6, ...
                    'LineWidth', 0.8);
            end
        end

        barColor = [0 0 0];

        % Bar + SEM
        bar([x1 x2], [m1 m2], ...
            'FaceColor','none', ...
            'EdgeColor',barColor, ...
            'LineWidth',1.5, ...
            'BarWidth',0.6, ...
            'FaceAlpha',0.7);

        errorbar([x1 x2], [m1 m2], [se1 se2], '.', ...
            'Color','k', 'LineWidth',1.5);

        % X tick / label (for each group Pre, Post)
        xticks_all = [xticks_all, x1, x2];
        xticklabels_all{end+1} = 'Pre';  
        xticklabels_all{end+1} = 'Post'; 
    end

    % Format
    ax = gca;
    ax.LineWidth = 2.5;
    ax.FontName = 'Arial';
    ax.FontSize  = 24;
    ax.TickLabelInterpreter = 'none';
    xticks(sort(xticks_all));
    xticklabels(xticklabels_all);
    % xtickangle(45);
    xlim([0, 3*(numel(groups)-1)+3]);  % a little further to the side of the last block
    ylim([20 100]);
    ylabel(yLabel, 'FontSize', 24, 'FontName', 'Arial');
    title(ttl, 'FontSize', 24, 'FontName', 'Arial');

    hold off;
end


function [m,se] = mean_sem(v)
    v = v(:);
    v = v(~isnan(v));
    n = numel(v);
    if n==0
        m = NaN; se = NaN;
    else
        m = mean(v);
        se = std(v)/sqrt(n);
    end
end


%% Reaction Time

% Coloumn Names
groupCol = 'Group';
s1Col    = 'Mean_RT_Learning_S1';
s2Col    = 'Mean_RT_Learning_S2';
perfCol  = 'Performers_Learning';

% To fix Group order
if ~iscategorical(T.(groupCol)), T.(groupCol)=categorical(T.(groupCol)); end
T.(groupCol) = reordercats(T.(groupCol), {'CNT','EX','EXCOG'});  

% Plot
plot_3groups_2conditions_RT(T, groupCol, s1Col, s2Col, perfCol, ...
    "Reaction Time (s)", "Learning Phase Mean RT by Groups");


function plot_3groups_2conditions_RT(T, groupCol, s1Col, s2Col, perfCol, yLabel, ttl)
    % Güvenlik: beklenen categorical
    if ~iscategorical(T.(groupCol)), T.(groupCol)=categorical(T.(groupCol)); end

    groups = categories(T.(groupCol));   % örn: {'CNT','EX','EXCOG'}

    figure('Color','w'); box off; hold on;

    % X positions: for each group Pre (x: base+1), Post (base+2)
    % base = 3*(g-1)  --> Group1: 1..2 / Group2: 4..5 / Group3: 7..8
    xticks_all = [];
    xticklabels_all = {};

    for g = 1:numel(groups)
        base = 3*(g-1);

        % Group data
        mask = (T.(groupCol)==groups{g});
        dS1  = T.(s1Col)(mask) / 1000;   % ms -> s
        dS2  = T.(s2Col)(mask) / 1000;   % ms -> s
        dPerf = T.(perfCol)(mask);

        % Mean/SEM
        [m1,se1] = mean_sem_RT(dS1);
        [m2,se2] = mean_sem_RT(dS2);

        % X positions (Pre, Post)
        x1 = base + 1;
        x2 = base + 2;

        % Participants' matching lines
        n = min([numel(dS1), numel(dS2), numel(dPerf)]);
        for k = 1:n
            if ~isnan(dS1(k)) && ~isnan(dS2(k))
                c = get_perf_color(dPerf(k));
                plot([x1+rand*0.2-0.1, x2+rand*0.2-0.1], [dS1(k), dS2(k)], '-o', ...
                    'Color', c, ...
                    'MarkerEdgeColor', c, ...
                    'MarkerFaceColor', c, ...
                    'MarkerSize', 6, ...
                    'LineWidth', 0.8);
            end
        end

        barColor = [0 0 0];

        % Bar + SEM
        bar([x1 x2], [m1 m2], ...
            'FaceColor','none', ...
            'EdgeColor',barColor, ...
            'LineWidth',1.5, ...
            'BarWidth',0.6, ...
            'FaceAlpha',0.7);

        errorbar([x1 x2], [m1 m2], [se1 se2], '.', ...
            'Color','k', 'LineWidth',1.5);

        % X tick / label (for each group Pre, Post)
        xticks_all = [xticks_all, x1, x2];
        xticklabels_all{end+1} = 'Pre'; 
        xticklabels_all{end+1} = 'Post'; 
    end

    % Format
    ax = gca;
    ax.LineWidth = 2.5;
    ax.FontName = 'Arial';
    ax.FontSize  = 24;
    ax.TickLabelInterpreter = 'none';
    xticks(sort(xticks_all));
    xticklabels(xticklabels_all);
    % xtickangle(45);
    xlim([0, 3*(numel(groups)-1)+3]);  % a little further to the side of the last block
    ylim padded;
    ylabel(yLabel, 'FontSize', 24, 'FontName', 'Arial');
    title(ttl, 'FontSize', 24, 'FontName', 'Arial');

    hold off;
end


function [m,se] = mean_sem_RT(v)
    v = v(:);
    v = v(~isnan(v));
    n = numel(v);
    if n==0
        m = NaN; se = NaN;
    else
        m = mean(v);
        se = std(v)/sqrt(n);
    end
end


%% Variability of RT

% Coloumn Names
groupCol = 'Group';
s1Col    = 'Mean_stdRT_Learning_S1';
s2Col    = 'Mean_stdRT_Learning_S2';
perfCol  = 'Performers_stdRT';

% To fix Group order
if ~iscategorical(T.(groupCol)), T.(groupCol)=categorical(T.(groupCol)); end
T.(groupCol) = reordercats(T.(groupCol), {'CNT','EX','EXCOG'});  

% Plot
plot_3groups_2conditions_stdRT(T, groupCol, s1Col, s2Col, perfCol, ...
    "Reaction Time SD (s)", "Learning Phase Mean RT SD by Groups");

%% Statistics 

T = readtable(dataFile, "Sheet", "Sheet1");
T(62,:) = []; %Exclusion of EX020_2 (=EX076)
groupCol = 'Group';

if ~iscategorical(T.(groupCol))
    T.(groupCol) = categorical(T.(groupCol));
end

T.(groupCol) = reordercats(T.(groupCol), {'CNT','EX','EXCOG'});

% Accuracy
run_paired_ttest_by_group(T, groupCol, ...
    'Mean_Accuracy_Learning_S1', 'Mean_Accuracy_Learning_S2', ...
    'Accuracy', '%');

% RT
run_paired_ttest_by_group(T, groupCol, ...
    'Mean_RT_Learning_S1', 'Mean_RT_Learning_S2', ...
    'Reaction Time', 'ms');

% stdRT
run_paired_ttest_by_group(T, groupCol, ...
    'Mean_stdRT_Learning_S1', 'Mean_stdRT_Learning_S2', ...
    'Reaction Time Variability', 'ms');


%% Local Functions
function plot_3groups_2conditions_stdRT(T, groupCol, s1Col, s2Col, perfCol, yLabel, ttl)
    % security: expected categorical
    if ~iscategorical(T.(groupCol)), T.(groupCol)=categorical(T.(groupCol)); end

    groups = categories(T.(groupCol));   % example: {'CNT','EX','EXCOG'}

    figure('Color','w'); box off; hold on;

    % X position: for each group ; Pre (x: base+1), Post (base+2)
    % base = 3*(g-1)  --> Group1: 1..2 / Group2: 4..5 / Group3: 7..8
    xticks_all = [];
    xticklabels_all = {};

    for g = 1:numel(groups)
        base = 3*(g-1);

        % Group data 
        mask = (T.(groupCol)==groups{g});
        dS1  = T.(s1Col)(mask) / 1000;   % ms -> s
        dS2  = T.(s2Col)(mask) / 1000;   % ms -> s
        dPerf = T.(perfCol)(mask);

        % Mean/SEM
        [m1,se1] = mean_sem_stdRT(dS1);
        [m2,se2] = mean_sem_stdRT(dS2);

        % X positions (Pre, Post)
        x1 = base + 1;
        x2 = base + 2;

        % Participants' match lines
        n = min([numel(dS1), numel(dS2), numel(dPerf)]);
        for k = 1:n
            if ~isnan(dS1(k)) && ~isnan(dS2(k))
                c = get_perf_color(dPerf(k));
                plot([x1+rand*0.2-0.1, x2+rand*0.2-0.1], [dS1(k), dS2(k)], '-o', ...
                    'Color', c, ...
                    'MarkerEdgeColor', c, ...
                    'MarkerFaceColor', c, ...
                    'MarkerSize', 6, ...
                    'LineWidth', 0.8);
            end
        end

        barColor = [0 0 0];

        % Bar + SEM
        bar([x1 x2], [m1 m2], ...
            'FaceColor','none', ...
            'EdgeColor',barColor, ...
            'LineWidth',1.5, ...
            'BarWidth',0.6, ...
            'FaceAlpha',0.7);

        errorbar([x1 x2], [m1 m2], [se1 se2], '.', ...
            'Color','k', 'LineWidth',1.5);

        % X tick / label (for each group Pre, Post)
        xticks_all = [xticks_all, x1, x2];
        xticklabels_all{end+1} = 'Pre';  
        xticklabels_all{end+1} = 'Post';
    end

    % Format
    ax = gca;
    ax.LineWidth = 2.5;
    ax.FontName = 'Arial';
    ax.FontSize  = 24;
    ax.TickLabelInterpreter = 'none';
    xticks(sort(xticks_all));
    xticklabels(xticklabels_all);
    % xtickangle(45);
    xlim([0, 3*(numel(groups)-1)+3]);  % a little further to the side of the last block
    ylim([0 0.75]);   % 750 ms -> 0.75 s
    ylabel(yLabel, 'FontSize', 24, 'FontName', 'Arial');
    title(ttl, 'FontSize', 24, 'FontName', 'Arial');

    hold off;
end


function [m,se] = mean_sem_stdRT(v)
    v = v(:);
    v = v(~isnan(v));
    n = numel(v);
    if n==0
        m = NaN; se = NaN;
    else
        m = mean(v);
        se = std(v)/sqrt(n);
    end
end


function c = get_perf_color(perfValue)
    perfValue = upper(strtrim(string(perfValue)));

    if perfValue == "HP"
        c = [0.55 0.75 1.00];   % light blue
    elseif perfValue == "LP"
        c = [1.00 0.55 0.55];   % light red 
    else
        c = [0.75 0.75 0.75];   % gray
    end
end

function run_paired_ttest_by_group(T, groupCol, s1Col, s2Col, measureName, unitText)

    if ~iscategorical(T.(groupCol))
        T.(groupCol) = categorical(T.(groupCol));
    end

    groups = categories(T.(groupCol));

    fprintf('\n================ %s: Paired t-test (Pre vs Post) ================\n', measureName);

    for g = 1:numel(groups)
        mask = T.(groupCol) == groups{g};

        x = T.(s1Col)(mask);
        y = T.(s2Col)(mask);

        valid = ~isnan(x) & ~isnan(y);
        x = x(valid);
        y = y(valid);

        if numel(x) >= 2
            [h,p,ci,stats] = ttest(x, y);

            fprintf('\nGroup: %s\n', groups{g});
            fprintf('n = %d\n', numel(x));
            fprintf('Pre mean = %.3f %s, Post mean = %.3f %s\n', mean(x), unitText, mean(y), unitText);
            fprintf('t(%d) = %.3f, p = %.5f\n', stats.df, stats.tstat, p);
            fprintf('95%% CI of difference = [%.3f, %.3f]\n', ci(1), ci(2));
        else
            fprintf('\nGroup: %s --> not enough data for t-test\n', groups{g});
        end
    end
end
