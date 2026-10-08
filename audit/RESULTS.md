# AI audit findings and substantive changes

Reference: [Bayham et al. (2020), Forests 11, 169](https://doi.org/10.3390/f11020169). Base repository revision: `5fe40759ee4194f3a5a86926e1105fdc3b66ca0e`. These are audit results from the available caches, not a correction issued by the journal or a rewritten manuscript.

## Resource-order estimates

The original cleaned-name merge matches on a nonunique key and replaces unmatched names with “other.” It produces 29 duplicate fire-days in the orders input and 28 extra regression rows. Adding the omitted date key alone does not resolve the lookup conflicts. The selected correction applies only unique candidate names and retains original names otherwise. It preserves all source rows and non-name values.

| High growth potential, total resources | Historical/published path: coefficient (clustered SE) | Legacy committed merge | Corrected primary path |
|---|---:|---:|---:|
| Model 1 | 10.579520 (2.223201) | 10.466424 (2.223630) | 10.579520 (2.223201) |
| Model 2 | 10.239923 (2.525698) | 10.218387 (2.525067) | 10.239923 (2.525698) |
| Model 3 | 7.266224 (2.378862) | 7.217846 (2.377655) | 7.266224 (2.378862) |
| Model 4 | 7.629420 (3.620320) | 7.811589 (2.724302) | 8.916430 (4.167038) |
| Observations | 3,735 | 3,763 | 3,735 |
| Commander categories in Model 4 | 1,243 | 516 | 1,372 |

Models 1–3 and all eight resource-type models have no commander fixed effect; after removing duplicate weighting they recover the historical estimates. Model 4 additionally changes commander grouping. Its high-growth coefficient remains positive at the 5% level (p=0.0324), but is less precisely estimated than in the flawed legacy path (p=0.00414). The historical path gives p=0.0351. This supports the broad positive association with anticipated growth while weakening the impression of precision from the legacy merge. In interaction models this coefficient is conditional on no potential evacuation, not an unconditional or causal effect.

Model 4's Low-growth coefficient is −0.926707 (SE 3.933466, p=0.8137), compared with +1.712409 (3.2106) historically and −2.422363 under the legacy path. None is statistically significant. The different sign does not establish a substantive reversal.

The corrected lookup uses 3,845 unambiguous corrections among 14,709 pre-orders input rows. It retains original names on 65 rows with conflicting candidates and 10,799 unmatched/empty-lookup rows; 88 original missing names remain. There are 102 conflicting keys in the complete lookup. Partial name cleaning can split spellings into additional categories, explaining why the conservative corrected category count exceeds the historical count. We do not claim 1,372 verified people. Resolving person identities requires source adjudication; no arbitrary candidate, fuzzy match, synthetic person or dropped observation was used.

## Reporting corrections affect evacuation interpretation

Published Tables 5–6 transpose **Lagged Growth** and **Potential Evacuation** for all eight resource types. The new tables attach labels by coefficient name. For example, Wildland Engines' lagged-growth coefficient is 0.178851 (SE 0.101153, p=0.0770), whereas potential evacuation is 0.342414 (SE 1.779470, p=0.8474).

After relabeling, none of the eight potential-evacuation main effects is significant even at 10%. The small significant coefficients attributed in the paper's narrative to potential evacuation for some resources belong to lagged growth instead. Thus that particular claim about responses to evacuation potential is not supported by these fitted main effects. The High-growth × Potential-Evacuation interaction for Type 2 Crews remains positive (0.502886, SE 0.2375, p=0.0342); the other resource-type high-growth interactions are not significant. This is a more limited finding than general responsiveness to evacuation risk, and all estimates remain observational.

The supplied supplement renderer also used stored unclustered coefficient tables while claiming fire-clustered SEs. For historical total-resource Model 1, it displayed 1.655295 rather than the clustered 2.223201. The new renderer requests clustered summaries explicitly and derives sample/fixed-effect counts from fitted models. Historical commander categories are 1,243, not the paper's printed 1,234.

All 27 Table 4 coefficient/SE pairs match printed precision on the historical benchmark. Across Tables 4–6, 90/91 pairs match after accounting for label reversals. The remaining LAT High-growth × Evacuation coefficient is 0.00036461 versus printed 0.0001 (SE agrees); the new table reports the fitted estimate. Its substantive inference remains null. This small mismatch remains unexplained.

## Growth and growth-potential models

All four quasipoisson growth models retain 4,820 observations. Their 224 saved coefficient/fit-statistic entries reproduce within 1e−10 (maximum coefficient difference about 8.4e−13). These are matches to committed outputs, not proof of a full raw-data reconstruction.

All four ordered-logit translations converge on 14,366 observations and 2,001 fire clusters, matching the archived Stata observation count. Independent score/Hessian and probability-gradient checks pass. The saved three-decimal Stata table matches 146/232 coefficients and 212/232 SEs at tolerance 0.0005. Raw weather coefficients (precipitation −0.082731, humidity −0.028756, temperature 0.042267, wind 0.052897) and index coefficients (BI 0.011776, ERC 0.027782) match displayed precision and retain the expected signs/significance. Largest discrepancies are in correlated area spline coefficients: raw-model spline 3 is 93.524041 versus 91.017, with SE 25.002772 versus 24.997. No specification was tuned to match these.

Figure 4's regenerated probability curves and uncertainty intervals are visually close to the archived Stata plots. The preceding audit's explicit pixel comparison found all 80 curve samples within 0.002 probability and all 176 interval endpoints within 0.0034 (0.005 raster tolerance). These comparisons were against existing repository plots, not copied published-page images. New full-precision R margins are supplied; full-precision historical Stata margins are unavailable. Visual agreement does not resolve coefficient discrepancies or establish exact Stata equivalence.

## Scope, evidence and interpretation

The principal conclusion that higher perceived growth accompanies more resource orders remains supported by these models. The strength of evidence in the richest specification is sensitive to commander grouping/inference. Evacuation-main-effect claims require revision after correcting row labels. No audit result establishes a causal mechanism, validates unobserved raw-data processing, or verifies the commanders' true identities.

The local end-to-end command rebuilds cached inputs, estimates corrected/historical/legacy resource paths, refits growth and R ordered-logit models, regenerates supported plots/tables, runs benchmark/invariant tests, and renders supported supplement sections. The archived original Stata source and reference outputs are retained. Missing raw inputs and map data are declared; the map is not regenerated. Native Stata execution remains unavailable. Package versions, relative source checksums, coverage, before/after coefficients and numerical validation are exported under `report/audit/`.
