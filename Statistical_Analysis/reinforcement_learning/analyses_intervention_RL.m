%% Learning Phase
% post-test outcome + baseline covariate
clc; clear;
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(projectRoot);
cfg = load_project_config();
if ~isfolder(cfg.outputDir), mkdir(cfg.outputDir); end

fileex = fullfile(cfg.behavioralGroupDataDir, ...
    'SPSS_Table_learning_1vs2ndSession_V5.xlsx');

T = readtable(fileex);
T(62,:) = []; %Exclusion of EX020_2 (=EX076)

DV  = T.Mean_RT_Learning_S2; % dependent variable
BL = T.Mean_RT_Learning_S1;  % baseline

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
X_main = [T1, T2, BL];
LM_main = fitlm(X_main, DV)

% Linear model with interactions
Xflm = [T1, T2, BL, BL.*T1, BL.*T2];
LM = fitlm(Xflm,DV) % Linear model. Here fitlm gives info of p values, r2, confidence intervals and ANOVA table

% EX vs CNT 
Xflm1 = [T1,BL, BL.*T1]; 
LM1 = fitlm(Xflm1,DV)

% EXCOG vs CNT
Xflm2 = [T2,BL, BL.*T2];
LM2 = fitlm(Xflm2,DV)

% model comparison of LM vs LM_main for RT:
nestedF(LM_main, LM, 'Learning phase - RT');

% normality test for sessions
[~, p_S1] = lillietest(BL) %S1
[~, p_S2] = lillietest(DV) %S2

% comparison for each group before and after 

[H,P,CI,STATS] = ttest(DV(T2 == 1), BL(T2 == 1)) %excog = activ4brain
[H,P,CI,STATS] = ttest(DV(T1 == 1), BL(T1 == 1)) %ex = aerobic
[H,P,CI,STATS] = ttest(DV(T1 == 0 & T2 == 0), BL(T1 == 0 & T2 == 0)) % cnt = control

[P,H, STATS] = signrank (DV(T2 == 1), BL(T2 == 1)) %excog = activ4brain
[P,H, STATS] = signrank (DV(T1 == 1), BL(T1 == 1)) %ex = aerobic
[P,H, STATS] = signrank (DV(T1 == 0 & T2 == 0), BL(T1 == 0 & T2 == 0)) % cnt = control

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

outputFile = fullfile(cfg.outputDir, 'Results_Summary_Learning_RT.xlsx');
if exist(outputFile,'file'), delete(outputFile); end   % start fresh

% RT block (after LM and LM_main are fit)
saveResults(outputFile, 'RT', LM, LM_main, DV, BL, T1, T2);

%% accuracy

DV  = T.Mean_Accuracy_Learning_S2;
BL = T.Mean_Accuracy_Learning_S1;

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

% model comparison of LM vs LM_main for accuracy:
nestedF(LM_main, LM, 'Learning phase - Accuracy');

% normality test for sessions
[~, p_S1] = lillietest(BL) %S1
[~, p_S2] = lillietest(DV) %S2

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

outputFile = fullfile(cfg.outputDir, 'Results_Summary_Learning_Accuracy.xlsx');
if exist(outputFile,'file'), delete(outputFile); end   % start fresh

% accuracy block
saveResults(outputFile, 'ACC', LM, LM_main, DV, BL, T1, T2);

%% RT variability


DV  = T.Mean_stdRT_Learning_S2;
BL = T.Mean_stdRT_Learning_S1;

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

% model comparison of LM vs LM_main for RT variability:
nestedF(LM_main, LM, 'Learning phase - stdRT');

% normality test for sessions
[~, p_S1] = lillietest(BL) %S1
[~, p_S2] = lillietest(DV) %S2

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

outputFile = fullfile(cfg.outputDir, 'Results_Summary_Learning_stdRT.xlsx');
if exist(outputFile,'file'), delete(outputFile); end   % start fresh

%RT variability block
saveResults(outputFile, 'stdRT', LM, LM_main, DV, BL, T1, T2);
