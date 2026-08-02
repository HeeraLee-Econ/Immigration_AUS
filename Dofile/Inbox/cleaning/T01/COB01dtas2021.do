// T01 - total population 
// 2016 census 에서 2006~2016

********************************************************************************
** Do file that converts Census i.xls to cob`i'.dta for 2021 Census
** by Jun Sung Kim on Nov 13, 2023
********************************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2021"
import excel using 1.xlsx, sheet("T01") clear

forvalues i = 1(1)547 {
import excel using `i'.xlsx, sheet("T01") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2021 = `i'
sort LGA2021
tempfile lga
save `lga'.dta, replace

import excel using `i'.xlsx, sheet("T01") clear

keep in 14/27
drop in 2/5 

keep A J K L 

destring J K L, replace 

ren J males21
ren K females21 
ren L persons21 

gen LGA2021 = `i'

sort LGA2021
merge m:1 LGA2021 using `lga'.dta
drop _merge

save /Users/ihuila/Desktop/data/2025ABS/afterControl/2021/t01/cob`i'.dta, replace 
}

***************************** STEP2 ******************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterControl/2021/t01"  

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/547 {
    
    * 1) 원자료 한 행만 남기기
	use cob`i', clear

	rename (males21 females21 persons21) ///
	(male_2021 female_2021 persons_2021)
	
	reshape long male_ female_ persons_, i(A) j(year)
	
	gen pop = persons_ if A== "Total persons(a)"
	gen ma_pop = male_ if A== "Total persons(a)"
	gen fe_pop = female_ if A== "Total persons(a)"
	
	gen pop1 = persons_ if A == "15-19 years" //15-19 
	gen pop2 = persons_ if A == "20-24 years" //20-24
	gen pop3 = persons_ if A == "25-34 years" //25-34
	gen pop4 = persons_ if A == "35-44 years" //35-44
	gen pop5 = persons_ if A == "45-54 years" //45-54
	gen pop6 = persons_ if A == "55-64 years" //55-64
	gen pop7 = persons_ if A == "65-74 years" // 65-74
	gen pop8 = persons_ if A == "75-84 years" // 75-84 
	gen pop9 = persons_ if A == "85 years and over" // 85 + 
	
	gen ma_pop1 = male_ if A == "15-19 years" //15-19 
	gen ma_pop2 = male_ if A == "20-24 years" //20-24
	gen ma_pop3 = male_ if A == "25-34 years" //25-34
	gen ma_pop4 = male_ if A == "35-44 years" //35-44
	gen ma_pop5 = male_ if A == "45-54 years" //45-54
	gen ma_pop6 = male_ if A == "55-64 years" //55-64 
	gen ma_pop7 = male_ if A == "65-74 years" //65-74
	gen ma_pop8 = male_ if A == "75-84 years" //75-84 
	gen ma_pop9 = male_ if A == "85 years and over" // 85+ 
	
	gen fe_pop1 = female_ if A == "15-19 years" //15-19 
	gen fe_pop2 = female_ if A == "20-24 years" //20-24
	gen fe_pop3 = female_ if A == "25-34 years" //25-34
	gen fe_pop4 = female_ if A == "35-44 years" //35-44
	gen fe_pop5 = female_ if A == "45-54 years" //45-54
	gen fe_pop6 = female_ if A == "55-64 years" //55-64 
	gen fe_pop7 = female_ if A == "65-74 years" //65-74
	gen fe_pop8 = female_ if A == "75-84 years" //75-84 
	gen fe_pop9 = female_ if A == "85 years and over" // 85+ 
	
	collapse (max) ///
    pop pop1-pop9 ma_pop fe_pop ma_pop1-ma_pop9 fe_pop1-fe_pop9 ///
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
save "cob01_2021census.dta", replace
**************************지역코드랑 머지하기********************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterControl/2021/t01"
 
import excel using "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2021") firstrow clear 

merge m:1 LGA2021 using cob01_2021census

drop _merge 

gen popfifold = pop1 + pop2 + pop3 + pop4 + pop5 + pop6
gen popfifteen = pop1 + pop2 + pop3 + pop4 + pop5 + pop6 + pop7 + pop8 + pop9 
gen popold = pop7 + pop8 + pop9 

gen ma_popfifold = ma_pop1 + ma_pop2 + ma_pop3 + ma_pop4 + ma_pop5 + ma_pop6 // 15-64세 
gen ma_popfifteen = ma_pop1 + ma_pop2 + ma_pop3 + ma_pop4 + ma_pop5 + ma_pop6 + ma_pop7 + ma_pop8 + ma_pop9 
gen ma_popold = ma_pop7 + ma_pop8 + ma_pop9 

gen fe_popfifold = fe_pop1 + fe_pop2 + fe_pop3 + fe_pop4 + fe_pop5 + fe_pop6 // 15-64세 
gen fe_popfifteen = fe_pop1 + fe_pop2 + fe_pop3 + fe_pop4 + fe_pop5 + fe_pop6 + fe_pop7 + fe_pop8 + fe_pop9 
gen fe_popold = fe_pop7 + fe_pop8 + fe_pop9 

//collapse (sum) accom commu culture eduser finance govser health manu perser proper retail totindus trans wholesale profess, by(LGAFINAL21 year)

save cob01_2021census_fin.dta, replace 
