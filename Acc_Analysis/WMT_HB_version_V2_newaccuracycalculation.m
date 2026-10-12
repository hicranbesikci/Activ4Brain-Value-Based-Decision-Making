clear; close all; clc;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();
accOutputDir = fullfile(cfg.outputDir, 'Acc_Analysis');
if ~isfolder(accOutputDir), mkdir(accOutputDir); end

eeglab;

%% =========================
% WMT TASK ANALYSIS
% Accuracy calculated like other tasks:
% Accuracy = Correct / (Correct + Incorrect + Missed) * 100
%% =========================

folder_path = cfg.accDataDir;
file_list = dir(fullfile(folder_path, '*WMT.mat'));

% Exclude participant EX020 from analysis
exclude_files = {'EX020_Session1_WMT.mat', 'EX020_Session2_WMT.mat'};
file_list = file_list(~ismember({file_list.name}, exclude_files));

fprintf('Number of total WMT files: %d\n', length(file_list));

%% =========================
% TEMP TABLE - FILE LEVEL
%% =========================

temp_table = table('Size', [0, 6], ...
    'VariableTypes', {'string', 'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'ParticipantID', 'Session', ...
                      'Accuracy', 'Number_correct', ...
                      'Number_incorrect', 'Number_without'});

%% =========================
% EVENT CODES
%% =========================

stim_codes = [11 12 13 14 101 102 103 104];
resp_codes = [41 42 43 44 61 62 63 64];

%% =========================
% MAIN LOOP
%% =========================

for i = 1:length(file_list)

    current_file = file_list(i).name;
    fprintf('\nProcessing: %s\n', current_file);

    try
        %% -------------------------
        % Extract participant/session
        %% -------------------------

        tokens = regexp(current_file, '^EX(\d+)_Session(\d)_WMT\.mat$', 'tokens');

        if isempty(tokens)
            fprintf('Filename format not matched: %s\n', current_file);
            continue;
        end

        participant_number = tokens{1}{1};
        session_number = str2double(tokens{1}{2});

        participant_id = "EX" + string(participant_number);

        %% -------------------------
        % Load data
        %% -------------------------

        data_struct = load(fullfile(folder_path, current_file));
        data_matrix = data_struct.data;
        labels = data_struct.labels;

        trig = convert_BIOPAC_triggers(data_matrix, labels);
        events = trig(trig > 0);

        %% -------------------------
        % Counters
        %% -------------------------

        full_correct_sequences = 0;
        incorrect_sequences = 0;
        missed_sequences = 0;

        idx = 1;

        %% -------------------------
        % Sequence loop
        %% -------------------------

        while idx <= length(events)

            % 40 marks the beginning of a WMT sequence
            if events(idx) == 40

                idx = idx + 1;

                stim_seq = [];
                resp_seq = [];

                %% -------------------------
                % Collect stimulus sequence until code 55
                %% -------------------------

                while idx <= length(events) && events(idx) ~= 55

                    if ismember(events(idx), stim_codes)
                        stim_seq(end+1) = events(idx);
                    end

                    idx = idx + 1;
                end

                %% -------------------------
                % After 55, collect responses
                %% -------------------------

                if idx <= length(events) && events(idx) == 55

                    idx = idx + 1;

                    while idx <= length(events) && ...
                          events(idx) ~= 40 && ...
                          length(resp_seq) < length(stim_seq)

                        % Response structure: 57 followed by response code
                        if events(idx) == 57 && ...
                           idx < length(events) && ...
                           ismember(events(idx+1), resp_codes)

                            resp_seq(end+1) = events(idx+1);
                            idx = idx + 2;

                        else
                            idx = idx + 1;
                        end
                    end
                end

                %% -------------------------
                % Classify sequence
                %% -------------------------

                if ~isempty(stim_seq)

                    sequence_correct = true;

                    % Missed / incomplete sequence:
                    % no response or fewer responses than stimuli
                    if isempty(resp_seq) || length(resp_seq) < length(stim_seq)

                        missed_sequences = missed_sequences + 1;

                    else

                        % Check each response
                        for j = 1:length(stim_seq)

                            s = stim_seq(j);
                            r = resp_seq(j);

                            switch s
                                case {11, 101}
                                    expected = [41, 61];

                                case {12, 102}
                                    expected = [42, 62];

                                case {13, 103}
                                    expected = [43, 63];

                                case {14, 104}
                                    expected = [44, 64];

                                otherwise
                                    expected = [];
                            end

                            if ~ismember(r, expected)
                                sequence_correct = false;
                            end
                        end

                        if sequence_correct
                            full_correct_sequences = full_correct_sequences + 1;
                        else
                            incorrect_sequences = incorrect_sequences + 1;
                        end
                    end
                end

            else
                idx = idx + 1;
            end
        end

        %% -------------------------
        % Accuracy
        %% -------------------------
        % Revised logic:
        % missed sequences ARE included in the denominator.

        total_sequences = full_correct_sequences + incorrect_sequences + missed_sequences;

        if total_sequences > 0

            accuracy = (full_correct_sequences / total_sequences) * 100;

        else
            accuracy = NaN;
        end

        %% -------------------------
        % Store file-level data
        %% -------------------------

        temp_table = [temp_table; ...
            {participant_id, session_number, accuracy, ...
             full_correct_sequences, incorrect_sequences, missed_sequences}];

        fprintf('Participant %s Session %d\n', participant_id, session_number);
        fprintf('Correct sequences: %d\n', full_correct_sequences);
        fprintf('Incorrect sequences: %d\n', incorrect_sequences);
        fprintf('Missed sequences: %d\n', missed_sequences);
        fprintf('Accuracy: %.2f%%\n', accuracy);

    catch ME
        fprintf('Error in %s: %s\n', current_file, ME.message);
        continue;
    end
end

%% =========================
% CONVERT TO PARTICIPANT-LEVEL TABLE
%% =========================

s1 = temp_table(temp_table.Session == 1, :);
s2 = temp_table(temp_table.Session == 2, :);

s1 = sortrows(s1, 'ParticipantID');
s2 = sortrows(s2, 'ParticipantID');

% Check participant matching
if ~isequal(s1.ParticipantID, s2.ParticipantID)
    error('Participants mismatch between Session 1 and Session 2');
end

results_table = table( ...
    s1.ParticipantID, ...
    s1.Number_correct, ...
    s1.Number_incorrect, ...
    s1.Number_without, ...
    s1.Accuracy, ...
    s2.Number_correct, ...
    s2.Number_incorrect, ...
    s2.Number_without, ...
    s2.Accuracy, ...
    'VariableNames', {'ParticipantID', ...
                      'Number_correct_S1', ...
                      'Number_incorrect_S1', ...
                      'Number_without_S1', ...
                      'Accuracy_S1', ...
                      'Number_correct_S2', ...
                      'Number_incorrect_S2', ...
                      'Number_without_S2', ...
                      'Accuracy_S2'});

save(fullfile(accOutputDir, 'results_table_WMT.mat'), 'results_table');
writetable(results_table, fullfile(accOutputDir, 'results_table_WMT.csv'));

disp(results_table);

%% =========================
% WMT ACCURACY STATS
%% =========================

fprintf('\nWMT Accuracy\n');
fprintf('-------------------------\n');

fprintf('S1 mean = %.2f%%\n', mean(results_table.Accuracy_S1, 'omitnan'));
fprintf('S2 mean = %.2f%%\n', mean(results_table.Accuracy_S2, 'omitnan'));

valid_acc = ~isnan(results_table.Accuracy_S1) & ~isnan(results_table.Accuracy_S2);

[~, p] = ttest(results_table.Accuracy_S1(valid_acc), ...
              results_table.Accuracy_S2(valid_acc));

fprintf('Accuracy S1 vs S2: p = %.4f\n', p);

%% =========================
% MISSED TRIALS / SEQUENCES SUMMARY
%% =========================

missed_S1 = results_table.Number_without_S1;
missed_S2 = results_table.Number_without_S2;

mean_missed_S1 = mean(missed_S1, 'omitnan');
min_missed_S1  = min(missed_S1, [], 'omitnan');
max_missed_S1  = max(missed_S1, [], 'omitnan');

mean_missed_S2 = mean(missed_S2, 'omitnan');
min_missed_S2  = min(missed_S2, [], 'omitnan');
max_missed_S2  = max(missed_S2, [], 'omitnan');

fprintf('\nWMT Missed Trials Summary\n');
fprintf('-------------------------\n');

fprintf('Session 1: mean = %.2f, range = %d-%d\n', ...
    mean_missed_S1, min_missed_S1, max_missed_S1);

fprintf('Session 2: mean = %.2f, range = %d-%d\n', ...
    mean_missed_S2, min_missed_S2, max_missed_S2);

missed_summary_WMT = table( ...
    "Working Memory Task", ...
    mean_missed_S1, min_missed_S1, max_missed_S1, ...
    mean_missed_S2, min_missed_S2, max_missed_S2, ...
    'VariableNames', {'Task', ...
                      'Mean_missed_S1', ...
                      'Min_missed_S1', ...
                      'Max_missed_S1', ...
                      'Mean_missed_S2', ...
                      'Min_missed_S2', ...
                      'Max_missed_S2'});

disp(missed_summary_WMT);

save(fullfile(accOutputDir, 'missed_summary_WMT.mat'), 'missed_summary_WMT');
writetable(missed_summary_WMT, fullfile(accOutputDir, 'missed_summary_WMT.csv'));

%% =========================
% PLOT
%% =========================

dataPair = [results_table.Accuracy_S1, results_table.Accuracy_S2];

plot_BL_FU_style(dataPair, ...
    'Accuracy (%)', ...
    'Working Memory Task – Accuracy', ...
    [0 100]);
