*********2021년 센서스에서 - 2021년도 
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2021"

***** 2021년 
forvalues i = 1(1)547 {
import excel using `i'.xlsx, sheet("T22") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.xlsx, sheet("T22") clear

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

*--------------------------------------
* 1. 소득구간 하한/상한 변수 생성
*--------------------------------------

gen inc_low  = .
gen inc_high = .

* 1. Negative/Nil income
replace inc_low  = 0   if inctyp == 1
replace inc_high = 0   if inctyp == 1

* 2. $1-$149
replace inc_low  = 1   if inctyp == 2
replace inc_high = 149 if inctyp == 2

* 3. $150-$299
replace inc_low  = 150 if inctyp == 3
replace inc_high = 299 if inctyp == 3

* 4. $300-$399
replace inc_low  = 300 if inctyp == 4
replace inc_high = 399 if inctyp == 4

* 5. $400-$499
replace inc_low  = 400 if inctyp == 5
replace inc_high = 499 if inctyp == 5

* 6. $500-$649
replace inc_low  = 500 if inctyp == 6
replace inc_high = 649 if inctyp == 6

* 7. $650-$799
replace inc_low  = 650 if inctyp == 7
replace inc_high = 799 if inctyp == 7

* 8. $800-$999
replace inc_low  = 800 if inctyp == 8
replace inc_high = 999 if inctyp == 8

* 9. $1,000-$1,499
replace inc_low  = 1000 if inctyp == 9
replace inc_high = 1499 if inctyp == 9

* 10. $1,500-$1,999
replace inc_low  = 1500 if inctyp == 10
replace inc_high = 1999 if inctyp == 10

* 11. $2,000-$2,499
replace inc_low  = 2000 if inctyp == 11
replace inc_high = 2499 if inctyp == 11

* 12. $2,500-$2,999
replace inc_low  = 2500 if inctyp == 12
replace inc_high = 2999 if inctyp == 12

* 13. $3,000-$3,999
replace inc_low  = 3000 if inctyp == 13
replace inc_high = 3999 if inctyp == 13

* 14. $4,000 or more (open-ended)
replace inc_low  = 4000 if inctyp == 14
replace inc_high = .    if inctyp == 14

* 15. Total → 계산에서 제외
replace inc_low  = . if inctyp == 15
replace inc_high = . if inctyp == 15

gen LGA2021 = `i'

sort LGA2021

save /Users/ihuila/Desktop/data/2025ABS/afterABS8/2021/cob`i'.dta, replace
}

*************************** 쌓기 
clear
use "/Users/ihuila/Desktop/data/2025ABS/afterABS8/2021/cob1.dta", clear

forvalues i = 2/547 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS8/2021/cob`i'.dta"
} 

ren onech ch_one 
ren twoch ch_two
ren thrch ch_thr
ren forch ch_fou
ren totalfam ch_tot

reshape long ch_, i(LGA2021 year inctyp inc_low inc_high) j(hh_type) string

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS8/v2_2021/"

save cob_2021census.dta, replace 
************************LGA2021 + cob_2021census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2021") firstrow clear

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS8/v2_2021" 

sort LGA2021
gen year = 2021 

merge m:n LGA2021 year using cob_2021census

drop _merge

save cob_2021census_fin.dta, replace 

