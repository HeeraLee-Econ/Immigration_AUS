// T32 (2001 census 기준 T16: occupation)
// 2021 census 에서 2021년도 것만 추출하기 
// T32a: 2011, 2016, 2021 males 
// T32b: 2011, 2016, 2021 females 
*****************************STEP1**************************************
****************************T32a: 2021 males*********************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2021"

forvalues i = 1(1)547 {
import excel using `i'.xlsx, sheet("T32a") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2021 = `i'
sort LGA2021
tempfile lga
save `lga'.dta, replace

import excel using `i'.xlsx, sheet("T32a") clear

keep A B C D E F G K 

ren B mal15_
ren C mal20_
ren D mal25_
ren E mal35_
ren F mal45_
ren G mal55_
ren K maltot_ 

keep in 51/66 
drop in 13/15 

destring mal15 mal20 mal25 mal35 mal45 mal55 maltot, replace 

gen year = 2021 
replace A = trim(A)

gen maj_type = . 
replace maj_type = 1  if A == "Natural and Physical Sciences"
replace maj_type = 2  if A == "Information Technology"
replace maj_type = 3  if A == "Engineering and Related Technologies"
replace maj_type = 4  if A == "Architecture and Building"
replace maj_type = 5  if A == "Agriculture, Environmental and Related Studies"
replace maj_type = 6  if A == "Health"
replace maj_type = 7  if A == "Education"
replace maj_type = 8  if A == "Management and Commerce"
replace maj_type = 9  if A == "Society and Culture"
replace maj_type = 10 if A == "Creative Arts"
replace maj_type = 11 if A == "Food, Hospitality and Personal Services"
replace maj_type = 12 if A == "Mixed Field Programmes"
replace maj_type = 13 if A == "Total"

drop A 

reshape wide mal15_ mal20_ mal25_ mal35_ mal45_ mal55_ maltot_, i(year) j(maj_type) 

gen LGA2021 = `i'

sort LGA2021
merge m:1 LGA2021 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterABS7/2021/cob`i'_ver1.dta, replace
}

********************************************************************************
****************************T32b: 2021 females*********************************
clear all
set more off
cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2021"

forvalues i = 1(1)547 {
import excel using `i'.xlsx, sheet("T32b") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2021 = `i'
sort LGA2021
tempfile lga
save `lga'.dta, replace

import excel using `i'.xlsx, sheet("T32b") clear

keep A B C D E F G K 

ren B fem15_ 
ren C fem20_
ren D fem25_
ren E fem35_
ren F fem45_
ren G fem55_ 
ren K femtot_

keep in 51/66
drop in 13/15 

destring fem15 fem20 fem25 fem35 fem45 fem55 femtot, replace 

gen year = 2021 

replace A = trim(A)

gen maj_type = . 
replace maj_type = 1  if A == "Natural and Physical Sciences"
replace maj_type = 2  if A == "Information Technology"
replace maj_type = 3  if A == "Engineering and Related Technologies"
replace maj_type = 4  if A == "Architecture and Building"
replace maj_type = 5  if A == "Agriculture, Environmental and Related Studies"
replace maj_type = 6  if A == "Health"
replace maj_type = 7  if A == "Education"
replace maj_type = 8  if A == "Management and Commerce"
replace maj_type = 9  if A == "Society and Culture"
replace maj_type = 10 if A == "Creative Arts"
replace maj_type = 11 if A == "Food, Hospitality and Personal Services"
replace maj_type = 12 if A == "Mixed Field Programmes"
replace maj_type = 13 if A == "Total"

drop A 

reshape wide fem15_ fem20_ fem25_ fem35_ fem45_ fem55_ femtot_, i(year) j(maj_type) 

gen LGA2021 = `i'

sort LGA2021
merge m:1 LGA2021 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterABS7/2021/cob`i'_ver2.dta, replace
}
***************************STEP2: append / by sex 
**** males 
clear
use "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2021/cob1_ver1.dta", clear

forvalues i = 2/547 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2021/cob`i'_ver1.dta"
} 
cd "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2021" 
save cob_2021_ver1.dta, replace 

**** females 
clear
use "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2021/cob1_ver2.dta"

forvalues i = 2/547 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2021/cob`i'_ver2.dta"
} 

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2021" 
save cob_2021_ver2.dta, replace 

***************************STEP3: merge  
use cob_2021_ver1, clear 
 
merge m:1 LGA2021 year using cob_2021_ver2

drop _merge 

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2021/"
save cob_2021census.dta, replace 
**************************STEP4:
************************LGA2001 + cob_2001census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2021") firstrow clear

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2021" 


sort LGA2021
gen year = 2021 

merge m:1 LGA2021 year using cob_2021census

drop _merge

save cob_2021census_fin.dta, replace 
