clear; close all; clc
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();
accOutputDir = fullfile(cfg.outputDir, 'Acc_Analysis');
if ~isfolder(accOutputDir), mkdir(accOutputDir); end

eeglab;

%% =========================
% STYLE
%% =========================
set(groot, 'defaultAxesFontName', 'Arial');
set(groot, 'defaultAxesFontSize', 12);

%% =========================
% LOAD FILES
%% =========================
folder_path = cfg.accDataDir;
file_list = dir(fullfile(folder_path, '*RTT*.mat'));

% Exclude participant EX020 from analysis
exclude_files = {'EX020_Session1_RTT.mat', 'EX020_Session2_RTT.mat'};
file_list = file_list(~ismember({file_list.name}, exclude_files));

fprintf('Number of total files: %d\n', length(file_list));

%% =========================
% RESULTS TABLE
% Added:
% - RT_all_S1 / RT_all_S2
% - MT_all_S1 / MT_all_S2
% - ET_all_S1 / ET_all_S2
%
% NOTE:
% Stored in milliseconds in table, converted to seconds only for plots
%% =========================
results_table_RTT = table('Size', [0, 27], ...
    'VariableTypes', {'string', ...
                      'double', 'double', 'double', ...
                      'double', 'double', 'double', ...
                      'double', 'double', 'double', ...
                      'double', 'double', 'double', 'double', ...
                      'double', 'double', 'double', ...
                      'double', 'double', 'double', ...
                      'double', 'double', 'double', ...
                      'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'ParticipantID', ...
                      'Number_correct_S1', 'Number_incorrect_S1', 'Number_without_S1', ...
                      'RT_correct_S1', 'RT_incorrect_S1', ...
                      'MT_correct_S1', 'MT_incorrect_S1', ...
                      'ET_correct_S1', 'ET_incorrect_S1', ...
                      'Accuracy_S1', 'RT_all_S1', 'MT_all_S1', 'ET_all_S1', ...
                      'Number_correct_S2', 'Number_incorrect_S2', 'Number_without_S2', ...
                      'RT_correct_S2', 'RT_incorrect_S2', ...
                      'MT_correct_S2', 'MT_incorrect_S2', ...
                      'ET_correct_S2', 'ET_incorrect_S2', ...
                      'Accuracy_S2', 'RT_all_S2', 'MT_all_S2', 'ET_all_S2'});

participants_map = containers.Map();

%% =========================
% MAIN LOOP
%% =========================
for i = 1:length(file_list)
    current_file = file_list(i).name;
    fprintf('\nProcessing: %s\n', current_file);

    try
        data_struct = load(fullfile(folder_path, current_file));
        data_matrix = data_struct.data;
        labels = data_struct.labels;

        % Generate triggers
        trig = convert_BIOPAC_triggers(data_matrix, labels);

        % Prepare EEGLAB data
        acc_data4eeglab = zeros(7, size(data_matrix, 1));
        acc_data4eeglab(1:6, :) = data_matrix(:, 1:6)';
        acc_data4eeglab(7, :) = trig';

        EEG = pop_importdata('dataformat','array','nbchan',0,'data','acc_data4eeglab', ...
            'setname','acc_data4eeglab','srate',500,'pnts',0,'xmin',0);
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0, 'gui', 'off');

        EEG = eeg_checkset(EEG);
        EEG = pop_chanevent(EEG, 7, 'edge', 'leading', 'edgelen', 0);
        [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

        EEG = pop_epoch(EEG, {'1' '2' '3' '4' '11' '12' '13' '14'}, [-0.1 2], ...
            'newname', 'acc_data4eeglab_epochs', 'epochinfo', 'yes');
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, [], 'gui', 'off');

        EEG = pop_rmbase(EEG, [-100 0]);
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, [], 'gui', 'off');

        if EEG.trials == 0
            error('No valid epoch found.');
        end

        limites_tempo = EEG.times <= 3000;
        ordem_canais = [1 3 5 2 4 6];
        n_epochs = EEG.trials;

        stimulus_codes = [1, 2, 3, 4, 11, 12, 13, 14];
        response_codes = [61, 62, 63, 64, 41, 42, 43, 44];

        reaction_times_all = nan(n_epochs, 6);
        execution_times = nan(n_epochs, 1);
        min_reaction_time = nan(n_epochs, 1);
        movement_times = nan(n_epochs, 1);   % NEW
        resposta_status = strings(n_epochs, 1);

        for trl = 1:n_epochs
            max_esquerdo = 0;
            max_direito = 0;

            for j = 1:6
                ch = ordem_canais(j);

                pre_estimulo = EEG.times >= -100 & EEG.times < 0;
                baseline = mean(EEG.data(ch, pre_estimulo, trl), 2);

                tempo = EEG.times(limites_tempo);
                signal = abs(EEG.data(ch, limites_tempo, trl) - baseline);

                baseline_std = std(EEG.data(ch, pre_estimulo, trl));
                threshold = mean(baseline) + 8 * baseline_std;
                search_range = find(tempo >= 0);

                for k = 1:(length(search_range) - 1)
                    if signal(search_range(k)) > threshold
                        reaction_times_all(trl, j) = tempo(search_range(k));
                        break;
                    end
                end

                amplitude = max(signal);
                if j <= 3
                    max_esquerdo = max(max_esquerdo, amplitude);
                else
                    max_direito = max(max_direito, amplitude);
                end
            end

            if max_esquerdo > max_direito
                min_reaction_time(trl) = nanmin(reaction_times_all(trl, 1:3));
            else
                min_reaction_time(trl) = nanmin(reaction_times_all(trl, 4:6));
            end

            tipo_eventos = EEG.epoch(trl).eventtype;
            latencia_eventos = EEG.epoch(trl).eventlatency;

            if iscell(tipo_eventos)
                tipo_eventos = cell2mat(tipo_eventos);
            end
            if iscell(latencia_eventos)
                latencia_eventos = cell2mat(latencia_eventos);
            end

            idx_resposta = find(ismember(tipo_eventos, response_codes), 1);

            if isempty(idx_resposta)
                resposta_status(trl) = "Without Answer";
                continue;
            else
                execution_times(trl) = latencia_eventos(idx_resposta);
            end

            % NEW: trial-level MT
            if ~isnan(execution_times(trl)) && ~isnan(min_reaction_time(trl))
                movement_times(trl) = execution_times(trl) - min_reaction_time(trl);
            end

            estimulo = tipo_eventos(ismember(tipo_eventos, stimulus_codes));
            resposta = tipo_eventos(idx_resposta);

            expected_idx = find(stimulus_codes == estimulo, 1);
            expected_response = response_codes(expected_idx);

            if resposta == expected_response
                resposta_status(trl) = "Correct";
            else
                resposta_status(trl) = "Incorrect";
            end
        end

        %% =========================
        % SUMMARIES
        %% =========================
        correct_answers = sum(resposta_status == "Correct");
        incorrect_answers = sum(resposta_status == "Incorrect");
        without_answer = sum(resposta_status == "Without Answer");

        % Correct / incorrect separated
        rt_correct = min_reaction_time(resposta_status == "Correct");
        rt_incorrect = min_reaction_time(resposta_status == "Incorrect");

        mt_correct = movement_times(resposta_status == "Correct");
        mt_incorrect = movement_times(resposta_status == "Incorrect");

        et_correct = execution_times(resposta_status == "Correct");
        et_incorrect = execution_times(resposta_status == "Incorrect");

        % Overall answered trials: Correct + Incorrect, excluding misses
        answered_idx = resposta_status ~= "Without Answer";

        rt_answered = min_reaction_time(answered_idx);
        mt_answered = movement_times(answered_idx);
        et_answered = execution_times(answered_idx);

        rt_median_all = median(rt_answered, 'omitnan');
        mt_median_all = median(mt_answered, 'omitnan');
        et_median_all = median(et_answered, 'omitnan');

        rt_median_correct = median(rt_correct, 'omitnan');
        rt_median_incorrect = median(rt_incorrect, 'omitnan');

        mt_median_correct = median(mt_correct, 'omitnan');
        mt_median_incorrect = median(mt_incorrect, 'omitnan');

        et_median_correct = median(et_correct, 'omitnan');
        et_median_incorrect = median(et_incorrect, 'omitnan');

        % Participant / session extraction
        tokens = regexp(current_file, '^EX(\d+)_Session(\d)_RTT\.mat$', 'tokens');

        if isempty(tokens)
            fprintf('Filename format not matched: %s\n', current_file);
            continue;
        end

        participant_number = tokens{1}{1};
        session_number = str2double(tokens{1}{2});

        accuracy = (correct_answers / (correct_answers + incorrect_answers + without_answer)) * 100;

        sess_data = struct( ...
            'correct', correct_answers, ...
            'incorrect', incorrect_answers, ...
            'without', without_answer, ...
            'accuracy', accuracy, ...
            'rt_all', rt_median_all, ...
            'mt_all', mt_median_all, ...
            'et_all', et_median_all, ...
            'rt_correct', rt_median_correct, ...
            'rt_incorrect', rt_median_incorrect, ...
            'mt_correct', mt_median_correct, ...
            'mt_incorrect', mt_median_incorrect, ...
            'et_correct', et_median_correct, ...
            'et_incorrect', et_median_incorrect ...
        );

        if isKey(participants_map, participant_number)
            p = participants_map(participant_number);
        else
            p = cell(1,2);
        end

        p{session_number} = sess_data;
        participants_map(participant_number) = p;

    catch ME
        fprintf('Error processing %s: %s\n', current_file, ME.message);
        continue;
    end
end

%% =========================
% BUILD FINAL TABLE
%% =========================
participant_ID = keys(participants_map);

for i = 1:length(participant_ID)
    ID = participant_ID{i};
    session = participants_map(ID);

    if numel(session) < 2 || isempty(session{1}) || isempty(session{2})
        fprintf('Skipping participant %s because one session is missing.\n', ID);
        continue;
    end

    row = { ...
        ID, ...
        session{1}.correct, session{1}.incorrect, session{1}.without, ...
        session{1}.rt_correct, session{1}.rt_incorrect, ...
        session{1}.mt_correct, session{1}.mt_incorrect, ...
        session{1}.et_correct, session{1}.et_incorrect, ...
        session{1}.accuracy, session{1}.rt_all, session{1}.mt_all, session{1}.et_all, ...
        session{2}.correct, session{2}.incorrect, session{2}.without, ...
        session{2}.rt_correct, session{2}.rt_incorrect, ...
        session{2}.mt_correct, session{2}.mt_incorrect, ...
        session{2}.et_correct, session{2}.et_incorrect, ...
        session{2}.accuracy, session{2}.rt_all, session{2}.mt_all, session{2}.et_all};

    results_table_RTT = [results_table_RTT; row];
end

results_table_RTT = sortrows(results_table_RTT, 'ParticipantID');
disp(results_table_RTT);
save(fullfile(accOutputDir, 'results_table_RTT.mat'), 'results_table_RTT');

%% =========================
% STATISTICS FOR FINAL PLOTS
%% =========================
fprintf('\nBaseline vs Follow-up:\n');
fprintf('----------------------\n');

[~, p_acc] = ttest(results_table_RTT.Accuracy_S1, results_table_RTT.Accuracy_S2);
fprintf('Accuracy: p = %.6f\n', p_acc);

valid_rt = ~isnan(results_table_RTT.RT_all_S1) & ~isnan(results_table_RTT.RT_all_S2);
[~, p_rt] = ttest(results_table_RTT.RT_all_S1(valid_rt), results_table_RTT.RT_all_S2(valid_rt));
fprintf('RT (all answered trials): p = %.6f\n', p_rt);

valid_mt = ~isnan(results_table_RTT.MT_all_S1) & ~isnan(results_table_RTT.MT_all_S2);
[~, p_mt] = ttest(results_table_RTT.MT_all_S1(valid_mt), results_table_RTT.MT_all_S2(valid_mt));
fprintf('MT (all answered trials): p = %.6f\n', p_mt);

valid_et = ~isnan(results_table_RTT.ET_all_S1) & ~isnan(results_table_RTT.ET_all_S2);
[~, p_et] = ttest(results_table_RTT.ET_all_S1(valid_et), results_table_RTT.ET_all_S2(valid_et));
fprintf('ET (all answered trials): p = %.6f\n', p_et);

%% =========================
% BASELINE VS FOLLOW-UP PLOTS
% Convert ms -> s for time plots
%% =========================
acc_pair = [results_table_RTT.Accuracy_S1, results_table_RTT.Accuracy_S2];

rt_pair = [results_table_RTT.RT_all_S1(valid_rt), results_table_RTT.RT_all_S2(valid_rt)] / 1000;
mt_pair = [results_table_RTT.MT_all_S1(valid_mt), results_table_RTT.MT_all_S2(valid_mt)] / 1000;
et_pair = [results_table_RTT.ET_all_S1(valid_et), results_table_RTT.ET_all_S2(valid_et)] / 1000;

% Accuracy
plot_BL_FU_style_gray( ...
    acc_pair, ...
    'Accuracy (%)', ...
    'Speed Processing Task - Accuracy', ...
    [0 100]);
saveas(gcf, fullfile(accOutputDir, 'SpeedProcessing_Accuracy_BLvsFU.png'));

% RT (seconds)
plot_BL_FU_style_gray( ...
    rt_pair, ...
    'Reaction Time (s)', ...
    'Speed Processing Task - Reaction Time', ...
    []);
saveas(gcf, fullfile(accOutputDir, 'SpeedProcessing_RT_BLvsFU_seconds.png'));

% MT (seconds)
plot_BL_FU_style_gray( ...
    mt_pair, ...
    'Movement Time (s)', ...
    'Speed Processing Task - Movement Time', ...
    []);
saveas(gcf, fullfile(accOutputDir, 'SpeedProcessing_MT_BLvsFU_seconds.png'));

% ET (seconds)
plot_BL_FU_style_gray( ...
    et_pair, ...
    'Execution Time (s)', ...
    'Speed Processing Task - Execution Time', ...
    []);
saveas(gcf, fullfile(accOutputDir, 'SpeedProcessing_ET_BLvsFU_seconds.png'));

%% =========================
% LOCAL FUNCTIONS
%% =========================
function plot_BL_FU_style_gray(dataPair, yLabel, ttl, yLimits)

    figure('Color','w');
    box off;
    hold on;

    barColor = [0 0 0];
    dotColor = [0.65 0.65 0.65];
    lineColor = [0.75 0.75 0.75];

    x1 = 1;
    x2 = 2;

    % Median + SEM
    [m1,se1] = median_sem_local(dataPair(:,1));
    [m2,se2] = median_sem_local(dataPair(:,2));

    % Individual paired lines and dots
    n = size(dataPair,1);
    for k = 1:n
        if ~isnan(dataPair(k,1)) && ~isnan(dataPair(k,2))
            plot([x1+rand*0.2-0.1, x2+rand*0.2-0.1], ...
                 [dataPair(k,1), dataPair(k,2)], '-o', ...
                'Color', lineColor, ...
                'MarkerEdgeColor', dotColor, ...
                'MarkerFaceColor', dotColor, ...
                'MarkerSize', 6, ...
                'LineWidth', 0.8);
        end
    end

    % Empty bars
    bar([x1 x2], [m1 m2], ...
        'FaceColor','none', ...
        'EdgeColor',barColor, ...
        'LineWidth',1.5, ...
        'BarWidth',0.6);

    % Error bars
    errorbar([x1 x2], [m1 m2], [se1 se2], '.', ...
        'Color','k', 'LineWidth',1.5);

    % Axis format
    ax = gca;
    ax.LineWidth = 2.5;
    ax.FontName = 'Arial';
    ax.FontSize = 24;
    ax.TickDir = 'out';
    ax.Box = 'off';

    xticks([1 2]);
    xticklabels({'BL','FU'});
    xlim([0 3]);

    if ~isempty(yLimits)
        ylim(yLimits);
    else
        yAll = dataPair(:);
        yMin = min(yAll, [], 'omitnan');
        yMax = max(yAll, [], 'omitnan');
        pad = 0.08 * (yMax - yMin);
        if pad == 0 || isnan(pad)
            pad = max(0.05 * abs(yMax), 0.05);
        end
        ylim([yMin-pad, yMax+pad]);
    end

    ylabel(yLabel, 'FontSize', 24, 'FontName', 'Arial');
    title(ttl, 'FontSize', 24, 'FontName', 'Arial');

    hold off;
end

function [m,se] = median_sem_local(v)
    v = v(:);
    v = v(~isnan(v));

    n = numel(v);
    if n == 0
        m = NaN;
        se = NaN;
    else
        m = median(v);
        se = std(v) / sqrt(n);
    end
end

%% =========================
%  RTT FIGURES (BL vs FU)
% ==========================

% Pair data (convert ms → s)
dataPair_ACC = [results_table.Accuracy_S1, results_table.Accuracy_S2];
dataPair_RT  = [results_table.RT_S1/1000, results_table.RT_S2/1000];
dataPair_MT  = [results_table.MT_S1/1000, results_table.MT_S2/1000];
dataPair_ET  = [results_table.ET_S1/1000, results_table.ET_S2/1000];

% Accuracy
plot_BL_FU_style(dataPair_ACC, ...
    'Accuracy (%)', ...
    'Speed Processing - Accuracy', []);

% RT
plot_BL_FU_style(dataPair_RT, ...
    'Time (s)', ...
    'Speed Processing - Reaction Time', []);

% MT
plot_BL_FU_style(dataPair_MT, ...
    'Time (s)', ...
    'Speed Processing - Movement Time', []);

% ET
plot_BL_FU_style(dataPair_ET, ...
    'Time (s)', ...
    'Speed Processing - Execution Time', []);
