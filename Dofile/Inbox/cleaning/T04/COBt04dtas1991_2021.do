*************************************STEP 1: 지역코드 + Y 데이터 합치기 
*****************************LGAFINAL21 + COB2021 
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS5" 

use 2001/cob_2001census_fin 

append using 2016/cob_2016census_fin
append using 2021/cob_2021census_fin

collapse (sum) mar_male* mar_female* no_male* no_female* to_male* to_female*, by(LGAFINAL21 year)

tab year // 지역개수 안맞음 

* 안맞는 지역 
drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 

tab year 
*************STEP4: label define 
label define agelab 1 "15-19 years" ///
                    2 "20-24 years" ///
                    3 "25-29 years" ///
                    4 "30-34 years" ///
                    5 "35-39 years" ///
                    6 "Total", replace
					
foreach stub in mar_male mar_female no_male no_female to_male to_female {
    forvalues j = 1/6 {
        local atext : label agelab `j'
        capture confirm variable `stub'`j'
        if !_rc {
            label variable `stub'`j' "`stub' (`atext')"
        }
    }
}

/*	
* 미혼 비율 
gen share_nomale = (no_male/to4_male)
gen share_nofemale = (no_female/to4_female) 
gen share_marmale = (mar_male / to4_male )
gen share_marfemale = (mar_female / to4_female) 
*/

save cob_final.dta, replace 
