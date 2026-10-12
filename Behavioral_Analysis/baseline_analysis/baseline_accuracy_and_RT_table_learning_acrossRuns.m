clear; clc;
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(projectRoot);
cfg = load_project_config();
behavioralOutputDir = fullfile(cfg.outputDir, 'Behavioral_Analysis');
if ~isfolder(behavioralOutputDir), mkdir(behavioralOutputDir); end

%new accuracy calculation: accuracy counts only when the participant
%selected the rewarded letter (A:80% / B:20% only counts when part selectA)

data_dir = cfg.rawBehavioralDataDir;
files = dir(data_dir);
files = files([files.isdir]);
files = files(~ismember({files.name},{'.','..'})); % deletes first two files from the list
files = files(endsWith({files.name}, '_L', 'IgnoreCase', true));   % only learning folders

skipNum=[57,74];


all_gr=setdiff(1:75,skipNum); % this is baseline study. EX76=EX20_2 (2nd attendance of EX20), so we dont include EX76 for baseline study.
subjectnumber=length(all_gr); 
processed_parts_learning = NaN(subjectnumber,1); 

trialnumber=30; %30 trials for easy - 30 for medium - 30 for difficult
totalrunno=4; %4 run for learning phase in total

taskdata.RTLearningSession1=NaN(trialnumber*3,subjectnumber,totalrunno);
taskdata.RTLearningSession2=NaN(trialnumber*3,subjectnumber,totalrunno);

taskdata.meanRTLearningSession1=NaN(subjectnumber,totalrunno);
taskdata.meanRTLearningSession2=NaN(subjectnumber,totalrunno);

taskdata.accuracyLearningSession1=NaN(trialnumber*3,subjectnumber,totalrunno);
taskdata.accuracyLearningSession2=NaN(trialnumber*3,subjectnumber,totalrunno);

taskdata.meanaccuracyLearningSession1=NaN(subjectnumber,totalrunno);
taskdata.meanaccuracyLearningSession2=NaN(subjectnumber,totalrunno);

for session=1:2

counter_participant=0;
run_counter=0; 

for f=1:length(files)
    partsName=split(files(f).name,'_');
    partsName=str2num(partsName{1});
    if ismember(partsName,all_gr)
        counter_learning=0;
        counter_participant=counter_participant+1;

        datadirectory=strcat(data_dir,'/',files(f).name);    
        subfiles = dir(fullfile(datadirectory, '*.mat'));

        runno_start=1;
        runno_end=4;  

    
        run_counter=0; 
            for j=runno_start:runno_end %the mat files of each phase files(ex:022L)."ex: S1run1.mat for 022L"  
                %for the 1st session j=23:26
                %for the 2nd session j=27:30
                run_counter=run_counter+1;
                counter_learning=0;
                matname=subfiles(j).name;
                matname=strcat(subfiles(j).folder,'/',matname);
                S=load(matname);
                disp(matname)
                for trl=1:3*trialnumber 
                    counter_learning=counter_learning+1;
                    if session==1
                        taskdata.RTLearningSession1(counter_learning,counter_participant,run_counter)=S.experiment.RT(trl); %RT table of all participants
                        if (S.experiment.side(S.experiment.trialorder(trl)) == 1 && S.experiment.select(trl)==1) || (S.experiment.side(S.experiment.trialorder(trl)) == -1 && S.experiment.select(trl)==0)
                            taskdata.accuracyLearningSession1(counter_learning,counter_participant,run_counter)=1; %Accuracy table of all participants
                        else
                            taskdata.accuracyLearningSession1(counter_learning,counter_participant,run_counter)=0;
                        end
                    elseif session==2
                        taskdata.RTLearningSession2(counter_learning,counter_participant,run_counter)=S.experiment.RT(trl); %RT table of all participants
                        if (S.experiment.side(S.experiment.trialorder(trl)) == 1 && S.experiment.select(trl)==1) || (S.experiment.side(S.experiment.trialorder(trl)) == -1 && S.experiment.select(trl)==0)
                            taskdata.accuracyLearningSession2(counter_learning,counter_participant,run_counter)=1; %Accuracy table of all participants
                        else
                            taskdata.accuracyLearningSession2(counter_learning,counter_participant,run_counter)=0;
                        end                
                    end
    
                end     
            end
    end
end

%accuracy and reaction time for all groups of pairs average of all participants
run=0;
for run=1:totalrunno
    for n=1:subjectnumber

            average_accuracy4LearningSession1(n,run)=mean(taskdata.accuracyLearningSession1(:,n,run), "omitnan");
            average_RT4LearningSession1(n,run)=mean(taskdata.RTLearningSession1(:,n,run),"omitnan");

    end
end
no_run=0;
for no_run=1:totalrunno

        accuracy_LearningSession1(no_run) = 100*squeeze(median(average_accuracy4LearningSession1(:,no_run),"omitnan"));
        vals = average_accuracy4LearningSession1(:,no_run);
        nval = sum(~isnan(vals));
        standart_err_Learning_accuracySession1(no_run) = 100*std(vals,'omitnan')/sqrt(nval);
       
        RT_LearningSession1(no_run) = 1000*squeeze(median(average_RT4LearningSession1(:,no_run), "omitnan")); %ms
        vals = average_RT4LearningSession1(:,no_run);
        nval = sum(~isnan(vals));
        standart_err_Learning_RTSession1(no_run) = 1000*std(vals,'omitnan')/sqrt(nval);

end

runno=0;
for runno=1:totalrunno
    for n=1:subjectnumber

            taskdata.meanaccuracyLearningSession1(n,runno)=100*mean(taskdata.accuracyLearningSession1(:,n,runno), "omitnan");
            taskdata.meanRTLearningSession1(n,runno)=1000*mean(taskdata.RTLearningSession1(:,n,runno), "omitnan");

    end
end

end

% =========================
% LEARNING: session-level mean columns
% =========================

Mean_Accuracy_Learning_S1 = median(taskdata.meanaccuracyLearningSession1, 2, 'omitnan');

Mean_RT_Learning_S1 = median(taskdata.meanRTLearningSession1, 2, 'omitnan');

% RT variability per run, then average across runs
stdRT_Learning_S1_runs = squeeze(std(taskdata.RTLearningSession1, 0, 1, 'omitnan')) * 1000; % subj x run

Mean_stdRT_Learning_S1 = median(stdRT_Learning_S1_runs, 2, 'omitnan');

%% for transfer phase
% clear all; clc;
data_dir = cfg.rawBehavioralDataDir;
files = dir(data_dir);
files = files([files.isdir]);
files = files(~ismember({files.name},{'.','..'})); % deletes first two files from the list
files = files(endsWith({files.name}, '_T', 'IgnoreCase', true));   % only transfer folders

skipNum=[21,57,74];
  
all_gr=setdiff(1:75,skipNum);
subjectnumber=length(all_gr);

trialnumber4smallVD=84;%7pairsx 4 presentations per runx3runs=84
trialnumber4mediumVD=60;%5pairsx 4 presentations per runx3runs=60
trialnumber4largeVD=36; %3pairsx 4 presentations per runx3runs=36
totalrunno=3; %3 runs for transfer phase in total
trialnoperrun=(trialnumber4smallVD + trialnumber4mediumVD + trialnumber4largeVD)/3;

taskdata.accuracyTransferSession1=NaN(trialnoperrun,subjectnumber,totalrunno); 
taskdata.RTTransferSession1=NaN(trialnoperrun,subjectnumber,totalrunno); 


taskdata.meanaccuracyTransferSession1=NaN(subjectnumber,totalrunno); 
taskdata.meanRTTransferSession1=NaN(subjectnumber,totalrunno);


counter_participant=0;
run_counter=0;

for f=1:length(files) 
    partsName=split(files(f).name,'_');
    partsName=str2num(partsName{1});
    if ismember(partsName,all_gr)
        counter_participant=counter_participant+1;
        counter_Transfer=0;
        datadirectory=strcat(data_dir,'/',files(f).name);
        subfiles = dir(fullfile(datadirectory, '*.mat'));

        runno_start = 1;
        runno_end   = 3; 

    
        if partsName == 30
            runno_start = 1;
            runno_end   = 2;
        end

        run_counter=0; 
            for j=runno_start:runno_end %the first 2 are empty. the 3-8's are .asc and .edf files.      
                run_counter=run_counter+1;
                counter_Transfer=0;
                matname=subfiles(j).name;
                matname=strcat(subfiles(j).folder,'/',matname);
                S=load(matname);
                disp(matname)
                for trialno=1:60
                        counter_Transfer= counter_Transfer + 1;
                            
                        taskdata.RTTransferSession1(counter_Transfer,counter_participant,run_counter)=S.experiment.RT(trialno); %reaction time for transfer
                            
                            if S.experiment.select(trialno) == S.experiment.valuable(trialno) %accuracy table for transfer 
                                %the difference between S.experiment.reward and
                                %S.experiment.valuable is valuable the correct
                                %answer of that trial. we randomized the order of
                                %trials (initial order is in S.experiment.reward)
                                taskdata.accuracyTransferSession1(counter_Transfer,counter_participant,run_counter)=1;
                            else
                                taskdata.accuracyTransferSession1(counter_Transfer,counter_participant,run_counter)=0;
                            end  
                end
            end
    end
end


%accuracy and reaction time for all groups of pairs average of all participants
runno=0;
for runno=1:totalrunno
    for n=1:subjectnumber

            average_accuracy4TransferSession1(n,runno)=mean(taskdata.accuracyTransferSession1(:,n,runno), "omitnan");
            average_RT4TransferSession1(n,runno)=mean(taskdata.RTTransferSession1(:,n,runno),"omitnan");

    end
end
run=0;
for run=1:totalrunno
        accuracy4TransferSession1(run)=100*median(average_accuracy4TransferSession1(:,run), "omitnan");    
        vals = average_accuracy4TransferSession1(:,run);
        nval = sum(~isnan(vals));
        standart_err_Transfer_accuracySession1(run) = 100*std(vals,'omitnan')/sqrt(nval);        
        
        RT4TransferSession1(run)=1000*median(average_RT4TransferSession1(:,run), "omitnan"); %(ms)
        vals = average_RT4TransferSession1(:,run);
        nval = sum(~isnan(vals));
        standart_err_Transfer_RTSession1(run) = 1000*std(vals,'omitnan')/sqrt(nval);        


end
run=0;
for run=1:totalrunno
    for n=1:subjectnumber

            taskdata.meanaccuracyTransferSession1(n,run)=100*mean(taskdata.accuracyTransferSession1(:,n,run), "omitnan"); 
            taskdata.meanRTTransferSession1(n,run)=1000*mean(taskdata.RTTransferSession1(:,n,run),"omitnan");

    end
end


% =========================
% TRANSFER: session-level mean columns
% =========================

Mean_Accuracy_Transfer_S1 = median(taskdata.meanaccuracyTransferSession1, 2, 'omitnan');

Mean_RT_Transfer_S1 = median(taskdata.meanRTTransferSession1, 2, 'omitnan');

% RT variability per run, then average across runs
stdRT_Transfer_S1_runs = squeeze(std(taskdata.RTTransferSession1, 0, 1, 'omitnan')) * 1000; % subj x run

Mean_stdRT_Transfer_S1 = median(stdRT_Transfer_S1_runs, 2, 'omitnan');

%% CREATE A TABLE FOR SPSS


skipNum=[57,74];
all_gr=setdiff(1:75,skipNum);
Parts_Code = all_gr';

Mean_Accuracy_Learning_S1 = median(taskdata.meanaccuracyLearningSession1, 2, 'omitnan');


Mean_RT_Learning_S1 = median(taskdata.meanRTLearningSession1, 2, 'omitnan');


stdRT_Learning_S1_runs = squeeze(std(taskdata.RTLearningSession1, 0, 1, 'omitnan')) * 1000;


Mean_stdRT_Learning_S1 = median(stdRT_Learning_S1_runs, 2, 'omitnan');

Accuracy_Learning_Run1_S1=taskdata.meanaccuracyLearningSession1(:,1);
Accuracy_Learning_Run2_S1=taskdata.meanaccuracyLearningSession1(:,2);
Accuracy_Learning_Run3_S1=taskdata.meanaccuracyLearningSession1(:,3);
Accuracy_Learning_Run4_S1=taskdata.meanaccuracyLearningSession1(:,4);


RT_Learning_Run1_S1=taskdata.meanRTLearningSession1(:,1);
RT_Learning_Run2_S1=taskdata.meanRTLearningSession1(:,2);
RT_Learning_Run3_S1=taskdata.meanRTLearningSession1(:,3);
RT_Learning_Run4_S1=taskdata.meanRTLearningSession1(:,4);


SPSS_Tablee_Learning=table(Parts_Code,Mean_Accuracy_Learning_S1, Mean_RT_Learning_S1,Mean_stdRT_Learning_S1, ...
    Accuracy_Learning_Run1_S1,Accuracy_Learning_Run2_S1,Accuracy_Learning_Run3_S1,Accuracy_Learning_Run4_S1, ...
    RT_Learning_Run1_S1,RT_Learning_Run2_S1,RT_Learning_Run3_S1,RT_Learning_Run4_S1);

filename1 = fullfile(behavioralOutputDir, 'Baseline_data_acrossRuns_learning.xlsx');
writetable(SPSS_Tablee_Learning,filename1,'Sheet',1)




% transfer phase 
skipNum_transfer=[21,57,74];
  
all_gr_transfer=setdiff(1:75,skipNum_transfer);
Parts_Code2 = all_gr_transfer';

Mean_Accuracy_Transfer_S1 = median(taskdata.meanaccuracyTransferSession1, 2, 'omitnan');


Mean_RT_Transfer_S1 = median(taskdata.meanRTTransferSession1, 2, 'omitnan');


stdRT_Transfer_S1_runs = squeeze(std(taskdata.RTTransferSession1, 0, 1, 'omitnan')) * 1000;


Mean_stdRT_Transfer_S1 = median(stdRT_Transfer_S1_runs, 2, 'omitnan');


Accuracy_Transfer_Run1_S1=taskdata.meanaccuracyTransferSession1(:,1);
Accuracy_Transfer_Run2_S1=taskdata.meanaccuracyTransferSession1(:,2);
Accuracy_Transfer_Run3_S1=taskdata.meanaccuracyTransferSession1(:,3);


RT_Transfer_Run1_S1=taskdata.meanRTTransferSession1(:,1);
RT_Transfer_Run2_S1=taskdata.meanRTTransferSession1(:,2);
RT_Transfer_Run3_S1=taskdata.meanRTTransferSession1(:,3);


SPSS_Tablee_Transfer=table(Parts_Code2, Mean_Accuracy_Transfer_S1, ...
    Mean_RT_Transfer_S1, Mean_stdRT_Transfer_S1, ...
    Accuracy_Transfer_Run1_S1,Accuracy_Transfer_Run2_S1,Accuracy_Transfer_Run3_S1, ...
    RT_Transfer_Run1_S1,RT_Transfer_Run2_S1,RT_Transfer_Run3_S1);

filename2 = fullfile(behavioralOutputDir, 'Baseline_data_acrossRuns_transfer.xlsx');
writetable(SPSS_Tablee_Transfer,filename2,'Sheet',1)

