clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS3/2021"

* LGA merge codes
import excel using "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2021") first clear
sort LGA2021
drop lga_code2021
tempfile lgacode
save `lgacode'.dta, replace

* Loop and append all LGAs' COB data
use cob1.dta, clear
ren A cob
foreach var in Afghanistan Bangladesh Nepal Pakistan "Country of birth not stated" Croatia Taiwan {
replace cob = "Born elsewhere(e)" if cob=="`var'"
}


collapse (sum) M1 F1 T1 M2 F2 T2 M3 F3 T3, by(LGA2021 lga_info cob)
tempfile all
save `all'.dta, replace

forvalues i = 2(1)547 {
	use cob`i'.dta, clear
	ren A cob
	foreach var in Afghanistan Bangladesh Nepal Pakistan "Country of birth not stated" Croatia Taiwan {
replace cob = "Born elsewhere(e)" if cob=="`var'"
}
	collapse (sum) M1 F1 T1 M2 F2 T2 M3 F3 T3, by(LGA2021 lga_info cob)
	append using `all'.dta
	save `all'.dta, replace
}

* Merge in the consistent LGA codes
sort LGA2021
merge m:1 LGA2021 using `lgacode'.dta
tab _merge
drop _merge

save "TEMP_2021_from2021_v401.dta", replace


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

* Afghanistan 
* Bangladesh
* Country of birth not stated 
* Croatia 
* Iran 
* Nepal 
* Pakistan
* Taiwan 

ren T3 pop
keep cob LGAFINAL21 pop countrycode
gen year = 2021

* 안맞는 지역 
drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 

* 기타 국가  
replace countrycode="ZZZ" if cob=="Born elsewhere"
egen cob_id=group(countrycode)

* 아시아권 국가 - dummay variable
tab countrycode 

gen asian = inlist(countrycode, "CHN","HKG","IND","IDN","JPN","KOR") ///
         | inlist(countrycode, "MYS","PHL","SGP","LKA","THA","VNM")
replace asian=0 if asian!=1 
tab asian
*********************************************
* pop_immi - 호주제외 이민자 수 (i,k,t)
gen pop_immi=pop
replace pop_immi=. if cob=="Australia"
replace pop_immi=. if cob=="ZZZ" 

gen pop_immi_asian=pop 
replace pop_immi_asian=. if asian!=1 

* tot_immi - 지역별 총 이민자 수 
bysort LGAFINAL21: egen totimmi= total(pop_immi) 

* tot_immi - 지역별 총 아시안 국가 출신 이민자 수
bysort LGAFINAL21: egen totimmi_asian = total(pop_immi_asian)

* tot_pop - 지역별 총 인구수 
bysort LGAFINAL21: egen tot_pop = total(pop) // 지역별 전체인구 (모든 국가 합쳐서)

* national_pop - 각 국가별 출신 총 인구수 
sort countrycode 
by countrycode: egen national_pop= total(pop)

* share_cob - k국가 출신인 사람의 비율 
gen share_cob=pop/national_pop 

save "asian_COB2021_robust_from2021_v501.dta", replace
