clear; close all; clc
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();
accOutputDir = fullfile(cfg.outputDir, 'Acc_Analysis');
if ~isfolder(accOutputDir), mkdir(accOutputDir); end

eeglab;

%% PATHS
acc_folder = cfg.accDataDir;
stimulus_folder = cfg.accStimulusDataDir;

acc_files = dir(fullfile(acc_folder, '*NDT*.mat'));
correctside_files = dir(fullfile(stimulus_folder, '*correctside.mat'));

% Exclude participant EX020 from analysis (also EX0061 bcs of attendance
% rate)
exclude_files = {'EX020_Session1_NDT.mat', 'EX020_Session2_NDT.mat'};
acc_files = acc_files(~ismember({acc_files.name}, exclude_files));

exclude_correctsidefiles = {'EX020Session1correctside.mat', 'EX020Session2correctside.mat','EX061Session1correctside.mat', 'EX061Session2correctside.mat'};
correctside_files = correctside_files(~ismember({correctside_files.name}, exclude_correctsidefiles));

fprintf('Number of acc data files: %d\n', length(acc_files));
fprintf('Number of correct side files: %d\n', length(correctside_files));

%% FINAL TABLE
% RT / MT / ET are computed from ALL ANSWERED trials
% Accuracy is still based on correct / incorrect / no answer counts

results_table = table('Size', [0, 15], ...
    'VariableTypes', {'string', ...
                      'double', 'double', 'double', 'double', 'double', 'double', 'double', ...
                      'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'ParticipantID', ...
                      'Number_correct_S1', 'Number_incorrect_S1', 'Number_without_S1', ...
                      'RT_answered_S1', 'MT_answered_S1', 'ET_answered_S1', 'Accuracy_S1', ...
                      'Number_correct_S2', 'Number_incorrect_S2', 'Number_without_S2', ...
                      'RT_answered_S2', 'MT_answered_S2', 'ET_answered_S2', 'Accuracy_S2'});

participants_map = containers.Map();

%% MAIN LOOP
for i = 1:length(acc_files)
    current_acc_file = acc_files(i).name;
    fprintf('\nProcessing: %s\n', current_acc_file);

    try
        data_struct = load(fullfile(acc_folder, current_acc_file));
        data_matrix = data_struct.data;
        labels      = data_struct.labels;

        % Extract participant and session
        tokens = regexp(current_acc_file, '^EX(\d+)_Session(\d)_NDT\.mat$', 'tokens');
        if isempty(tokens)
            error('Filename does not match expected pattern: %s', current_acc_file);
        end

        participant_number = tokens{1}{1};
        session_number     = str2double(tokens{1}{2});

        % Find matching correctside file
        correctside_file = sprintf('Ex%ssession%dcorrectside.mat', participant_number, session_number);
        correctside_path = fullfile(stimulus_folder, correctside_file);

        if ~exist(correctside_path, 'file')
            error('Correctside file not found: %s', correctside_file);
        end

        correctside_data = load(correctside_path);
        correct_side     = correctside_data.correct;

        % Generate triggers
        trig = convert_BIOPAC_triggers(data_matrix, labels);

        % Build EEGLAB data
        % 6 accel channels + 1 trigger channel
        acc_data4eeglab = zeros(7, size(data_matrix, 1));
        acc_data4eeglab(1:6, :) = data_matrix(:, 1:6)';
        acc_data4eeglab(7, :)   = trig';

        EEG = pop_importdata( ...
            'dataformat', 'array', ...
            'nbchan', 7, ...
            'data', acc_data4eeglab, ...
            'setname', 'acc_data4eeglab', ...
            'srate', 500, ...
            'pnts', 0, ...
            'xmin', 0);

        [ALLEEG, EEG, CURRENTSET] = pop_newset([], EEG, 0, 'gui', 'off');

        EEG = eeg_checkset(EEG);
        EEG = pop_chanevent(EEG, 7, 'edge', 'leading', 'edgelen', 0);
        [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

        % NDT stimulus trigger = 40
        EEG = pop_epoch(EEG, {'40'}, [-0.1 3], ...
            'newname', 'acc_data4eeglab_epochs', 'epochinfo', 'yes');
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, [], 'gui', 'off');

        EEG = pop_rmbase(EEG, [-100 0]);
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, [], 'gui', 'off');

        if EEG.trials == 0
            error('No valid epochs found.');
        end

        fprintf('Trials in EEG: %d\n', EEG.trials);
        fprintf('Length of correct_side: %d\n', numel(correct_side));

        n_epochs = min(EEG.trials, numel(correct_side));
        if EEG.trials ~= numel(correct_side)
            warning('Mismatch between EEG trials (%d) and correct_side length (%d). Using minimum = %d.', ...
                EEG.trials, numel(correct_side), n_epochs);
        end

        % Analysis settings
        time_mask     = EEG.times <= 3000;
        time_vec      = EEG.times(time_mask);
        pre_stim_mask = EEG.times >= -100 & EEG.times < 0;

        % Same channel order you used originally
        ordem_canais = [1 3 5 2 4 6];

        % NDT codes
        stimulus_codes = 40;
        response_codes = [41, 42];

        reaction_times_all = nan(n_epochs, 6); % in ms
        min_reaction_time  = nan(n_epochs, 1); % in ms
        execution_times    = nan(n_epochs, 1); % in ms
        movement_times     = nan(n_epochs, 1); % in ms
        resposta_status    = strings(n_epochs, 1);

        for trl = 1:n_epochs
            max_esquerdo = 0;
            max_direito  = 0;

            % -------- RT detection from accelerometer --------
            for j = 1:6
                ch = ordem_canais(j);

                baseline_mean = mean(EEG.data(ch, pre_stim_mask, trl), 2);
                baseline_std  = std(EEG.data(ch, pre_stim_mask, trl));

                signal = abs(EEG.data(ch, time_mask, trl) - baseline_mean);

                threshold = 0 + 8 * baseline_std; % after baseline correction

                search_range = find(time_vec >= 0);

                idx_onset = find(signal(search_range) > threshold, 1, 'first');

                if ~isempty(idx_onset)
                    reaction_times_all(trl, j) = time_vec(search_range(idx_onset));
                end

                amplitude = max(signal);
                if j <= 3
                    max_esquerdo = max(max_esquerdo, amplitude);
                else
                    max_direito = max(max_direito, amplitude);
                end
            end

            % choose leg with higher motor activation, then fastest RT on that leg
            if max_esquerdo > max_direito
                min_reaction_time(trl) = min(reaction_times_all(trl, 1:3), [], 'omitnan');
            else
                min_reaction_time(trl) = min(reaction_times_all(trl, 4:6), [], 'omitnan');
            end

            % -------- Response / ET detection --------
            tipo_eventos     = EEG.epoch(trl).eventtype;
            latencia_eventos = EEG.epoch(trl).eventlatency;

            % Convert event types to numeric vector if needed
            if ~iscell(tipo_eventos)
                tipo_eventos = {tipo_eventos};
            end
            if ~iscell(latencia_eventos)
                latencia_eventos = num2cell(latencia_eventos);
            end

            tipo_eventos_num = nan(1, numel(tipo_eventos));
            latencias_num    = nan(1, numel(latencia_eventos));

            for e = 1:numel(tipo_eventos)
                if ischar(tipo_eventos{e}) || isstring(tipo_eventos{e})
                    tipo_eventos_num(e) = str2double(string(tipo_eventos{e}));
                else
                    tipo_eventos_num(e) = double(tipo_eventos{e});
                end

                if ischar(latencia_eventos{e}) || isstring(latencia_eventos{e})
                    latencias_num(e) = str2double(string(latencia_eventos{e}));
                else
                    latencias_num(e) = double(latencia_eventos{e});
                end
            end

            idx_resposta = find(ismember(tipo_eventos_num, response_codes), 1, 'first');

            if isempty(idx_resposta)
                resposta_status(trl) = "Without Answer";
                continue;
            end

            execution_times(trl) = latencias_num(idx_resposta); % ms from stimulus onset
            resposta = tipo_eventos_num(idx_resposta);

            % Expected response:
            % correct_side = 1 -> response 41
            % correct_side = 2 -> response 42
            expected_response = 40 + correct_side(trl);

            if resposta == expected_response
                resposta_status(trl) = "Correct";
            else
                resposta_status(trl) = "Incorrect";
            end

            if ~isnan(min_reaction_time(trl)) && ~isnan(execution_times(trl))
                movement_times(trl) = execution_times(trl) - min_reaction_time(trl);
            end

            fprintf('Trial %d: StimulusSide %d | Expected %d | Response %d --> %s\n', ...
                trl, correct_side(trl), expected_response, resposta, resposta_status(trl));
        end

        %% COUNTS
        correct_answers   = sum(resposta_status == "Correct");
        incorrect_answers = sum(resposta_status == "Incorrect");
        without_answer    = sum(resposta_status == "Without Answer");

        accuracy = (correct_answers / (correct_answers + incorrect_answers + without_answer)) * 100;

        %% ALL ANSWERED TRIALS
        answered_idx = (resposta_status == "Correct") | (resposta_status == "Incorrect");

        rt_answered = min_reaction_time(answered_idx);
        et_answered = execution_times(answered_idx);
        mt_answered = movement_times(answered_idx);

        % Remove impossible / noisy trials
        valid_idx = ~isnan(rt_answered) & ~isnan(et_answered) & ~isnan(mt_answered) & ...
                    (rt_answered >= 0) & (et_answered >= 0) & (mt_answered >= 0);

        rt_answered = rt_answered(valid_idx);
        et_answered = et_answered(valid_idx);
        mt_answered = mt_answered(valid_idx);

        % Median values (still in ms here)
        rt_median_answered = median(rt_answered, 'omitnan');
        mt_median_answered = median(mt_answered, 'omitnan');
        et_median_answered = median(et_answered, 'omitnan');

        % Convert to seconds so it matches the other scripts/plots
        rt_median_answered_s = rt_median_answered / 1000;
        mt_median_answered_s = mt_median_answered / 1000;
        et_median_answered_s = et_median_answered / 1000;

        sess_data = struct( ...
            'correct',      correct_answers, ...
            'incorrect',    incorrect_answers, ...
            'without',      without_answer, ...
            'accuracy',     accuracy, ...
            'rt_answered',  rt_median_answered_s, ...
            'mt_answered',  mt_median_answered_s, ...
            'et_answered',  et_median_answered_s);

        if isKey(participants_map, participant_number)
            p = participants_map(participant_number);
        else
            p = cell(1,2);
        end

        p{session_number} = sess_data;
        participants_map(participant_number) = p;

    catch ME
        fprintf('Error processing %s: %s\n', current_acc_file, ME.message);
        continue;
    end
end

%% BUILD FINAL TABLE
participant_ID = keys(participants_map);

for i = 1:length(participant_ID)
    ID = participant_ID{i};
    session = participants_map(ID);

    if numel(session) < 2 || isempty(session{1}) || isempty(session{2})
        fprintf('Skipping participant %s because one session is missing.\n', ID);
        continue;
    end

    row = { ...
        string(ID), ...
        session{1}.correct, session{1}.incorrect, session{1}.without, ...
        session{1}.rt_answered, session{1}.mt_answered, session{1}.et_answered, session{1}.accuracy, ...
        session{2}.correct, session{2}.incorrect, session{2}.without, ...
        session{2}.rt_answered, session{2}.mt_answered, session{2}.et_answered, session{2}.accuracy};

    results_table = [results_table; row];
end

results_table = sortrows(results_table, 'ParticipantID');

disp(results_table);

save(fullfile(accOutputDir, 'results_table_NDT_answered.mat'), 'results_table');
writetable(results_table, fullfile(accOutputDir, 'results_table_NDT_answered.csv'));

%% =========================
%  STATISTICS
%  =========================
fprintf('\nSession 1 vs Session 2 (ALL ANSWERED trials)\n');
fprintf('--------------------------------------------\n');

[h_rt, p_rt] = ttest(results_table.RT_answered_S1, results_table.RT_answered_S2);
[h_mt, p_mt] = ttest(results_table.MT_answered_S1, results_table.MT_answered_S2);
[h_et, p_et] = ttest(results_table.ET_answered_S1, results_table.ET_answered_S2);

fprintf('RT answered: p = %.9f\n', p_rt);
fprintf('MT answered: p = %.9f\n', p_mt);
fprintf('ET answered: p = %.9f\n', p_et);

fprintf('\nAccuracy\n');
fprintf('--------\n');

mean_acc_s1 = mean(results_table.Accuracy_S1, 'omitnan');
std_acc_s1  = std(results_table.Accuracy_S1, 'omitnan');

mean_acc_s2 = mean(results_table.Accuracy_S2, 'omitnan');
std_acc_s2  = std(results_table.Accuracy_S2, 'omitnan');

fprintf('Accuracy Session 1: mean = %.4f, std = %.4f\n', mean_acc_s1, std_acc_s1);
fprintf('Accuracy Session 2: mean = %.4f, std = %.4f\n', mean_acc_s2, std_acc_s2);

[h_acc, p_acc] = ttest(results_table.Accuracy_S1, results_table.Accuracy_S2);
fprintf('Accuracy Session 1 vs Session 2: p = %.9f\n', p_acc);

%% =========================
%  PLOTS
%  plot_BL_FU_style must exist as a separate .m file
%  =========================

% RT
rt_pair = [results_table.RT_answered_S1, results_table.RT_answered_S2];
plot_BL_FU_style(rt_pair, 'Time (s)', 'NDT - Reaction Time', []);

% MT
mt_pair = [results_table.MT_answered_S1, results_table.MT_answered_S2];
plot_BL_FU_style(mt_pair, 'Time (s)', 'NDT - Movement Time', []);

% ET
et_pair = [results_table.ET_answered_S1, results_table.ET_answered_S2];
plot_BL_FU_style(et_pair, 'Time (s)', 'NDT - Execution Time', []);

% Accuracy
acc_pair = [results_table.Accuracy_S1, results_table.Accuracy_S2];
plot_BL_FU_style(acc_pair, 'Accuracy (%)', 'NDT - Accuracy', [0 100]);

%% OPTIONAL: save figures
% figHandles = findall(0, 'Type', 'figure');
% for f = 1:length(figHandles)
%     fig = figHandles(f);
%     figName = get(get(fig, 'CurrentAxes'), 'Title');
%     if iscell(figName)
%         figName = figName{1};
%     end
%     if isempty(figName)
%         figName = sprintf('Figure_%d', f);
%     end
%     safeName = regexprep(figName, '[^\w\d-]', '_');
%     saveas(fig, [safeName '.png']);
% end
