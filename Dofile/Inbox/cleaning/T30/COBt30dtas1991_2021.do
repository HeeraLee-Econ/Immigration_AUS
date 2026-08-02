*************************************STEP 1: 지역코드 + Y 데이터 합치기 
*****************************LGAFINAL21 + COB2021 
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2021" 

import excel using "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2021") firstrow clear 

merge m:1 LGA2021 using cob2021_2021.dta

drop _merge 

 collapse (sum) ///
        boss_male boss_female boss_persons tomale_ tofemale_ topersons_, ///
        by(LGAFINAL21 year)
		
save cob2021_2021.dta, replace 
************************LGAFINAL16 + COB2016_2016, COB2016_2011, COB2016_2006 
clear 
set more off

* 경로 매크로
local root "/Users/ihuila/Desktop/data/2025ABS"
local out  "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2016" 

* 1) 매핑(교차표) 한번만 읽어서 tempfile로 저장
import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2016") firstrow clear
tempfile xwalk
save `xwalk'

* 2) 처리할 연도 목록
local years 2006 2011 2016 

foreach y of local years {
    * 원자료 불러오기
    use "`out'/cob2016_`y'.dta", clear

    * 매핑 merge (기존 _merge 있으면 제거)
    capture drop _merge
    merge m:1 LGA2016 using `xwalk', keepusing(LGAFINAL21) nogenerate

    * 혹시 year 변수가 없다면 생성
    capture confirm variable year
    if _rc gen year = `y'

    * 한 연도에 중복 LGA 존재 → 합산
	collapse (sum) ///
        boss_male boss_female boss_persons tomale_ tofemale_ topersons_, ///
        by(LGAFINAL21 year)

    * 저장 (같은 파일명으로 덮어쓰기)
    save "`out'/cob2016_`y'.dta", replace
}
***************************************************************************
************************LGAFINAL01 + COB2001_2001, COB2001_1996 
clear 
set more off

* 경로 매크로
local root "/Users/ihuila/Desktop/data/2025ABS"
local out  "/Users/ihuila/Desktop/data/2025ABS/afterABS4/2001"

* 1) 매핑(교차표) 한번만 읽어서 tempfile로 저장
import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2001") firstrow clear
tempfile xwalk
save `xwalk'

* 2) 처리할 연도 목록
local years 1996 2001 

foreach y of local years {
    * 원자료 불러오기
    use "`out'/cob2001_`y'.dta", clear

    * 매핑 merge (기존 _merge 있으면 제거)
    capture drop _merge
    merge m:1 LGA2001 using `xwalk', keepusing(LGAFINAL21) nogenerate

    * 혹시 year 변수가 없다면 생성
    capture confirm variable year
    if _rc gen year = `y'

    * 한 연도에 중복 LGA 존재 → 합산
	collapse (sum) ///
        boss_male boss_female boss_persons tomale_ tofemale_ topersons_, ///
        by(LGAFINAL21 year)

    * 저장 (같은 파일명으로 덮어쓰기)
    save "`out'/cob2001_`y'.dta", replace
}
*****************************************************************************
****************************STEP 2 Y데이터: LONG-TYPE 만들기 
clear 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS/afterABS4"

use "2021/cob2021_2021.dta"

append using "2016/cob2016_2016.dta"
append using "2016/cob2016_2011.dta"
append using "2016/cob2016_2006.dta"

append using "2001/cob2001_2001.dta"
append using "2001/cob2001_1996.dta"

tab year 

save "/Users/ihuila/Desktop/data/2025ABS/afterABS4/cob_long.dta", replace 
***************************************************************************
****************************STEP 3 X 데이터: Y 데이터 머지 -> 여기부터 코드 수정해야 함 
use "/Users/ihuila/Desktop/data/2025ABS/afterABS4/cob_long.dta", clear 

merge 1:1 LGAFINAL21 year using "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_0907.dta"

keep if _merge==3 // 1996년부터 ~ 
drop _merge

tab year 

merge m:1 LGAFINAL21 year using "/Users/ihuila/Desktop/data/2025ABS/aftercontrol.dta"

keep if _merge==3 
drop _merge // 통제변수때문에 2001부터 시작 

xtset LGAFINAL21 year
*************STEP4: 필요한 변수 생성
* manager 비율 
gen pboss_male = (boss_male/tomale_) 
gen pboss_female = (boss_female/tofemale_) 
gen pboss_persons = (boss_persons/topersons_) 

gen pboss_t = boss_male + boss_female + boss_persons // 제조업종사자 총 숫자 
gen to = tomale_ + tofemale_ + topersons_ // 그냥 토탈인구 

gen re_fe=boss_female/boss_male

gen p_t = (pboss_t/to) 

save "/Users/ihuila/Desktop/data/2025ABS/afterABS4/cob_final.dta", replace 
