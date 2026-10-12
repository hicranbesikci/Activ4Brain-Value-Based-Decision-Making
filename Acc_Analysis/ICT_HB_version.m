clear; close all; clc
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();
accOutputDir = fullfile(cfg.outputDir, 'Acc_Analysis');
if ~isfolder(accOutputDir), mkdir(accOutputDir); end

eeglab;

%% =========================
%  SETTINGS
% ==========================
folder_path = cfg.accDataDir;
file_list = dir(fullfile(folder_path, '*ICT*.mat'));

% Exclude participant EX020 from analysis
exclude_files = {'EX020_Session1_ICT.mat', 'EX020_Session2_ICT.mat'};
file_list = file_list(~ismember({file_list.name}, exclude_files));

fprintf('Number of total ICT files: %d\n', length(file_list));

save_results_mat = true;
save_figures = false;   % true if you want to save figures
fig_out_dir = fullfile(accOutputDir, 'ICT_Figures');

if save_figures && ~exist(fig_out_dir, 'dir')
    mkdir(fig_out_dir);
end

% Error bar type: 'sem' or 'sd'
error_type = 'sem';

% Plot appearance
bar_face_color = [0.82 0.82 0.82];
bar_edge_color = [0.25 0.25 0.25];
dot_color      = [0.45 0.45 0.45];
line_color     = [0.70 0.70 0.70];

rng(1); % reproducible jitter

%% =========================
%  RESULTS TABLE
% ==========================
results_table = table('Size', [0, 15], ...
    'VariableTypes', {'string', ...
                      'double', 'double', 'double', ...   % S1 counts
                      'double', 'double', 'double', 'double', ... % S1 metrics
                      'double', 'double', 'double', ...   % S2 counts
                      'double', 'double', 'double', 'double'}, ... % S2 metrics
    'VariableNames', {'ParticipantID', ...
                      'Number_correct_S1', 'Number_incorrect_S1', 'Number_without_S1', ...
                      'RT_S1', 'MT_S1', 'ET_S1', 'Accuracy_S1', ...
                      'Number_correct_S2', 'Number_incorrect_S2', 'Number_without_S2', ...
                      'RT_S2', 'MT_S2', 'ET_S2', 'Accuracy_S2'});

participants_map = containers.Map();

%% =========================
%  MAIN LOOP
% ==========================
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

        EEG = pop_importdata( ...
            'dataformat','array', ...
            'nbchan',0, ...
            'data','acc_data4eeglab', ...
            'setname','acc_data4eeglab', ...
            'srate',500, ...
            'pnts',0, ...
            'xmin',0);

        [ALLEEG, EEG, CURRENTSET] = pop_newset([], EEG, 0, 'gui', 'off');
        EEG = eeg_checkset(EEG);
        EEG = pop_chanevent(EEG, 7, 'edge', 'leading', 'edgelen', 0);
        [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

        % Epoch only GO stimuli
        EEG = pop_epoch(EEG, {'11' '12' '13' '14' '101' '102' '103' '104'}, [-0.1 2], ...
            'newname', 'acc_data4eeglab_epochs', 'epochinfo', 'yes');
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, [], 'gui', 'off');

        EEG = pop_rmbase(EEG, [-100 0]);
        [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, [], 'gui', 'off');

        if EEG.trials == 0
            error('No valid epochs found.');
        end

        % Analysis setup
        time_limit_mask = EEG.times <= 2000;  % original epoch is 2 s after onset
        channel_order = [1 3 5 2 4 6];        % Lx Ly Lz Rx Ry Rz (same logic as original)
        n_epochs = EEG.trials;

        stimulus_codes = [101, 102, 103, 104, 11, 12, 13, 14];
        response_codes = [61, 62, 63, 64, 41, 42, 43, 44];

        reaction_times_all = nan(n_epochs, 6); % per channel
        rt_trial = nan(n_epochs, 1);           % selected trial-level RT
        et_trial = nan(n_epochs, 1);           % pedal press latency
        mt_trial = nan(n_epochs, 1);           % ET - RT
        response_status = strings(n_epochs, 1);

        for trl = 1:n_epochs
            max_left = 0;
            max_right = 0;

            for j = 1:6
                ch = channel_order(j);

                pre_stim_mask = EEG.times >= -100 & EEG.times < 0;
                baseline_signal = EEG.data(ch, pre_stim_mask, trl);
                baseline_mean = mean(baseline_signal, 2);
                baseline_std  = std(baseline_signal);

                time_vec = EEG.times(time_limit_mask);
                signal = abs(EEG.data(ch, time_limit_mask, trl) - baseline_mean);

                threshold = 8 * baseline_std;
                post_stim_idx = find(time_vec >= 0);

                for k = 1:(length(post_stim_idx) - 1)
                    idx = post_stim_idx(k);
                    if signal(idx) > threshold
                        reaction_times_all(trl, j) = time_vec(idx);
                        break;
                    end
                end

                amplitude = max(signal);

                if j <= 3
                    max_left = max(max_left, amplitude);
                else
                    max_right = max(max_right, amplitude);
                end
            end

            % Choose the leg with higher activation, then take fastest axis of that leg
            if max_left > max_right
                rt_trial(trl) = min(reaction_times_all(trl, 1:3), [], 'omitnan');
            else
                rt_trial(trl) = min(reaction_times_all(trl, 4:6), [], 'omitnan');
            end

            % Read task events
            event_types = EEG.epoch(trl).eventtype;
            event_latencies = EEG.epoch(trl).eventlatency;

            if iscell(event_types)
                event_types = cell2mat(event_types);
            end
            if iscell(event_latencies)
                event_latencies = cell2mat(event_latencies);
            end

            idx_response = find(ismember(event_types, response_codes), 1);

            if isempty(idx_response)
                response_status(trl) = "Without Answer";
                continue;
            else
                et_trial(trl) = event_latencies(idx_response); % in ms
            end

            stimulus = event_types(ismember(event_types, stimulus_codes));
            response = event_types(idx_response);

            expected_idx = find(stimulus_codes == stimulus, 1);
            expected_response = response_codes(expected_idx);

            if response == expected_response
                response_status(trl) = "Correct";
            else
                response_status(trl) = "Incorrect";
            end

            if ~isnan(rt_trial(trl)) && ~isnan(et_trial(trl))
                mt_trial(trl) = et_trial(trl) - rt_trial(trl);
            end
        end

        %% Summaries
        correct_answers   = sum(response_status == "Correct");
        incorrect_answers = sum(response_status == "Incorrect");
        without_answer    = sum(response_status == "Without Answer");

        % ICT final plots/analysis requested without correct-vs-incorrect split.
        % Still, because incorrect trials are theoretically possible in raw data,
        % we compute medians from CORRECT trials for RT/MT/ET, matching the report logic.
        rt_correct = rt_trial(response_status == "Correct");
        mt_correct = mt_trial(response_status == "Correct");
        et_correct = et_trial(response_status == "Correct");

        rt_median = median(rt_correct, 'omitnan');
        mt_median = median(mt_correct, 'omitnan');
        et_median = median(et_correct, 'omitnan');

        accuracy = (correct_answers / (correct_answers + incorrect_answers + without_answer)) * 100;

        % Extract participant/session info
        tokens = regexp(current_file, '^EX(\d+)_Session(\d)_ICT\.mat$', 'tokens');
        if isempty(tokens)
            error('Filename does not match expected pattern: %s', current_file);
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
%  BUILD FINAL TABLE
% ==========================
participant_IDs = keys(participants_map);

for i = 1:length(participant_IDs)
    ID = participant_IDs{i};
    session = participants_map(ID);

    % Skip incomplete participants
    if length(session) < 2 || isempty(session{1}) || isempty(session{2})
        fprintf('Skipping participant %s due to missing session.\n', ID);
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

disp(results_table);

if save_results_mat
    save(fullfile(accOutputDir, 'results_table_ICT.mat'), 'results_table');
end

%% =========================
%  CONVERT ms TO s FOR PLOTTING / REPORTING
% ==========================
results_table.RT_S1_sec = results_table.RT_S1 / 1000;
results_table.RT_S2_sec = results_table.RT_S2 / 1000;
results_table.MT_S1_sec = results_table.MT_S1 / 1000;
results_table.MT_S2_sec = results_table.MT_S2 / 1000;
results_table.ET_S1_sec = results_table.ET_S1 / 1000;
results_table.ET_S2_sec = results_table.ET_S2 / 1000;

%% =========================
%  STATISTICS
% ==========================
fprintf('\n=============================\n');
fprintf('INHIBITORY CONTROL TASK STATS\n');
fprintf('=============================\n');

% Session 1 vs Session 2 (correct/go-based medians)
[~, p_rt] = ttest(results_table.RT_S1, results_table.RT_S2);
[~, p_mt] = ttest(results_table.MT_S1, results_table.MT_S2);
[~, p_et] = ttest(results_table.ET_S1, results_table.ET_S2);
[~, p_acc] = ttest(results_table.Accuracy_S1, results_table.Accuracy_S2);

fprintf('RT  S1 vs S2: p = %.6f\n', p_rt);
fprintf('MT  S1 vs S2: p = %.6f\n', p_mt);
fprintf('ET  S1 vs S2: p = %.6f\n', p_et);
fprintf('ACC S1 vs S2: p = %.6f\n', p_acc);

fprintf('\nDescriptives:\n');
fprintf('Accuracy S1: mean = %.2f, SD = %.2f\n', mean(results_table.Accuracy_S1, 'omitnan'), std(results_table.Accuracy_S1, 'omitnan'));
fprintf('Accuracy S2: mean = %.2f, SD = %.2f\n', mean(results_table.Accuracy_S2, 'omitnan'), std(results_table.Accuracy_S2, 'omitnan'));

fprintf('RT S1 (s): mean = %.3f, SD = %.3f\n', mean(results_table.RT_S1_sec, 'omitnan'), std(results_table.RT_S1_sec, 'omitnan'));
fprintf('RT S2 (s): mean = %.3f, SD = %.3f\n', mean(results_table.RT_S2_sec, 'omitnan'), std(results_table.RT_S2_sec, 'omitnan'));

fprintf('MT S1 (s): mean = %.3f, SD = %.3f\n', mean(results_table.MT_S1_sec, 'omitnan'), std(results_table.MT_S1_sec, 'omitnan'));
fprintf('MT S2 (s): mean = %.3f, SD = %.3f\n', mean(results_table.MT_S2_sec, 'omitnan'), std(results_table.MT_S2_sec, 'omitnan'));

fprintf('ET S1 (s): mean = %.3f, SD = %.3f\n', mean(results_table.ET_S1_sec, 'omitnan'), std(results_table.ET_S1_sec, 'omitnan'));
fprintf('ET S2 (s): mean = %.3f, SD = %.3f\n', mean(results_table.ET_S2_sec, 'omitnan'), std(results_table.ET_S2_sec, 'omitnan'));

%% =========================
%  PLOT DATA PREP
% ==========================
acc_s1 = results_table.Accuracy_S1;
acc_s2 = results_table.Accuracy_S2;

rt_s1 = results_table.RT_S1_sec;
rt_s2 = results_table.RT_S2_sec;

mt_s1 = results_table.MT_S1_sec;
mt_s2 = results_table.MT_S2_sec;

et_s1 = results_table.ET_S1_sec;
et_s2 = results_table.ET_S2_sec;

% %% =========================
% %  OPTIONAL SUMMARY TABLE
% % ==========================
% summary_table = table( ...
%     ["Accuracy"; "RT"; "MT"; "ET"], ...
%     [mean(acc_s1,'omitnan'); mean(rt_s1,'omitnan'); mean(mt_s1,'omitnan'); mean(et_s1,'omitnan')], ...
%     [mean(acc_s2,'omitnan'); mean(rt_s2,'omitnan'); mean(mt_s2,'omitnan'); mean(et_s2,'omitnan')], ...
%     [compute_error(acc_s1,error_type); compute_error(rt_s1,error_type); compute_error(mt_s1,error_type); compute_error(et_s1,error_type)], ...
%     [compute_error(acc_s2,error_type); compute_error(rt_s2,error_type); compute_error(mt_s2,error_type); compute_error(et_s2,error_type)], ...
%     [p_acc; p_rt; p_mt; p_et], ...
%     'VariableNames', {'Measure', 'Baseline_Mean', 'FollowUp_Mean', 'Baseline_Error', 'FollowUp_Error', 'p_value'});
% 
% disp(summary_table);
% 
% if save_results_mat
%     save('summary_table_ICT.mat', 'summary_table');
% end

%% =========================
%  ICT FIGURES (BL vs FU)
% ==========================

% Pair data (convert ms → s)
dataPair_ACC = [results_table.Accuracy_S1, results_table.Accuracy_S2];
dataPair_RT  = [results_table.RT_S1/1000, results_table.RT_S2/1000];
dataPair_MT  = [results_table.MT_S1/1000, results_table.MT_S2/1000];
dataPair_ET  = [results_table.ET_S1/1000, results_table.ET_S2/1000];

% Accuracy
plot_BL_FU_style(dataPair_ACC, ...
    'Accuracy (%)', ...
    'Inhibitory Control - Accuracy', [0 100]);

% RT
plot_BL_FU_style(dataPair_RT, ...
    'Time (s)', ...
    'Inhibitory Control - Reaction Time', [0 .7]);

% MT
plot_BL_FU_style(dataPair_MT, ...
    'Time (s)', ...
    'Inhibitory Control - Movement Time', [0 1]);

% ET
plot_BL_FU_style(dataPair_ET, ...
    'Time (s)', ...
    'Inhibitory Control - Execution Time', [0 1.6]);
