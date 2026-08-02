**********************************************************************  
* Created by Heera Lee 
* Purpose: creates immigration shock explanatory/instrumental variables
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

local years  1991 1996 2001 2006 2011 2016 2021
local census 2001 2001 2001 2016 2016 2016 2021

* LONG-TYPE 으로 만들기 
local n : word count `years'
forvalues k = 1/`n' {
    local y : word `k' of `years'
    local c : word `k' of `census'
    if `k'==1 use "$interim/ABS/X/COB`y'_robust_from`c'_v501.dta", clear
    else       append using "$interim/ABS/X/COB`y'_robust_from`c'_v501.dta"
}

order countrycode LGAFINAL21 year
sort countrycode LGAFINAL21 year

drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 // 지방정부 없는 미편입지역, 혹은 원주민 소유 원격지, 해외령 

tab year
isid LGAFINAL21 countrycode year

save "$interim/ABS/X/COB_X_long.dta", replace
********************************************************************************
* Construct X, IV 

use "$interim/ABS/X/COB_X_long.dta", clear 

order LGAFINAL21 countrycode year
label var pop "Population including Aus, pop i,k,t"
label var pop_immi "Immigration excluding Aus, Immi i,k,t"
label var totimmi "Immi i,t"
label var tot_pop "total population within region - including Aus, pop i,t"
label var national_pop "total immigrants from same origin countries, immi k,t"

* 1. immi i,k,t = pop_immi 
ren pop_immi immi_ikt  

* 2. immi k,t = national_pop 
br if national_pop == 0 // only Australia
ren national_pop immi_kt 

* 3. immi i,t = totimmi 
ren totimmi immi_it 

* 4. popi,t = tot_pop 
ren tot_pop pop_it 

* 4.1. pop i,1991 
preserve
    keep if year == 1991
    collapse (sum) pop_i91 = pop, by(LGAFINAL21)
    tempfile pop91
    save `pop91', replace
restore
merge m:1 LGAFINAL21 using `pop91', nogen

sort LGAFINAL21 year 

* 5. Xit 
gen Xit = immi_it / pop_i91 

label var Xit "immigration share(denominator:pop i,91)"
********************************************************************
****************** IV 만들기 (share) 
* 1. immi i,k,91 + immi k,91 
* 1.1. immi i,k,91 
preserve
    keep if year == 1991
    collapse (sum) immi_ik91 = immi_ikt, by(LGAFINAL21 countrycode)
    keep LGAFINAL21 countrycode immi_ik91
    tempfile base91
    save `base91', replace 
restore
merge m:1 LGAFINAL21 countrycode using `base91', nogen

sort LGAFINAL21 countrycode year // check 

* 1.2. immi k,91 
preserve
    keep if year == 1991
    keep countrycode immi_kt
    duplicates drop countrycode, force   // countrycode별로 1개만 남김
    rename immi_kt immi_k91
    tempfile base91
    save `base91', replace
restore
merge m:1 countrycode using `base91', nogen

sort LGAFINAL21 countrycode year // check 

* 3. immi i,k,91 / immi k,91. 
gen share91 = immi_ik91 / immi_k91

* 4. Zit (IV)
gen Zit_p = share91 * immi_kt
bysort LGAFINAL21 year: egen Zit_b = total(Zit_p)

gen Zit = Zit_b / pop_i91 

label var Zit "IV(denominator:pop i,91)"

drop Zit_b Zit_p 

gen g_kt = immi_kt

**********************************************************************
* 이질성 분석용: 영어권(English-speaking) 출신국 이민자 비중
* (GBR/USA/NZL/CAN/IRL - "Main English-Speaking Countries" 분류)
**********************************************************************
gen english = 0
replace english = 1 if countrycode == "GBR"
replace english = 1 if countrycode == "USA"
replace english = 1 if countrycode == "NZL"
replace english = 1 if countrycode == "CAN"
replace english = 1 if countrycode == "IRL"
replace english = . if countrycode == "AUS"   // native 제외 (있다면)

gen immi_eng_ikt = immi_ikt * english         // 영어권만 추출

bysort LGAFINAL21 year: egen immi_eng_it = total(immi_eng_ikt)  // LGA x year 합산

gen immi_noneng_it = immi_it - immi_eng_it

gen share_eng    = immi_eng_it / immi_it
gen share_noneng = immi_noneng_it / immi_it

assert pop_it == pop_i91 if year==1991 // for check

save "$interim/ABS/X/processingIV.dta", replace // save for rotemberg weight
***************************************************************************
keep LGAFINAL21 year Xit Zit immi_it immi_eng_it immi_noneng_it share_eng share_noneng

duplicates drop LGAFINAL21 year, force

save "$data/ABS_immi_final.dta", replace
