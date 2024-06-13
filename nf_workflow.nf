#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.input_spectra = "README.md"

TOOL_FOLDER = "$baseDir/bin"

process processDataPython {
    publishDir "./nf_output", mode: 'copy'

    conda "$TOOL_FOLDER/conda_env.yml"

    input:
    file input 

    output:
    file 'summary.tsv'
    path ''


    """
    python $TOOL_FOLDER/download_public_data_usi.py $input python_output.tsv downloaded summary.tsv --nestfiles 'recreate'
    """
}


workflow {
    data_ch = Channel.fromPath(params.input_spectra)
    
    // Outputting Python
    processDataPython(data_ch)

}
