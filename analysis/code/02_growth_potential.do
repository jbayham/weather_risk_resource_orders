 
*cd "F:/Projects/Wildfire/Fire_Weather/"
use "../inputs/02_gp_ds_stata.dta", clear 
 
*format report_date %td
 

******************************************
tab growth_potential

label define gp 1 "Low" 2 "Medium" 3 "High" 4 "Extreme"

encode gacc, g(gacc1)
encode terrain, g(terrain1) label(gp)
encode growth_potential, g(growth_potential1) label(gp)
encode cause_desc, g(cause_desc1)
encode year, g(year1)

*spline
mkspline sp_area = area, cubic nk(4)

*all
ologit growth_potential1 ///
prcp rmin tmax wind bi erc i.sfwp ///
i.gacc1##c.doy_cos i.cause_desc1 i.terrain1 i.year1 PC1-PC20 sp_area*, vce(cluster ross_inc_id)
estimates store ol_all

*raw weather
ologit growth_potential1 ///
prcp rmin tmax wind  ///
i.gacc1##c.doy_cos i.cause_desc1 i.terrain1 i.year1 PC1-PC20 sp_area*, vce(cluster ross_inc_id)
estimates store ol_raw

*bi, erc
ologit growth_potential1 ///
bi erc ///
i.gacc1##c.doy_cos i.cause_desc1 i.terrain1 i.year1 PC1-PC20 sp_area*, vce(cluster ross_inc_id)
estimates store ol_index

*sfwp
ologit growth_potential1 ///
i.sfwp ///
i.gacc1##c.doy_cos i.cause_desc1 i.terrain1 i.year1 PC1-PC20 sp_area*, vce(cluster ross_inc_id)
estimates store ol_sfwp

outreg2 [ol_*] using "../../report/tables/need_formatting/02_gp_raw.xls", ///
replace excel dec(3) sortvar(prcp rmin tmax wind bi erc i.sfwp)


*****************************************
*Generate figures

estimates restore ol_sfwp

margins sfwp
marginsplot, scheme(538w) ///
legend(order(1 "Low" 2 "Medium" 3 "High" 4 "Extreme" ) size(large) pos(1) ring(0) region(fcolor(none))) ///
ylab(0(.2).8,labsize(large)) xlab(,labsize(large)) yscale(r(0 .8)) ///
title("") ytitle("") xtitle("Categorical Fire Behavior Index", size(huge))
graph export "../../report/figures/gp_sfwp_leg.png", replace

marginsplot, scheme(538w) ///
legend(off) ///
ylab(0(.2).8,labsize(large)) xlab(,labsize(large)) yscale(r(0 .8)) ///
title("") ytitle("") xtitle("Categorical Fire Behavior Index", size(huge))
graph export "../../report/figures/gp_sfwp.png", replace


****
estimates restore ol_index

margins, at(erc=(0(10)100))
marginsplot, scheme(538w) ///
legend(order(1 "Low" 2 "Medium" 3 "High" 4 "Extreme" ) size(large) pos(1) ring(0) region(fcolor(none))) ///
ylab(0(.2).8,labsize(large)) xlab(,labsize(large)) yscale(r(0 .8)) ///
title("") ytitle("") xtitle("Energy Release Component", size(huge))
graph export "../../report/figures/gp_erc_leg.png", replace

marginsplot, scheme(538w) ///
legend(off) ///
ylab(0(.2).8,labsize(large)) xlab(,labsize(large)) yscale(r(0 .8)) ///
title("") ytitle("") xtitle("Energy Release Component", size(huge))
graph export "../../report/figures/gp_erc.png", replace


****
margins, at(bi=(0(10)100))
marginsplot, scheme(538w) ///
legend(order(1 "Low" 2 "Medium" 3 "High" 4 "Extreme" ) size(large) pos(1) ring(0) region(fcolor(none))) ///
ylab(0(.2).8,labsize(large)) xlab(,labsize(large)) yscale(r(0 .8)) ///
title("") ytitle("") xtitle("Burning Index", size(huge))
graph export "../../report/figures/gp_bi_leg.png", replace

marginsplot, scheme(538w) ///
legend(off) ///
ylab(0(.2).8,labsize(large)) xlab(,labsize(large)) yscale(r(0 .8)) ///
title("") ytitle("") xtitle("Burning Index", size(huge))
graph export "../../report/figures/gp_bi.png", replace


estimates restore ol_raw


margins, at(tmax=(10(4)45))
marginsplot, scheme(538w) ///
legend(order(1 "Low" 2 "Medium" 3 "High" 4 "Extreme" ) size(large) pos(1) ring(0) region(fcolor(none))) ///
ylab(0(.2).8,labsize(large)) xlab(,labsize(large)) yscale(r(0 .8)) ///
title("") ytitle("") xtitle("Temperature", size(huge))
graph export "../../report/figures/gp_tmax_leg.png", replace

marginsplot, scheme(538w) ///
legend(off) ///
ylab(0(.2).8,labsize(large)) xlab(,labsize(large)) yscale(r(0 .8)) ///
title("") ytitle("") xtitle("Temperature", size(huge))
graph export "../../report/figures/gp_tmax.png", replace


****
margins, at(wind=(0(3)30))
marginsplot, scheme(538w) ///
ylab(0(.2).8,labsize(large)) xlab(,labsize(large)) yscale(r(0 .8)) ///
legend(order(1 "Low" 2 "Medium" 3 "High" 4 "Extreme" ) size(large) pos(1) ring(0) region(fcolor(none))) ///
title("") ytitle("") xtitle("Wind", size(huge))
graph export "../../report/figures/gp_wind_leg.png", replace

marginsplot, scheme(538w) ///
ylab(0(.2).8,labsize(large)) xlab(,labsize(large)) yscale(r(0 .8)) ///
legend(off) ///
title("") ytitle("") xtitle("Wind", size(huge))
graph export "../../report/figures/gp_wind.png", replace


****
margins, at(prcp=(0(1)10))
marginsplot, scheme(538w) ///
legend(order(1 "Low" 2 "Medium" 3 "High" 4 "Extreme" ) size(large) pos(1) ring(0) region(fcolor(none))) ///
ylab(0(.2).8,labsize(large)) xlab(,labsize(large)) yscale(r(0 .8)) ///
title("") ytitle("") xtitle("Precipitation", size(huge))
graph export "../../report/figures/gp_prcp_leg.png", replace

marginsplot, scheme(538w) ///
legend(off) ///
ylab(0(.2).8,labsize(large)) xlab(,labsize(large)) yscale(r(0 .8)) ///
title("") ytitle("") xtitle("Precipitation", size(huge))
graph export "../../report/figures/gp_prcp.png", replace

****
margins, at(rmin=(0(5)50))
marginsplot, scheme(538w) ///
legend(order(1 "Low" 2 "Medium" 3 "High" 4 "Extreme" ) size(large) pos(11) ring(0) region(fcolor(none))) ///
ylab(0(.2).8,labsize(large)) xlab(,labsize(large)) yscale(r(0 .8)) ///
title("") ytitle("") xtitle("Minimum Humidity", size(huge))
graph export "../../report/figures/gp_rmin_leg.png", replace 

marginsplot, scheme(538w) ///
legend(off) ///
ylab(0(.2).8,labsize(large)) xlab(,labsize(large)) yscale(r(0 .8)) ///
title("") ytitle("") xtitle("Minimum Humidity", size(huge))
graph export "../../report/figures/gp_rmin.png", replace 


