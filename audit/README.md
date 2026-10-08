# AI-assisted reproducibility audit

This audit checks and repairs the cached-data workflow for [Bayham et al. (2020)](https://doi.org/10.3390/f11020169). It is not a revised paper. Original Stata source, committed input caches and archival tables/figures are retained. No published PDF, manuscript copy or paper-page image is included.

## Run

From the repository root, with R 4.5, Python 3 and Pandoc available:

```sh
Rscript --vanilla audit/install.R
Rscript --vanilla audit/reproduce.R > audit-run.log 2>&1
```

Installation is an explicit network-enabled step. It installs missing packages into `audit-library/`; a compatible C++ toolchain is needed for fixest. It downloads the original CRAN fixest 0.2.1 archive, verifies its SHA-256, and adds a guarded `DOUBLE_EPS = DBL_EPSILON` compiler compatibility alias. It does not alter estimation code. Modern fixest defaults differ in singleton handling and inference, so silently substituting a newer version is unsupported. R itself and Pandoc must be installed separately.

Other R requirements: dplyr >=1.1, tidyr, purrr, stringr, readr, tibble, lubridate, haven, ggplot2, skimr, lmtest, sandwich, broom, DescTools, margins, MASS, numDeriv, rmarkdown and knitr. Exact tested versions appear in `report/audit/packages.csv`. The original project pinned R 3.6.1; this is a compatibility reconstruction, not that complete historical environment. An existing dependency library can be supplied via `WEATHER_R_LIBS` (platform-separated library directories); `audit-library/`, if present, takes precedence. The runner refuses a different fixest version.

`audit/install.R` requires network access only during setup. The reproduction itself uses local committed caches. No automatic installation or private-data download occurs during reproduction. Runs are deterministic; there is no simulation draw or bootstrap seed. The tested cached workflow fits comfortably on a Mac; no remote computation is required.

## Selected workflow

The runner first tests commander reconciliation, copies source scripts and the seven required caches into isolated generated directories, and rebuilds analysis inputs there. It never overwrites the repository's original caches. It runs three clearly identified data paths:

1. **Corrected (primary):** join on explicit `(ross_inc_id, sitnum, time_since_disco)` keys with a many-to-one assertion. Identical duplicate corrections are collapsed; conflicting corrections are not selected arbitrarily. Only one distinct nonblank candidate is applied. Otherwise retain the original name, including its original missingness. Every source fire-day and non-name value is preserved. No forward fill, blanket “other” replacement, fuzzy matching, or observation deletion is used.
2. **Historical (benchmark):** omit the cleaned-name merge, as in the parent of commit `ffc9038`. This reproduces published resource estimates and stays separate from corrected estimates.
3. **Legacy (diagnostic only):** reproduce the original many-to-many merge and missing-name replacement so before/after differences remain measurable. This path is not a recommended analysis.

The conservative correction does not establish true commander identities. Partial cleaning can fragment one person's records between raw and cleaned spellings; conflicting keys could reflect either multiple commanders or erroneous lookup entries. Adjudicating these requires source knowledge. We preserve information rather than invent identities. The selected estimates and exact group counts are disclosed, and the historical alternative is retained as a sensitivity/benchmark.

Verified compatibility fixes name the outlier flag before binding columns, use readr's current argument spelling, convert skimr's appended row type, and correct DescTools' `Efron` spelling. The existing quasipoisson/resource formulas, outlier rules, PCA and resource sum are unchanged. Source script 06 now loads its orders input. Script 04 reconstructs the resource sum after reloading data; its illustrative manual arithmetic is not used for fitted results.

## Ordered logits in R

`analysis/code/02_growth_potential.R` is primary; the original `.do` is unmodified. Four weather blocks retain the source specification: all weather; precipitation/minimum humidity/maximum temperature/wind; BI/ERC; categorical SFWP. All include GACC × cosine-of-day-of-year main effects/interactions, cause, terrain, year, PC1–PC20 and three restricted-cubic area spline columns. No incident fixed effects or random effects are added.

The ordered response is Low/Medium/High/Extreme. Reference levels are EB GACC, Human cause, Low terrain, year 2007 and SFWP 1. The code's terrain reference differs from the paper's prose; we follow the code. Input year is already numeric-labelled, so its existing categories are used instead of the do-file's string-only `encode year`. Blank strings become missing. `cause_desc` abbreviates `cause_descr` in the Stata source.

The spline uses four knots at input-area percentiles 5, 35, 65 and 95 **before** complete-case filtering: 0.145, 0.950, 5.000, 64.083. The explicit basis follows [Stata mkspline](https://www.stata.com/manuals15/rmkspline.pdf). All nine R quantile types produce these same knots on this input. A centered, invertible QR transformation improves conditioning; fitted parameters and covariance are transformed back. `MASS::polr` maximizes the cumulative-logit likelihood, followed by independently checked Newton polishing using analytic scores and observed Hessian.

Covariance aggregates likelihood scores by `ross_inc_id`, uses inverse observed Hessian on both sides, and applies G/(G−1) for G clusters; no OLS N/(N−K) adjustment is added. This follows [Stata maximum-likelihood cluster correction](https://www.stata.com/manuals13/p_robust.pdf). The implementation checks analytic scores against sandwich, Hessian against numerical derivatives, and average-probability gradients against finite differences.

Margins set each predictor to the do-file's grid for every estimation-sample observation, average all four category probabilities, and compute normal delta-method 95% intervals using the fire-clustered covariance. They are not predictions at mean covariates. The temperature sequence `10(4)45` ends at 42. The exact grids, probabilities and intervals are exported. No parameter, knot or sample selection is tuned to the reference estimates.

## Outputs and validation

- `report/audit/Table3.csv` through `Table6.csv`: primary aggregate estimates with terms and labels preserved together.
- `report/audit/S1-summary.csv`, `S2-growth.csv`, `gp-coefficients.csv`, and resource-coefficients file: regenerated supported supplement sections, with model-specific coverage.
- `report/audit/figures/`: newly generated outlier/PCA, growth, ordered-logit and contingency figures. Figure 4 contains both requested panels.
- `report/Supplement-audit.html`: local, self-contained supported supplement. The missing map is explicitly omitted.
- `report/audit/*benchmark.csv`, `stata-comparison.csv`, validation CSVs and all-path coefficients: comparisons and numerical diagnostics.
- `audit-output/`: ignored intermediate copies, row-level predictions and model objects; never publish these en masse.

Published numeric benchmark tolerances are 0.00005 for four-decimal coefficient/SE values. The saved Stata table uses 0.0005 for three-decimal values. Saved growth results are checked at 1e−10. Published Tables 5–6 label reversals are annotated in the benchmark fixture; the unresolved LAT interaction mismatch is reported, not forced to pass. See [results](RESULTS.md).

Tests cover ambiguous and duplicate commander keys, date mismatch, order invariance, missingness and row preservation; unchanged non-name values; unaffected resource Models 1–3; term-keyed labels; explicit clustered rendering; numerical ordered-logit checks; and historical/saved benchmarks. GitHub CI runs lightweight join/syntax/publication checks. The full local run is the cached-data end-to-end validation, not a claim that CI rebuilds the entire paper.

## Coverage limits

The raw Access databases, ROSS input and preparedness workbook are absent. The map's complexity CSV/cache is absent. The cached run cannot validate extraction, unobserved data edits or the map. The original baseline failed on unavailable/obsolete package APIs; it was established before repairs at commit `5fe40759ee4194f3a5a86926e1105fdc3b66ca0e`.

Native Stata is unavailable. Some translated coefficients, particularly spline terms, differ from archived rounded output. Separate audit probes with float spline storage or complete-case knots did not resolve this; they are not included as selectable production specifications. Original Stata model objects/full-precision margins would help isolate the remaining difference. Close plot agreement is not a claim of exact Stata equivalence.
