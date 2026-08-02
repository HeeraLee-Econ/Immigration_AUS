*********2001년 센서스에서 - 1991년 / 1996년 
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2001"

********************************* 1991년 
forvalues i = 1(1)625 {
import excel using `i'.XLS, sheet("T 03A") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2001 = `i'
sort LGA2001
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 03A") clear

keep A B C N O Q R 
ren B mar_male 
ren C mar_female 
ren N no_male 
ren O no_female 
ren Q to_male 
ren R to_female 

keep in 11/28
drop in 6/17 

destring mar_male mar_female no_male no_female to_male to_female, replace 

gen year = 1991 

encode A, gen(age_id)
drop A 

reshape wide mar_male mar_female no_male no_female to_male to_female, ///
    i(year) j(age_id)
	
// age_id 
// 1: 15-19years, 2: 20-24years, 3: 25-29years, 4: 30-34years, 5: 35-39years, 6: total 

gen LGA2001 = `i'

sort LGA2001

save /Users/ihuila/Desktop/data/2025ABS/afterABS5/2001/cob`i'_ver1.dta, replace
}

************************************ 1996년
forvalues i = 1(1)625 {
import excel using `i'.XLS, sheet("T 03A") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2001 = `i'
sort LGA2001
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 03A") clear

keep A B C N O Q R 

ren B mar_male 
ren C mar_female 
ren N no_male 
ren O no_female 
ren Q to_male 
ren R to_female 

keep in 32/49 
drop in 6/17 

destring mar_male mar_female no_male no_female to_male to_female, replace 

gen year = 1996  

encode A, gen(age_id)
drop A 

reshape wide mar_male mar_female no_male no_female to_male to_female, ///
    i(year) j(age_id)
	
// age_id 
// 1: 15-19years, 2: 20-24years, 3: 25-29years, 4: 30-34years, 5: 35-39years, 6: total 

gen LGA2001 = `i'

sort LGA2001

save /Users/ihuila/Desktop/data/2025ABS/afterABS5/2001/cob`i'_ver2.dta, replace
}

***** 2001년 
forvalues i = 1(1)625 {
import excel using `i'.XLS, sheet("T 03B") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2001 = `i'
sort LGA2001
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 03B") clear

keep A B C N O Q R

ren B mar_male 
ren C mar_female
ren N no_male 
ren O no_female 
ren Q to_male 
ren R to_female 

keep in 11/28 
drop in 6/17 

gen year=2001 

destring mar_male mar_female no_male no_female to_male to_female, replace 

encode A, gen(age_id)
drop A 

reshape wide mar_male mar_female no_male no_female to_male to_female, ///
    i(year) j(age_id)
	
// age_id 
// 1: 15-19years, 2: 20-24years, 3: 25-29years, 4: 30-34years, 5: 35-39years, 6: total 

gen LGA2001 = `i'
sort LGA2001

save /Users/ihuila/Desktop/data/2025ABS/afterABS5/2001/cob`i'_ver3.dta, replace
}

** 쌓기 
clear
use "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2001/cob1_ver1.dta", clear

forvalues i = 2/625 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2001/cob`i'_ver1.dta"
} 

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2001/cob1_ver2.dta"

forvalues i = 2/625 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2001/cob`i'_ver2.dta"
} 

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2001/cob1_ver3.dta"

forvalues i = 2/625 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2001/cob`i'_ver3.dta"
} 

tab year 
tab LGA2001 

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2001/"

save cob_2001census.dta, replace 

************************LGA2001 + cob_2001census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2001") firstrow clear

expand 3
sort LGA2001

gen year = .
bysort LGA2001: gen id = _n

replace year = 1991 if id == 1
replace year = 1996 if id == 2
replace year = 2001 if id == 3

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2001" 
merge m:1 LGA2001 year using cob_2001census

drop _merge

save cob_2001census_fin.dta, replace 
