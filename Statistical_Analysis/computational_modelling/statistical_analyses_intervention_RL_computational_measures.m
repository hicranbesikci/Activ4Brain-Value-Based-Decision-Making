%% Computational Parameters 
% post-test outcome + baseline covariate

% alpha_gain 

clc; clear;
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(projectRoot);
cfg = load_project_config();

filecsv = fullfile(cfg.computationalFittedDataDir, ...
    'All_FittedParameters_Merged_withGroups.csv');

T = readtable(filecsv);
T(63, :) = []; T(62, :) = []; 

DV  = T.alpha_gain_S2; % dependent variable
BL = T.alpha_gain_S1;  % baseline

DV_log = log10(DV);
BL_log = log10(BL);

T1 = []; T2 = [];
for s = 1:length(T.Group)
    if strcmp(T.Group(s), 'EX') % T1 == 1 means participant belongs to Aerobic group
        T1 = [T1; 1]; % 0, control, 1 for aerobic, 0 for activ4brain
        T2 = [T2; 0]; % 0, control, 0 for aerobic, 1 for activ4brain
    elseif strcmp(T.Group(s), 'EXCOG') % T2 == 1 means participant belongs to Activ4brain group
        T1 = [T1; 0]; % 0, control, 1 for aerobic, 0 for activ4brain
        T2 = [T2; 1]; % 0, control, 0 for aerobic, 1 for activ4brain
     elseif strcmp(T.Group(s), 'CNT') % T1 & T2 == 0 means participant belongs to Control group
        T1 = [T1; 0]; % 0, control, 1 for aerobic, 0 for activ4brain
        T2 = [T2; 0]; % 0, control, 0 for aerobic, 1 for activ4brain
    end
end

% Here X marix includes ; 
% T1 → Difference between EX and CNT 
% T2 → Difference between EXCOG and CNT
% BL → Baseline effect
% BL.*T1 → Baseline effect differs in EX group?
% BL.*T2 → Baseline effect differs in EXCOG group?
% ones(...) → sabit terim (intercept)
% Model is ; DV = β0 ​+ β1​T1 + β2​T2 + β3​BL + β4​(BL×T1) + β5​(BL×T2) + ε

X = [T1, T2, BL, BL.*T1, BL.*T2, ones(length(DV), 1)];

[B,BINT,R,RINT,STATS] = regress(DV,X)

% Linear model not including interactions 
X_main = [T1, T2, BL_log];
LM_main = fitlm(X_main, DV_log)

% Linear model with interactions
Xflm = [T1, T2, BL_log, BL_log.*T1, BL_log.*T2];
LM = fitlm(Xflm,DV) % Linear model. Here fitlm gives info of p values, r2, confidence intervals and ANOVA table

% EX vs CNT 
Xflm1 = [T1,BL, BL.*T1]; 
LM1 = fitlm(Xflm1,DV)

% EXCOG vs CNT
Xflm2 = [T2,BL, BL.*T2];
LM2 = fitlm(Xflm2,DV)

% comparison for each group before and after - only significant for
% activ4brain

[H,P,CI,STATS] = ttest(DV(T2 == 1), BL(T2 == 1)) 
[H,P,CI,STATS] = ttest(DV(T1 == 1), BL(T1 == 1)) 
[H,P,CI,STATS] = ttest(DV(T1 == 0 & T2 == 0), BL(T1 == 0 & T2 == 0)) 

MD_EXCOG_BL = median(BL_log(T2 == 1))
SD_EXCOG_BL = std(BL_log(T2 == 1))
MD_EXCOG_FU = median(DV_log(T2 == 1))
SD_EXCOG_FU = std(DV_log(T2 == 1))
MD_EX_BL = median(BL_log(T1 == 1))
SD_EX_BL = std(BL_log(T1 == 1))
MD_EX_FU = median(DV_log(T1 == 1))
SD_EX_FU = std(DV_log(T1 == 1))
MD_CNT_BL = median(BL_log(T1 == 0 & T2 == 0))
SD_CNT_BL = std(BL_log(T1 == 0 & T2 == 0))
MD_CNT_FU = median(DV_log(T1 == 0 & T2 == 0))
SD_CNT_FU = std(DV_log(T1 == 0 & T2 == 0))


%% alpha_loss

DV  = T.alpha_loss_S2;
BL = T.alpha_loss_S1;

DV_log = log10(DV);
BL_log = log10(BL);

T1 = []; T2 = [];
for s = 1:length(T.Group)
    if strcmp(T.Group(s), 'EX')
        T1 = [T1; 1];% 0, control, 1 for aerobic, 0 for activ4brain
        T2 = [T2; 0];% 0, control, 0 for aerobic, 1 for activ4brain
    elseif strcmp(T.Group(s), 'EXCOG')
        T1 = [T1; 0];% 0, control, 1 for aerobic, 0 for activ4brain
        T2 = [T2; 1];% 0, control, 0 for aerobic, 1 for activ4brain
     elseif strcmp(T.Group(s), 'CNT')
        T1 = [T1; 0];% 0, control, 1 for aerobic, 0 for activ4brain
        T2 = [T2; 0];% 0, control, 0 for aerobic, 1 for activ4brain
    end
end

X = [T1, T2, BL, BL.*T1, BL.*T2, ones(length(DV), 1)];

[B,BINT,R,RINT,STATS] = regress(DV,X)

% Linear model not including interactions 
X_main = [T1, T2, BL];
LM_main = fitlm(X_main, DV)

% Linear model with interactions
Xflm = [T1, T2, BL, BL.*T1, BL.*T2];
LM = fitlm(Xflm,DV)

Xflm1 = [T1,BL, BL.*T1];
LM1 = fitlm(Xflm1,DV)

Xflm2 = [T2,BL, BL.*T2];
LM2 = fitlm(Xflm2,DV)

% comparison for each group before and after 

[H,P,CI,STATS] = ttest(DV(T2 == 1), BL(T2 == 1)) 
[H,P,CI,STATS] = ttest(DV(T1 == 1), BL(T1 == 1)) 
[H,P,CI,STATS] = ttest(DV(T1 == 0 & T2 == 0), BL(T1 == 0 & T2 == 0)) 

table.MD_EXCOG_BL = median(BL_log(T2 == 1))
table.SD_EXCOG_BL = std(BL_log(T2 == 1))
table.MD_EXCOG_FU = median(DV_log(T2 == 1))
table.SD_EXCOG_FU = std(DV_log(T2 == 1))
table.MD_EX_BL = median(BL_log(T1 == 1))
table.SD_EX_BL = std(BL_log(T1 == 1))
table.MD_EX_FU = median(DV_log(T1 == 1))
table.SD_EX_FU = std(DV_log(T1 == 1))
table.MD_CNT_BL = median(BL_log(T1 == 0 & T2 == 0))
table.SD_CNT_BL = std(BL_log(T1 == 0 & T2 == 0))
table.MD_CNT_FU = median(DV_log(T1 == 0 & T2 == 0))
table.SD_CNT_FU = std(DV_log(T1 == 0 & T2 == 0))
%% beta


DV  = T.beta_S2;
BL = T.beta_S1;

T1 = []; T2 = [];
for s = 1:length(T.Group)
    if strcmp(T.Group(s), 'EX')
        T1 = [T1; 1];% 0, control, 1 for aerobic, 0 for activ4brain
        T2 = [T2; 0];% 0, control, 0 for aerobic, 1 for activ4brain
    elseif strcmp(T.Group(s), 'EXCOG')
        T1 = [T1; 0];% 0, control, 1 for aerobic, 0 for activ4brain
        T2 = [T2; 1];% 0, control, 0 for aerobic, 1 for activ4brain
     elseif strcmp(T.Group(s), 'CNT')
        T1 = [T1; 0];% 0, control, 1 for aerobic, 0 for activ4brain
        T2 = [T2; 0];% 0, control, 0 for aerobic, 1 for activ4brain
    end
end

X = [T1, T2, BL, BL.*T1, BL.*T2, ones(length(DV), 1)];

[B,BINT,R,RINT,STATS] = regress(DV,X)

% Linear model not including interactions 
X_main = [T1, T2, BL];
LM_main = fitlm(X_main, DV)

% Linear model with interactions
Xflm = [T1, T2, BL, BL.*T1, BL.*T2];
LM = fitlm(Xflm,DV)

Xflm1 = [T1,BL, BL.*T1];
LM1 = fitlm(Xflm1,DV)

Xflm2 = [T2,BL, BL.*T2];
LM2 = fitlm(Xflm2,DV)

% comparison for each group before and after 

[H,P,CI,STATS] = ttest(DV(T2 == 1), BL(T2 == 1)) 
[H,P,CI,STATS] = ttest(DV(T1 == 1), BL(T1 == 1)) 
[H,P,CI,STATS] = ttest(DV(T1 == 0 & T2 == 0), BL(T1 == 0 & T2 == 0)) 

MD_EXCOG_BL = median(BL(T2 == 1))
SD_EXCOG_BL = std(BL(T2 == 1))
MD_EXCOG_FU = median(DV(T2 == 1))
SD_EXCOG_FU = std(DV(T2 == 1))
MD_EX_BL = median(BL(T1 == 1))
SD_EX_BL = std(BL(T1 == 1))
MD_EX_FU = median(DV(T1 == 1))
SD_EX_FU = std(DV(T1 == 1))
MD_CNT_BL = median(BL(T1 == 0 & T2 == 0))
SD_CNT_BL = std(BL(T1 == 0 & T2 == 0))
MD_CNT_FU = median(DV(T1 == 0 & T2 == 0))
SD_CNT_FU = std(DV(T1 == 0 & T2 == 0))

