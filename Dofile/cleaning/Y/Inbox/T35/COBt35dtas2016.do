// T35 (2001 census 기준 T16: occupation)
// 2001 census 에서 1996, 2001 데이터 긁어오기 

********************************************************************************
** Do file that converts Census i.xls to cob`i'.dta for 2021 Census
** by Jun Sung Kim on Nov 13, 2023
********************************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2016"

forvalues i = 1(1)544 {
import excel using `i'.XLS, sheet("T 35") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 35") clear

keep in 11/21 
drop in 9/10 

keep A B C D F G H J K L 

drop if A==""

replace B = "" if B==".."
replace C = "" if C==".."
replace D = "" if D==".."
replace F = "" if F==".."
replace G = "" if G==".."
replace H = "" if H==".."
replace J = "" if J==".."
replace K = "" if K==".."
replace L = "" if L==".."

destring B C D F G H J K L  , replace

drop if B==. & C==. & D==. & F==. & G==. & H==. & J ==. & K==.& L==. 

ren B male06 
ren C femal06 
ren D persons06 

ren F male11 
ren G female11
ren H persons11 

ren J male16 
ren K female16
ren L persons16 

gen LGA2016 = `i'

sort LGA2016
merge m:1 LGA2016 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterABS4/2016/cob`i'.dta, replace
}

*********************************** STEP2 **********************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2016" 

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/544 {
    
    * 1) 원자료 한 행만 남기기
	use cob`i', clear

	rename (male06 femal06 persons06 male11 female11 persons11 male16 female16 persons16) ///
		   (male_2006 female_2006 persons_2006 male_2011 female_2011 persons_2011 male_2016 female_2016 persons_2016)

	reshape long male_ female_ persons_, i(A) j(year)

	gen mana_male = male_ if A == "Managers"
	gen mana_female = female_ if A == "Managers"
	gen mana_tot = persons_ if A == "Managers"

	gen prof_male = male_ if A == "Professionals"
	gen prof_female = female_ if A == "Professionals"
	gen prof_tot = persons_ if A == "Professionals"

	gen trade_male = male_ if A == "Technicians and Trades Workers"
	gen trade_female = female_ if A == "Technicians and Trades Workers"
	gen trade_tot = persons_ if A == "Technicians and Trades Workers"

	gen com_male = male_ if A == "Community and Personal Service Workers"
	gen com_female = female_ if A == "Community and Personal Service Workers"
	gen com_tot = persons_ if A == "Community and Personal Service Workers"
	
	gen adserv_male = male_ if A == "Clerical and Administrative Workers"
	gen adserv_female = female_ if A == "Clerical and Administrative Workers"
	gen adserv_tot = persons_ if A == "Clerical and Administrative Workers"

	gen sale_male = male_ if A == "Sales Workers"
	gen sale_female = female_ if A == "Sales Workers"
	gen sale_tot = persons_ if A == "Sales Workers"
	
	gen drive_male = male_ if A == "Machinery Operators and Drivers"
	gen drive_female = female_ if A == "Machinery Operators and Drivers"
	gen drive_tot = persons_ if A == "Machinery Operators and Drivers"

	gen lab_male = male_ if A == "Labourers"
	gen lab_female = female_ if A == "Labourers"
	gen lab_tot = persons_ if A == "Labourers"
	
	gen totoccu_male = male_ if A == "Total"
	gen totoccu_female = female_ if A == "Total"
	gen totoccu_tot = persons_ if A == "Total"
	
	collapse (max) ///
    mana_male mana_female mana_tot ///
    prof_male prof_female prof_tot ///
    trade_male trade_female trade_tot ///
	com_male com_female com_tot /// 
    adserv_male adserv_female adserv_tot ///
    sale_male sale_female sale_tot ///
    drive_male drive_female drive_tot ///
    lab_male lab_female lab_tot ///
   totoccu_male totoccu_female totoccu_tot ///
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
save "cob_2016census.dta", replace
************************LGA2016 + cob_2016census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2016") firstrow clear

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2016" 

expand 3
sort LGA2016

gen year = .
bysort LGA2016: gen id = _n

replace year = 2006 if id == 1
replace year = 2011 if id == 2
replace year = 2016 if id == 3

merge m:1 LGA2016 year using cob_2016census

drop _merge

save cob_2016census_fin.dta, replace 
