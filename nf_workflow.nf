#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.input_mri_file = "./data/test_downloadpublicdata.txt"
params.parallelism = "1"
params.filepersplit = "1000"

params.autodownload = "No"
params.dataset_accession = "No"

params.dryrun = "Yes"

params.filtering_prefix = "No"

// Parsing
parallelism = params.parallelism.toInteger()

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

process accessionToMRI {
    publishDir "./nf_output", mode: 'copy'

    conda "$TOOL_FOLDER/conda_env.yml"

    input:
    val accession

    output:
    file 'mri_file.tsv'

    """
    python $TOOL_FOLDER/accession_to_mri.py $accession mri_file.tsv
    """
}

process filterMRIFile {
    publishDir "./nf_output", mode: 'copy'

    conda "$TOOL_FOLDER/conda_env.yml"

    input:
    file input_mri_file
    val filtering_prefix

    output:
    file 'filtered_mri_file.tsv'

    script:
    """
    (head -n 1 $input_mri_file && grep '$filtering_prefix' $input_mri_file) > filtered_mri_file.tsv
    """
}

process filterBlackLists {
    publishDir "./nf_output", mode: 'copy'

    conda "$TOOL_FOLDER/conda_env.yml"

    input:
    file input_mri_file

    output:
    file 'blacklist_filtered_mri_file.tsv'

    """
    python $TOOL_FOLDER/blacklist_datasets.py \
    $input_mri_file \
    blacklist_filtered_mri_file.tsv
    """
}

process processDownload {
    publishDir "./nf_output", mode: 'copy'

    conda "$TOOL_FOLDER/conda_env.yml"

    maxForks parallelism

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
        _mri_file_ch = autodownload(1)
    }
    else if(params.autodownload == 'Accession') {
        _mri_file_ch = accessionToMRI(params.dataset_accession)
    }
    else{
        _mri_file_ch = Channel.fromPath(params.input_mri_file)
    }

    // If filtering prefix is set, we filter the input file
    if(params.filtering_prefix != 'No') {
        __mri_file_ch = filterMRIFile(_mri_file_ch, params.filtering_prefix)
    }
    else {
        __mri_file_ch = _mri_file_ch
    }

    // TODO We should include a blacklist filtering code here

    mri_file_ch = filterBlackLists(__mri_file_ch)


    // Splitting input file
    splits_ch = splitInput(mri_file_ch)
    
    // Outputting Python
    summaries_ch = processDownload(splits_ch.collect(), dataset_location_ch)

    // Merging the summaries, keeping the headers
    statistics_ch = summaries_ch.collectFile( name: 'summary.tsv', keepHeader: true, storeDir: './nf_output' )

    processDownload_Statistics(statistics_ch)






}
