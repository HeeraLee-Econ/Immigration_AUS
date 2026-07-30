******************************************************************************
*** 1. LONG TYPE DATA로 만들기 
clear 
set more off 

use "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2001/COB1991_robust_from2001_v501.dta"

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2001/COB1996_robust_from2001_v501.dta"

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2001/COB2001_robust_from2001_v501.dta"

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2016/COB2006_robust_from2016_v501.dta"
append using "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2016/COB2011_robust_from2016_v501.dta"

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2016/COB2016_robust_from2016_v501.dta"

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2021/COB2021_robust_from2021_v501.dta"

drop cob 
order countrycode LGAFINAL21 year 
sort countrycode LGAFINAL21 year 

drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 

tab year 

save "/Users/ihuila/Desktop/data/2025ABS/afterABS3/COB_X_long.dta", replace 
********************************************************************************
******************* X 변수 만들기 (share)
use "/Users/ihuila/Desktop/data/2025ABS/afterABS3/COB_X_long.dta", clear 

order LGAFINAL21 countrycode year
label var pop "Population including Aus, pop i,k,t"
label var pop_immi "Immigration excluding Aus, Immi i,k,t"
label var totimmi "Immi i,t"
label var tot_pop "total population within region - including Aus, pop i,t"
label var national_pop "total immigrants from same origin countries, immi k,t"

* 1. immi i,k,t = pop_immi 
ren pop_immi immi_ikt  

* 2. immi k,t = national_pop 
br if national_pop == 0 // Australia만 나와야 함 
ren national_pop immi_kt 

* 3. immi i,t = totimmi 
ren totimmi immi_it 

* 4. popi,t = tot_pop 
ren tot_pop pop_it 

* 4.1. pop i,t-1
preserve

collapse (sum) pop_it = pop, by(LGAFINAL21 year)
sort LGAFINAL21 year
by LGAFINAL21: gen lag_pop_it = pop_it[_n-1]

tempfile poppanel
save `poppanel', replace 
restore
merge m:1 LGAFINAL21 year using `poppanel', nogen

// check 
sort LGAFINAL21 year 

* 4.2. pop i,1991 
preserve
    keep if year == 1991
    collapse (sum) pop_i91 = pop, by(LGAFINAL21)
    tempfile pop91
    save `pop91', replace
restore
merge m:1 LGAFINAL21 using `pop91', nogen

sort LGAFINAL21 year 

* 5. Xit 
gen Xit = immi_it / lag_pop_it
gen Xit2 = immi_it / pop_i91 

label var Xit "immigration share(denominator:pop i,t-1)"
label var Xit2 "immigration share(denominator:pop i,91)"
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

* 3. immi i,k,91 / immi k,91 
gen shift91 = immi_ik91 / immi_k91

* 4. Zit (IV)
gen Zit_p = shift91 * immi_kt
bysort LGAFINAL21 year: egen Zit_b = total(Zit_p)

gen Zit = Zit_b / lag_pop_it
gen Zit2 = Zit_b / pop_i91 

label var Zit "IV(denominator:pop i,t-1)"
label var Zit2 "IV(denominator:pop i,91)"

drop Zit_b Zit_p 
************************************Rotemberg weight용으로 *************** 
gen g_kt = immi_kt 

save "/Users/ihuila/Desktop/data/2025ABS/afterIV/processingIV.dta", replace 
***********************Rotemberg용 변수 또 만들기 
keep LGAFINAL21 year Xit Xit2 Zit Zit2 

duplicates drop LGAFINAL21 year, force
			 
save "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_0907.dta", replace 
**************************************************************************** 
*************rotemberg weight -> S i,k,91 (population 으로 나누기전)
use "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2001/COB1991_robust_from2001_v502.dta", clear 

label var pop_i91 "population in LGA `i' in year 1991"

expand 7

bys LGAFINAL21 (year): gen copy_id = _n

replace year = 1991 if copy_id == 1
replace year = 1996 if copy_id == 2
replace year = 2001 if copy_id == 3
replace year = 2006 if copy_id == 4
replace year = 2011 if copy_id == 5
replace year = 2016 if copy_id == 6
replace year = 2021 if copy_id == 7

drop copy_id
order LGAFINAL21 year 
sort LGAFINAL21 year 

save "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_share.dta", replace 
***************rotemberg weight -> g k,t 부분 
use "/Users/ihuila/Desktop/data/2025ABS/afterIV/processingIV.dta", clear 

keep LGAFINAL21 year countrycode g_kt lag_pop_it 

sort LGAFINAL21 countrycode year 
sort countrycode year 

reshape wide g_kt lag_pop_it, i(LGAFINAL21 year) j(countrycode) string

drop g_ktAUS 
keep lag_pop_itAUS LGAFINAL21 year g_kt* 
ren lag_pop_itAUS lag_pop_it 

merge m:1 LGAFINAL21 year using "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_0907.dta"
drop _merge 

merge m:1 LGAFINAL21 year using "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_share.dta"
drop _merge 

save "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_rotem.dta", replace 
