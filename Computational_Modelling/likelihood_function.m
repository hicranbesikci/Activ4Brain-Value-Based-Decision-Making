function NegLL = likelihood_function(all_choices, outcomes, nConds, alpha_gain, alpha_loss, beta)
% 3-conditions (easy-medium-difficult) + (2 alphas & B) + softmax likelihood.
% - Per-condition Q init = [0.5 0.5]
% - First trial of each condition (its first occurrence in the sequence) uses uniform [0.5 0.5]
% - Same softmax & RW updates as the simulation
%
% Inputs:
%   all_choices   [3 x T] in {1,2}
%   outcomes      [3 x T] in {0,1}



    T = length(all_choices);
    Q = 0.5 * ones(nConds, 2);
    p_chosen = NaN(T*nConds,1);


counter_trial = 0;

for c = 1:nConds
    for t = 1:T

        ch = all_choices(c,t);   % 1 or 2
        r  = outcomes(c,t);      % 0 or 1
        counter_trial = counter_trial+1;

    if isnan(ch) || isnan(r) 
        % Participant didn't make a choice / no data
        % -> Don't include this trial to likelyhood 
        % -> Don't update Q values
        continue;
    end

        if t == 1
            % first time we ever see this condition -> uniform
            p = [0.5, 0.5];
        else
            expQ_A = exp(beta * Q(c,1));
            expQ_B = exp(beta * Q(c,2));
            probA  = expQ_A / (expQ_A + expQ_B);
            p = [probA, 1 - probA];
        end

        % chosen prob
        p_chosen(counter_trial) = p(ch);

        % Q-value update (gain/loss alphas) on chosen action of this condition
        delta = r - Q(c, ch);
        if r == 1
            Q(c, ch) = Q(c, ch) + alpha_gain * delta;
        else
            Q(c, ch) = Q(c, ch) + alpha_loss * delta;
        end
    end



end
        valid_idx = ~isnan(p_chosen);
        NegLL = -sum(log(p_chosen(valid_idx)));
end
