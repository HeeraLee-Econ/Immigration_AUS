**********************************************************************
* Created by Heera Lee
* Purpose: append T24(2006census), T33(2021census) and construct variables for analysis
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
**********************************************************************
use "$data/ABS_T24_2006census.dta", clear 
append using "$data/ABS_T33_2021census.dta"

drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 // 지방정부 없는 미편입지역, 혹은 원주민 소유 원격지, 해외령 

tab year // 496 * 6, 1996~2021

**********************************************************************
* 20-34/15-39 연령대 합산 (T24/T33은 T04와 같은 5세단위 브라켓: 1519/2024/2529/3034/3539/4044)
**********************************************************************
* 20-34
gen employed_m_2034   = employed_m_2024   + employed_m_2529   + employed_m_3034
gen employed_f_2034   = employed_f_2024   + employed_f_2529   + employed_f_3034
gen unemployed_m_2034 = unemployed_m_2024 + unemployed_m_2529 + unemployed_m_3034
gen unemployed_f_2034 = unemployed_f_2024 + unemployed_f_2529 + unemployed_f_3034
gen laborforce_m_2034 = laborforce_m_2024 + laborforce_m_2529 + laborforce_m_3034
gen laborforce_f_2034 = laborforce_f_2024 + laborforce_f_2529 + laborforce_f_3034
gen grandtotal_m_2034 = grandtotal_m_2024 + grandtotal_m_2529 + grandtotal_m_3034
gen grandtotal_f_2034 = grandtotal_f_2024 + grandtotal_f_2529 + grandtotal_f_3034

* 15-39
gen employed_m_1539   = employed_m_1519   + employed_m_2024   + employed_m_2529   + employed_m_3034   + employed_m_3539
gen employed_f_1539   = employed_f_1519   + employed_f_2024   + employed_f_2529   + employed_f_3034   + employed_f_3539
gen unemployed_m_1539 = unemployed_m_1519 + unemployed_m_2024 + unemployed_m_2529 + unemployed_m_3034 + unemployed_m_3539
gen unemployed_f_1539 = unemployed_f_1519 + unemployed_f_2024 + unemployed_f_2529 + unemployed_f_3034 + unemployed_f_3539
gen laborforce_m_1539 = laborforce_m_1519 + laborforce_m_2024 + laborforce_m_2529 + laborforce_m_3034 + laborforce_m_3539
gen laborforce_f_1539 = laborforce_f_1519 + laborforce_f_2024 + laborforce_f_2529 + laborforce_f_3034 + laborforce_f_3539
gen grandtotal_m_1539 = grandtotal_m_1519 + grandtotal_m_2024 + grandtotal_m_2529 + grandtotal_m_3034 + grandtotal_m_3539
gen grandtotal_f_1539 = grandtotal_f_1519 + grandtotal_f_2024 + grandtotal_f_2529 + grandtotal_f_3034 + grandtotal_f_3539

**********************************************************************
* employment share(고용률) = employed / grandtotal(생산가능인구) -> E/P ratio
* unemployment share(실업률) = unemployed / laborforce(경제활동인구) -> 표준 실업률 정의
* (분모를 다르게 쓰는 이유: 고용률은 노동시장 이탈 효과까지 잡으려고 생산가능인구 대비로,
*  실업률은 "구직중인 사람 대비 실업자"라는 표준 정의를 따르려고 경제활동인구 대비로 계산함)
**********************************************************************
* 전연령
gen empshare_ageall  = (employed_m_ageall + employed_f_ageall) / (grandtotal_m_ageall + grandtotal_f_ageall)
gen empmshare_ageall = employed_m_ageall / grandtotal_m_ageall
gen empfshare_ageall = employed_f_ageall / grandtotal_f_ageall

gen unempshare_ageall  = (unemployed_m_ageall + unemployed_f_ageall) / (laborforce_m_ageall + laborforce_f_ageall)
gen unempmshare_ageall = unemployed_m_ageall / laborforce_m_ageall
gen unempfshare_ageall = unemployed_f_ageall / laborforce_f_ageall

/*
* 20-34세
* empshare_2034/empmshare_2034는 초소형 지역에서 ABS 랜덤조정으로 1을 넘는 값이 나와서 생성 안 함
gen empshare_2034  = (employed_m_2034 + employed_f_2034) / (grandtotal_m_2034 + grandtotal_f_2034)
gen empmshare_2034 = employed_m_2034 / grandtotal_m_2034
gen empfshare_2034 = employed_f_2034 / grandtotal_f_2034
*/

gen unempshare_2034  = (unemployed_m_2034 + unemployed_f_2034) / (laborforce_m_2034 + laborforce_f_2034)
gen unempmshare_2034 = unemployed_m_2034 / laborforce_m_2034
gen unempfshare_2034 = unemployed_f_2034 / laborforce_f_2034

/*
* 15-39세
gen empshare_1539  = (employed_m_1539 + employed_f_1539) / (grandtotal_m_1539 + grandtotal_f_1539)
* empmshare_1539는 초소형 지역에서 ABS 랜덤조정으로 1을 넘는 값이 나와서 생성 안 함
* gen empmshare_1539 = employed_m_1539 / grandtotal_m_1539
gen empfshare_1539 = employed_f_1539 / grandtotal_f_1539
*/

gen unempshare_1539  = (unemployed_m_1539 + unemployed_f_1539) / (laborforce_m_1539 + laborforce_f_1539)
gen unempmshare_1539 = unemployed_m_1539 / laborforce_m_1539
gen unempfshare_1539 = unemployed_f_1539 / laborforce_f_1539

label var empshare_ageall    "Employment rate (E/P ratio, all ages, both sexes, denominator=working-age population)"
label var empmshare_ageall   "Employment rate (E/P ratio, all ages, male)"
label var empfshare_ageall   "Employment rate (E/P ratio, all ages, female)"
label var unempshare_ageall  "Unemployment rate (all ages, both sexes, denominator=labour force)"
label var unempmshare_ageall "Unemployment rate (all ages, male)"
label var unempfshare_ageall "Unemployment rate (all ages, female)"

label var unempshare_2034  "Unemployment rate (age 20-34, both sexes)"
label var unempmshare_2034 "Unemployment rate (age 20-34, male)"
label var unempfshare_2034 "Unemployment rate (age 20-34, female)"

label var unempshare_1539  "Unemployment rate (age 15-39, both sexes)"
label var unempmshare_1539 "Unemployment rate (age 15-39, male)"
label var unempfshare_1539 "Unemployment rate (age 15-39, female)"

* 나중에 T26/T35(occupation) 기반 skill/직업 구성비(share) 만들 때 분모로 쓸 총 취업자수
* (T26/T35는 "employed 15세+" 기준 데이터라 working-age population이 아니라 total employed로
*  나눠야 함 - Peri & Sparber 2009, Foged & Peri 2016 등 occupational upgrading 문헌 표준)
rename employed_m_ageall totemp_m
rename employed_f_ageall totemp_f
label var totemp_m "Total employed (all ages, male) - denominator for T26/T35 occupation share"
label var totemp_f "Total employed (all ages, female) - denominator for T26/T35 occupation share"

**********************************************************************
* 15+ 인구, labor force 인구 (나중에 skill별 displacement 분석의 분모로 쓸 raw count)
**********************************************************************
rename grandtotal_m_ageall pop15_m
rename grandtotal_f_ageall pop15_f
gen pop15_total = pop15_m + pop15_f

rename laborforce_m_ageall lf_m
rename laborforce_f_ageall lf_f
gen lf_total = lf_m + lf_f

label var pop15_total "Population aged 15+ (all ages, both sexes)"
label var pop15_m     "Population aged 15+ (all ages, male)"
label var pop15_f     "Population aged 15+ (all ages, female)"
label var lf_total    "Labour force (all ages, both sexes)"
label var lf_m        "Labour force (all ages, male)"
label var lf_f        "Labour force (all ages, female)"

keep LGAFINAL21 year totemp_m totemp_f pop15_total pop15_m pop15_f lf_total lf_m lf_f ///
    empshare_ageall empmshare_ageall empfshare_ageall ///
    unempshare_ageall unempmshare_ageall unempfshare_ageall ///
    unempshare_2034 unempmshare_2034 unempfshare_2034 ///
    unempshare_1539 unempmshare_1539 unempfshare_1539

* check: share가 1 넘는지 확인
local sharevars empshare_ageall empmshare_ageall empfshare_ageall ///
    unempshare_ageall unempmshare_ageall unempfshare_ageall 
	/*
    empshare_2034 empmshare_2034 empfshare_2034 ///
    unempshare_2034 unempmshare_2034 unempfshare_2034 ///
    empshare_1539 empmshare_1539 empfshare_1539 ///
    unempshare_1539 unempmshare_1539 unempfshare_1539
*/ // 연령대로 disaggregate 한 경우에는 1 넘는값이 있음 (아주 인구가 적은 지역의 경우)
foreach v of local sharevars {
    summarize `v', meanonly
    di as text "`v': min=" %6.4f r(min) "  max=" %6.4f r(max)

    count if `v' > 1 & !missing(`v') 
    if r(N) > 0 {
        di as error ">>> `v' has `r(N)' obs exceeding 1"
    }
}
save "$data/ABS_T2433_total.dta", replace
