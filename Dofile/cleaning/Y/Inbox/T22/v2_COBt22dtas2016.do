*********2016년 센서스에서 - 2006, 2011, 2016년 
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2016"

***** 2006년 
forvalues i = 1(1)544 {
import excel using `i'.XLS, sheet("T 22a") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 22a") clear

keep A B C D E F 
ren B onech 
ren C twoch 
ren D thrch 
ren E forch // 4명 이상 
ren F totalfam  

keep in 13/30 
drop in 15/17 

destring onech twoch thrch forch totalfam, replace 

gen year = 2006 

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

gen LGA2016 = `i'

sort LGA2016

save /Users/ihuila/Desktop/data/2025ABS/afterABS8/2016/cob`i'_ver1.dta, replace
}

***** 2011년 
forvalues i = 1(1)544 {
import excel using `i'.XLS, sheet("T 22a") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 22a") clear

keep A B C D E F 
ren B onech 
ren C twoch 
ren D thrch 
ren E forch // 4명 이상 
ren F totalfam  

keep in 34/51 
drop in 15/17 

destring onech twoch thrch forch totalfam, replace 

gen year = 2011 

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

gen LGA2016 = `i'

sort LGA2016

save /Users/ihuila/Desktop/data/2025ABS/afterABS8/2016/cob`i'_ver2.dta, replace
}

***** 2016년 
forvalues i = 1(1)544 {
import excel using `i'.XLS, sheet("T 22b") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 22b") clear

keep A B C D E F 
ren B onech 
ren C twoch 
ren D thrch 
ren E forch // 4명 이상 
ren F totalfam  

keep in 13/30 
drop in 15/17

destring onech twoch thrch forch totalfam, replace 

gen year = 2016 

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

gen LGA2016 = `i'

sort LGA2016

save /Users/ihuila/Desktop/data/2025ABS/afterABS8/2016/cob`i'_ver3.dta, replace
}

*************************** 쌓기 
clear
use "/Users/ihuila/Desktop/data/2025ABS/afterABS8/2016/cob1_ver1.dta", clear

forvalues i = 2/544 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS8/2016/cob`i'_ver1.dta"
} 

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS8/2016/cob1_ver2.dta"

forvalues i = 2/544 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS8/2016/cob`i'_ver2.dta"
} 

append using "/Users/ihuila/Desktop/data/2025ABS/afterABS8/2016/cob1_ver3.dta"

forvalues i = 2/544 {
	append using "/Users/ihuila/Desktop/data/2025ABS/afterABS8/2016/cob`i'_ver3.dta"
} 

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS8/v2_2016/"

ren onech ch_one 
ren twoch ch_two
ren thrch ch_thr
ren forch ch_fou
ren totalfam ch_tot

reshape long ch_, i(LGA2016 year inctyp inc_low inc_high) j(hh_type) string

save cob_2016census.dta, replace 
************************LGA2016 + cob_2016census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2016") firstrow clear

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS8/v2_2016" 

expand 3
sort LGA2016

gen year = . 
bysort LGA2016: gen id = _n

replace year = 2006 if id == 1
replace year = 2011 if id == 2
replace year = 2016 if id == 3

merge m:n LGA2016 year using cob_2016census //m:n 

drop _merge

save cob_2016census_fin.dta, replace 


