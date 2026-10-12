function NegLL = lik_RW_2alpha_softmax_3conditions(all_choices, outcomes, conditionLabels, nConds, alpha_gain, alpha_loss, beta)
% 3-conditions RW (2 alphas) + softmax likelihood.
% - Per-condition Q init = [0.5 0.5]
% - First trial of each condition (its first occurrence in the sequence) uses uniform [0.5 0.5]
% - Same softmax & RW updates as the simulation
%
% Inputs:
%   all_choices   [T x 1] in {1,2}
%   outcomes      [T x 1] in {0,1}
%   conditionLabels [T x 1] in {1..nConds}

    T = numel(all_choices);
    Q = 0.5 * ones(nConds, 2);
    p_chosen = zeros(T,1);

    % find the first occurrence index of each condition in the sequence
    firstIdx = zeros(nConds,1);
    for c = 1:nConds
        firstIdx(c) = find(conditionLabels == c, 1, 'first');
    end

    for t = 1:T
        c  = conditionLabels(t);
        ch = all_choices(t);   % 1 or 2
        r  = outcomes(t);      % 0 or 1

        if t == firstIdx(c)
            % first time we ever see this condition -> uniform
            p = [0.5, 0.5];
        else
            expQ_A = exp(beta * Q(c,1));
            expQ_B = exp(beta * Q(c,2));
            probA  = expQ_A / (expQ_A + expQ_B);
            p = [probA, 1 - probA];
        end

        % chosen prob
        p_chosen(t) = p(ch);

        % Q-value update (gain/loss alphas) on chosen action of this condition
        delta = r - Q(c, ch);
        if r == 1
            Q(c, ch) = Q(c, ch) + alpha_gain * delta;
        else
            Q(c, ch) = Q(c, ch) + alpha_loss * delta;
        end
    end

    NegLL = -sum(log(p_chosen)); 
end
