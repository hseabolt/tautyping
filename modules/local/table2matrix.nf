process TABLE2MATRIX {
    label "process_low"

    input:
    path(table)

    output:
	path "*.matrix"               , emit: matrix
	
    when:
    task.ext.when == null || task.ext.when

    script:  
    def args = task.ext.args ?: ''
	def prefix = task.ext.prefix ?: 'matrix'
	"""
	table2matrix -i $table $args > ${prefix}.matrix
	"""
}
