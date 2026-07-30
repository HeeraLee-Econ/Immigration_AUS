*************STEP1: cob_2001census + cob_2016census + cob_2021census 머지하기 
clear 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4/"

use 2001/cob_2001census_fin.dta 

append using 2016/cob_2016census_fin
append using 2021/cob_2021census_fin

collapse (sum) *_female *_male *_tot , by(LGAFINAL21 year)

tab year 

// 지역 개수가 안맞음 

* 안맞는 지역 
drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 

tab year // 496개씩 
*************STEP2: 필요한 변수 생성
* high skill jobs 
egen highsk_tot = rowtotal(mana_tot prof_tot asso_tot)
egen highsk_male = rowtotal(mana_male prof_male asso_male)
egen highsk_female = rowtotal(mana_female prof_female asso_female)

* middle skill jobs 
egen midsk_tot = rowtotal(trade_tot com_tot adserv_tot)
egen midsk_male = rowtotal(trade_male com_male adserv_male)
egen midsk_female = rowtotal(trade_female com_female adserv_female)

* low skill jobs 
egen lowsk_tot = rowtotal(sale_tot eleser_tot drive_tot lab_tot)
egen lowsk_male = rowtotal(sale_male eleser_male drive_male lab_male)
egen lowsk_female = rowtotal(sale_female eleser_female drive_female lab_female)

/*
gen highsk_share = highsk_tot / totoccu_tot 
gen midsk_share = midsk_tot / totoccu_tot 
gen lowsk_share = lowsk_tot / totoccu_tot 
*/

save cob_final.dta, replace 
