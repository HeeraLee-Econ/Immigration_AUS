// T32 (2001 census 기준 T12: F)
// 2001 census 에서 1996, 2001 데이터 긁어오기 

********************************************************************************
** Do file that converts Census i.xls to cob`i'.dta for 2021 Census
** by Jun Sung Kim on Nov 13, 2023
********************************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2001"

forvalues i = 1(1)625 {
import excel using `i'.XLS, sheet("T 12") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2001 = `i'
sort LGA2001
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 12") clear

keep A B C F G J K 

keep in 10/26 
drop in 13/16 

replace B = "" if B=="n.a."
replace C = "" if C=="n.a."
replace F = "" if F=="n.a."
replace G = "" if G=="n.a."
replace J = "" if J=="n.a."
replace K = "" if K=="n.a."

destring B C F G J K, replace

drop if B==. & C==. & F==. & G==. & J==. & K==. 

ren B male91
ren C female91 

ren F male96
ren G female96

ren J male01 
ren K female01

gen LGA2001 = `i'

sort LGA2001
merge m:1 LGA2001 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterABS7/2001/cob`i'.dta, replace
}

***************************** STEP2 ******************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2001" 

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/625 {
    
    * 1) 원자료 한 행만 남기기
	use cob`i', clear

	rename (male91 female91 male96 female96 male01 female01) ///
	(male_1991 female_1991 male_1996 female_1996 male_2001 female_2001)
		
	reshape long male_ female_ persons_, i(A) j(year)

	gen natu_male = male_ if A == "Natural and Physical Sciences"
	gen natu_female = female_ if A == "Natural and Physical Sciences"
	
	gen info_male = male_ if A == "Information Technology"
	gen info_female = female_ if A ==  "Information Technology"
	
	gen engine_male = male_ if A == "Engineering and Related Technologies"
	gen engine_female = female_ if A == "Engineering and Related Technologies"

	gen archi_male = male_ if A == "Architecture and Building"
	gen archi_female = female_ if A ==  "Architecture and Building"

	gen agric_male = male_ if A == "Agriculture, Environmental & Related Studies"
	gen agric_female = female_ if A == "Agriculture, Environmental & Related Studies"
	
	gen health_male = male_ if A == "Health"
	gen health_female = female_ if A == "Health"
	
	gen edu_male = male_ if A == "Education"
	gen edu_female = female_ if A == "Education"

	gen manage_male = male_ if A == "Management and Commerce"
	gen manage_female = female_ if A == "Management and Commerce"
	
	gen soci_male = male_ if A == "Society and Culture"
	gen soci_female = female_ if A == "Society and Culture"
	
	gen arts_male = male_ if A == "Creative Arts"
	gen arts_female = female_ if A == "Creative Arts"
	
	gen hos_male = male_ if A == "Food, Hospitality and Personal Services"
	gen hos_female = female_ if A ==  "Food, Hospitality and Personal Services"

	gen mixed_male = male_ if A == "Mixed Field Programmes"
	gen mixed_female = female_ if A == "Mixed Field Programmes"

	gen tot_male = male_ if A == "Total"
	gen tot_female = female_ if A == "Total"

	collapse (max) ///
    engine_male engine_female ///
    info_male info_female ///
    natu_male natu_female ///
    archi_male archi_female ///
    agric_male agric_female ///
    health_male health_female ///
    edu_male edu_female ///
    manage_male manage_female ///
    soci_male soci_female ///
    arts_male arts_female ///
    hos_male hos_female ///
    mixed_male mixed_female ///
    tot_male tot_female ///
    , by(LGA2001 year lga_info)

	append using `master'
    save `master', replace
}
cd "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2001" 
save "cob_2001census.dta", replace
************************LGA2001 + cob_2001census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2001") firstrow clear

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS7/2001" 

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
