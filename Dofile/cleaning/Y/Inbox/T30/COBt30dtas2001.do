*** Double income with no children family - 1991, 1996 from 2001 census 
********************************************************************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/rawdata/2001"

forvalues i = 1(1)625 {
import excel using `i'.XLS, sheet("T 17") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2001 = `i'
sort LGA2001
tempfile lga
save `lga'.dta, replace

import excel using `i'.XLS, sheet("T 17") clear

keep in 7/20 

keep A B D F 

replace B = "" if B==".."
replace D = "" if D==".."
replace F = "" if F==".."

drop in 1/5 
drop in 2/3 
drop in 3/6 

destring B D F,  replace

drop if B==. & D==. & F==. 

ren B house91 
ren D house96 
ren F house01  

gen LGA2001 = `i'

sort LGA2001
merge m:1 LGA2001 using `lga'.dta
drop _merge

compress

save /Users/ihuila/Desktop/data/2025ABS/afterABS6/2001/cob`i'.dta, replace
}

**********************************************************************
***************** STEP 2 -  census **********************************
***************************** STEP2 ******************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS6/2001" 

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











***************************** STEP2 ******************************
***************************** GROUP 1 - occupation*********************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2016" 

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/544 {
    
    * 1) 원자료 한 행만 남기기
	use cob`i', clear
	
	drop in 3 

	rename (male06 femal06 persons06 male11 female11 persons11 male16 female16 persons16) ///
		   (male_2006 female_2006 persons_2006 male_2011 female_2011 persons_2011 male_2016 female_2016 persons_2016)

	reshape long male_ female_ persons_, i(A) j(year)

	gen boss_male = .
	gen boss_female = .
	gen boss_persons = .

	* 2. egen으로 year 그룹별 합계 계산
	bysort year: egen boss_male_temp = total(male_)
	bysort year: egen boss_female_temp= total(female_)
	bysort year: egen boss_persons_temp = total(persons_)

	* 3. 해당 값을 각 행에 저장
	replace boss_male  = boss_male_temp
	replace boss_female = boss_female_temp
	replace boss_persons = boss_persons_temp

	* 4. 정리 (임시변수 제거)
	drop boss_male_temp boss_female_temp boss_persons_temp
	drop A male_ female_ persons_

	collapse (mean) boss*, by(year LGA2016 lga_info)

    * 3) 마스터에 누적
    tempfile cur
    save `cur', replace

    use `master', clear
    append using `cur'
    save `master', replace
}

* 4) 최종 결과 저장
use `master', clear
save "cob_g1.dta", replace
***************************** GROUP 2 - TOTAL ******************************
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2016" 

* 0) 전체 LGA 누적 저장용 마스터 파일(비어있는 셸)
tempfile master
save `master', emptyok replace

forvalues i = 1/544 {
    
    * 1) 원자료 한 행만 남기기
	use cob`i', clear
	
	keep in 3 

	rename (male06 femal06 persons06 male11 female11 persons11 male16 female16 persons16) ///
		   (tomale_2006 tofemale_2006 topersons_2006 tomale_2011 tofemale_2011 topersons_2011 tomale_2016 tofemale_2016 topersons_2016)

	reshape long tomale_ tofemale_ topersons_, i(A) j(year)
	drop A 
    * 3) 마스터에 누적
    tempfile cur
    save `cur', replace

    use `master', clear
    append using `cur'
    save `master', replace
}

* 4) 최종 결과 저장
use `master', clear
save "cob_g2.dta", replace
********************************************************************
*******************STEP3 ***************************** 
********* 각 그룹별 데이터 모두 merge ******
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2016" 

use cob_g1.dta, replace 

merge 1:1 year LGA2016 using cob_g2.dta 

drop _merge 

save cob2016_merge.dta, replace 

use cob_g1.dta, replace 

merge 1:1 year LGA2016 using cob_g2.dta 

drop _merge 
tab year 

save cob2016_merge.dta, replace 
*********************************
use cob2016_merge.dta, clear 
keep if year==2006  
save cob2016_2006.dta, replace
 
use cob2016_merge.dta, clear 
keep if year==2011  
save cob2016_2011.dta, replace 

use cob2016_merge.dta, clear 
keep if year==2016 
save cob2016_2016.dta, replace 
