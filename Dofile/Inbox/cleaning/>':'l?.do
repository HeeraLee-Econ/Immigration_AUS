*************************************STEP 1: 지역코드 + Y 데이터 합치기 
*****************************LGAFINAL21 + COB2021_ 
clear all
set more off

* 경로 매크로
local root "/Users/ihuila/Desktop/data/2025ABS"
local out  "`root'/afterABS/2021"

* 1) 매핑(교차표) 한번만 읽어서 tempfile로 저장
import excel "`root'/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2021") firstrow clear
tempfile xwalk
save `xwalk'

* 2) 처리할 연도 목록
local years 2021 2016 2011

foreach y of local years {
    * 원자료 불러오기
    use "`out'/cob2021_`y'.dta", clear

    * 매핑 merge (기존 _merge 있으면 제거)
    capture drop _merge
    merge m:1 LGA2021 using `xwalk', keepusing(LGAFINAL21) nogenerate

    * 혹시 year 변수가 없다면 생성
    capture confirm variable year
    if _rc gen year = `y'

    * 한 연도에 중복 LGA 존재 → 합산
    collapse (sum) ///
        fam_female_g6 fam_same_g6 fam_male_g6 ///
        fam_female_g5 fam_same_g5 fam_male_g5 ///
        fam_female_g4 fam_same_g4 fam_male_g4 ///
        fam_female_g3 fam_same_g3 fam_male_g3 ///
        fam_female_g2 fam_same_g2 fam_male_g2 ///
        fam_female_g1 fam_same_g1 fam_male_g1 ///
        fam_t, ///
        by(LGAFINAL21 year)

    * 저장 (같은 파일명으로 덮어쓰기)
    save "`out'/cob2021_`y'.dta", replace
}
************************LGAFINAL21 + COB2016_2006 
clear 
set more off

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2016") firstrow 

merge m:1 LGA2016 using "/Users/ihuila/Desktop/data/2025ABS/afterABS/2016/cob2016_2006.dta"

br 
drop _merge

tab LGAFINAL21 // 한 연도에 중복지역 있음 

* collapse 실행
collapse (sum) fam_female_g6 fam_same_g6 fam_male_g6 ///
               fam_female_g5 fam_same_g5 fam_male_g5 ///
               fam_female_g4 fam_same_g4 fam_male_g4 ///
               fam_female_g3 fam_same_g3 fam_male_g3 ///
               fam_female_g2 fam_same_g2 fam_male_g2 ///
               fam_female_g1 fam_same_g1 fam_male_g1 ///
			   fam_t, ///
         by(LGAFINAL21 year)

tab LGAFINAL21

save "/Users/ihuila/Desktop/data/2025ABS/afterABS/2016/cob2016_2006.dta", replace
***************************************************************************
****************************STEP 2 Y데이터: LONG-TYPE 만들기 
clear 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS/afterABS"

use "2021/cob2021_2021.dta"

append using "2021/cob2021_2016.dta"
append using "2021/cob2021_2011.dta"
append using "2016/cob2016_2006"

tab year 

save "/Users/ihuila/Desktop/data/2025ABS/afterABS/cob_long.dta", replace 
***************************************************************************
****************************STEP 3 X 데이터: Y 데이터 머지 -> 여기부터 코드 수정해야 함 
use "/Users/ihuila/Desktop/data/2025ABS/afterABS/cob_long.dta", clear 

merge 1:1 LGAFINAL21 year using "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_0907.dta"

br if _merge==1 
br if _merge==2 // 1991-2001년 데이터 

keep if _merge==3 // 2006년부터 ~ 
drop _merge

tab year 

merge m:1 LGAFINAL21 year using  "/Users/ihuila/Desktop/data/2025ABS/afterIV/IVasian_0930.dta"
br if _merge==2 // 1991-2001년 데이터 
keep if _merge==3 

drop _merge

merge m:1 LGAFINAL21 year using "/Users/ihuila/Desktop/data/2025ABS/aftercontrol.dta"

keep if _merge==3 
drop _merge // 통제변수때문에 2001부터 시작 

xtset LGAFINAL21 year

*************STEP4: 필요한 변수 생성
* 각 그룹별 가구수 총합 
gen fam_g1 = fam_female_g1 + fam_male_g1 + fam_same_g1 
gen fam_g2 = fam_female_g2 + fam_male_g2 + fam_same_g2 
gen fam_g3 = fam_female_g3 + fam_male_g3 + fam_same_g3 
gen fam_g4 = fam_female_g4 + fam_male_g4 + fam_same_g4 
gen fam_g5 = fam_female_g5 + fam_male_g5 + fam_same_g5 
gen fam_g6 = fam_female_g6 + fam_male_g6 + fam_same_g6 

order fam_g6 fam_t

* 임시로 변수 만들어보기 
gen share_female = fam_female_g6 / fam_t * 100
gen share_same = fam_same_g6 / fam_t * 100

save "/Users/ihuila/Desktop/data/2025ABS/afterABS/cob_final.dta", replace 
