clear 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2001"

******************************
* education level : 1991~1996년도 통제변수 없어서 추가로 클리닝하고 변수만들기 
******************************

import excel using 1.xls, sheet("T 11") clear

forvalues i = 1(1)625 {
import excel using `i'.xls, sheet("T 11") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2001 = `i'
sort LGA2001
tempfile lga
save `lga'.dta, replace

import excel using `i'.xls, sheet("T 11") clear

keep in 10/22
drop in 4/11
drop in 5 

keep A D H 

replace D = "" if D==".."
replace H = "" if H==".."

destring D H, replace 
ren D T1 // T1: 1991 년도 
ren H T2 // T2: 1996 년도 

gen LGA2001 = `i'

sort LGA2001
merge m:1 LGA2001 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterControl/edu/cob`i'.dta, replace
}

***************************** STEP2 ******************************
******************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterControl/edu" 

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/625 {
    
    * 1) 원자료 한 행만 남기기
	use cob`i', clear
	
	rename (T1 T2) ///
	(T_1991 T_20)
	reshape long T_, i(A) j(year)

	* 먼저 빈 변수들 만들기
	gen bach = .
	gen grad = .
	gen postgrad = .
	gen edu_total = .

	* 조건별로 값 채우기
	replace bach = T_ if A == "Bachelor Degree"
	replace grad = T_ if A == "Graduate Diploma and Graduate Certificate"
	replace postgrad = T_ if A == "Postgraduate Degree"
	replace edu_total = T_ if A == "Total"

	collapse (mean) bach grad postgrad edu_total, by(LGA2001 year lga_info)

    * 3) 마스터에 누적
    tempfile cur
    save `cur', replace

    use `master', clear
    append using `cur'
    save `master', replace
}

* 4) 최종 결과 저장
use `master', clear
save "cob.dta", replace

*******************************************************************
******************************************************************
