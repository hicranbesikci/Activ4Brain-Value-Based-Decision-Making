function [all_choices, outcomes, conditionLabels] = simulation_3conditions(nBlocks, nConditions, nTrialsPerCond, rewardProbs, alpha_gain, alpha_loss, beta)
% 3-conditions simulation :
% - Per-condition Q init = [0.5 0.5]
% - First trial of EACH condition in block 1 is random (uniform)
% - Softmax (two options) + cumsum sampling
% - Q-value update with gain/loss learning rates

    nOptions = 2;
    T = nBlocks * nConditions * nTrialsPerCond;

    Q = 0.5 * ones(nConditions, nOptions);
    all_choices     = zeros(T,1);
    outcomes        = zeros(T,1);
    conditionLabels = zeros(T,1);

    trialIdx = 1;
    for block = 1:nBlocks
        for cond = 1:nConditions
            for t = 1:nTrialsPerCond

                if block == 1 && t == 1
                    option = randi([1, 2]);        % first time this condition appears
                    softmax_probs = [0.5 0.5];
                else
                    expQ_A = exp(beta * Q(cond,1));
                    expQ_B = exp(beta * Q(cond,2));
                    probA  = expQ_A / (expQ_A + expQ_B);
                    probB  = 1 - probA;
                    softmax_probs = [probA, probB];

                    Resp = [1 2];
                    C = cumsum(softmax_probs);
                    option = Resp(1 + sum(C(end) * rand > C));
                end

                reward = rand < rewardProbs(cond, option);

                delta = reward - Q(cond, option);
                if reward == 1
                    Q(cond, option) = Q(cond, option) + alpha_gain * delta;
                else
                    Q(cond, option) = Q(cond, option) + alpha_loss * delta;
                end

                all_choices(trialIdx)  = option;
                outcomes(trialIdx)     = reward;
                conditionLabels(trialIdx) = cond;

                trialIdx = trialIdx + 1;
            end
        end
    end
end
