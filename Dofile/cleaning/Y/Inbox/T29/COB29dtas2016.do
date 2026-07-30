// T29 - labor force, age15+, education level, unemployed 
// 2016 census 에서 2006~2016

********************************************************************************
** Do file that converts Census i.xls to cob`i'.dta for 2021 Census
** by Jun Sung Kim on Nov 13, 2023
********************************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2016"

forvalues i = 1(1)544 {
import excel using `i'.XLS, sheet("T 29") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 29") clear

keep in 14/30 
drop in 6/13

keep A B C D F G H J K L 

destring B C D F G H J K L, replace 

ren B males06 
ren C females06 
ren D persons06 

ren F males11
ren G females11
ren H persons11

ren J males16
ren K females16 
ren L persons16 

gen LGA2016 = `i'

sort LGA2016
merge m:1 LGA2016 using `lga'.dta
drop _merge

save /Users/ihuila/Desktop/data/2025ABS/afterControl/2016/t29/cob`i'.dta, replace 
}

***************************** STEP2 ******************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterControl/2016/t29" 

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/544 {
    
    * 1) 원자료 한 행만 남기기
	use cob`i', clear

	rename (males06 females06 persons06 males11 females11 persons11 males16 females16 		persons16) ///
	(male_2006 female_2006 persons_2006 male_2011 female_2011 persons_2011 male_2016  	female_2016 persons_2016)
	
	reshape long male_ female_ persons_, i(A) j(year)
	
	gen employed_a = persons_ if A == "Employed, worked part-time"
	gen employed_b = persons_ if A == "Employed, worked full-time(b)"
	gen employed_c = persons_ if A == "Employed, away from work(c)"
	//gen popfifteen = persons_ if A== "Persons aged 15 years and over"
	gen unemployed = persons_ if A== "Unemployed, looking for work"
	gen labor_force = persons_ if A== "Total labour force"
	//gen nolabor_force = persons_ if A== "Not in the labour force"
	gen dip = persons_ if A == "Advanced Diploma and Diploma Level"
	gen postgrad = persons_ if A == "Postgraduate Degree Level"
	gen grad = persons_ if A == "Graduate Diploma and Graduate Certificate Level"
	gen bach = persons_ if A == "Bachelor Degree Level"
	
	gen ma_employed_a = male_ if A == "Employed, worked part-time"
	gen ma_employed_b = male_ if A == "Employed, worked full-time(b)"
	gen ma_employed_c = male_ if A == "Employed, away from work(c)"
	//gen ma_popfifteen = male_ if A== "Persons aged 15 years and over"
	gen ma_unemployed = male_ if A== "Unemployed, looking for work"
	gen ma_labor_force = male_ if A== "Total labour force"
	//gen ma_nolabor_force = male_ if A== "Not in the labour force"
	gen ma_dip = male_ if A == "Advanced Diploma and Diploma Level"
	gen ma_postgrad = male_ if A == "Postgraduate Degree Level"
	gen ma_grad = male_ if A == "Graduate Diploma and Graduate Certificate Level"
	gen ma_bach = male_ if A == "Bachelor Degree Level"

	gen fe_employed_a = female_ if A == "Employed, worked part-time"
	gen fe_employed_b = female_ if A == "Employed, worked full-time(b)"
	gen fe_employed_c = female_ if A == "Employed, away from work(c)"
	//gen fe_popfifteen = female_ if A== "Persons aged 15 years and over"
	gen fe_unemployed = female_ if A== "Unemployed, looking for work"
	gen fe_labor_force = female_ if A== "Total labour force"
	//gen fe_nolabor_force = female_ if A== "Not in the labour force"
	gen fe_dip = female_ if A == "Advanced Diploma and Diploma Level"
	gen fe_postgrad = female_ if A == "Postgraduate Degree Level"
	gen fe_grad = female_ if A == "Graduate Diploma and Graduate Certificate Level"
	gen fe_bach = female_ if A == "Bachelor Degree Level"
	
	collapse (max) ///
	employed_a employed_b employed_c /// 
	ma_employed_a ma_employed_b ma_employed_c /// 
	fe_employed_a fe_employed_b fe_employed_c ///
    unemployed labor_force  ///
    postgrad grad bach dip ///
    ma_unemployed ma_labor_force ///
    ma_postgrad ma_grad ma_bach ma_dip ///
    fe_unemployed fe_labor_force  ///
    fe_postgrad fe_grad fe_bach fe_dip ///
    , by(year LGA2016 lga_info)

    * 3) 마스터에 누적
    tempfile cur
    save `cur', replace

    use `master', clear
    append using `cur'
    save `master', replace
}

* 4) 최종 결과 저장
use `master', clear
save "cob29_2016census.dta", replace
************************LGA2016 + cob_2016census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2016") firstrow clear

cd "/Users/ihuila/Desktop/data/2025ABS/afterControl/2016/t29" 

expand 3
sort LGA2016

gen year = .
bysort LGA2016: gen id = _n

replace year = 2006 if id == 1
replace year = 2011 if id == 2
replace year = 2016 if id == 3

merge m:1 LGA2016 year using cob29_2016census

drop _merge

save cob29_2016census_fin.dta, replace 

