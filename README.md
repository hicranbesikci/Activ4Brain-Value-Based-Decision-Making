# Improvement in value-based decision-making through a combined cognitive training and aerobic exercise program (Activ4Brain) in older adults

This repository contains the MATLAB analysis code associated with the study **“Improvement in value-based decision-making through a combined cognitive training and aerobic exercise program (Activ4Brain) in older adults.”**

## Authors

Hicran Beşikci, Kaan Akalp, Matilde Vasconcelos, Luís Rama, Ana Rita Sousa e Silva, Elena Zamfir, Beatriz Branquinho Gomes, Ana Maria Teixeira, Miguel Castelo-Branco, and Maria José Ribeiro.

## Repository contents

| Directory | Description |
| --- | --- |
| `Acc_Analysis/` | Analyses of the cognitive training tasks and their associations with reinforcement-learning outcomes. |
| `Behavioral_Analysis/` | Behavioral accuracy, reaction-time, baseline, pre/post, and visualization analyses. |
| `Computational_Modelling/` | Reinforcement-learning model fitting, likelihood functions, parameter recovery, and parameter plots. |
| `Satisfaction_Survey_Analysis/` | Satisfaction questionnaire and System Usability Scale visualizations. |
| `Statistical_Analysis/` | Intervention analyses for behavioral and computational outcomes. |

The repository contains code only. Participant-level data and study data files are not distributed here.

## Software requirements

The code was developed using:

- MATLAB R2025b
- Statistics and Machine Learning Toolbox
- Optimization Toolbox
- EEGLAB v2026.0.0

EEGLAB must be installed separately and available on the MATLAB path before running the scripts in `Acc_Analysis/`.

## Local configuration

Data paths are kept outside the version-controlled code so that participant data and computer-specific directory names are not uploaded to GitHub.

1. Copy `config_example.m` and rename the copy to `config_local.m`.
2. Open `config_local.m` and replace each example path with the corresponding data directory on your computer.
3. Do not commit `config_local.m`. It is excluded by `.gitignore`.

The configuration includes separate locations for behavioral data, cognitive-task data, computational-model data, and satisfaction-survey data.

## Project setup

Set the MATLAB Current Folder to the root of this repository and run:

```matlab
cfg = setup_project();
```

This command:

- adds the analysis directories to the MATLAB path;
- loads the local configuration;
- creates the local `outputs/` directory; and
- reports configured data directories that cannot be found.

Generated results are written under `outputs/`. This directory is excluded from version control.

## Expected data files

The scripts expect study data with the original variable names and structures. Key inputs include:

- `SPSS_Table_learning_1vs2ndSession_V5.xlsx`
- `SPSS_Table_transfer_1vs2ndSession_V5.xlsx`
- `All_FittedParameters_Merged_withGroups.csv`
- `SATISFACTION_QUESTIONARY_withExcluded.xlsx`
- participant-level MATLAB files used by the behavioral, cognitive-task, and computational-model analyses

These files are not included in this repository. Researchers with authorized access to compatible data can specify their local directories in `config_local.m`.

## Analysis workflow

### Behavioral analyses

The scripts in `Behavioral_Analysis/` generate pre/post plots and behavioral summaries. Within `Behavioral_Analysis/baseline_analysis/`:

1. `accuracy_and_RT_table_learning_and_transfer_SPSS.m` generates difficulty-level baseline tables and MATLAB result files.
2. `baseline_accuracy_and_RT_table_learning_acrossRuns.m` generates across-run baseline tables.
3. `plot_baseline_data_learning_transfer_v2_without_diffLvl.m` reads those generated files and creates the baseline plots.

### Cognitive-task analyses

The task-specific scripts in `Acc_Analysis/` generate intermediate result tables under `outputs/Acc_Analysis/`. The correlation scripts use these generated tables together with the reinforcement-learning spreadsheet.

The task scripts require EEGLAB because they use EEGLAB import, event, epoching, and baseline-correction functions.

### Computational modelling

`Computational_Modelling/q_learning_model.m` fits the reinforcement-learning model for each participant and session. It saves fitted parameters and minimum negative log-likelihood values under `outputs/Computational_Modelling/`.

The Rescorla–Wagner (Q-learning) model includes three free parameters:

- `alpha_gain`: learning rate for positive prediction errors;
- `alpha_loss`: learning rate for negative prediction errors; and
- `beta`: inverse-temperature parameter controlling choice stochasticity.

The files under `Computational_Modelling/recovery/` perform parameter simulation and recovery. `Plot4_effect_of_intervention_comp_parameters_boxplot.m` creates intervention plots from the merged fitted-parameter table specified in the local configuration.

### Statistical analyses

The scripts in `Statistical_Analysis/` perform the intervention analyses for learning, transfer, and computational parameters. Generated statistical summary workbooks are written under `outputs/`.

### Satisfaction survey

The scripts in `Satisfaction_Survey_Analysis/` read the configured questionnaire workbook and generate the corresponding visualizations. Exported figures are written under `outputs/Satisfaction_Survey_Analysis/`.

## Data availability

This is a code-only repository. Study data are not included. Data access, where applicable, is governed by the data-availability conditions described in the associated article.

## License

The code in this repository is available under the [MIT License](LICENSE).

## Citation

When using this code, please cite the associated article and the archived release of this repository. Publication and repository DOI information will be added when available.
