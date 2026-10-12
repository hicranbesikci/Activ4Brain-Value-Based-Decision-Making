function [Xfit, LL, BIC, NegLL_all, X_best, X0_all, X0_best] = fit_RW_2alpha_softmax_3conditions_multiStart( ...
        all_choices, outcomes, conditionLabels, nConds, nStarts)
% multi-start MLE (RW, 2-alpha + softmax, multi-condition)
% Input:
%   all_choices, outcomes, conditionLabels, nConds  
%   nStarts -> how many starts? (default: 20)
% Output:
%   Xfit = [alpha_gain, alpha_loss, beta] (best)
%   LL   = best log-likelihood
%   BIC  = k*log(n) + 2*NegLL_best
%   NegLL_all = NegLL values of each start (and which X0 (start) used for it)

    if nargin < 5 || isempty(nStarts)
        nStarts = 20;
    end

    
    obFunc = @(x) lik_RW_2alpha_softmax_3conditions( ...
                    all_choices, outcomes, conditionLabels, nConds, ...
                    x(1), x(2), x(3) );

    % lower/upper boundries
    LB = [0, 0, 0];      % [alpha_gain, alpha_loss, beta]
    UB = [1, 1, 25];


    % save results
    X0_all      = NaN(nStarts, 3);
    X_best      = NaN(nStarts, 3);
    NegLL_all   = NaN(nStarts, 1);

    % produces random X0 for each start, run fmincon, save NegLL
    for s = 1:nStarts
       
        X0 = [rand, rand, exprnd(1)];

        [xhat, negll] = fmincon(obFunc, X0, [], [], [], [], LB, UB);

        X0_all(s,:)    = X0;
        X_best(s,:)    = xhat;
        NegLL_all(s,1) = negll;
    end

    % Choose minimum NegLL
    [NegLL_best, iBest] = min(NegLL_all);
    Xfit = X_best(iBest, :);
    X0_best = X0_all(iBest,:);

 
    LL  = -NegLL_best;
    k   = 3;
    n   = numel(all_choices);
    BIC = k*log(n) + 2*NegLL_best;   % = k*log(n) - 2*LL
end
