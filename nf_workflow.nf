#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.input_mri_file = "./data/test_downloadpublicdata.txt"
params.parallelism = "1"
params.filepersplit = "1000"
params.autodownload = "No"
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

process autodownload {
    publishDir "./nf_output", mode: 'copy'

    conda "$TOOL_FOLDER/conda_env.yml"

    input:
    val x

    output:
    file 'mri_file.tsv'

    """
    wget -O mri_file.tsv https://datasetcache.gnps2.org/dataset/downloadmri
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
    python $TOOL_FOLDER/downloadpublicdata/bin/download_public_data_usi.py \
    $input_mri \
    $dataset_location \
    ${input_mri}_summary.tsv \
    --nestfiles 'recreate' \
    --noconversion \
    ${dryrunFlag}
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
    
    dataset_location_ch = Channel.fromPath(params.datasetlocation)

    if(params.autodownload == 'Yes') {
        mri_file_ch = autodownload(1)
    }
    else{
        mri_file_ch = Channel.fromPath(params.input_mri_file)
    }


    // Splitting input file
    splits_ch = splitInput(mri_file_ch)
    
    // Outputting Python
    summaries_ch = processDownload(splits_ch.collect(), dataset_location_ch)

    // Merging the summaries, keeping the headers
    statistics_ch = summaries_ch.collectFile( name: 'summary.tsv', keepHeader: true, storeDir: './nf_output' )

    processDownload_Statistics(statistics_ch)






}
