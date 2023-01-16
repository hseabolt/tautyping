process CREATE_LIST {
    label 'process_low'

    input:
    path(sample_sheet)

    output:
	path "genomes.list"               , emit: list
	
    when:
    task.ext.when == null || task.ext.when

    script:  
    def args = task.ext.args ?: ''
    """
	cut $args $sample_sheet > genomes.list
    """
}