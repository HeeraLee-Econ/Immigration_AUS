*********2021년 센서스에서 - 2021년도 
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2021"

***** 2021년 
forvalues i = 1(1)547 {
import excel using `i'.xlsx, sheet("T23") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.xlsx, sheet("T23") clear

keep A B C D E F 
ren B onech 
ren C twoch 
ren D thrch 
ren E forch // 4명 이상 
ren F totalfam  

keep in 54/71 
drop in 15/17 

destring onech twoch thrch forch totalfam, replace 

gen year = 2021

gen inctyp = .
replace inctyp = 1  if A == "Negative/Nil income"
replace inctyp = 2  if A == "$1-$149"
replace inctyp = 3  if A == "$150-$299"
replace inctyp = 4  if A == "$300-$399"
replace inctyp = 5  if A == "$400-$499"
replace inctyp = 6  if A == "$500-$649"
replace inctyp = 7  if A == "$650-$799"
replace inctyp = 8  if A == "$800-$999"
replace inctyp = 9  if A == "$1,000-$1,499"
replace inctyp = 10 if A == "$1,500-$1,999"
replace inctyp = 11 if A == "$2,000-$2,499"
replace inctyp = 12 if A == "$2,500-$2,999"
replace inctyp = 13 if A == "$3,000-$3,999"
replace inctyp = 14 if A == "$4,000 or more"
replace inctyp = 15 if A == "Total"

drop A 
reshape wide onech twoch thrch forch totalfam, i(year) j(inctyp) 

gen LGA2021 = `i'

sort LGA2021

save /Users/ihuila/Desktop/data/2025ABS/afterABS9/2021/cob`i'.dta, replace
}

*************************** 쌓기 
clear
use "/Users/ihuila/Desktop/data/2025ABS/afterABS9/2021/cob1.dta", clear

forvalues i = 2/547 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS9/2021/cob`i'.dta"
} 

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS9/2021/"

save cob_2021census.dta, replace 
************************LGA2021 + cob_2021census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2021") firstrow clear

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS9/2021" 

sort LGA2021
gen year = 2021 

merge m:1 LGA2021 year using cob_2021census

drop _merge

save cob_2021census_fin.dta, replace 

