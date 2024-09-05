#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.input_mri_file = "./data/test_downloadpublicdata.txt"
params.parallelism = "1"
params.filepersplit = "1000"
params.dryrun = "Yes"

params.datasetlocation = "/data/datasets/server"

TOOL_FOLDER = "$baseDir/bin"

process splitInput {
    publishDir "./nf_output", mode: 'copy'

    conda "$TOOL_FOLDER/conda_env.yml"

    input:
    file input_mri_file

    output:
    file 'file_splits/*'

    """
    mkdir -p file_splits
    python $TOOL_FOLDER/split_file.py \
    $input_mri_file \
    $params.filepersplit \
    file_splits
    """
}

process processDownload {
    publishDir "./nf_output", mode: 'copy'

    conda "$TOOL_FOLDER/conda_env.yml"

    maxForks params.parallelism

    input:
    each file(input_mri)
    file dataset_location

    output:
    file '*summary.tsv'

    script:
    def dryrunFlag = params.dryrun == 'Yes' ? '--dryrun' : ''

    
    """
    python $TOOL_FOLDER/download_public_data_usi.py \
    $input_mri \
    $dataset_location \
    ${input_mri}_summary.tsv \
    --nestfiles 'recreate' \
    --noconversion \ 
    $dryrunFlag
    """
}




workflow {
    data_ch = Channel.fromPath(params.input_mri_file)
    dataset_location_ch = Channel.fromPath(params.datasetlocation)

    // Splitting input file
    splits_ch = splitInput(data_ch)
    
    // Outputting Python
    summaries_ch = processDownload(splits_ch.collect(), dataset_location_ch)

    // Merging the summaries, keeping the headers
    summaries_ch.collectFile( name: 'summary.tsv', keepHeader: true, storeDir: './nf_output' )






}
