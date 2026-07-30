*** Double income with no children family - 2006 from 2016 census 
********************************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2016"
import excel using 1.XLS, sheet("T 30a") clear

forvalues i = 1(1)544 {
import excel using `i'.XLS, sheet("T 30a") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 30a") clear

keep A Q 
keep in 14/24
drop in 2/10 
destring Q, replace 

gen year = 2006 
gen LGA2016 = `i'

sort LGA2016
merge m:1 LGA2016 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterABS6/2016/cob`i'_ver1.dta, replace
}

*******************************************************************************
*** Double income with no children family - 2011 from 2016 census 
********************************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2016"
import excel using 1.XLS, sheet("T 30b") clear

forvalues i = 1(1)544 {
import excel using `i'.XLS, sheet("T 30b") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 30b") clear

keep A Q 
keep in 14/24
drop in 2/10 
destring Q, replace 

gen year = 2011 
gen LGA2016 = `i'

sort LGA2016
merge m:1 LGA2016 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterABS6/2016/cob`i'_ver2.dta, replace
}

*******************************************************************************
*** Double income with no children family - 2016 from 2016 census 
********************************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2016"
import excel using 1.XLS, sheet("T 30b") clear

forvalues i = 1(1)544 {
import excel using `i'.XLS, sheet("T 30b") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 30b") clear

keep A Q 
keep in 14/24
drop in 2/10 
destring Q, replace 

gen year = 2016 
gen LGA2016 = `i'

sort LGA2016
merge m:1 LGA2016 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterABS6/2016/cob`i'_ver3.dta, replace
}

**********************************************************************
***************** STEP 2 -  census **********************************
cd "/Users/ihuila/Desktop/data/2025ABS/afterABS6/2016/"
clear 
set more off 

use cob1_ver1

merge 1:1 A year using cob1_ver2 
drop _merge
merge 1:1 A year using cob1_ver3

drop _merge
















***************************** STEP2 ******************************
***************************** GROUP 1 - occupation*********************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2016" 

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/544 {
    
    * 1) 원자료 한 행만 남기기
	use cob`i', clear
	
	drop in 3 

	rename (male06 femal06 persons06 male11 female11 persons11 male16 female16 persons16) ///
		   (male_2006 female_2006 persons_2006 male_2011 female_2011 persons_2011 male_2016 female_2016 persons_2016)

	reshape long male_ female_ persons_, i(A) j(year)

	gen boss_male = .
	gen boss_female = .
	gen boss_persons = .

	* 2. egen으로 year 그룹별 합계 계산
	bysort year: egen boss_male_temp = total(male_)
	bysort year: egen boss_female_temp= total(female_)
	bysort year: egen boss_persons_temp = total(persons_)

	* 3. 해당 값을 각 행에 저장
	replace boss_male  = boss_male_temp
	replace boss_female = boss_female_temp
	replace boss_persons = boss_persons_temp

	* 4. 정리 (임시변수 제거)
	drop boss_male_temp boss_female_temp boss_persons_temp
	drop A male_ female_ persons_

	collapse (mean) boss*, by(year LGA2016 lga_info)

    * 3) 마스터에 누적
    tempfile cur
    save `cur', replace

    use `master', clear
    append using `cur'
    save `master', replace
}

* 4) 최종 결과 저장
use `master', clear
save "cob_g1.dta", replace
***************************** GROUP 2 - TOTAL ******************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2016" 

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/544 {
    
    * 1) 원자료 한 행만 남기기
	use cob`i', clear
	
	keep in 3 

	rename (male06 femal06 persons06 male11 female11 persons11 male16 female16 persons16) ///
		   (tomale_2006 tofemale_2006 topersons_2006 tomale_2011 tofemale_2011 topersons_2011 tomale_2016 tofemale_2016 topersons_2016)

	reshape long tomale_ tofemale_ topersons_, i(A) j(year)
	drop A 
    * 3) 마스터에 누적
    tempfile cur
    save `cur', replace

    use `master', clear
    append using `cur'
    save `master', replace
}

* 4) 최종 결과 저장
use `master', clear
save "cob_g2.dta", replace
********************************************************************
*******************STEP3 ***************************** 
********* 각 그룹별 데이터 모두 merge ******
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2016" 

use cob_g1.dta, replace 

merge 1:1 year LGA2016 using cob_g2.dta 

drop _merge 

save cob2016_merge.dta, replace 

use cob_g1.dta, replace 

merge 1:1 year LGA2016 using cob_g2.dta 

drop _merge 
tab year 

save cob2016_merge.dta, replace 
*********************************
use cob2016_merge.dta, clear 
keep if year==2006  
save cob2016_2006.dta, replace
 
use cob2016_merge.dta, clear 
keep if year==2011  
save cob2016_2011.dta, replace 

use cob2016_merge.dta, clear 
keep if year==2016 
save cob2016_2016.dta, replace 
