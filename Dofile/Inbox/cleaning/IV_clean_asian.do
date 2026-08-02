******************************************************************************
*** 1. LONG TYPE DATA로 만들기 
clear 
set more off 

use "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2001/asian_COB1991_robust_from2001_v501.dta"

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2001/asian_COB1996_robust_from2001_v501.dta"
append using "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2001/asian_COB2001_robust_from2001_v501.dta"

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2016/asian_COB2006_robust_from2016_v501.dta"
append using "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2016/asian_COB2011_robust_from2016_v501.dta"
append using "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2016/asian_COB2016_robust_from2016_v501.dta"

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2021/asian_COB2021_robust_from2021_v501.dta"

drop cob 
order countrycode LGAFINAL21 year 
sort countrycode LGAFINAL21 year 

*drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 

save "/Users/ihuila/Desktop/data/2025ABS/afterABS3/COB_Xasian_long.dta", replace 
******************* X 변수 만들기 (share)
use "/Users/ihuila/Desktop/data/2025ABS/afterABS3/COB_Xasian_long.dta", clear 

* 1. 1991년 데이터에서 지역별 인구 tot_pop91 계산

// 1991년도 기준 인구변수 만들기 
preserve
    keep if year == 1991
    keep LGAFINAL21 tot_pop
    rename tot_pop tot_pop91
    duplicates drop LGAFINAL21, force
    sort LGAFINAL21
    tempfile pop91
    save `pop91'
restore
sort LGAFINAL21
merge m:1 LGAFINAL21 using `pop91', keepusing(tot_pop91)
drop _merge

// 1996년도 기준 인구변수 만들기 
preserve
    keep if year == 1996
    keep LGAFINAL21 tot_pop
    rename tot_pop tot_pop96
    duplicates drop LGAFINAL21, force
    sort LGAFINAL21
    tempfile pop96
    save `pop96'
restore
sort LGAFINAL21
merge m:1 LGAFINAL21 using `pop96', keepusing(tot_pop96)
drop _merge

// 2001년도 기준 인구변수 만들기 
preserve
    keep if year == 2001
    keep LGAFINAL21 tot_pop
    rename tot_pop tot_pop01
    duplicates drop LGAFINAL21, force
    sort LGAFINAL21
    tempfile pop01
    save `pop01'
restore
sort LGAFINAL21
merge m:1 LGAFINAL21 using `pop01', keepusing(tot_pop01)
drop _merge

// 2006년도 기준 인구변수 만들기 
preserve
    keep if year == 2006
    keep LGAFINAL21 tot_pop
    rename tot_pop tot_pop06
    duplicates drop LGAFINAL21, force
    sort LGAFINAL21
    tempfile pop06
    save `pop06'
restore
sort LGAFINAL21
merge m:1 LGAFINAL21 using `pop06', keepusing(tot_pop06)
drop _merge

* 2. Xit (share) - asian 국가 출신 
gen X_share91  = totimmi_asian / tot_pop91
gen X_share96  = totimmi_asian / tot_pop96
gen X_share01  = totimmi_asian / tot_pop01
gen X_share06  = totimmi_asian / tot_pop06

*******************************************************************************
****************** IV 만들기 (share) 
* 1.1 immi i,k,91 
preserve
    keep if year == 1991 & asian==1 
    collapse (sum) immi_ik91 = pop_immi_asian , by(LGAFINAL21 countrycode)
    keep LGAFINAL21 countrycode immi_ik91 
    tempfile base91
    save `base91'
restore
sort LGAFINAL21  
merge m:1 LGAFINAL21 countrycode using `base91', nogen 
replace immi_ik91 = 0 if missing(immi_ik91)

* 1.2 immi k,91
*bysort countrycode: egen immi_k91 = total(immi_ik91) if asian==1 

preserve
    keep if year == 1991 & asian==1
    collapse (sum) immi_k91 = immi_ik91, by(countrycode)
    tempfile k91
    save `k91'
restore

merge m:1 countrycode using `k91', nogen
replace immi_k91 = 0 if missing(immi_k91)

* 2. immi k,t = national_pop 
gen immi_kt = national_pop if asian==1 
replace immi_kt = 0 if missing(immi_kt)

* 3. weight 
gen weight91 = immi_ik91 / immi_k91 

* 3. 분자 
gen Z_comp = weight91 * immi_kt 

* 4. summation
bysort LGAFINAL21 year: egen Z_comp2 = total(Z_comp)

* 5. 최종 Zit (share)
gen Z_share91 = Z_comp2 / tot_pop91 

gen Z91_1996 = Z_share91 * (year-1996)
gen Z91_2001 = Z_share91 * (year-2000)
gen Z91_2006 = Z_share91 * (year-2005)
gen Z91_2011 = Z_share91 * (year-2010)
gen Z91_2016 = Z_share91 * (year-2015)
gen Z91_2021 = Z_share91 * (year-2020)

drop Z_comp Z_comp2 

/*
*******************************************************************************
*************** X 변수 만들기 (difference)
bysort LGAFINAL21 countrycode (year): ///
    gen dX_share = X_share91 - X_share91[_n-1]
*******************************************************************************
**************** Z 변수 만들기 (difference)
* 1. difference immik,t 
sort countrycode year
by countrycode: gen dimmi_kt = immi_kt - immi_kt[_n-1]

* 2. 분자 
gen Z_comp = weight91 * dimmi_kt

* 3. summation 
bysort LGAFINAL21 year: egen Z_comp2 = total(Z_comp)

* 4. 최종 difference Z 만들기 
gen dZ_share91 = Z_comp2 / tot_pop91
/*
gen dZ_share96 = Z_comp2 / tot_pop96
gen dZ_share01 = Z_comp2 / tot_pop01
gen dZ_share06 = Z_comp2 / tot_pop06
*/
drop Z_comp Z_comp2 
*/
******************************************************************************
collapse (mean) X_share91 X_share96 X_share01 X_share06 Z_share91  Z91_1996 Z91_2001 Z91_2006 Z91_2011 Z91_2016 Z91_2021, by(LGAFINAL21 year)

foreach v in X_share91 X_share96 X_share01 X_share06 Z_share91 Z91_1996 Z91_2001 Z91_2006 Z91_2011 Z91_2016 Z91_2021 {
    rename `v' a_`v'
}

save "/Users/ihuila/Desktop/data/2025ABS/afterIV/IVasian_0930.dta", replace 

/*
merge m:1 LGAFINAL21 year using COB_SHARE_long.dta, nogen 

save "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_0907.dta", replace 
*/
