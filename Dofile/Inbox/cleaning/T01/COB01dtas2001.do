******************************
* labor force, unemployed, employed, 15+, 65+ 
******************************
clear 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2001"

forvalues i = 1(1)625 {
import excel using `i'.xls, sheet("T 01") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2001 = `i'
sort LGA2001
tempfile lga
save `lga'.dta, replace

import excel using `i'.xls, sheet("T 01") clear

keep in 10/30 
drop in 2
drop in 4/16 

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

save /Users/ihuila/Desktop/data/2025ABS/afterControl/2001/cob`i'.dta, replace
}

***************************** STEP2 ******************************
******************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterControl/2001" 
	
* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/625 {
    
    * 1) 원자료 한 행만 남기기
	use cob`i', clear
	
	rename (males91 females91 persons91 males96 females96 persons96 males01 females01 persons01) ///
	(male_1991 female_1991 persons_1991 male_1996 female_1996 persons_1996 male_2001  female_2001 persons_2001)
	
	reshape long male_ female_ persons_, i(A) j(year)
	
	gen popfifteen = persons_ if A== "Aged 15 years and over(a)"
	gen popold = persons_ if A== "Aged 65 years and over(a)"
	gen employed = persons_ if A== "Employed(d)"
	gen labor_force = persons_ if A== "In the labour force(d)"
	gen nolabor_force = persons_ if A== "Not in the labour force(d)"
	gen pop = persons_ if A== "Total persons(a)"
	gen unemployed = persons_ if A== "Unemployed(d)"
	
	gen ma_popfifteen = male_ if A== "Aged 15 years and over(a)"
	gen ma_popold = male_ if A== "Aged 65 years and over(a)"
	gen ma_employed = male_ if A== "Employed(d)"
	gen ma_labor_force = male_ if A== "In the labour force(d)"
	gen ma_nolabor_force = male_ if A== "Not in the labour force(d)"
	gen ma_pop = male_ if A== "Total persons(a)"
	gen ma_unemployed = male_ if A== "Unemployed(d)"
	
	gen fe_popfifteen = female_ if A== "Aged 15 years and over(a)"
	gen fe_popold = female_ if A== "Aged 65 years and over(a)"
	gen fe_employed = female_ if A== "Employed(d)"
	gen fe_labor_force = female_ if A== "In the labour force(d)"
	gen fe_nolabor_force = female_ if A== "Not in the labour force(d)"
	gen fe_pop = female_ if A== "Total persons(a)"
	gen fe_unemployed = female_ if A== "Unemployed(d)"

	collapse (max) ///
    pop popfifteen popold employed labor_force nolabor_force unemployed ///
    ma_pop ma_popfifteen ma_popold ma_employed ma_labor_force ma_nolabor_force ma_unemployed ///
    fe_pop fe_popfifteen fe_popold fe_employed fe_labor_force fe_nolabor_force fe_unemployed ///
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
save "cob01_2001census.dta", replace
************************LGA2001 + cob_2001census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2001") firstrow clear

cd "/Users/ihuila/Desktop/data/2025ABS/afterControl/2001" 

expand 3
sort LGA2001

gen year = .
bysort LGA2001: gen id = _n

replace year = 1991 if id == 1
replace year = 1996 if id == 2
replace year = 2001 if id == 3


merge m:1 LGA2001 year using cob01_2001census

drop _merge

gen popfifold = popfifteen - popold // 15-64세 
gen ma_popfifold = ma_popfifteen - ma_popold  // 15-64세 
gen fe_popfifold = fe_popfifteen - fe_popold //15-64세 

save cob01_2001census_fin.dta, replace 

