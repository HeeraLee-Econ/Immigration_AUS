*********2021년 센서스에서 - 2021년데이터만 
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2021"

forvalues i = 1(1)547 {
import excel using `i'.xlsx, sheet("T04") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2021 = `i'
sort LGA2021
tempfile lga
save `lga'.dta, replace

import excel using `i'.xlsx, sheet("T04") clear

keep A B C R S V W 

ren B mar_male 
ren C mar_female 
ren R no_male 
ren S no_female 
ren V to_male
ren W to_female

keep in 52/68 
drop in 6/16 

destring mar_male mar_female no_male no_female to_male to_female, replace 

gen year = 2021 

encode A, gen(age_id)
drop A 

reshape wide mar_male mar_female no_male no_female to_male to_female, ///
    i(year) j(age_id)
	
	// age_id 
// 1: 15-19years, 2: 20-24years, 3: 25-29years, 4: 30-34years, 5: 35-39years, 6: total 

gen LGA2021 = `i'

sort LGA2021

save /Users/ihuila/Desktop/data/2025ABS/afterABS5/2021/cob`i'.dta, replace
}
**********************************************************
clear
use "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2021/cob1.dta", clear

forvalues i = 2/547 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2021/cob`i'.dta"
} 

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2021/"

save cob_2021census.dta, replace 
************************LGA2021 + cob_2021census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2021") firstrow clear

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS5/2021" 

sort LGA2021
gen year = 2021 

merge m:1 LGA2021 year using cob_2021census

drop _merge

save cob_2021census_fin.dta, replace 
