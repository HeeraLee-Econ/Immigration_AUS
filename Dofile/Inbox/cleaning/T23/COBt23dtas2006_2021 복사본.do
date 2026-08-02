*************************************STEP 1: 지역코드 + Y 데이터 합치기 
*****************************LGAFINAL21 + COB2021 
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS9" 

use 2016/cob_2016census_fin

append using 2021/cob_2021census_fin

sort LGAFINAL21 year 

collapse (sum) onech* twoch* thrch* forch* totalfam* , by(LGAFINAL21 year)

tab year // 지역개수 안맞음 

* 안맞는 지역 
drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 

tab year 
*************STEP4: label define 
label define inctyplab ///
    1  "Negative/Nil income" ///
    2  "$1-$149" ///
    3  "$150-$299" ///
    4  "$300-$399" ///
    5  "$400-$499" ///
    6  "$500-$649" ///
    7  "$650-$799" ///
    8  "$800-$999" ///
    9  "$1,000-$1,499" ///
    10 "$1,500-$1,999" ///
    11 "$2,000-$2,499" ///
    12 "$2,500-$2,999" ///
    13 "$3,000-$3,999" ///
    14 "$4,000 or more" ///
    15 "Total", replace

foreach stub in onech twoch thrch forch totalfam {
    forvalues j = 1/15 {
        local atext : label inctyplab `j'
        capture confirm variable `stub'`j'
        if !_rc {
            label variable `stub'`j' "`stub' (`atext')"
        }
    }
}

foreach stub in onech twoch thrch forch totalfam {
    forvalues j = 1/15 {
        capture confirm variable `stub'`j'
        if !_rc {
            rename `stub'`j' onep_`stub'`j'
        }
    }
}

save cob_final.dta, replace 
