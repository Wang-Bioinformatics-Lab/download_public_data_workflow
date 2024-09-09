#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.input_mri_file = "./data/test_downloadpublicdata.txt"

TOOL_FOLDER = "$baseDir/bin"

process processDownload {
    publishDir "./nf_output", mode: 'copy'

    conda "$TOOL_FOLDER/conda_env.yml"

    input:
    file input_mri

    output:
    file 'summary.tsv' 

    """
    python $TOOL_FOLDER/download_public_data_usi.py \
    $input_mri \
    /home/user/LabData/taoxu/projects/download_public_data_workflow/data/datasets/server \
    summary.tsv \
    --nestfiles 'recreate'
    """
}

process processDownload_Statistics {
    publishDir "./nf_output", mode: 'copy'

    conda "$TOOL_FOLDER/conda_env.yml"

    input:
    file input

    output:
    file 'download_summary_statistics.tsv'


    """
    python $TOOL_FOLDER/download_statistics.py \
    $input \
    .
    """
}

workflow {
    data_ch = Channel.fromPath(params.input_mri_file)
    
    // Outputting Python
    statistics_ch = processDownload(data_ch) 
    processDownload_Statistics(statistics_ch)
}
