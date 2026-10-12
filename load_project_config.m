function cfg = load_project_config()
%LOAD_PROJECT_CONFIG Load machine-specific paths for the analysis scripts.

projectRoot = fileparts(mfilename('fullpath'));
configFile = fullfile(projectRoot, 'config_local.m');

if ~isfile(configFile)
    error(['Local configuration was not found. Copy config_example.m to ' ...
        'config_local.m and update the data directories for your computer.']);
end

run(configFile);

if ~exist('cfg', 'var') || ~isstruct(cfg)
    error('config_local.m must create a structure named cfg.');
end

cfg.projectRoot = projectRoot;
cfg.outputDir = fullfile(projectRoot, 'outputs');
end
