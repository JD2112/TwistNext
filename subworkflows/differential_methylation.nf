include { EDGER_ANALYSIS } from '../modules/edger'
include { METHYLKIT_ANALYSIS } from '../modules/methylkit'

workflow DIFFERENTIAL_METHYLATION {
    take:
    coverage_files    // Channel: [ val(meta), path(coverage) ]
    design_file       // Path: design file
    compare_str       // String: comparison string
    coverage_threshold // Integer: coverage threshold
    method            // String: 'edger', 'methylkit', or 'both'

    main:
    ch_versions = Channel.empty()

    // Prepare the coverage files channel
    coverage_files_prepared = coverage_files
        .map { meta, file -> file }
        .collect()

    if (method == 'edger' || method == 'both') {
        EDGER_ANALYSIS (
            coverage_files_prepared,
            design_file,
            compare_str,
            coverage_threshold
        )
        ch_edger_results = EDGER_ANALYSIS.out.results
        ch_versions = ch_versions.mix(EDGER_ANALYSIS.out.versions)
    }

    if (method == 'methylkit' || method == 'both') {
        METHYLKIT_ANALYSIS (
            coverage_files_prepared,
            design_file,
            compare_str,
            coverage_threshold
        )
        ch_methylkit_results = METHYLKIT_ANALYSIS.out.results
        ch_versions = ch_versions.mix(METHYLKIT_ANALYSIS.out.versions)
    }

    // Combine results based on the method
    ch_results = Channel.empty()
    if (method == 'edger') {
        ch_results = ch_edger_results.map { result -> tuple('edger', result) }
    } else if (method == 'methylkit') {
        ch_results = ch_methylkit_results.map { result -> tuple('methylkit', result) }
    } else if (method == 'both') {
        ch_results = ch_edger_results.map { result -> tuple('edger', result) }
            .mix(ch_methylkit_results.map { result -> tuple('methylkit', result) })
    } else {
        error "Invalid differential methylation method: ${method}. Choose 'edger', 'methylkit', or 'both'."
    }

    emit:
    results  = ch_results    // Channel: [ val(method), path(results) ]
    versions = ch_versions   // Channel: [ path(versions.yml) ]
}