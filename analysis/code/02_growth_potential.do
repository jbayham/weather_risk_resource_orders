 *This script estimates models to corroborate the R code.
 
cd "F:\Projects\Wildfire\Fire_Weather\"
use "analysis\inputs\02_gp_ds_stata.dta", clear 
 
*format report_date %td
 

******************************************
tab growth_potential

label define gp 1 "Low" 2 "Medium" 3 "High" 4 "Extreme"

encode gacc, g(gacc1)
encode terrain, g(terrain1)
encode growth_potential, g(growth_potential1) label(gp)
encode cause_desc, g(cause_desc1)

*spline
mkspline sp_area 4 = area, pctile

*raw weather
ologit growth_potential1 ///
prcp rmin tmax wind  ///
i.gacc1##c.doy_cos i.cause_desc1 i.terrain1 PC1-PC10 sp_area*, vce(cluster ross_inc_id)
estimates store ol_raw

ologit growth_potential1 ///
bi erc i.sfwp ///
i.gacc1##c.doy_cos i.cause_desc1 i.terrain1 PC1-PC10 sp_area*, vce(cluster ross_inc_id)
estimates store ol_index

outreg2 [ol_*] using "report\tables\need_formatting\gp_raw.xls", ///
replace excel dec(3) sortvar(prcp rmin tmax wind bi erc i.sfwp)

estimates restore ol_index

margins sfwp
marginsplot, scheme(538w) ///
legend(order(1 "Low" 2 "Medium" 3 "High" 4 "Extreme" ) pos(1) ring(0) region(fcolor(none))) ///
title("") ytitle("") xtitle("Severe Fire Weather Potential")
graph export "report\figures\gp_sfwp.emf", replace

margins, at(erc=(0(20)100))
marginsplot, scheme(538w) ///
legend(order(1 "Low" 2 "Medium" 3 "High" 4 "Extreme" ) size(large) pos(1) ring(0) region(fcolor(none))) ///
ylab(,labsize(large)) xlab(,labsize(large)) ///
title("") ytitle("") xtitle("(a) Energy Release Component", size(huge))
graph export "report\figures\gp_erc.emf", replace

estimates restore ol_raw

/*
margins, at(tmax=(10(4)45))
marginsplot, scheme(538w) ///
legend(order(1 "Low" 2 "Medium" 3 "High" 4 "Extreme" ) pos(1) ring(0) region(fcolor(none))) ///
title("") ytitle("") xtitle("Maximum Temperature")
*/

margins, at(wind=(0(3)30))
marginsplot, scheme(538w) ///
legend(order(1 "Low" 2 "Medium" 3 "High" 4 "Extreme" ) pos(1) ring(0) region(fcolor(none))) ///
title("") ytitle("") xtitle("Wind")
graph export "report\figures\gp_wind.emf", replace

/*
margins, at(prcp=(0(1)10))
marginsplot, scheme(538w) ///
legend(order(1 "Low" 2 "Medium" 3 "High" 4 "Extreme" ) pos(1) ring(0) region(fcolor(none))) ///
title("") ytitle("") xtitle("Precipitation")
*/

margins, at(rmin=(0(5)50))
marginsplot, scheme(538w) ///
legend(order(1 "Low" 2 "Medium" 3 "High" 4 "Extreme" ) size(large) pos(11) ring(0) region(fcolor(none))) ///
ylab(,labsize(large)) xlab(,labsize(large)) ///
title("") ytitle("") xtitle("(b) Minimum Humidity", size(huge))
graph export "report\figures\gp_rmin.emf", replace 


