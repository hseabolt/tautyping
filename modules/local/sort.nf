process SORT {
	label 'process_low'

    input:
    val file_in

    output:
	path("*.sorted.txt")                 , emit: sorted
	
    when:
    task.ext.when == null || task.ext.when

    script:  
	def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${file_in.SimpleName}"
    """
	sort $args ${file_in} > ${prefix}.sorted.txt
    """
}