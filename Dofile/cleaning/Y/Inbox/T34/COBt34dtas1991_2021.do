*************STEP1: cob_2001census + cob_2016census + cob_2021census 머지하기 
clear 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS/afterABS2/"

use 2001/cob_2001census_fin.dta 

append using 2016/cob_2016census_fin
append using 2021/cob_2021census_fin

collapse (sum) *_female *_male *_tot, by(LGAFINAL21 year)

tab year 

* 안맞는 지역 
drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 

tab year 
*************STEP2: 필요한 변수 생성
* 제조업 종사자 비율 
//gen manu_share = manu_tot/totindus_tot 

* 서비스업 종사자 총 숫자 
egen service_tot = rowtotal(elec_tot cons_tot wholesale_tot retail_tot accom_tot trans_tot commu_tot finance_tot proper_tot profe_tot admin_tot govser_tot eduser_tot health_tot culture_tot perser_tot) //총 16개의 범주 합쳐서  

egen service_female = rowtotal(elec_female cons_female wholesale_female retail_female accom_female trans_female commu_female finance_female proper_female profe_female admin_female govser_female eduser_female health_female culture_female perser_female)

egen service_male = rowtotal(elec_male cons_male wholesale_male retail_male accom_male trans_male commu_male finance_male proper_male profe_male admin_male govser_male eduser_male health_male culture_male perser_male)

* 서비스업 세부 
egen consum_serv = rowtotal(retail_tot accom_tot culture_tot perser_tot)
egen consum_serv_fe = rowtotal(retail_female accom_female culture_female perser_female)
egen consum_serv_ma = rowtotal(retail_male accom_male culture_male perser_male)

egen produc_serv = rowtotal(commu_tot finance_tot proper_tot profe_tot admin_tot)
egen produc_serv_fe = rowtotal(commu_female finance_female proper_female profe_female admin_female)
egen produc_serv_ma = rowtotal(commu_male finance_male proper_male profe_male admin_male)

egen public_serv = rowtotal(govser_tot eduser_tot health_tot)
egen public_serv_fe = rowtotal(govser_female eduser_female health_female)
egen public_serv_ma = rowtotal(govser_male eduser_male health_male)

label variable consum_serv "consumer service(redefined)"
label variable produc_serv "producer service (redefined)"
label variable public_serv "public service (redefined)"

//gen serv_share = service_tot / totindus_tot 

save cob_final.dta, replace 
