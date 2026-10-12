function saveResults(outputFile, prefix, LM, LM_main, DV, BL, T1, T2)
% saveResults  Save LM coefficient tables and per-group signrank results
%   prefix is used to label the sheets, e.g. 'RT', 'ACC', 'stdRT'

    % ---- LM with interactions -------------------------------------------
    Cfull = LM.Coefficients;                       % MATLAB table
    Cfull.Term = LM.CoefficientNames(:);           % keep names as a column
    Cfull = movevars(Cfull, 'Term', 'Before', 1);
    writetable(Cfull, outputFile, ...
        'Sheet', [prefix '_LM_full'], 'WriteRowNames', false);

    % ---- LM main effects only -------------------------------------------
    Cmain = LM_main.Coefficients;
    Cmain.Term = LM_main.CoefficientNames(:);
    Cmain = movevars(Cmain, 'Term', 'Before', 1);
    writetable(Cmain, outputFile, ...
        'Sheet', [prefix '_LM_main'], 'WriteRowNames', false);

    % ---- signrank per group --------------------------------------------
    idx   = {T2==1,    T1==1,  T1==0 & T2==0};
    names = {'EXCOG', 'EX',    'CNT'};

    G   = strings(numel(idx),1);
    N   = nan(numel(idx),1);
    SR  = nan(numel(idx),1);
    Z   = nan(numel(idx),1);
    P   = nan(numel(idx),1);
    H   = nan(numel(idx),1);

    for k = 1:numel(idx)
        d = DV(idx{k});  b = BL(idx{k});
        [p, h, s] = signrank(d, b);
        G(k)  = names{k};
        N(k)  = numel(d);
        SR(k) = s.signedrank;
        if isfield(s,'zval'), Z(k) = s.zval; end   % zval only for n large enough
        P(k)  = p;
        H(k)  = h;
    end

    SRtbl = table(G, N, SR, Z, P, H, ...
        'VariableNames', {'Group','N','signedrank','zval','p_value','H'});
    writetable(SRtbl, outputFile, 'Sheet', [prefix '_signrank']);
end