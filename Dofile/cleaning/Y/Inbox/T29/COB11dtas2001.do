clear 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2001"

******************************
* education level : 1991~1996년도 통제변수 없어서 추가로 클리닝하고 변수만들기 
******************************

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

keep in 10/13 

keep A B C D F G H J K L 

destring B C D F G H J K L, replace 

ren B males91 
ren C females91 
ren D persons91 

ren F males96 
ren G females96 
ren H persons96

ren J males01 
ren K females01 
ren L persons01 

gen LGA2001 = `i'

sort LGA2001
merge m:1 LGA2001 using `lga'.dta
drop _merge

save /Users/ihuila/Desktop/data/2025ABS/afterControl/2001/t11/cob`i'.dta, replace
}

***************************** STEP2 ******************************
******************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterControl/2001/t11" 

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/625 {
    
    * 1) 원자료 한 행만 남기기
	use cob`i', clear
	
	rename (males91 females91 persons91 males96 females96 persons96 males01 females01 persons01) ///
	(male_1991 female_1991 persons_1991 male_1996 female_1996 persons_1996 male_2001  female_2001 persons_2001)
	
	reshape long male_ female_ persons_, i(A) j(year)

	gen dip = persons_ if A == "Advanced Diploma and Diploma"
	gen bach = persons_ if A == "Bachelor Degree"
	gen grad = persons_ if A == "Graduate Diploma and Graduate Certificate"
	gen postgrad = persons_ if A == "Postgraduate Degree"
	gen edu_total = persons_ if A == "Total"
	
	gen ma_dip = male_ if A == "Advanced Diploma and Diploma"
	gen ma_bach = male_ if A == "Bachelor Degree"
	gen ma_grad = male_ if A == "Graduate Diploma and Graduate Certificate"
	gen ma_postgrad = male_ if A == "Postgraduate Degree"
	gen ma_edu_total = male_ if A == "Total"
	
	gen fe_dip = female_ if A == "Advanced Diploma and Diploma"
	gen fe_bach = female_ if A == "Bachelor Degree"
	gen fe_grad = female_ if A == "Graduate Diploma and Graduate Certificate"
	gen fe_postgrad = female_ if A == "Postgraduate Degree"
	gen fe_edu_total = female_ if A == "Total"
	
	collapse (max) ///
	dip ma_dip fe_dip ///
    bach grad postgrad edu_total ///
    ma_bach ma_grad ma_postgrad ma_edu_total ///
    fe_bach fe_grad fe_postgrad fe_edu_total ///
    , by(LGA2001 year lga_info)

    * 3) 마스터에 누적
    tempfile cur
    save `cur', replace

    use `master', clear
    append using `cur'
    save `master', replace
}

* 4) 최종 결과 저장
use `master', clear
save "cob11_2001census.dta", replace
************************LGA2001 + cob_2001census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2001") firstrow clear

cd "/Users/ihuila/Desktop/data/2025ABS/afterControl/2001/t11" 

expand 3
sort LGA2001

gen year = .
bysort LGA2001: gen id = _n

replace year = 1991 if id == 1
replace year = 1996 if id == 2
replace year = 2001 if id == 3

merge m:1 LGA2001 year using cob11_2001census

drop _merge

save cob11_2001census_fin.dta, replace 

