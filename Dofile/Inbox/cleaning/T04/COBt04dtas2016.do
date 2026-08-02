*********2016년 센서스에서 - 2006, 2011, 2016년 
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2016"

***** 2006년 
forvalues i = 1(1)544 {
import excel using `i'.XLS, sheet("T 04a") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 04a") clear

keep A B C N O Q R 

ren B mar_male 
ren C mar_female
ren N no_male 
ren O no_female 
ren Q to_male 
ren R to_female 

keep in 12/28 
drop in 6/16

destring mar_male mar_female no_male no_female to_male to_female, replace 

gen year = 2006 

encode A, gen(age_id)
drop A 

reshape wide mar_male mar_female no_male no_female to_male to_female, ///
    i(year) j(age_id)
	
	// age_id 
// 1: 15-19years, 2: 20-24years, 3: 25-29years, 4: 30-34years, 5: 35-39years, 6: total 


gen LGA2016 = `i'

sort LGA2016

save /Users/ihuila/Desktop/data/2025ABS/afterABS5/2016/cob`i'_ver1.dta, replace
}

***** 2011년 
forvalues i = 1(1)544 {
import excel using `i'.XLS, sheet("T 04a") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 04a") clear

keep A B C N O Q R 

ren B mar_male 
ren C mar_female
ren N no_male 
ren O no_female 
ren Q to_male 
ren R to_female 

keep in 32/48 
drop in 6/16  

destring mar_male mar_female no_male no_female to_male to_female, replace 

gen year = 2011 

encode A, gen(age_id)
drop A 

reshape wide mar_male mar_female no_male no_female to_male to_female, ///
    i(year) j(age_id)
	
	// age_id 
// 1: 15-19years, 2: 20-24years, 3: 25-29years, 4: 30-34years, 5: 35-39years, 6: total 

gen LGA2016 = `i'

sort LGA2016

save /Users/ihuila/Desktop/data/2025ABS/afterABS5/2016/cob`i'_ver2.dta, replace
}

***** 2016년 
forvalues i = 1(1)544 {
import excel using `i'.XLS, sheet("T 04b") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 04b") clear

keep A B C N O Q R 

ren B mar_male 
ren C mar_female
ren N no_male 
ren O no_female 
ren Q to_male 
ren R to_female 

keep in 12/28 
drop in 6/16 

destring mar_male mar_female no_male no_female to_male to_female, replace 

gen year = 2016  

encode A, gen(age_id)
drop A 

reshape wide mar_male mar_female no_male no_female to_male to_female, ///
    i(year) j(age_id)
	
	// age_id 
// 1: 15-19years, 2: 20-24years, 3: 25-29years, 4: 30-34years, 5: 35-39years, 6: total 

gen LGA2016 = `i'

sort LGA2016

save /Users/ihuila/Desktop/data/2025ABS/afterABS5/2016/cob`i'_ver3.dta, replace
}

*************************** 쌓기 
clear
use "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2016/cob1_ver1.dta", clear

forvalues i = 2/544 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2016/cob`i'_ver1.dta"
} 

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2016/cob1_ver2.dta"

forvalues i = 2/544 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2016/cob`i'_ver2.dta"
} 

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2016/cob1_ver3.dta"

forvalues i = 2/544 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2016/cob`i'_ver3.dta"
} 

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2016/"

save cob_2016census.dta, replace 
************************LGA2016 + cob_2016census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2016") firstrow clear


cd "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2016" 

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


