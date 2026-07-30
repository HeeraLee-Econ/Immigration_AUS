*************STEP1: 2001 census 끼리 합치기 
clear 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS/afterControl/2001" 

use cob01_2001census_fin.dta

merge 1:1 LGA2001 year using t11/cob11_2001census_fin

drop _merge

save "/Users/ihuila/Desktop/data/2025ABS/afterControl/control_2001.dta", replace 
 
*************STEP1: 2016 census끼리 합치기 
clear 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS/afterControl/2016" 

use t29/cob29_2016census_fin.dta

merge 1:1 LGA2016 year using t01/cob01_2016census_fin

drop _merge

save "/Users/ihuila/Desktop/data/2025ABS/afterControl/control_2016.dta", replace 
*************STEP1: 2021 census끼리 합치기 
clear 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS/afterControl/2021" 

use t29/cob29_2021census_fin.dta

merge 1:1 LGA2021 year using t01/cob01_2021census_fin

drop _merge 
save "/Users/ihuila/Desktop/data/2025ABS/afterControl/control_2021.dta", replace 
******************************************************************************* 
************* STEP2 : append 하기
clear 
cd "/Users/ihuila/Desktop/data/2025ABS/afterControl/"

use control_2001.dta 

append using control_2016
append using control_2021 

keep state lga_name1 LGAFINAL21 LGAFINAL21_H year id lga_info pop popfifteen popold popfifold labor_force employed employed_a employed_b employed_c unemployed dip bach grad postgrad ma_pop ma_popfifteen ma_popold ma_popfifold ma_labor_force ma_employed ma_employed_a ma_employed_b ma_employed_c ma_unemployed ma_dip ma_bach ma_grad ma_postgrad fe_pop fe_popfifteen fe_popold fe_popfifold fe_labor_force fe_employed fe_employed_a fe_employed_b fe_employed_c fe_unemployed fe_dip fe_bach fe_grad fe_postgrad 

collapse (sum) pop popfifteen popold popfifold labor_force employed employed_a employed_b employed_c unemployed dip bach grad postgrad ma_pop ma_popfifteen ma_popold ma_popfifold ma_labor_force ma_employed ma_employed_a ma_employed_b ma_employed_c ma_unemployed ma_dip ma_bach ma_grad ma_postgrad fe_pop fe_popfifteen fe_popold fe_popfifold fe_labor_force fe_employed fe_employed_a fe_employed_b fe_employed_c fe_unemployed fe_dip fe_bach fe_grad fe_postgrad , by(LGAFINAL21 year)

tab year 

// 지역 개수가 안맞음 

* 안맞는 지역 
drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 

tab year // 496개씩 

gen collegeov = bach + grad + postgrad 
gen fe_collegeov = fe_bach + fe_grad + fe_postgrad 
gen ma_collegeov = ma_bach + ma_grad + ma_postgrad 

br if year>=1991 & year<=2001 // employed 
br if year>=2006 & year<=2021 // employed_a, employed_b, employed_c 

egen employed_new = rowtotal(employed employed_a employed_b employed_c)
egen ma_employed_new = rowtotal(ma_employed ma_employed_a ma_employed_b ma_employed_c)
egen fe_employed_new = rowtotal(fe_employed fe_employed_a fe_employed_b fe_employed_c)

/*
egen employed_new = rowtotal(employed employed_a employed_b)
egen ma_employed_new = rowtotal(ma_employed ma_employed_a ma_employed_b)
egen fe_employed_new = rowtotal(fe_employed fe_employed_a fe_employed_b)
*/

drop employed ma_employed fe_employed 
ren (employed_new ma_employed_new fe_employed_new) (employed ma_employed fe_employed)
drop employed_a employed_b employed_c ma_employed_a ma_employed_b ma_employed_c fe_employed_a fe_employed_b fe_employed_c

sort LGAFINAL21 year 

save control_final.dta, replace 
******************************************************************************* 
************* STEP3 : metropolitan area 
**** STEP4: metropolitan area 
clear 

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_metrostatus1.xlsx", sheet("LGAFINAL_Metro") firstrow clear

gen metro2 = 1 if metro == 1 | outermetro == 1 
replace metro2 = 0 if metro2==. 

cd "/Users/ihuila/Desktop/data/2025ABS/afterControl"
save metropolitan.dta, replace 

clear 
import excel using "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2001") firstrow clear 

merge m:1 LGAFINAL using metropolitan.dta 

drop if _merge!=3 
drop _merge 

keep state LGAFINAL21 metro outermetro metro2 

sort LGAFINAL21 
duplicates drop LGAFINAL21 , force 

merge m:n LGAFINAL21 using control_final.dta 

drop _merge 


/*
gen dipov = dip + bach + grad + postgrad 
gen fe_dipov = fe_dip + fe_bach + fe_grad + fe_postgrad 
gen ma_dipov = ma_dip + ma_bach + ma_grad + ma_postgrad 
*/


save control_final.dta, replace 


