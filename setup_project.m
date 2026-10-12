function cfg = setup_project()
%SETUP_PROJECT Prepare the Activ4Brain analysis code for the current session.
%   CFG = SETUP_PROJECT adds the repository's code directories to the
%   MATLAB path, loads the machine-specific configuration, creates the
%   output directory, and reports any data directories that are missing.

projectRoot = fileparts(mfilename('fullpath'));

codeDirectories = {
    'Acc_Analysis'
    'Behavioral_Analysis'
    'Computational_Modelling'
    'Satisfaction_Survey_Analysis'
    'Statistical_Analysis'
};

addpath(projectRoot);
for index = 1:numel(codeDirectories)
    codeDirectory = fullfile(projectRoot, codeDirectories{index});
    if isfolder(codeDirectory)
        addpath(genpath(codeDirectory));
    end
end

cfg = load_project_config();

if ~isfolder(cfg.outputDir)
    mkdir(cfg.outputDir);
end

dataDirectoryFields = {
    'rawBehavioralDataDir'
    'behavioralInterventionDir'
    'behavioralGroupDataDir'
    'accDataDir'
    'accStimulusDataDir'
    'accAnalysisDataDir'
    'computationalFittedDataDir'
    'computationalParticipantDataDir'
    'computationalParticipantDataNewDir'
    'satisfactionDataDir'
};

missingDirectories = strings(0, 1);
for index = 1:numel(dataDirectoryFields)
    fieldName = dataDirectoryFields{index};
    if ~isfield(cfg, fieldName) || ~isfolder(cfg.(fieldName))
        missingDirectories(end + 1, 1) = string(fieldName); %#ok<AGROW>
    end
end

if isempty(missingDirectories)
    fprintf('Project setup complete. All configured data directories were found.\n');
else
    warning('Project setup complete, but these data directories were not found: %s', ...
        strjoin(missingDirectories, ', '));
end

fprintf('Analysis outputs will be written to:\n%s\n', cfg.outputDir);
end
