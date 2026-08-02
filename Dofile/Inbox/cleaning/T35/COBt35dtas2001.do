// T35 (2001 census 기준 T16: occupation)
// 2001 census 에서 1996, 2001 데이터 긁어오기 

********************************************************************************
** Do file that converts Census i.xls to cob`i'.dta for 2021 Census
** by Jun Sung Kim on Nov 13, 2023
********************************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2001"

forvalues i = 1(1)625 {
import excel using `i'.XLS, sheet("T 16") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2001 = `i'
sort LGA2001
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 16") clear

keep in 10/22
drop in 10/12  // not stated, inadequately described 
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

destring B C D F G H J K L, replace

drop if B==. & C==. & D==. & F==. & G==. & H==. & J==. & K==. & L==. 

ren B male91
ren C female91 
ren D persons91 

ren F male96
ren G female96
ren H persons96 

ren J male01 
ren K female01
ren L persons01 

gen LGA2001 = `i'

sort LGA2001
merge m:1 LGA2001 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterABS4/2001/cob`i'.dta, replace
}

***************************** STEP2 ******************************
***************************** GROUP 1 - occupation*********************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2001" 

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/625 {
    
    * 1) 원자료 한 행만 남기기
	use cob`i', clear
	
	rename (male91 female91 persons91 male96 female96 persons96 male01 female01 persons01) ///
	(male_1991 female_1991 persons_1991 male_1996 female_1996 persons_1996 male_2001  female_2001 persons_2001)
		
	reshape long male_ female_ persons_, i(A) j(year)

	gen mana_male = male_ if A == "Managers and Administrators"
	gen mana_female = female_ if A ==  "Managers and Administrators"
	gen mana_tot = persons_ if A ==  "Managers and Administrators"

	gen prof_male = male_ if A == "Professionals"
	gen prof_female = female_ if A == "Professionals"
	gen prof_tot = persons_ if A == "Professionals"
	
	gen asso_male = male_ if A == "Associate Professionals"
	gen asso_female = female_ if A == "Associate Professionals"
	gen asso_tot = persons_ if A == "Associate Professionals"

	gen trade_male = male_ if A == "Tradespersons and Related Workers"
	gen trade_female = female_ if A == "Tradespersons and Related Workers"
	gen trade_tot = persons_ if A == "Tradespersons and Related Workers"

	gen adserv_male = male_ if A == "Advanced Clerical and Service Workers"
	gen adserv_female = female_ if A ==  "Advanced Clerical and Service Workers"
	gen adserv_tot = persons_ if A ==  "Advanced Clerical and Service Workers"

	gen sale_male = male_ if A == "Intermediate Clerical, Sales and Service Workers"
	gen sale_female = female_ if A == "Intermediate Clerical, Sales and Service Workers"
	gen sale_tot = persons_ if A == "Intermediate Clerical, Sales and Service Workers"
	
	gen drive_male = male_ if A == "Intermediate Production and Transport Workers"
	gen drive_female = female_ if A == "Intermediate Production and Transport Workers"
	gen drive_tot = persons_ if A == "Intermediate Production and Transport Workers"

	gen eleser_male = male_ if A == "Elementary Clerical, Sales and Service Workers"
	gen eleser_female = female_ if A ==  "Elementary Clerical, Sales and Service Workers"
	gen eleser_tot = persons_ if A ==  "Elementary Clerical, Sales and Service Workers"

	gen lab_male = male_ if A == "Labourers and Related Workers"
	gen lab_female = female_ if A == "Labourers and Related Workers"
	gen lab_tot = persons_ if A == "Labourers and Related Workers"
	
	
	gen totoccu_male = male_ if A == "Total"
	gen totoccu_female = female_ if A == "Total"
	gen totoccu_tot = persons_ if A == "Total"

	collapse (max) ///
    mana_male mana_female mana_tot ///
    prof_male prof_female prof_tot ///
    asso_male asso_female asso_tot ///
    trade_male trade_female trade_tot ///
    adserv_male adserv_female adserv_tot ///
    sale_male sale_female sale_tot ///
    drive_male drive_female drive_tot ///
    eleser_male eleser_female eleser_tot ///
    lab_male lab_female lab_tot ///
    totoccu_male totoccu_female totoccu_tot ///
    , by(year LGA2001 lga_info)

	
    * 3) 마스터에 누적
    tempfile cur
    save `cur', replace

    use `master', clear
    append using `cur'
    save `master', replace
}

* 4) 최종 결과 저장
use `master', clear
save "cob_2001census.dta", replace
************************LGA2001 + cob_2001census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2001") firstrow clear

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2001" 

expand 3
sort LGA2001

gen year = .
bysort LGA2001: gen id = _n

replace year = 1991 if id == 1
replace year = 1996 if id == 2
replace year = 2001 if id == 3


merge m:1 LGA2001 year using cob_2001census

drop _merge

save cob_2001census_fin.dta, replace 
