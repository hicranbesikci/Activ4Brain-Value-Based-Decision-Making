% This code is written to find each participant's fitted parameters


clc; clear; close all;
projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(projectRoot);
cfg = load_project_config();
computationalOutputDir = fullfile(cfg.outputDir, 'Computational_Modelling');
if ~isfolder(computationalOutputDir), mkdir(computationalOutputDir); end

rng("shuffle");

skipPart= [1,2,5,13,17,27,37,43,44,57,59,61,65,74];
Parts = setdiff(1:76,skipPart);
for session =1:2
    for PartsNum = setdiff(1:76,skipPart)
       
    
    
    % % --- MAIN CODE - SIMULATION (3 conditions) ---
    % 
    % clc; clear all; close all;
    % rng("shuffle");
    % 
    % % PARAMETERS
    % nBlocks        = 4;
    % nConditions    = 3;                 % Easy, Medium, Hard
    % nTrialsPerCond = 30;                % trials per condition per block
    % nTrialsPerBlk  = nConditions * nTrialsPerCond;
    % nTrials        = nBlocks * nTrialsPerBlk;
    % nOptions       = 2;
    % 
    % alpha_gain = 0.75;   % LR when reward is received
    % alpha_loss = 0.5;   % LR when no reward is received
    % beta       = 5;      % Softmax inverse temperature
    % 
    % % Reward probabilities per condition (rows) and option (columns)
    % %   row1=Easy, row2=Medium, row3=Difficult
    % rewardProbs = [0.8 0.2;   % Easy
    %                0.7 0.3;   % Medium
    %                0.6 0.4];  % Difficult
    % 
    % % Initialize Q-values per condition
    % Q = 0.5 * ones(nConditions, nOptions);
    % 
    % % Preallocate logs
    % all_choices      = zeros(nTrials, 1);
    % outcomes         = zeros(nTrials, 1);
    % predictionErrors = zeros(nTrials, 1);
    % Qhistory         = NaN(nTrials, nOptions);
    % conditionLabels  = zeros(nTrials, 1);
    % blockLabels      = zeros(nTrials, 1);
    % softmaxHistory   = zeros(nTrials, nOptions);
    % 
    % % MAIN LOOP
    % trialIdx = 1;
    % for block = 1:nBlocks
    %     for cond = 1:nConditions
    %         for t = 1:nTrialsPerCond
    % 
    %             if block == 1 && t == 1
    %                 % first trial of THIS condition (in block 1): random
    %                 option = randi([1, 2]);
    %                 softmax_probs = [0.5 0.5];
    %             else
    %                 % Softmax action selection (two options)
    %                 expQ_A = exp(beta * Q(cond,1));
    %                 expQ_B = exp(beta * Q(cond,2));
    %                 probA  = expQ_A / (expQ_A + expQ_B);
    %                 probB  = 1 - probA;
    %                 softmax_probs = [probA, probB];
    % 
    %                 % Sample action
    %                 Resp = [1 2];
    %                 C = cumsum(softmax_probs);
    %                 option = Resp(1 + sum(C(end) * rand > C));
    %             end
    % 
    %             % Generate reward from condition-specific probs
    %             reward = rand < rewardProbs(cond, option);
    % 
    %             % Prediction error & update
    %             delta = reward - Q(cond, option);
    %             if reward == 1
    %                 Q(cond, option) = Q(cond, option) + alpha_gain * delta;
    %             else
    %                 Q(cond, option) = Q(cond, option) + alpha_loss * delta;
    %             end
    % 
    %             % Logging
    %             all_choices(trialIdx)      = option;
    %             outcomes(trialIdx)         = reward;
    %             predictionErrors(trialIdx) = delta;
    %             Qhistory(trialIdx, :)      = Q(cond, :);
    %             conditionLabels(trialIdx)  = cond;
    %             blockLabels(trialIdx)      = block;
    %             softmaxHistory(trialIdx,:) = softmax_probs;
    % 
    %             trialIdx = trialIdx + 1;
    %         end
    %     end
    % end
    
    % ---- Fit (3 conditions)(multi-start) ----
    nConditions = 3;
    nStarts     = 500;
    alpha_gain  = 0.75;   % LR when reward is received
    alpha_loss  = 0.5;   % LR when no reward is received
    beta        = 6;      % Softmax inverse temperature
    
    % PartsNum=3;

        participantStem = sprintf('%03d_S%d', PartsNum, session);
        choicesFile = fullfile(cfg.computationalParticipantDataNewDir, ...
            [participantStem '_all_choices.mat']);
        outcomesFile = fullfile(cfg.computationalParticipantDataNewDir, ...
            [participantStem '_outcomes.mat']);
        load(choicesFile);
        load(outcomesFile);
    
    [Xfit, LL, BIC, NegLL_all, X_best, X0_all, X0_best] = fitting_function( ...
        all_choices, outcomes, nConditions, nStarts);
    
    % To control: best NegLL and which start? 
    [minNegLL, idxBest] = min(NegLL_all);
    fprintf('Best NegLL = %.3f (start #%d)\n', minNegLL, idxBest);
    fprintf('Xfit = [alpha_gain=%.3f, alpha_loss=%.3f, beta=%.3f]\n', Xfit);
    fprintf('X0_best = [alpha_gain=%.3f, alpha_loss=%.3f, beta=%.3f]\n', X0_best);
    
    % Save the fitted parameters and best NegLL from participant data.
    filename = fullfile(computationalOutputDir, ...
        sprintf('%d_S%d_Fitted_parameters.mat', PartsNum, session));
    save(filename, "Xfit")

    filename_NegLL = fullfile(computationalOutputDir, ...
        sprintf('%d_S%d_minNegLL.mat', PartsNum, session));
    save(filename_NegLL,"minNegLL")
    
    end
end
