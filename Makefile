run:
	nextflow run ./nf_workflow.nf -resume -c nextflow.config \
	--filepersplit=3 --input_mri_file=./data/test_downloadpublicdata.txt \
	--datasetlocation=./data/datasets --parallelism=3
