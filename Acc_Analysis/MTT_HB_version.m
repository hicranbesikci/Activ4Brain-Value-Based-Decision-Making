clear; close all; clc
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();
accOutputDir = fullfile(cfg.outputDir, 'Acc_Analysis');
if ~isfolder(accOutputDir), mkdir(accOutputDir); end

eeglab;

%% =========================
% MTT TASK ANALYSIS
% No correct / incorrect split
% ICT-like structure
% =========================
%One participant is missing bcs we lost the data from 1st session (EX070)

folder_path = cfg.accDataDir;
file_list = dir(fullfile(folder_path, '*MTT*.mat'));

% Exclude participant EX020 from analysis
exclude_files = {'EX020_Session1_MTT.mat', 'EX020_Session2_MTT.mat'};
file_list = file_list(~ismember({file_list.name}, exclude_files));

fprintf('Number of total files: %d\n', length(file_list));

%% Final results table
results_table = table('Size', [0, 15], ...
    'VariableTypes', {'string', ...
                      'double', 'double', 'double', ...
                      'double', 'double', 'double', 'double', ...
                      'double', 'double', 'double', ...
                      'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'ParticipantID', ...
                      'Number_correct_S1', 'Number_incorrect_S1', 'Number_without_S1', ...
                      'RT_S1', 'MT_S1', 'ET_S1', 'Accuracy_S1', ...
                      'Number_correct_S2', 'Number_incorrect_S2', 'Number_without_S2', ...
                      'RT_S2', 'MT_S2', 'ET_S2', 'Accuracy_S2'});

participants_map = containers.Map();

%% =========================
% EVENT DEFINITIONS
% Adjust only if your MTT codes are different
% =========================
stimulus_codes = [1, 2, 3, 4, 11, 12, 13, 14];
response_codes = [61, 62, 63, 64, 41, 42, 43, 44];

%% =========================
% MAIN LOOP
% =========================
for i = 1:length(file_list)
    current_file = file_list(i).name;
    fprintf('\nProcessing: %s\n', current_file);

    try
        data_struct = load(fullfile(folder_path, current_file));
        data_matrix = data_struct.data;
        labels = data_struct.labels;

        % Generate triggers
        trig = convert_BIOPAC_triggers(data_matrix, labels);

        % Prepare data for EEGLAB
        acc_data4eeglab = zeros(7, size(data_matrix, 1));
        acc_data4eeglab(1:6, :) = data_matrix(:, 1:6)';
        acc_data4eeglab(7, :) = trig';

        EEG = pop_importdata('dataformat','array','nbchan',0,'data','acc_data4eeglab', ...
            'setname','acc_data4eeglab','srate',500,'pnts',0,'xmin',0);
        [ALLEEG, EEG, CURRENTSET] = pop_newset([], EEG, 0, 'gui', 'off');

        EEG = eeg_checkset(EEG);
        EEG = pop_chanevent(EEG, 7, 'edge', 'leading', 'edgelen', 0);
        [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

        EEG = pop_epoch(EEG, {'1' '2' '3' '4' '11' '12' '13' '14'}, [-0.1 3], ...
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

        reaction_times_all = nan(n_epochs, 6);
        execution_times = nan(n_epochs, 1);
        min_reaction_time = nan(n_epochs, 1);
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

                for k = 1:length(search_range)
                    if signal(search_range(k)) > threshold
                        reaction_times_all(trl, j) = tempo(search_range(k));
                        break;
                    end
                end

                amplitude = max(signal, [], 'omitnan');
                if j <= 3
                    max_esquerdo = max(max_esquerdo, amplitude);
                else
                    max_direito = max(max_direito, amplitude);
                end
            end

            % Select response leg based on largest movement amplitude
            if max_esquerdo > max_direito
                min_reaction_time(trl) = min(reaction_times_all(trl, 1:3), [], 'omitnan');
            else
                min_reaction_time(trl) = min(reaction_times_all(trl, 4:6), [], 'omitnan');
            end

            % Event information
            tipo_eventos = EEG.epoch(trl).eventtype;
            latencia_eventos = EEG.epoch(trl).eventlatency;

            % eventtype -> numeric
            if iscell(tipo_eventos)
                tipo_eventos = cellfun(@convert_to_numeric, tipo_eventos);
            elseif isnumeric(tipo_eventos)
                tipo_eventos = double(tipo_eventos);
            else
                tipo_eventos = convert_to_numeric(tipo_eventos);
            end

            % eventlatency -> numeric
            if iscell(latencia_eventos)
                latencia_eventos = cellfun(@convert_to_numeric, latencia_eventos);
            elseif isnumeric(latencia_eventos)
                latencia_eventos = double(latencia_eventos);
            else
                latencia_eventos = convert_to_numeric(latencia_eventos);
            end

            tipo_eventos = double(tipo_eventos(:))';
            latencia_eventos = double(latencia_eventos(:))';

            idx_resposta = find(ismember(tipo_eventos, response_codes), 1, 'first');

            if isempty(idx_resposta)
                resposta_status(trl) = "Without Answer";
                continue;
            else
                execution_times(trl) = latencia_eventos(idx_resposta);
            end

            idx_estimulo = find(ismember(tipo_eventos, stimulus_codes), 1, 'first');

            if isempty(idx_estimulo)
                resposta_status(trl) = "Without Answer";
                continue;
            end

            estimulo = tipo_eventos(idx_estimulo);
            resposta = tipo_eventos(idx_resposta);

            expected_idx = find(stimulus_codes == estimulo, 1);

            if isempty(expected_idx)
                resposta_status(trl) = "Without Answer";
                continue;
            end

            expected_response = response_codes(expected_idx);

            if resposta == expected_response
                resposta_status(trl) = "Correct";
            else
                resposta_status(trl) = "Incorrect";
            end
        end

        %% Session summary
        correct_answers   = sum(resposta_status == "Correct");
        incorrect_answers = sum(resposta_status == "Incorrect");
        without_answer    = sum(resposta_status == "Without Answer");

        % Use all answered trials (correct + incorrect), exclude misses
        valid_idx = resposta_status ~= "Without Answer";

        rt_all = min_reaction_time(valid_idx);
        et_all = execution_times(valid_idx);
        mt_all = et_all - rt_all;

        rt_median = median(rt_all, 'omitnan');
        mt_median = median(mt_all, 'omitnan');
        et_median = median(et_all, 'omitnan');

        accuracy = (correct_answers / (correct_answers + incorrect_answers + without_answer)) * 100;

        % Filename structure example:
        % EX001_Session1_MTT.mat
        tokens = regexp(current_file, '^EX(\d+)_Session(\d)_MTT\.mat$', 'tokens');

        if isempty(tokens)
            fprintf('Filename format not matched: %s\n', current_file);
            continue;
        end

        participant_number = tokens{1}{1};
        session_number = str2double(tokens{1}{2});

        sess_data = struct( ...
            'correct', correct_answers, ...
            'incorrect', incorrect_answers, ...
            'without', without_answer, ...
            'accuracy', accuracy, ...
            'rt', rt_median, ...
            'mt', mt_median, ...
            'et', et_median);

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
% FINAL TABLE
% =========================
participant_ID = keys(participants_map);

for i = 1:length(participant_ID)
    ID = participant_ID{i};
    session = participants_map(ID);

    if numel(session) < 2 || isempty(session{1}) || isempty(session{2})
        continue;
    end

    row = { ...
        string(ID), ...
        session{1}.correct, session{1}.incorrect, session{1}.without, ...
        session{1}.rt, session{1}.mt, session{1}.et, session{1}.accuracy, ...
        session{2}.correct, session{2}.incorrect, session{2}.without, ...
        session{2}.rt, session{2}.mt, session{2}.et, session{2}.accuracy};

    results_table = [results_table; row];
end

results_table = sortrows(results_table, 'ParticipantID');
disp(results_table);

resultsTableFile = fullfile(accOutputDir, 'results_table_MTT.mat');
save(resultsTableFile, 'results_table');
writetable(results_table, fullfile(accOutputDir, 'Results_all_MTT.xlsx'));

%% =========================
% STATISTICS
% =========================
load(resultsTableFile)

fprintf('\nSession 1 vs Session 2:\n');
fprintf('-----------------------\n');

[h_rt, p_rt]   = ttest(results_table.RT_S1, results_table.RT_S2);
[h_mt, p_mt]   = ttest(results_table.MT_S1, results_table.MT_S2);
[h_et, p_et]   = ttest(results_table.ET_S1, results_table.ET_S2);
[h_acc, p_acc] = ttest(results_table.Accuracy_S1, results_table.Accuracy_S2);

fprintf('RT: p = %.4f\n', p_rt);
fprintf('MT: p = %.9e\n', p_mt);
fprintf('ET: p = %.9e\n', p_et);
fprintf('Accuracy: p = %.4f\n', p_acc);

fprintf('\nAccuracy summary:\n');
fprintf('-----------------\n');
fprintf('Accuracy Session 1: mean = %.4f, std = %.4f\n', ...
    mean(results_table.Accuracy_S1, 'omitnan'), std(results_table.Accuracy_S1, 'omitnan'));
fprintf('Accuracy Session 2: mean = %.4f, std = %.4f\n', ...
    mean(results_table.Accuracy_S2, 'omitnan'), std(results_table.Accuracy_S2, 'omitnan'));

%% =========================
%  MTT FIGURES (BL vs FU)
% ==========================

% Pair data (convert ms -> s)
dataPair_ACC = [results_table.Accuracy_S1, results_table.Accuracy_S2];
dataPair_RT  = [results_table.RT_S1/1000, results_table.RT_S2/1000];
dataPair_MT  = [results_table.MT_S1/1000, results_table.MT_S2/1000];
dataPair_ET  = [results_table.ET_S1/1000, results_table.ET_S2/1000];

% Accuracy
plot_BL_FU_style(dataPair_ACC, ...
    'Accuracy (%)', ...
    'Multitasking Task - Accuracy', [0 100]);

% RT
plot_BL_FU_style(dataPair_RT, ...
    'Time (s)', ...
    'Multitasking Task - Reaction Time', []);

% MT
plot_BL_FU_style(dataPair_MT, ...
    'Time (s)', ...
    'Multitasking Task - Movement Time', []);

% ET
plot_BL_FU_style(dataPair_ET, ...
    'Time (s)', ...
    'Multitasking Task - Execution Time', []);

%% =========================
% LOCAL FUNCTION
% =========================
function out = convert_to_numeric(x)
    if isnumeric(x)
        out = double(x);
    elseif ischar(x) || isstring(x)
        s = char(string(x));
        s = regexprep(s, '[^\d\.\-]', '');
        out = str2double(s);
    else
        out = NaN;
    end
end
