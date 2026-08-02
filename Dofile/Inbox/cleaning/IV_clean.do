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

save "/Users/ihuila/Desktop/data/2025ABS/afterABS3/COB_X_long.dta", replace 
********************************************************************************
******************* X 변수 만들기 (share)
use "/Users/ihuila/Desktop/data/2025ABS/afterABS3/COB_X_long.dta", clear 

order LGAFINAL21 countrycode year
label var pop "Population including Aus, pop i,k,t"
label var pop_immi "Immigration excluding Aus, Immi i,k,t"
label var totimmi "Immi i,t"
label var tot_pop "total population within region - including Aus, pop i,t"

* 1. immi i,k,t = pop_immi 
ren pop_immi  immi_ikt  

//확인용: gen immi_ikt = pop_immi 

/*
gen immi_ikt2 = immi_ikt // 기타 국가 뺀 버전 
replace immi_ikt2 = . if countrycode == "ZZZ"
*/

* 2. immi k,t = 
br if national_pop == 0 // Australia만 나와야 함 
ren national_pop immi_kt 

/*
gen immi_kt2 = immi_kt // 기타 국가 뺀 버전 
replace immi_kt2 = . if countrycode == "ZZZ"
*/

// 확인용 bysort countrycode year: egen immi_kt = total(immi_ikt)

* 3. immi i,t 
ren totimmi immi_it 

/*
bysort LGAFINAL21 year: egen immi_it2 = total(immi_ikt2) // 기타국가 빠진 버전 
*/

/* 확인용 
bysort LGAFINAL21 year: egen immi_it = total(immi_ikt)
count if immi_it != totimmi 
*/

* 4. s i,k,t 
gen s_ikt = immi_ikt / immi_it

//gen s_ikt2 = immi_ikt2 / immi_it2 

//replace s_ikt =. if countrycode == "AAA"
//replace s_ikt =. if countrycode == "ZZZ"

* 4.1. lagged immi k,t = immi k,t-5 (5년전 )

isid LGAFINAL21 countrycode year
egen pid = group(LGAFINAL21 countrycode), label
tsset pid year, delta(5)

gen immi_kt_lag5 = L1.immi_kt
gen immi_kt2_lag5 = L1.immi_kt2 

gen g_kt2 = (immi_kt - immi_kt_lag5) / immi_kt_lag5
gen g_kt2_2 = (immi_kt2 - immi_kt2_lag5) / immi_kt2_lag5

gen g_kt3 = immi_kt - immi_kt_lag5
gen g_kt3_2 = immi_kt2 - immi_kt2_lag5 

replace g_kt3 =. if countrycode == "AUS"
replace g_kt3_2 =. if countrycode == "AUS" | countrycode == "ZZZ"

order LGAFINAL21 countrycode year immi_kt immi_kt_lag5 g_kt2 g_kt3 

* 5. shock 
* 5.1 stock 
gen Xit_p = s_ikt * immi_kt 
bys LGAFINAL21 year: egen Xit = total(Xit_p)

* 5.2. growth rate 
drop Xit_p 
gen Xit_p =  s_ikt * g_kt2
bys LGAFINAL21 year: egen Xit2 = total(Xit_p)

* 5.3. difference 
drop Xit_p 
gen Xit_p = s_ikt * g_kt3
bys LGAFINAL21 year: egen Xit3 = total(Xit_p)

drop Xit_p 

label var Xit "stock"
label var Xit2 "growth rate"
label var Xit3 "difference" 

label var g_kt2_2 "growth rate (exclu-other)"
label var g_kt3_2 "difference (ecl)" 
********************************************************************************
* 5. shock (OTHER version only: excluding ZZZ)
* Uses: s_ikt2, immi_kt2, g_kt2_2, g_kt3_2
* Creates: Xit_other, Xit2_other, Xit3_other
********************************************************************************
local s    "s_ikt2"
local imkt "immi_kt2"
local g2   "g_kt2_2"
local g3   "g_kt3_2"
local suf  "_other"

* 5.1 stock
gen Xit_p = `s' * `imkt'
bys LGAFINAL21 year: egen Xit`suf' = total(Xit_p)
drop Xit_p

* 5.2 growth rate
gen Xit_p = `s' * `g2'
bys LGAFINAL21 year: egen Xit2`suf' = total(Xit_p)
drop Xit_p

* 5.3 difference
gen Xit_p = `s' * `g3'
bys LGAFINAL21 year: egen Xit3`suf' = total(Xit_p)
drop Xit_p

label var Xit`suf'  "stock (other-excl ZZZ)"
label var Xit2`suf' "growth rate (other-excl ZZZ)"
label var Xit3`suf' "difference (other-excl ZZZ)"
*******************************************************************************
****************** IV 만들기 (share) 
* 1. immi i,k,91 + immi i,91 
* base91 만들기 (당신 코드 그대로)
preserve
    keep if year == 1991
    collapse (sum) immi_ik91 = immi_ikt, by(LGAFINAL21 countrycode)

    * immi i,91 (denominator of shift-share)
    bysort LGAFINAL21: egen immi_i91 = total(immi_ik91)

    keep LGAFINAL21 countrycode immi_ik91 immi_i91
    tempfile base91
    save `base91'
restore
merge m:1 LGAFINAL21 countrycode using `base91', nogen

* 2. weight 
gen shift91 = immi_ik91 / immi_i91

* 3.
* 3.1. Zit, stock 
gen Zit_p = shift91 * immi_kt 
bysort LGAFINAL21 year: egen Zit = total(Zit_p)

* 3.2. Zit, growth rate 
drop Zit_p 
gen Zit_p = shift91 * g_kt2
bysort LGAFINAL21 year: egen Zit2 = total(Zit_p)

* 3.3. Zit, difference 
drop Zit_p 
gen Zit_p = shift91 * g_kt3
bysort LGAFINAL21 year: egen Zit3 = total(Zit_p)

label var Zit "stock"
label var Zit2 "growth rate"
label var Zit3 "difference"

********************************************************************************
* IV 만들기 (OTHER only: excluding ZZZ)  -> suffix "_other"
* Uses: immi_ikt2, immi_kt2, g_kt2_2, g_kt3_2
* Creates: shift91_other, Zit_other, Zit2_other, Zit3_other
********************************************************************************
* 1) base91_other: 1991년 기준 (ZZZ 제외) immi_ik91_other, immi_i91_other
preserve
    keep if year == 1991

    * ZZZ 제외한 i,k,91
    collapse (sum) immi_ik91_other = immi_ikt2, by(LGAFINAL21 countrycode)

    * ZZZ 제외한 i,91 (shift-share 분모)
    bysort LGAFINAL21: egen immi_i91_other = total(immi_ik91_other)

    keep LGAFINAL21 countrycode immi_ik91_other immi_i91_other
    tempfile base91_other
    save `base91_other'
restore

merge m:1 LGAFINAL21 countrycode using `base91_other', nogen

* 2) weight: shift91_other
gen shift91_other = immi_ik91_other / immi_i91_other

* 3) Zit shocks (other)
local suf "_other"
local sh  "shift91_other"
local imkt "immi_kt2"
local g2  "g_kt2_2"
local g3  "g_kt3_2"

foreach spec in stock grow diff {

    tempvar Zit_p

    if "`spec'" == "stock" {
        local rhs "`imkt'"
        local out "Zit`suf'"
        local lab "stock (other-excl ZZZ)"
    }
    else if "`spec'" == "grow" {
        local rhs "`g2'"
        local out "Zit2`suf'"
        local lab "growth rate (other-excl ZZZ)"
    }
    else if "`spec'" == "diff" {
        local rhs "`g3'"
        local out "Zit3`suf'"
        local lab "difference (other-excl ZZZ)"
    }

    gen `Zit_p' = `sh' * `rhs'
    bysort LGAFINAL21 year: egen `out' = total(`Zit_p')
    label var `out' "`lab'"
}
******* 확인용 
// g_kt2: 결측값 있는지 확인 
br if g_kt2 == . & year !=1991 & countrycode != "AUS"

// immi_kt 
br if immi_kt == 0 // Australia만 나와야 함 
br if immi_kt == 0 & countrycode == "AUS"

// immi i,k,t 와 immi i,t 의 범위가 일치하는지 확인 
bysort LGAFINAL21 year: egen check_it = total(immi_ikt)
count if check_it != immi_it & !missing(check_it, immi_it)

******* 확인용  (excluding other 버전)
* g_kt2_2 결측 체크 (1991 제외, AUS/ZZZ 제외)
br if g_kt2_2 == . & year != 1991 & countrycode != "AUS" & countrycode != "ZZZ"

* immi_kt2 == 0 체크 (보통 AUS만 0일 수 있는데, ZZZ는 .로 빠짐)
br if immi_kt2 == 0
br if immi_kt2 == 0 & countrycode == "AUS"

* immi i,k,t 합이 immi_it2와 일치하는지 확인 (ZZZ 제외 합)
bysort LGAFINAL21 year: egen check_it2 = total(immi_ikt2)
count if check_it2 != immi_it2 & !missing(check_it2, immi_it2)
drop check_it2

save "/Users/ihuila/Desktop/data/2025ABS/afterIV/processingIV.dta", replace 

keep LGAFINAL21 year Xit Xit2 Xit3 Zit Zit2 Zit3 Xit_other Xit2_other Xit3_other Zit_other Zit2_other Zit3_other
duplicates drop LGAFINAL21 year, force

*** scale 변경 
foreach v in Xit Zit Xit2 Zit2 Xit3 Zit3 Xit_other Xit2_other Xit3_other Zit_other Zit2_other Zit3_other{
   gen `v'_s = `v' /100000
}

// totimmi - 지역 내 총 이민자 수 (해당연도, immi i,t)
// tot_pop - 지역 내 총 인구 수 (해당연도, pop i,t)
			 
save "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_0907.dta", replace 
**************************************************************************** 
*************rotemberg weight -> share 91년도 부분 
use "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2001/COB1991_robust_from2001_v502.dta", clear 
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

keep LGAFINAL21 year countrycode g_kt2 g_kt3 g_kt2_2 g_kt3_2

sort LGAFINAL21 countrycode year 
sort countrycode year 

//collapse (mean) g_kt2 g_kt3, by(LGAFINAL21 year)

reshape wide g_kt2 g_kt3 g_kt2_2 g_kt3_2, i(LGAFINAL21 year) j(countrycode) string

merge m:1 LGAFINAL21 year using "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_0907.dta"
drop _merge 

merge m:1 LGAFINAL21 year using "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_share.dta"
drop _merge 

save "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_rotem.dta", replace 
