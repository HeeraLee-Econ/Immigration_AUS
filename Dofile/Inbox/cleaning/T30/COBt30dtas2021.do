
// 2001 census 에서 1996, 2001 데이터 긁어오기 

********************************************************************************
** Do file that converts Census i.xls to cob`i'.dta for 2021 Census
** by Jun Sung Kim on Nov 13, 2023
********************************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2021"

forvalues i = 1(1)547 {
import excel using `i'.xlsx, sheet("T30a") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2021 = `i'
sort LGA2021
tempfile lga
save `lga'.dta, replace

import excel using `i'.xlsx, sheet("T35") clear

keep in 11/21
drop in 3/10

keep A J K L 

drop if A==""

replace J = "" if J==".."
replace K = "" if K==".."
replace L = "" if L==".."

destring J K L , replace

drop if J==. & K==. & L==. 

ren J male21 
ren K female21
ren L persons21 

gen LGA2021 = `i'

sort LGA2021
merge m:1 LGA2021 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterABS4/2021/cob`i'.dta, replace
}

***************************** STEP2 ******************************
***************************** GROUP 1 - occupation*********************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2021" 

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/547 {
    
    * 1) 원자료 한 행만 남기기
	use cob`i', clear
	
	drop in 3 

	rename (male21 female21 persons21) ///
		   (male_2021 female_2021 persons_2021)

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

	collapse (mean) boss*, by(year LGA2021 lga_info)

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

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2021" 

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/547 {
    
    * 1) 원자료 한 행만 남기기
	use cob`i', clear
	
	keep in 3 

	rename (male21 female21 persons21) ///
		   (tomale_ tofemale_ topersons_)
	drop A 
	
	gen year=2021 
	
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

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2021" 

use cob_g1.dta, replace 

merge 1:1 year LGA2021 using cob_g2.dta 

drop _merge 
tab year 

save cob2021_2021.dta, replace 
