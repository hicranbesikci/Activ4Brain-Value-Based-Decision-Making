function nestedF(LM_main, LM_int, label)
% NESTEDF  Compare main-effects model vs interaction model
%
% Two models are nested : interaction model adds only 2 terms (BL.*T1 ve BL.*T2) 
% to main-effects model. So, difference between them can be determined by 
% F test.
%
% Hypothesis: "added 2 interaction terms are BOTH zero"
%   p < .05  -> interaction model is signiticantly better  -> pay attention LM
%   p > .05  -> interaction terims are unnecessary         -> pay attention LM_main
%
% Usage:  nestedF(LM_main, LM, 'Learning phase - RT')

    % --- Warning: same dataset for both models? --------------
    % fitlm discarts automatically NaN rows. If two models use datasets
    % with different size, comparison will be invalid but MATLAB does not
    % give any error.

    if LM_main.NumObservations ~= LM_int.NumObservations
        error('Models use different N (%d vs %d). Nested test is invalid.', ...
              LM_main.NumObservations, LM_int.NumObservations);
    end

    % ---------------- 4 value for F test --------------------------------
    SSE_main = LM_main.SSE;    % the mean squared error that the simple model cannot explain
    SSE_int  = LM_int.SSE;     % the sum of squared errors that the extended model cannot explain
    df_main  = LM_main.DFE;    % the residual degrees of freedom of the simple model
    df_int   = LM_int.DFE;     % the residual degrees of freedom of the extended model

    q = df_main - df_int;      % number of added terms terim sayisi (burada = 2)

    % --- F formula -------------------------------------------------------
    % numerator   : how much the error per added term has decreased
    % denominator : the magnitude per degree of freedom of the residual noise
    % If the ratio is large, the gain is substantial relative to the noise.
    F = ((SSE_main - SSE_int) / q) / (SSE_int / df_int);
    p = 1 - fcdf(F, q, df_int);

    % --- Additional metrics (the lower the value, the better the model) -------------------------
    dAIC = LM_int.ModelCriterion.AIC - LM_main.ModelCriterion.AIC;
    dBIC = LM_int.ModelCriterion.BIC - LM_main.ModelCriterion.BIC;

    % --- Rapor -----------------------------------------------------------
    fprintf('\n===== NESTED MODEL COMPARISON: %s =====\n', label);
    fprintf('N = %d\n', LM_int.NumObservations);
    fprintf('R2 main-effects = %.4f\n', LM_main.Rsquared.Ordinary);
    fprintf('R2 interaction  = %.4f   (dR2 = %.4f)\n', ...
            LM_int.Rsquared.Ordinary, ...
            LM_int.Rsquared.Ordinary - LM_main.Rsquared.Ordinary);
    fprintf('F(%d,%d) = %.3f,  p = %.4f\n', q, df_int, F, p);
    fprintf('dAIC = %+.2f,  dBIC = %+.2f   (negative = supports interaction )\n', dAIC, dBIC);

    if p < 0.05
        fprintf('>> Interaction model is better. Select INTERACTION model.\n');
    else
        fprintf('>> Interaction terms does not improve the fit. Select MAIN-EFFECTS model.\n');
    end
end