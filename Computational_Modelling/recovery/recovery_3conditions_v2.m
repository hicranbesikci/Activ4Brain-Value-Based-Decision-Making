% --- PARAMETER RECOVERY CODE (3 conditions) ---

clear; clc; close all;
rng(2);   % fixed seed: same synthetic datasets everytime

% Initialize task parameters
nBlocks        = 4;
nConditions    = 3;
nTrialsPerCond = 30;
T              = nBlocks * nConditions * nTrialsPerCond; 

% Reward probabilities [cond x option]
rewardProbs = [0.8 0.2; 
               0.7 0.3; 
               0.6 0.4];

nStarts   = 500;   % number of multi-start per subject 
nDatasets = 61;    % number of synthetic subjects

% [alpha_gain; alpha_loss; beta]
Xsim = zeros(3, nDatasets);   % true parameters
Xfit = zeros(3, nDatasets);   % fitted parameters

for k = 1:nDatasets

    % --------- TRUE PARAMETERS ---------
    ag = rand;       % alpha_gain ~ U(0,1)
    al = rand;       % alpha_loss ~ U(0,1)

    % beta ~ Exponential(5), ama fit'in üst sınırı 25 olduğu için truncate edelim
    be = exprnd(5);
    if be > 25
        be = 25;     % fitter'ın UB'si ile tutarlı olsun
    end

    % --------- SIMULATION (3 conditions) ---------
    [all_choices, outcomes, conditionLabels] = ...
        simulation_3conditions(nBlocks, nConditions, nTrialsPerCond, ...
                               rewardProbs, ag, al, be);

    % --------- MODEL FIT (MULTI-START) ---------

    % [Xfit, LL, BIC, NegLL_all, X_best, X0_all, X0_best] = ...
    %    fit_RW_2alpha_softmax_3conditions_multiStart(...);

    [xhat, LL, BIC, NegLL_all, X_best, X0_all, X0_best] = ...
        fit_RW_2alpha_softmax_3conditions_multiStart( ...
            all_choices, outcomes, conditionLabels, nConditions, nStarts);

    % --------- SAVE ---------
    Xsim(:,k) = [ag; al; be];
    Xfit(:,k) = xhat(:);   % create 3x1 matris
end

% --------- BASIC RECOVERY PLOTS ---------

figure(1); clf; set(gcf,'Position',[100 100 900 300])
names = {'\alpha_{gain}','\alpha_{loss}','\beta'};

for i = 1:3
    subplot(1,3,i); hold on; box off; axis square

    plot(Xsim(i,:), Xfit(i,:), 'o', 'MarkerSize', 6, 'LineWidth', 1)

    xl = [min(Xsim(i,:)) max(Xsim(i,:))];
    yl = [min(Xfit(i,:)) max(Xfit(i,:))];
    lo = min([xl yl]);
    hi = max([xl yl]);

    plot([lo hi], [lo hi], 'k--')  % identity line

    if i == 3
        % log scale for beta
        set(gca, 'XScale', 'log', 'YScale', 'log');
        xlabel('true \beta'); ylabel('est \beta')
    else
        xlim([0 1]); ylim([0 1]);
        xlabel(['true ' names{i}]); ylabel(['est ' names{i}])
    end

    title(names{i})
end

%% Visualizing part

% correlation printout
% Pearson correlation + p-values
[r_ag, p_ag] = corr(Xsim(1,:)', Xfit(1,:)', ...
                    'Type','Pearson','Rows','complete');

[r_al, p_al] = corr(Xsim(2,:)', Xfit(2,:)', ...
                    'Type','Pearson','Rows','complete');

[r_be, p_be] = corr(Xsim(3,:)', Xfit(3,:)', ...
                    'Type','Pearson','Rows','complete');

fprintf('\nParameter Recovery Results:\n');
fprintf('alpha_gain: r = %.3f, p = %.3e\n', r_ag, p_ag);
fprintf('alpha_loss: r = %.3f, p = %.3e\n', r_al, p_al);
fprintf('beta:       r = %.3f, p = %.3e\n', r_be, p_be);

% --- 2D Heatmaps for Parameter Recovery (true vs estimated) ---
figure(10); clf;
set(gcf,'Position',[100 100 1100 300]);

names = {'\alpha_{gain}','\alpha_{loss}','\beta'};
trueVals = Xsim;
estVals  = Xfit;

for i = 1:3
    subplot(1,3,i); hold on; box off; axis square

    plot(Xsim(i,:), Xfit(i,:), 'o', 'MarkerSize', 7, 'LineWidth', 1)

    if i == 3
        set(gca,'XScale','log','YScale','log');
        lims = [0.2 30];                       % beta icin ortak sinir
        xlabel('true \beta'); ylabel('estimated \beta')
    else
        lims = [0 1];
        xlabel(['true '      names{i}]);
        ylabel(['estimated ' names{i}])
    end

    plot(lims, lims, 'k--')                    % identity line, tam kose kose
    xlim(lims); ylim(lims);

    % title(sprintf('%s   r = %.2f', names{i}, rvals(i)))   % r'yi baslikta goster
    ax = gca;
    ax.LineWidth = 2;
    ax.FontName = 'Arial';
    ax.FontSize = 16;
    ax.TickLabelInterpreter = 'tex';
    ax.YDir = 'normal';
end
    
  
