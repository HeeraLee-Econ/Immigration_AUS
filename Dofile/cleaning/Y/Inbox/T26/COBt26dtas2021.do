********************************************************************************
** Do file that converts Census i.xls to cob`i'.dta for 2021 Census
** by Jun Sung Kim on Nov 13, 2023
********************************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2021"

forvalues i = 1(1)547 {
import excel using `i'.xlsx, sheet("T26") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2021 = `i'
sort LGA2021
tempfile lga
save `lga'.dta, replace

import excel using `i'.xlsx, sheet("T26") clear

keep A H 
keep in 12/45 

destring H, replace 

ren H fam21 

gen couplety = 1 in 2/4 
replace couplety = 2 in 8/10 
replace couplety = 3 in 14/16
replace couplety = 4 in 20/22 
replace couplety = 5 in 26/28 
replace couplety = 6 in 31/34 

// 1: Couple family with no children:    
// 2: Couple family with children under 15 years and dependent students 
// 3: Couple family with children under 15 years and no dependent students 
// 4: Couple family with no children under 15 years and with dependent students 
// 5: Couple family with no children under 15 years and non-dependent children only 
// 6: Total Couple families 

drop if couplety ==. 


gen LGA2021 = `i'

sort LGA2021
merge m:1 LGA2021 using `lga'.dta
drop _merge

save /Users/ihuila/Desktop/data/2025ABS/afterABS/2021/cob`i'.dta, replace
}

******************************STEP2******************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS/2021"

* 전체 LGA 누적 저장용 마스터 파일
tempfile master
save `master', emptyok replace

forvalues i = 1/547 {
    
	use cob`i'.dta 
	
	gen str12 rel_income = ""
	replace rel_income = "female_higher" if strpos(lower(A), "higher than male") > 0
	replace rel_income = "same"          if strpos(lower(A), "same as male") > 0
	replace rel_income = "male_higher"   if strpos(lower(A), "lower than male") > 0
	replace rel_income = "Total" if A == "Total"

	tostring couplety, gen(ct) format(%9.0g)
	gen str40 varid = "ct" + ct + "_" + rel_income
	drop ct
	ren fam21 fam2021 
	keep LGA2021 varid fam2021 
	reshape wide fam2021, i(LGA2021) j(varid) string

	foreach y in 2021 {
		foreach v of varlist fam`y'ct* {
			rename `v' `=subinstr("`v'","fam`y'","",1)'`y'
		}
	}

	reshape long ct1_female_higher ct1_male_higher ct1_same /// 
				ct2_female_higher ct2_male_higher ct2_same /// 
				ct3_female_higher ct3_male_higher ct3_same /// 
				ct4_female_higher ct4_male_higher ct4_same /// 
				ct5_female_higher ct5_male_higher ct5_same /// 
				ct6_female_higher ct6_male_higher ct6_same ct6_Total, i(LGA2021) j(year)
				
    append using `master'
    save `master', replace
}

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS/2021" 

save cob_2021census.dta, replace 
**************************지역 머지하기*****************
************************LGA2001 + cob_2001census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2021") firstrow clear

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS/2021" 

sort LGA2021
gen year = 2021 

merge m:1 LGA2021 year using cob_2021census

drop _merge

save cob_2021census_fin.dta, replace 
