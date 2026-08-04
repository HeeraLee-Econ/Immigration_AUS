**********************************************************************
* Created by Heera Lee
* Purpose: append T26(2006census), T35(2021census) and construct variables for analysis
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
**********************************************************************
use "$data/ABS_T2635_total.dta", clear

merge m:1 LGAFINAL21 year using "$data/ABS_T01_total.dta", assert(3)
drop _merge

merge m:1 LGAFINAL21 year using "$data/ABS_T02_total.dta", assert(3)
drop _merge

merge m:1 LGAFINAL21 year using "$data/ABS_T04_total.dta", assert(3)
drop _merge

merge m:1 LGAFINAL21 year using "$data/ABS_T2231_total.dta", assert(3)
drop _merge

merge m:1 LGAFINAL21 year using "$data/ABS_T2433_total.dta", assert(3)
drop _merge

merge m:1 LGAFINAL21 year using "$data/ABS_immi_final.dta"
// _merge==2 는 ABS_immi_final.dta 에 1991년도 데이터 있어서 
drop _merge 

order LGAFINAL21 year 
sort LGAFINAL21 year 

// lagged control variable 
xtset LGAFINAL21 year 
tsset LGAFINAL21 year, delta(5) 

// lagged control variable
gen fifteenshare_lag    = L.fifteenshare
gen bachshare_ageall_lag = L.bachshare_ageall

// time trend - 2001년도 기준. 
gen trend = (year - 2001) / 5 
egen fifteenshare_base = max(cond(year==2001, fifteenshare_lag, .)), by(LGAFINAL21)
egen bach_base          = max(cond(year==2001, bachshare_ageall_lag, .)), by(LGAFINAL21)

gen fifteen_trend = fifteenshare_base * trend  
replace fifteen_trend =. if year <=1996 

gen bach_trend = bach_base * trend 
replace bach_trend =.  if year<=1996 

save "$final/ABS_XY_final.dta", replace 
