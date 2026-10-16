#!/bin/bash
#SBATCH --job-name=spliceai_testrun
#SBATCH --partition=all
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --mail-user="j.m.van_der_molen@lumc.nl"
#SBATCH --mail-type="ALL"
#SBATCH --time=00:30:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

REPO_DIR="/exports/sascstudent/jmvandermolen1/SpliceAI_SASC"          #Repo
REF_FASTA="/exports/sascstudent/jmvandermolen1/resources/hg19.fa"     #Reference genome
ENV_PATH="/exports/sascstudent/jmvandermolen1/conda_envs/spliceai_env"  #Path to conda environment

module purge
module load tools/miniconda/python3.9/4.12.0
eval "$(conda shell.bash hook)"

cd "$REPO_DIR" || { echo "REPO_DIR niet gevonden: $REPO_DIR"; exit 1; }

echo "=== Stap 1: ingebouwde unittest (geen extern referentiegenoom nodig) ==="
python -m unittest discover -s tests -v

echo ""
echo "=== Stap 2: testrun op het meegeleverde example VCF ==="
if [ -f "$REF_FASTA" ]; then
    spliceai \
        -I examples/input.vcf \
        -O "${SLURM_JOB_NAME}_${SLURM_JOB_ID}_output.vcf" \
        -R "$REF_FASTA" \
        -A grch37

    echo "--- Vergelijking met de verwachte output (examples/output.vcf) ---"
    diff examples/output.vcf "${SLURM_JOB_NAME}_${SLURM_JOB_ID}_output.vcf" \
        && echo "Output komt overeen met het verwachte resultaat." \
        || echo "Verschillen gevonden, hierboven weergegeven."
else
    echo "REF_FASTA niet gevonden op $REF_FASTA — stap 2 overgeslagen. Vul het juiste pad naar een hg19/GRCh37 fasta in."
fi