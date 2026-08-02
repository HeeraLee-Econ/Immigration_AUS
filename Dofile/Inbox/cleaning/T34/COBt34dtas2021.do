// T34 (2001 census 기준 T15: industry)
// 2001 census 에서 1996, 2001 데이터 긁어오기 

********************************************************************************
** Do file that converts Census i.xls to cob`i'.dta for 2021 Census
** by Jun Sung Kim on Nov 13, 2023
********************************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2021"

forvalues i = 1(1)547 {
import excel using `i'.xlsx, sheet("T34") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2021 = `i'
sort LGA2021
tempfile lga
save `lga'.dta, replace

import excel using `i'.xlsx, sheet("T34") clear

keep in 11/33 
drop in 20/22 

keep A J K L 

replace J = "" if J==".."
replace K = "" if K==".."
replace L = "" if L==".."

destring A J K L, replace

drop if J ==. &  K ==. & L ==.

ren J male21 
ren K female21 
ren L persons21 

gen LGA2021= `i'

sort LGA2021
merge m:1 LGA2021 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterABS2/2021/cob`i'.dta, replace
}

***************************** STEP2 ******************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS2/2021" 

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/547 {
    
	    * 1) 원자료 한 행만 남기기
	use cob`i', clear
	
	rename (male21 female21 persons21) ///
	(male_2021 female_2021 persons_2021)

	reshape long male_ female_ persons_ , i(A) j(year)

	gen agri_male   = male_   if A == "Agriculture, Forestry and Fishing"
	gen agri_female = female_ if A == "Agriculture, Forestry and Fishing"
	gen agri_tot    = persons_ if A == "Agriculture, Forestry and Fishing"
	
	gen mini_male   = male_   if A == "Mining"
	gen mini_female = female_ if A == "Mining"
	gen mini_tot    = persons_ if A == "Mining"
	
	gen manu_male   = male_   if A == "Manufacturing"
	gen manu_female = female_ if A == "Manufacturing"
	gen manu_tot    = persons_ if A == "Manufacturing"
	
	gen elec_male   = male_   if A == "Electricity, Gas, Water and Waste Services"
	gen elec_female = female_ if A == "Electricity, Gas, Water and Waste Services"
	gen elec_tot    = persons_ if A == "Electricity, Gas, Water and Waste Services"
	
	gen cons_male   = male_   if A == "Construction"
	gen cons_female = female_ if A == "Construction"
	gen cons_tot    = persons_ if A == "Construction"
		
	gen wholesale_male   = male_   if A == "Wholesale Trade"
	gen wholesale_female = female_ if A == "Wholesale Trade"
	gen wholesale_tot    = persons_ if A == "Wholesale Trade"

	gen retail_male   = male_   if A == "Retail Trade"
	gen retail_female = female_ if A == "Retail Trade"
	gen retail_tot    = persons_ if A == "Retail Trade"
	
	gen accom_male   = male_   if A == "Accommodation and Food Services"
	gen accom_female = female_ if A == "Accommodation and Food Services"
	gen accom_tot    = persons_ if A == "Accommodation and Food Services"

	gen trans_male   = male_   if A == "Transport, Postal and Warehousing"
	gen trans_female = female_ if A == "Transport, Postal and Warehousing"
	gen trans_tot    = persons_ if A == "Transport, Postal and Warehousing"
	
	gen commu_male = male_ if A == "Information Media and Telecommunications"
	gen commu_female = female_  if A == "Information Media and Telecommunications"
	gen commu_tot = persons_   if A == "Information Media and Telecommunications"
	
	gen finance_male   = male_   if A == "Financial and Insurance Services"
	gen finance_female = female_ if A == "Financial and Insurance Services"
	gen finance_tot    = persons_ if A == "Financial and Insurance Services"
	
	gen proper_male   = male_   if A == "Rental, Hiring and Real Estate Services"
	gen proper_female = female_ if A == "Rental, Hiring and Real Estate Services"
	gen proper_tot    = persons_ if A == "Rental, Hiring and Real Estate Services"
	
	//새로생긴 분야 
	gen profe_male   = male_   if A == "Professional, Scientific and Technical Services"
	gen profe_female = female_ if A == "Professional, Scientific and Technical Services"
	gen profe_tot    = persons_ if A == "Professional, Scientific and Technical Services"
	
	// 새로생긴 분야 
	gen admin_male   = male_   if A == "Administrative and Support Services"
	gen admin_female = female_ if A == "Administrative and Support Services"
	gen admin_tot    = persons_ if A == "Administrative and Support Services"
	
	gen govser_male   = male_   if A == "Public Administration and Safety"
	gen govser_female = female_ if A == "Public Administration and Safety"
	gen govser_tot    = persons_ if A == "Public Administration and Safety"
	
	gen eduser_male   = male_   if A == "Education and Training"
	gen eduser_female = female_ if A == "Education and Training"
	gen eduser_tot    = persons_ if A == "Education and Training"

	gen health_male   = male_   if A == "Health Care and Social Assistance"
	gen health_female = female_ if A == "Health Care and Social Assistance"
	gen health_tot    = persons_ if A == "Health Care and Social Assistance"
	
	gen culture_male   = male_   if A == "Arts and Recreation Services"
	gen culture_female = female_ if A == "Arts and Recreation Services"
	gen culture_tot    = persons_ if A == "Arts and Recreation Services"

	gen perser_male   = male_   if A == "Other Services"
	gen perser_female = female_ if A == "Other Services"
	gen perser_tot    = persons_ if A == "Other Services"

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
profe_male profe_female profe_tot ///
admin_male admin_female admin_tot ///
govser_male govser_female govser_tot ///
eduser_male eduser_female eduser_tot ///
health_male health_female health_tot ///
culture_male culture_female culture_tot ///
perser_male perser_female perser_tot ///
totindus_male totindus_female totindus_tot ///
, by(LGA2021 year lga_info)


    append using `master'
    save `master', replace
	
}

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS2/2021" 
save "cob_2021census.dta", replace
*************************지역코드랑 머지하기********************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS2/2021"

import excel using "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2021") firstrow clear 

merge m:1 LGA2021 using "/Users/ihuila/Desktop/data/2025ABS/afterABS2/2021/cob_2021census.dta"

drop _merge 

save cob_2021census_fin.dta, replace 
