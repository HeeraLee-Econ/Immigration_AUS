**********************************************************************  
* Created by Heera Lee 

* Purpose of the program: 
* =====================                                                      
* This program creates immigration shock (explanatory variables and instrumental variables)
* ====================== 
* Immigration in Australia 
* ABS (Australia Burea of Statistics) 
* 2001 census: 1991, 1996, 2001 
* 2016 census: 2006, 2011, 2016 
* 2021 census: 2011, 2016, 2021 (only using 2021 information)
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
**********************************************************************	
set more off

* LGA merge codes
import excel using "$raw/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2016") first clear
sort LGA2016
tempfile lgacode
save `lgacode'.dta, replace

* Loop and append all LGAs' COB data
use cob1.dta, clear
ren A cob
foreach var in Zimbabwe Pakistan "Country of Birth not stated" Croatia "The Former Yugoslav Republic of Macedonia" Malta Turkey {
replace cob = "Born elsewhere(e)" if cob=="`var'"
}

collapse (sum) M1 F1 T1 M2 F2 T2 M3 F3 T3, by(LGA2016 lga_info cob)
tempfile all
save `all'.dta, replace

forvalues i = 2(1)544 {
	use cob`i'.dta, clear
	ren A cob
	foreach var in Zimbabwe Pakistan "Country of Birth not stated" Croatia "The Former Yugoslav Republic of Macedonia" Malta Turkey {
replace cob = "Born elsewhere(e)" if cob=="`var'"
}
	collapse (sum) M1 F1 T1 M2 F2 T2 M3 F3 T3, by(LGA2016 lga_info cob)
	append using `all'.dta
	save `all'.dta, replace
}

* Merge in the consistent LGA codes
sort LGA2016
merge m:1 LGA2016 using `lgacode'.dta
tab _merge
drop _merge

save "TEMP_2016_from2016_v401.dta", replace


collapse (sum) M1 F1 T1 M2 F2 T2 M3 F3 T3, by(LGAFINAL21 cob)

drop if cob=="Total"

* fix cob names
replace cob = "Australia" if cob=="Australia(b)"
replace cob = "China" if cob=="China (excludes SARs and Taiwan)(c)"
replace cob = "Hong Kong" if cob=="Hong Kong (SAR of China)(c)"
replace cob = "United Kingdom" if cob=="United Kingdom, Channel Islands and Isle of Man(d)"
replace cob = "Born elsewhere" if cob=="Born elsewhere(e)"

* generate country code
gen countrycode = "AUS" if cob=="Australia"
replace countrycode = "CAN" if cob=="Canada"
replace countrycode = "CHN" if cob=="China"
replace countrycode = "EGY" if cob=="Egypt"
replace countrycode = "FJI" if cob=="Fiji"
replace countrycode = "DEU" if cob=="Germany"
replace countrycode = "GRC" if cob=="Greece"
replace countrycode = "HKG" if cob=="Hong Kong"

replace countrycode = "IRN" if cob=="Iran" // 교수님 코드에서 추가한 나라 (2001,2016,2021 센서스에 있음)
replace countrycode = "IND" if cob=="India"
replace countrycode = "IDN" if cob=="Indonesia"
replace countrycode = "IRQ" if cob=="Iraq"
replace countrycode = "IRL" if cob=="Ireland"
replace countrycode = "ITA" if cob=="Italy"
replace countrycode = "JPN" if cob=="Japan"
replace countrycode = "KOR" if cob=="Korea, Republic of (South)"
replace countrycode = "LBN" if cob=="Lebanon"
replace countrycode = "MYS" if cob=="Malaysia"

replace countrycode = "NLD" if cob=="Netherlands"
replace countrycode = "NZL" if cob=="New Zealand"
replace countrycode = "PHL" if cob=="Philippines"
replace countrycode = "POL" if cob=="Poland"
replace countrycode = "SGP" if cob=="Singapore"
replace countrycode = "ZAF" if cob=="South Africa"
replace countrycode = "LKA" if cob=="Sri Lanka"
replace countrycode = "THA" if cob=="Thailand"

replace countrycode = "GBR" if cob=="United Kingdom"
replace countrycode = "USA" if cob=="United States of America"
replace countrycode = "VNM" if cob=="Vietnam"

* Country of Birth not stated 
* Croatia 
* The Former Yugoslav Republic of Macedonia
* Replace countrycode = "MLT" if cob=="Malta"
* replace countrycode = "TUR" if cob=="Turkey"
* Pakistan 
* Zimbabwe 
* Iran 

replace countrycode="ZZZ" if cob=="Born elsewhere"

ren T3 pop
keep cob LGAFINAL21 pop countrycode
gen year = 2016

/*
* 안맞는 지역 
drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 
*/

* 국가 아이디 
egen cob_id=group(countrycode)
*********************************************
* pop_immi - 호주제외 이민자 수 (i,k,t)
gen pop_immi=pop
replace pop_immi=. if cob=="Australia"

* tot_immi - 지역별 총 이민자 수 (immi i,t)
bysort LGAFINAL21: egen totimmi= total(pop_immi) 

* tot_pop - 지역별 총 인구수 (pop i,t)
bysort LGAFINAL21: egen tot_pop = total(pop) // 지역별 전체인구 (모든 국가 합쳐서)

* national_pop - 각 국가별 출신 총 인구수 (immi k,t)
sort countrycode 
by countrycode: egen national_pop= total(pop_immi)

* share_cob - k국가 출신인 사람의 비율 (immi i,k,t / immi k,t)
gen share_cob=pop_immi/national_pop 

save "$interim/ABS/X/COB2016_robust_from2016_v501.dta", replace
/*
***************************************************
use "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2016/COB2016_robust_from2016_v501.dta", clear 

* share_cob = k국가 출신인 이민자 수 / 지역별 전체 이민자 수 
*bysort region: egen totimmi16 = total(pop_immi)

* 1. 
ren totimmi totimmi16 // 지역별 총 이민자 수 (in 2016)

* 2. 국가별 share 생성
gen share16 = pop_immi / totimmi16

* 3. 필요한 열만 남기기
keep LGAFINAL21 countrycode share16

* 4. wide 형태로 reshape (국가별 열 생성)
reshape wide share16, i(LGAFINAL21) j(countrycode) string

gen year = 2016 

save "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2016/COB2016_robust_from2016_v502.dta", replace
*********************************************
use "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2016/COB2016_robust_from2016_v501.dta", clear 

ren national_pop immi

* 4. wide reshape (국가별 national total 변수를 가로로 붙임)
keep LGAFINAL21 countrycode immi
reshape wide immi, i(LGAFINAL21) j(countrycode) string

gen year = 2016 

save "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2016/COB2016_robust_from2016_v503.dta", replace
*/
