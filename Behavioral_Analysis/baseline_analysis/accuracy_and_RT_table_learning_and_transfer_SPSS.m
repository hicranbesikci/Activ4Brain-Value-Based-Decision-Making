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

gr_excog=[4,7,8,9,10,12,25,28,30,32,36]; %11 participants
gr_ex=[3,6,11,14,29,31,33,34]; %8 participants
gr_cnt=[15,16,18,19,20,22,23,24,25,26,35]; %11 participants
skipNum=[1,2,5,13,17,27,37,43,44,57,59,61,65,74];
skipNum4baseline=[57,74];
onlybaselinedata=[1,2,5,13,17,27,37,43,44,59,65];
all_gr=(1:75); %it will be until 75 bcs EX76 is the 2nd participation of EX20.
%this is baseline analysis so we don't count EX76.
all_gr(skipNum4baseline)=[];
       
for session=1:1
%     if session==1
%         runno_start=23;
%         runno_end=26;
%     elseif session==2
%         runno_start=27;
%         runno_end=30;
%     end
trialnumber=30; %30 trials for easy - 30 for medium - 30 for difficult
subjectnumber=length(all_gr);
totalrunno=4; %4 runs for learning phase in total

taskdata.easypairRT=NaN(trialnumber*totalrunno,subjectnumber);
taskdata.mediumpairRT=NaN(trialnumber*totalrunno,subjectnumber);
taskdata.difficultpairRT=NaN(trialnumber*totalrunno,subjectnumber);

taskdata.easypairmeanRT=NaN(subjectnumber,1);
taskdata.mediumpairmeanRT=NaN(subjectnumber,1);
taskdata.difficultpairmeanRT=NaN(subjectnumber,1);

taskdata.accuracyeasypair=NaN(trialnumber*totalrunno,subjectnumber);
taskdata.accuracymediumpair=NaN(trialnumber*totalrunno,subjectnumber);
taskdata.accuracydifficultpair=NaN(trialnumber*totalrunno,subjectnumber);

taskdata.meanaccuracyeasypair=NaN(subjectnumber,1);
taskdata.meanaccuracymediumpair=NaN(subjectnumber,1);
taskdata.meanaccuracydifficultpair=NaN(subjectnumber,1);

counter_participant=0;
for f=4:2:length(files)-3 %beacuse we dont include ex76 (=ex20_2)
    partsName=split(files(f).name,'_');
    partsName=str2num(partsName{1});
    counter_easypair=0;
    counter_mediumpair=0;
    counter_difficultpair=0;
    counter_participant=counter_participant+1;
    if ismember(partsName,onlybaselinedata)
        datadirectory=strcat(data_dir,'/',files(f).name);    
        subfiles = dir(datadirectory);
        runno_start=8;
        runno_end=11;
    else
        datadirectory=strcat(data_dir,'/',files(f).name);    
        subfiles = dir(datadirectory);
        runno_start=13;
        runno_end=16;
    end
    if partsName==17
        datadirectory=strcat(data_dir,'/',files(f).name);    
        subfiles = dir(datadirectory);        
        runno_start=12;
        runno_end=15; 
    end
    if partsName==20
        datadirectory=strcat(data_dir,'/',files(f).name);    
        subfiles = dir(datadirectory);        
        runno_start=18;
        runno_end=21; 
    end
    if partsName==23
        datadirectory=strcat(data_dir,'/',files(f).name);    
        subfiles = dir(datadirectory);        
        runno_start=14;
        runno_end=17; 
    end    
        for j=runno_start:runno_end %the mat files of each phase files(ex:022L)."ex: S1run1.mat for 022L"  
            %for the 1st session j=23:26
            %for the 2nd session j=27:30
            matname=subfiles(j).name;
            matname=strcat(subfiles(j).folder,'/',matname);
            S=load(matname);
            for trl=1:3*trialnumber    
                if S.experiment.trialorder(trl) <=30 %for easy pairs
                    counter_easypair=counter_easypair+1;
                    taskdata.easypairRT(counter_easypair,counter_participant)=S.experiment.RT(trl); %RT table of all participants
                    if (S.experiment.side(S.experiment.trialorder(trl)) == 1 && S.experiment.select(trl)==1) || (S.experiment.side(S.experiment.trialorder(trl)) == -1 && S.experiment.select(trl)==0)
                        taskdata.accuracyeasypair(counter_easypair,counter_participant)=1; %Accuracy table of all participants
                    else
                        taskdata.accuracyeasypair(counter_easypair,counter_participant)=0;
                    end
                elseif (30 < S.experiment.trialorder(trl)) && (S.experiment.trialorder(trl) <= 60)  % for medium pairs
                    counter_mediumpair=counter_mediumpair+1;
                    taskdata.mediumpairRT(counter_mediumpair,counter_participant)=S.experiment.RT(trl);
                    if (S.experiment.side(S.experiment.trialorder(trl)) == 1 && S.experiment.select(trl)==1) || (S.experiment.side(S.experiment.trialorder(trl)) == -1 && S.experiment.select(trl)==0)
                        taskdata.accuracymediumpair(counter_mediumpair,counter_participant)=1;
                    else
                        taskdata.accuracymediumpair(counter_mediumpair,counter_participant)=0;
                    end                
                elseif (60 < S.experiment.trialorder(trl)) && (S.experiment.trialorder(trl) <= 90)  % for difficult pairs
                    counter_difficultpair=counter_difficultpair+1;
                    taskdata.difficultpairRT(counter_difficultpair,counter_participant)=S.experiment.RT(trl);
                    if (S.experiment.side(S.experiment.trialorder(trl)) == 1 && S.experiment.select(trl)==1) || (S.experiment.side(S.experiment.trialorder(trl)) == -1 && S.experiment.select(trl)==0) %for accuracy
                        taskdata.accuracydifficultpair(counter_difficultpair,counter_participant)=1;
                    else
                        taskdata.accuracydifficultpair(counter_difficultpair,counter_participant)=0;
                    end                
                end
            end     
        end
end

%accuracy and reaction time for all groups of pairs average of all participants
for n=1:subjectnumber
average_accuracy4easypair(n)=mean(taskdata.accuracyeasypair(:,n), "omitnan");
average_RT4easypair(n)=mean(taskdata.easypairRT(:,n),"omitnan");
average_accuracy4mediumpair(n)=mean(taskdata.accuracymediumpair(:,n), "omitnan");
average_RTmediumpair(n)=mean(taskdata.mediumpairRT(:,n),"omitnan");
average_accuracy4difficultpair(n)=mean(taskdata.accuracydifficultpair(:,n), "omitnan");
average_RT4difficultpair(n)=mean(taskdata.difficultpairRT(:,n),"omitnan");
end

                accuracy_easypair = 100*squeeze(mean(average_accuracy4easypair, "omitnan"));
                accuracy_mediumpair = 100*squeeze(mean(average_accuracy4mediumpair, "omitnan"));
                accuracy_difficultpair = 100*squeeze(mean(average_accuracy4difficultpair, "omitnan"));

                standart_err_easypair_accuracy = 100*squeeze(std(average_accuracy4easypair))/sqrt(subjectnumber); %standart error for easy pair
                standart_err_mediumpair_accuracy = 100*squeeze(std(average_accuracy4mediumpair))/sqrt(subjectnumber); %standart error for medium pair
                standart_err_difficultpair_accuracy =100*squeeze(std(average_accuracy4difficultpair))/sqrt(subjectnumber); %standart error for difficult pair
                
                RT_easypair = 1000*squeeze(mean(average_RT4easypair, "omitnan")); %ms
                RT_mediumpair = 1000*squeeze(mean(average_RTmediumpair, "omitnan"));
                RT_difficultpair = 1000*squeeze(mean(average_RT4difficultpair, "omitnan"));


                standart_err_easypairRT = 1000*squeeze(std(average_RT4easypair))/sqrt(subjectnumber); %standart error for easy pair
                standart_err_mediumpairRT = 1000*squeeze(std(average_RTmediumpair))/sqrt(subjectnumber); %standart error for medium pair
                standart_err_difficultpairRT = 1000*squeeze(std(average_RT4difficultpair))/sqrt(subjectnumber); %standart error for difficult pair

for n=1:subjectnumber
    taskdata.meanaccuracyeasypair(n)=100*mean(taskdata.accuracyeasypair(:,n), "omitnan");
    taskdata.easypairmeanRT(n)=1000*mean(taskdata.easypairRT(:,n), "omitnan");
    taskdata.meanaccuracymediumpair(n)=100*mean(taskdata.accuracymediumpair(:,n), "omitnan");
    taskdata.mediumpairmeanRT(n)=1000*mean(taskdata.mediumpairRT(:,n), "omitnan");
    taskdata.meanaccuracydifficultpair(n)=100*mean(taskdata.accuracydifficultpair(:,n), "omitnan");
    taskdata.difficultpairmeanRT(n)=1000*mean(taskdata.difficultpairRT(:,n), "omitnan");
end


end

%% CREATE A TABLE 


% Label={'Parts_Code','Accuracy_Easy_Learning','Accuracy_Medium_Learning','Accuracy_Difficult_Learning','Accuracy_Easy_Transfer','Accuracy_Medium_Transfer','Accuracy_Difficult_Transfer','RT_Easy_Learning','RT_Medium_Learning','RT_Difficult_Learning','RT_Easy_Transfer','RT_Medium_Transfer','RT_Difficult_Transfer'};
Parts_Code=(all_gr)';
Accuracy_Easy_Learning=taskdata.meanaccuracyeasypair(:);
Accuracy_Medium_Learning=taskdata.meanaccuracymediumpair(:);
Accuracy_Difficult_Learning=taskdata.meanaccuracydifficultpair(:);
RT_Easy_Learning=taskdata.easypairmeanRT(:);
RT_Medium_Learning=taskdata.mediumpairmeanRT(:);
RT_Difficult_Learning=taskdata.difficultpairmeanRT(:);

SPSS_Table=table(Parts_Code,Accuracy_Easy_Learning,Accuracy_Medium_Learning,Accuracy_Difficult_Learning,RT_Easy_Learning,RT_Medium_Learning,RT_Difficult_Learning);

filename = fullfile(behavioralOutputDir, 'Baseline_data_by_diflvl_learning.xlsx');
writetable(SPSS_Table,filename,'Sheet',1)
save(fullfile(behavioralOutputDir, 'Baseline_data_by_diflvl_learning.mat'), 'taskdata')


%% for transfer phase
clear; clc;
projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(projectRoot);
cfg = load_project_config();
behavioralOutputDir = fullfile(cfg.outputDir, 'Behavioral_Analysis');
if ~isfolder(behavioralOutputDir), mkdir(behavioralOutputDir); end

data_dir = cfg.rawBehavioralDataDir;
files = dir(data_dir);

gr_excog=[4,7,8,9,10,12,25,28,30,32,36]; %11 participants
gr_ex=[3,6,11,14,29,31,33,34]; %8 participants
gr_cnt=[15,16,18,19,20,22,23,24,25,26,35]; %11 participants
skipNum=[1,2,5,13,17,21,27,37,43,44,57,59,61,65,74];
skipNum4baseline=[21,57,74];
onlybaselinedata=[1,2,5,13,17,27,37,43,44,59,65];
all_gr=(1:75); %it will be until 75 bcs EX76 is the 2nd participation of EX20.
%this is baseline analysis so we don't count EX76.
all_gr(skipNum4baseline)=[];

for session=1:1
%     if session==1
%         runno_start=15;
%         runno_end=17;
%     elseif session==2
%         runno_start=18;
%         runno_end=20;
%     end

trialnumber4smallVD=84; %7pairsx 4 presentations per runx3runs=84
trialnumber4meadiumVD=60; %5pairsx 4 presentations per runx3runs=60
trialnumber4largeVD=36;  %3pairsx 4 presentations per runx3runs=36
subjectnumber=length(all_gr);
totalrunno=3; %3 runs for transfer phase in total

taskdata.accuracysmallvd=NaN(trialnumber4smallVD,subjectnumber); 
taskdata.accuracymediumvd=NaN(trialnumber4meadiumVD,subjectnumber);
taskdata.accuracylargevd=NaN(trialnumber4largeVD,subjectnumber);
taskdata.smallvdRT=NaN(trialnumber4smallVD,subjectnumber); 
taskdata.mediumvdRT=NaN(trialnumber4meadiumVD,subjectnumber); 
taskdata.largevdRT=NaN(trialnumber4largeVD,subjectnumber); 

taskdata.meanaccuracysmallvd=NaN(subjectnumber,1); 
taskdata.meanaccuracymediumvd=NaN(subjectnumber,1);
taskdata.meanaccuracylargevd=NaN(subjectnumber,1);
taskdata.smallvdmeanRT=NaN(subjectnumber,1);
taskdata.mediumvdmeanRT=NaN(subjectnumber,1); 
taskdata.largevdmeanRT=NaN(subjectnumber,1);
counter_participant=0;

for f=5:2:length(files)-2 %beacuse we dont include ex76 (=ex20_2)
    partsName=split(files(f).name,'_');
    partsName=str2num(partsName{1});
    if partsName==21
        continue
    end
        counter_participant=counter_participant+1;
        counter_smallvd=0;
        counter_mediumvd=0;
        counter_largevd=0;
    if ismember(partsName,onlybaselinedata)
        disp(partsName)
        datadirectory=strcat(data_dir,'/',files(f).name);
        subfiles = dir(datadirectory);
        runno_start=6;
        runno_end=8;
    else
        datadirectory=strcat(data_dir,'/',files(f).name);
        subfiles = dir(datadirectory);
        runno_start=9;
        runno_end=11;
    end
    if partsName==30
        runno_start=8;
        runno_end=9;
    elseif partsName==20
        runno_start=12;
        runno_end=14;
    elseif partsName==24
        runno_start=10;
        runno_end=12;
    end
        for j=runno_start:runno_end %the first 2 are empty. the 3-8's are .asc and .edf files.      
            matname=subfiles(j).name;
            matname=strcat(subfiles(j).folder,'/',matname);
            S=load(matname);
            for trialno=1:60
                if (5 <= S.experiment.trialorder(trialno) && S.experiment.trialorder(trialno) <=8) || ...
                        (13 <= S.experiment.trialorder(trialno) && S.experiment.trialorder(trialno) <=16) || ...
                        (25 <= S.experiment.trialorder(trialno) && S.experiment.trialorder(trialno) <=28) || ...
                        (33 <= S.experiment.trialorder(trialno) && S.experiment.trialorder(trialno) <=36) || ... 
                        (41 <= S.experiment.trialorder(trialno) && S.experiment.trialorder(trialno) <=44) || ...
                        (53 <= S.experiment.trialorder(trialno) && S.experiment.trialorder(trialno) <=56) || ...
                        (57 <= S.experiment.trialorder(trialno) && S.experiment.trialorder(trialno) <=60) %for small value dif's pairs
                    counter_smallvd= counter_smallvd + 1;
                    taskdata.smallvdRT(counter_smallvd,counter_participant)=S.experiment.RT(trialno); %reaction time for small vd pairs
                    if S.experiment.select(trialno) == S.experiment.valuable(trialno) %accuracy table for small vd pairs
                        taskdata.accuracysmallvd(counter_smallvd,counter_participant)=1;
                    else
                        taskdata.accuracysmallvd(counter_smallvd,counter_participant)=0;
                    end                  
                elseif (17 <= S.experiment.trialorder(trialno)) && (S.experiment.trialorder(trialno) <= 20) || ...
                        (29 <= S.experiment.trialorder(trialno)) && (S.experiment.trialorder(trialno) <=32) || ...
                        (37 <= S.experiment.trialorder(trialno)) && (S.experiment.trialorder(trialno) <=40) || ...
                        (45 <= S.experiment.trialorder(trialno)) && (S.experiment.trialorder(trialno) <=48) || ....
                        (49 <= S.experiment.trialorder(trialno)) && (S.experiment.trialorder(trialno) <=52) % for medium value dif's pairs
                    counter_mediumvd= counter_mediumvd + 1;
                    taskdata.mediumvdRT(counter_mediumvd,counter_participant)=S.experiment.RT(trialno); %reaction time for medium vd pairs
                    if S.experiment.select(trialno) == S.experiment.valuable(trialno)
                        taskdata.accuracymediumvd(counter_mediumvd,counter_participant)=1;
                    else
                        taskdata.accuracymediumvd(counter_mediumvd,counter_participant)=0;
                    end                 
                elseif (1 <= S.experiment.trialorder(trialno)) && (S.experiment.trialorder(trialno) <= 4) || ...
                        (9 <= S.experiment.trialorder(trialno)) && (S.experiment.trialorder(trialno) <=12) || ...
                        (21 <= S.experiment.trialorder(trialno)) && (S.experiment.trialorder(trialno) <=24)  % for large value dif's pairs (easier ones)
                    counter_largevd= counter_largevd + 1;
                    taskdata.largevdRT(counter_largevd,counter_participant)=S.experiment.RT(trialno); %reaction time for large vd pairs
                    if S.experiment.select(trialno) == S.experiment.valuable(trialno)
                        taskdata.accuracylargevd(counter_largevd,counter_participant)=1;
                    else
                        taskdata.accuracylargevd(counter_largevd,counter_participant)=0;
                    end  
                end
            end
        end
end


%accuracy and reaction time for all groups of pairs average of all participants
for n=1:subjectnumber
average_accuracy4smallvd(n)=mean(taskdata.accuracysmallvd(:,n), "omitnan");
average_RT4smallvd(n)=mean(taskdata.smallvdRT(:,n),"omitnan");
average_accuracy4mediumvd(n)=mean(taskdata.accuracymediumvd(:,n), "omitnan");
average_RTmediumvd(n)=mean(taskdata.mediumvdRT(:,n),"omitnan");
average_accuracy4largevd(n)=mean(taskdata.accuracylargevd(:,n), "omitnan");
average_RT4largevd(n)=mean(taskdata.largevdRT(:,n),"omitnan");
end

                accuracy4smallvd  = 100*mean(average_accuracy4smallvd,  'omitnan');
                accuracy4mediumvd = 100*mean(average_accuracy4mediumvd, 'omitnan');
                accuracy4largevd  = 100*mean(average_accuracy4largevd,  'omitnan');
                
                RT4smallvd  = 1000*mean(average_RT4smallvd,  'omitnan');
                RT4mediumvd = 1000*mean(average_RTmediumvd,  'omitnan');
                RT4largevd  = 1000*mean(average_RT4largevd,  'omitnan');

                standart_err_smallvd_accuracy = 100*squeeze(std(average_accuracy4smallvd))/sqrt(subjectnumber); %standart error for smallvd pairs accuracy
                standart_err_mediumvd_accuracy = 100*squeeze(std(average_accuracy4mediumvd))/sqrt(subjectnumber); %standart error for mediumvd pairs accuracy
                standart_err_largevd_accuracy = 100*squeeze(std(average_accuracy4largevd))/sqrt(subjectnumber); %standart error for largevd pairs accuracy

                standart_err_smallvd_RT = 1000*squeeze(std(average_RT4smallvd))/sqrt(subjectnumber); %standart error for smallvd's pairs RT
                standart_err_mediumvd_RT = 1000*squeeze(std(average_RTmediumvd))/sqrt(subjectnumber); %standart error for mediumvd's pairs RT
                standart_err_largevd_RT = 1000*squeeze(std(average_RT4largevd))/sqrt(subjectnumber); %standart error for largevd's pairs RT 

for n=1:subjectnumber
    taskdata.meanaccuracysmallvd(n)=100*mean(taskdata.accuracysmallvd(:,n), "omitnan"); 
    taskdata.meanaccuracymediumvd(n)=100*mean(taskdata.accuracymediumvd(:,n), "omitnan");
    taskdata.meanaccuracylargevd(n)=100*mean(taskdata.accuracylargevd(:,n), "omitnan");
    taskdata.smallvdmeanRT(n)=1000*mean(taskdata.smallvdRT(:,n),"omitnan");
    taskdata.mediumvdmeanRT(n)=1000*mean(taskdata.mediumvdRT(:,n),"omitnan");
    taskdata.largevdmeanRT(n)=1000*mean(taskdata.largevdRT(:,n),"omitnan");
end

end


%% CREATE A TABLE FOR SPSS
%transfer phase

Parts_Code=(all_gr)';

Accuracy_Easy_Transfer=taskdata.meanaccuracylargevd(:);
Accuracy_Medium_Transfer=taskdata.meanaccuracymediumvd(:);
Accuracy_Difficult_Transfer=taskdata.meanaccuracysmallvd(:);

RT_Easy_Transfer=taskdata.largevdmeanRT(:);
RT_Medium_Transfer=taskdata.mediumvdmeanRT(:);
RT_Difficult_Transfer=taskdata.smallvdmeanRT(:);

SPSS_Table=table(Parts_Code,Accuracy_Easy_Transfer,Accuracy_Medium_Transfer,Accuracy_Difficult_Transfer,RT_Easy_Transfer,RT_Medium_Transfer,RT_Difficult_Transfer);

filename = fullfile(behavioralOutputDir, 'Baseline_data_by_diflvl_transfer.xlsx');
writetable(SPSS_Table,filename,'Sheet',1)
save(fullfile(behavioralOutputDir, 'Baseline_data_by_diflvl_transfer.mat'), 'taskdata')

