********************************************************************************
** Do file that converts Census i.xls to cob`i'.dta for 2021 Census
** by Jun Sung Kim on Nov 13, 2023
********************************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2016"

import excel using 1.XLS, sheet("T 26") clear 

forvalues i = 1(1)544 {
import excel using `i'.XLS, sheet("T 26") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 26") clear

keep A B E H 
keep in 12/45 

destring B E H, replace

ren B fam06 
ren E fam11 
ren H fam16 

/*
replace B = "" if B==".."
replace E = "" if E==".."
replace H = "" if H==".."

drop if B==. & E==. & H == . 
*/

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

gen LGA2016 = `i'

sort LGA2016
merge m:1 LGA2016 using `lga'.dta
drop _merge

save /Users/ihuila/Desktop/data/2025ABS/afterABS/2016/cob`i'.dta, replace
}

***************************** STEP2 ******************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS/2016"

*전체 LGA 누적 저장용 마스터 파일
tempfile master
save `master', emptyok replace

forvalues i = 1/544 {
    
	use cob`i'.dta 
	
	gen str12 rel_income = ""
	replace rel_income = "female_higher" if strpos(lower(A), "higher than male") > 0
	replace rel_income = "same"          if strpos(lower(A), "same as male") > 0
	replace rel_income = "male_higher"   if strpos(lower(A), "lower than male") > 0
	replace rel_income = "Total" if A == "Total"

	tostring couplety, gen(ct) format(%9.0g)
	gen str40 varid = "ct" + ct + "_" + rel_income
	drop ct

	ren (fam06 fam11 fam16) (fam2006 fam2011 fam2016)
	keep LGA2016 varid fam2006 fam2011 fam2016
	reshape wide fam2006 fam2011 fam2016, i(LGA2016) j(varid) string

	foreach y in 2006 2011 2016 {
		foreach v of varlist fam`y'ct* {
			rename `v' `=subinstr("`v'","fam`y'","",1)'`y'
		}
	}

	reshape long ct1_female_higher ct1_male_higher ct1_same /// 
				ct2_female_higher ct2_male_higher ct2_same /// 
				ct3_female_higher ct3_male_higher ct3_same /// 
				ct4_female_higher ct4_male_higher ct4_same /// 
				ct5_female_higher ct5_male_higher ct5_same /// 
				ct6_female_higher ct6_male_higher ct6_same ct6_Total, i(LGA2016) j(year)
			
    append using `master'
    save `master', replace
}

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS/2016" 

save cob_2016census.dta, replace 
********************************************************
*******************STEP3 ***************************** 
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2016") firstrow clear

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS/2016" 

expand 3
sort LGA2016

gen year = .
bysort LGA2016: gen id = _n

replace year = 2006 if id == 1
replace year = 2011 if id == 2
replace year = 2016 if id == 3

merge m:1 LGA2016 year using cob_2016census

drop _merge

save cob_2016census_fin.dta, replace 
