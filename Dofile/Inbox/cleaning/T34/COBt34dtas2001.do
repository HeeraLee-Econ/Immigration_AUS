// T34 (2001 census 기준 T15: industry)
// 2001 census 에서 1996, 2001 데이터 긁어오기 

********************************************************************************
** Do file that converts Census i.xls to cob`i'.dta for 2021 Census
** by Jun Sung Kim on Nov 13, 2023
********************************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2001"
import excel using 1.XLS, sheet("T 15") clear

forvalues i = 1(1)625 {
import excel using `i'.XLS, sheet("T 15") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2001 = `i'
sort LGA2001
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 15") clear

keep in 10/30
drop in 20 
drop in 18/19

keep A B C D F G H J K L

replace D = "" if D==".."
replace H = "" if H==".."
replace L = "" if L==".."

destring A B C D F G H J K L,  replace

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

save /Users/ihuila/Desktop/data/2025ABS/afterABS2/2001/cob`i'.dta, replace
}

***************************** STEP2 ******************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS2/2001" 

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/625 {
    
	    * 1) 원자료 한 행만 남기기
	use cob`i', clear
	
	rename (male91 female91 persons91 male96 female96 persons96 male01 female01 persons01) ///
	(male_1991 female_1991 persons_1991 male_1996 female_1996 persons_1996 male_2001  female_2001 persons_2001)
	
	reshape long male_ female_ persons_, i(A) j(year)

	gen agri_male   = male_   if A == "Agriculture, Forestry and Fishing"
	gen agri_female = female_ if A == "Agriculture, Forestry and Fishing"
	gen agri_tot    = persons_ if A == "Agriculture, Forestry and Fishing"
	
	gen mini_male   = male_   if A == "Mining"
	gen mini_female = female_ if A == "Mining"
	gen mini_tot    = persons_ if A == "Mining"
	
	gen manu_male   = male_   if A == "Manufacturing"
	gen manu_female = female_ if A == "Manufacturing"
	gen manu_tot    = persons_ if A == "Manufacturing"
	
	gen elec_male   = male_   if A == "Electricity, Gas and Water Supply"
	gen elec_female = female_ if A == "Electricity, Gas and Water Supply"
	gen elec_tot    = persons_ if A == "Electricity, Gas and Water Supply"
	
	gen cons_male   = male_   if A == "Construction"
	gen cons_female = female_ if A == "Construction"
	gen cons_tot    = persons_ if A == "Construction"
		
	gen wholesale_male   = male_   if A == "Wholesale Trade"
	gen wholesale_female = female_ if A == "Wholesale Trade"
	gen wholesale_tot    = persons_ if A == "Wholesale Trade"

	gen retail_male   = male_   if A == "Retail Trade"
	gen retail_female = female_ if A == "Retail Trade"
	gen retail_tot    = persons_ if A == "Retail Trade"
	
	gen accom_male   = male_   if A == "Accommodation, Cafes and Restaurants"
	gen accom_female = female_ if A == "Accommodation, Cafes and Restaurants"
	gen accom_tot    = persons_ if A == "Accommodation, Cafes and Restaurants"

	gen trans_male   = male_   if A == "Transport and Storage"
	gen trans_female = female_ if A == "Transport and Storage"
	gen trans_tot    = persons_ if A == "Transport and Storage"
	
	gen commu_male   = male_   if A == "Communication Services"
	gen commu_female = female_ if A == "Communication Services"
	gen commu_tot    = persons_ if A == "Communication Services"

	gen finance_male   = male_   if A == "Finance and Insurance"
	gen finance_female = female_ if A == "Finance and Insurance"
	gen finance_tot    = persons_ if A == "Finance and Insurance"
	
	gen proper_male   = male_   if A == "Property and Business Services"
	gen proper_female = female_ if A == "Property and Business Services"
	gen proper_tot    = persons_ if A == "Property and Business Services"

	gen govser_male   = male_   if A == "Government Administration and Defence"
	gen govser_female = female_ if A == "Government Administration and Defence"
	gen govser_tot    = persons_ if A == "Government Administration and Defence"

	gen eduser_male   = male_   if A == "Education"
	gen eduser_female = female_ if A == "Education"
	gen eduser_tot    = persons_ if A == "Education"

	gen health_male   = male_   if A == "Health and Community Services"
	gen health_female = female_ if A == "Health and Community Services"
	gen health_tot    = persons_ if A == "Health and Community Services"

	gen culture_male   = male_   if A == "Cultural and Recreational Services"
	gen culture_female = female_ if A == "Cultural and Recreational Services"
	gen culture_tot    = persons_ if A == "Cultural and Recreational Services"

	gen perser_male   = male_   if A == "Personal and Other Services"
	gen perser_female = female_ if A == "Personal and Other Services"
	gen perser_tot    = persons_ if A == "Personal and Other Services"

	gen totindus_male   = male_   if A == "Total"
	gen totindus_female = female_ if A == "Total"
	gen totindus_tot    = persons_ if A == "Total"
	
	collapse (max) ///
	agri_male agri_female agri_tot ///
	mini_male mini_female mini_tot ///
	manu_male manu_female manu_tot ///
	elec_male elec_female elec_tot ///
	cons_male cons_female cons_tot ///
	wholesale_male wholesale_female wholesale_tot ///
	retail_male retail_female retail_tot ///
	accom_male accom_female accom_tot ///
	trans_male trans_female trans_tot ///
	commu_male commu_female commu_tot ///
	finance_male finance_female finance_tot ///
	proper_male proper_female proper_tot ///
	govser_male govser_female govser_tot ///
	eduser_male eduser_female eduser_tot ///
	health_male health_female health_tot ///
	culture_male culture_female culture_tot ///
	perser_male perser_female perser_tot ///
	totindus_male totindus_female totindus_tot ///
	, by(LGA2001 year lga_info) ///

    append using `master'
    save `master', replace
	
}

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS2/2001" 
save "cob_2001census.dta", replace
************************LGA2001 + cob_2001census
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2001") firstrow clear


cd "/Users/ihuila/Desktop/data/2025ABS/afterABS2/2001" 

expand 3
sort LGA2001

gen year = .
bysort LGA2001: gen id = _n

replace year = 1991 if id == 1
replace year = 1996 if id == 2
replace year = 2001 if id == 3

merge m:1 LGA2001 year using cob_2001census

drop _merge

//collapse (sum)  accom commu culture eduser finance govser health manu perser proper retail totindus trans wholesale ,by(LGAFINAL21 year)

save cob_2001census_fin.dta, replace 
