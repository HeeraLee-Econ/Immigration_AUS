**********************************************************************  
* Created by Heera Lee 
* Purpose: creates Rotemberg weight 
* 2001 census: 1991, 1996, 2001 / 2016 census: 2006, 2011, 2016 / 2021 census: 2021
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
**********************************************************************
set more off

use "$interim/ABS/X/COB1991_robust_from2001_v502.dta", clear
label var pop_i91 "population in LGA in year 1991"

expand 7
bys LGAFINAL21 (year): gen copy_id = _n

local yrs 1991 1996 2001 2006 2011 2016 2021
forvalues c = 1/7 {
    local yr : word `c' of `yrs'
    replace year = `yr' if copy_id==`c'
}

drop copy_id
sort LGAFINAL21 year

tempfile share91wide 
save `share91wide'.dta, replace

* ---- g_kt를 국가별 wide로 ----
use "$interim/ABS/X/processingIV.dta", clear
keep LGAFINAL21 year countrycode g_kt

reshape wide g_kt, i(LGAFINAL21 year) j(countrycode) string
drop g_ktAUS

* ---- Xit/Zit, share91/pop_i91 병합 ----
merge m:1 LGAFINAL21 year using "$data/ABS_immi_final.dta", nogen
merge m:1 LGAFINAL21 year using `share91wide'.dta, nogen

save "$data/ABS_immi_rotem.dta", replace
