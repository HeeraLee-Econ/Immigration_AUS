// T29 - labor force, age15+, education level, unemployed 
// 2016 census 에서 2006~2016

********************************************************************************
** Do file that converts Census i.xls to cob`i'.dta for 2021 Census
** by Jun Sung Kim on Nov 13, 2023
********************************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2021"

forvalues i = 1(1)547 {
import excel using `i'.xlsx, sheet("T29") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2021 = `i'
sort LGA2021
tempfile lga
save `lga'.dta, replace

import excel using `i'.xlsx, sheet("T29") clear

keep in 15/31
drop in 6/12 

keep A J K L 

destring J K L, replace 

ren J males21
ren K females21 
ren L persons21 

gen LGA2021 = `i'

sort LGA2021
merge m:1 LGA2021 using `lga'.dta
drop _merge

save /Users/ihuila/Desktop/data/2025ABS/afterControl/2021/t29/cob`i'.dta, replace 
}

***************************** STEP2 ******************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterControl/2021/t29" 

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/547 {
    
    * 1) 원자료 한 행만 남기기
	use cob`i', clear

	rename (males21 females21 persons21) /// 
	(male_2021 female_2021 persons_2021)
	
	reshape long male_ female_ persons_, i(A) j(year)
	
	gen employed_a = persons_ if A == "Employed, worked part-time(c)"
	gen employed_b = persons_ if A == "Employed, worked full-time(b)"
	gen employed_c = persons_ if A == "Employed, away from work(d)"

	 // 2016년이랑 어차피 매치 세부 고용 카테고리 안맞아도 나중에 합산할거라서 괜찮음 
	//gen popfifteen = persons_ if A== "Persons aged 15 years and over"
	gen unemployed = persons_ if A== "Unemployed, looking for work"
	gen labor_force = persons_ if A== "Total labour force"
	//gen nolabor_force = persons_ if A== "Not in the labour force"
	gen dip = persons_ if A == "Advanced Diploma and Diploma Level"
	gen postgrad = persons_ if A == "Postgraduate Degree Level"
	gen grad = persons_ if A == "Graduate Diploma and Graduate Certificate Level"
	gen bach = persons_ if A == "Bachelor Degree Level"
	
	gen ma_employed_a = male_ if A == "Employed, worked part-time(c)"
	gen ma_employed_b = male_ if A == "Employed, worked full-time(b)"
	gen ma_employed_c = male_ if A == "Employed, away from work(d)"

	//gen ma_popfifteen = male_ if A== "Persons aged 15 years and over"
	gen ma_unemployed = male_ if A== "Unemployed, looking for work"
	gen ma_labor_force = male_ if A== "Total labour force"
	//gen ma_nolabor_force = male_ if A== "Not in the labour force"
	gen ma_dip = male_ if A == "Advanced Diploma and Diploma Level"
	gen ma_postgrad = male_ if A == "Postgraduate Degree Level"
	gen ma_grad = male_ if A == "Graduate Diploma and Graduate Certificate Level"
	gen ma_bach = male_ if A == "Bachelor Degree Level"

	gen fe_employed_a = female_ if A == "Employed, worked part-time(c)"
	gen fe_employed_b = female_ if A == "Employed, worked full-time(b)"
	gen fe_employed_c = female_ if A == "Employed, away from work(d)"
	
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
    unemployed labor_force ///
    postgrad grad bach dip ///
    ma_unemployed ma_labor_force ///
    ma_postgrad ma_grad ma_bach ma_dip ///
    fe_unemployed fe_labor_force ///
    fe_postgrad fe_grad fe_bach fe_dip ///
    , by(year LGA2021 lga_info)

    * 3) 마스터에 누적
    tempfile cur
    save `cur', replace

    use `master', clear
    append using `cur'
    save `master', replace
}

* 4) 최종 결과 저장
use `master', clear
save "cob29_2021census.dta", replace

**************************지역코드랑 머지하기********************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterControl/2021/t29"
 
import excel using "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2021") firstrow clear 

merge m:1 LGA2021 using cob29_2021census

drop _merge 

//collapse (sum) accom commu culture eduser finance govser health manu perser proper retail totindus trans wholesale profess, by(LGAFINAL21 year)

save cob29_2021census_fin.dta, replace 
