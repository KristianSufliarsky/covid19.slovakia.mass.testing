##' Estimate minimum specificity of the antigen test used for mass testing in
##' Slovakia
##'
##' @importFrom dplyr select filter rowwise mutate group_by summarise ungroup
##' @importFrom tibble tibble
##' @importFrom tidyr pivot_longer separate pivot_wider expand_grid nest unnest
##' @importFrom purrr map
##' @export
##' @param cutoff probability cut-off, i.e. x if minimal specificty is to be
##' estabilshed with probability >= x
estimate_min_specificity <- function(cutoff = 0.95) {
  ms.tst %>%
    select(county, attendance_1, attendance_2, attendance_3,
           positive_1, positive_2, positive_3) %>%
    pivot_longer(-county) %>%
    separate("name", c("name", "round"),"_") %>%
    pivot_wider() %>%
    filter(!is.na(attendance)) -> dta

  N <- 100
  samples <- 100

  spec <- dta %>%
    expand_grid(specificity = seq(99.7/100, 99.9995/100, length.out = N)) %>%
    ## probability of seeing positives given specificty is at most x
    ## (where at the maximum all positives are false positives)
    mutate(p = 1 - pbeta(1 - specificity, positive + 1,
                         attendance - positive + 1)) %>%
    group_by(specificity) %>%
    ## overall probability that specificity is at most x
    summarise(probability = prod(p), .groups = "drop") %>%
    ungroup() %>%
    ## get probability that specificity is at least x
    filter(probability < 1 - cutoff) %>%
    summarise(min_spec = max(specificity)) %>%
    .$min_spec

  return(spec)
}
