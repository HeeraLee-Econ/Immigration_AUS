clear all
set more off
cd "/Users/ihuila/Desktop/data/2025ABS/afterABS7/" 

use 2016/cob_2016census_fin 
** use 2001/cob_2001census_fin 

append using 2021/cob_2021census_fin 

sort LGAFINAL21 year 

collapse (sum) mal* fem* , by(LGAFINAL21 year)

tab year 

drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001  // 지역 맞추기 (496)

tab year 

save cob_final.dta, replace 
