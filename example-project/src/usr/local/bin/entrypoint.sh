#!/usr/bin/env bash

# Initialise conda
source /opt/conda/etc/profile.d/conda.sh

# Activate the conda environment
conda activate "${CONDA_ENVIRONMENT_NAME}"

# Run the command
python run.py
