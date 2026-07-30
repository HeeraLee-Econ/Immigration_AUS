// T32 (2001 census 기준 T12: field of study)
// 2016census 에서 2006, 2011, 2016년도 데이터 가져오기 

// T 32a: 2006, 2011 males, 
// T 32b: 2016 males 
// T 32c: 2006, 2011 females 
// T 32d: 2016 females 

// T 32e: 2006, 2011 persons 
// T 32f: 2016 persons 
***************************STEP1:T 32a*********************************
***************T32 a: 2006, 2011 males 
clear 
cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2016"

forvalues i = 1(1)544 {
	
import excel using `i'.XLS, sheet("T 32a") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 32a") clear
keep A B C D E F G K 

ren B mal15_ 
ren C mal20_
ren D mal25_
ren E mal35_
ren F mal45_
ren G mal55_ 
ren K maltot_

keep in 13/47
drop in 13/15
drop in 14/16  
drop in 26/28

destring mal15 mal20 mal25 mal35 mal45 mal55 maltot, replace 

gen year= 2006 in 1/13 
replace year = 2011 in 14/26 

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

gen LGA2016 = `i'

sort LGA2016
merge m:1 LGA2016 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterABS7/2016/cob`i'_ver1.dta, replace
}

****************T 32b: 2016 males
clear 
cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2016"

forvalues i = 1(1)544 {
import excel using `i'.XLS, sheet("T 32b") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 32b") clear

keep A B C D E F G K 

ren B mal15_ 
ren C mal20_
ren D mal25_
ren E mal35_
ren F mal45_
ren G mal55_ 
ren K maltot_

keep in 13/28 
drop in 13/15 

destring mal15 mal20 mal25 mal35 mal45 mal55 maltot, replace 

gen year = 2016 

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

gen LGA2016 = `i'

sort LGA2016
merge m:1 LGA2016 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterABS7/2016/cob`i'_ver2.dta, replace
}

***************T32 c: 2006, 2011 females 
clear 
cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2016"

forvalues i = 1(1)544 {
import excel using `i'.XLS, sheet("T 32c") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 32c") clear

keep A B C D E F G K 

ren B fem15_ 
ren C fem20_
ren D fem25_
ren E fem35_
ren F fem45_
ren G fem55_ 
ren K femtot_

keep in 13/47
drop in 13/15
drop in 14/16  
drop in 26/28

destring fem15 fem20 fem25 fem35 fem45 fem55 femtot, replace 

gen year= 2006 in 1/13 
replace year = 2011 in 14/26 

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

gen LGA2016 = `i'

sort LGA2016
merge m:1 LGA2016 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterABS7/2016/cob`i'_ver3.dta, replace
}

****************T 32d: 2016 females 
clear 
cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2016"

forvalues i = 1(1)544 {
import excel using `i'.XLS, sheet("T 32d") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 32d") clear

keep A B C D E F G K 

ren B fem15_ 
ren C fem20_
ren D fem25_
ren E fem35_
ren F fem45_
ren G fem55_ 
ren K femtot_

keep in 13/28 
drop in 13/15 

destring fem15 fem20 fem25 fem35 fem45 fem55 femtot, replace 

gen year= 2016

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

gen LGA2016 = `i'

sort LGA2016
merge m:1 LGA2016 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterABS7/2016/cob`i'_ver4.dta, replace
}

***********************males - long type (ver1, ver2) **********************
clear
use "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2016/cob1_ver1.dta", clear

forvalues i = 2/544 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2016/cob`i'_ver1.dta"
} 

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2016/cob1_ver2.dta"

forvalues i = 2/544 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2016/cob`i'_ver2.dta"
} 

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2016" 
save cob_ver12.dta, replace 

***********************females - long type (ver3, ver4) **********************
clear
use "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2016/cob1_ver3.dta", clear

forvalues i = 2/544 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2016/cob`i'_ver3.dta"
} 

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2016/cob1_ver4.dta"

forvalues i = 2/544 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2016/cob`i'_ver4.dta"
} 

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2016" 
save cob_ver34.dta, replace 

**********************males:females - merge 
cd "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2016/"
use cob_ver12, clear 

merge m:1 LGA2016 year using cob_ver34

drop _merge

tab year 

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2016"
save cob_2016census.dta, replace 
************************************************************
************************LGA2016 + cob_2016census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2016") firstrow clear

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2016" 

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
