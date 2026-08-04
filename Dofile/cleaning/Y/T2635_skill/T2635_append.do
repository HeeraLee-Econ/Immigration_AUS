**********************************************************************
* Created by Heera Lee
* Purpose: append T26(2006census), T35(2021census) and construct variables for analysis
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
**********************************************************************
use "$data/ABS_T26_2006census.dta", clear 
append using "$data/ABS_T35_2021census.dta"

drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 // 지방정부 없는 미편입지역, 혹은 원주민 소유 원격지, 해외령 

tab year // 496 * 6, 1996~2021

**********************************************************************
* skill 분류(ANZSCO skill level 기준, HILDA 개인단위 skill 분류와 통일): 고숙련/중숙련/저숙련
*   highsk = Managers + Professionals
*   midsk  = Technicians and Trades Workers + Community and Personal Service Workers
*            + Clerical and Administrative Workers
*   lowsk  = Sales Workers + Machinery Operators and Drivers + Labourers
**********************************************************************
gen highsk_m = managers_m + professionals_m
gen highsk_f = managers_f + professionals_f

gen midsk_m = techtrades_m + comservice_m + clerical_m
gen midsk_f = techtrades_f + comservice_f + clerical_f

gen lowsk_m = sales_m + machinery_m + labourers_m
gen lowsk_f = sales_f + machinery_f + labourers_f

**********************************************************************
* share = skill그룹 취업자 / total_m,total_f(전체 취업자) -> compositional(재배치) effect
* (denominator가 total employed라서 "실직 여부"가 아니라 "취업자 내 직업구성 변화"를 잡음)
**********************************************************************
gen highskshare  = (highsk_m + highsk_f) / (total_m + total_f)
gen highskmshare = highsk_m / total_m
gen highskfshare = highsk_f / total_f

gen midskshare  = (midsk_m + midsk_f) / (total_m + total_f)
gen midskmshare = midsk_m / total_m
gen midskfshare = midsk_f / total_f

gen lowskshare  = (lowsk_m + lowsk_f) / (total_m + total_f)
gen lowskmshare = lowsk_m / total_m
gen lowskfshare = lowsk_f / total_f

label var highskshare  "High-skill occupation share (Managers+Professionals / total employed, both sexes)"
label var highskmshare "High-skill occupation share (male)"
label var highskfshare "High-skill occupation share (female)"

label var midskshare  "Middle-skill occupation share (Technicians/Trades+Community Service+Clerical/Admin / total employed, both sexes)"
label var midskmshare "Middle-skill occupation share (male)"
label var midskfshare "Middle-skill occupation share (female)"

label var lowskshare  "Low-skill occupation share (Sales+Machinery Operators+Labourers / total employed, both sexes)"
label var lowskmshare "Low-skill occupation share (male)"
label var lowskfshare "Low-skill occupation share (female)"

* check: share가 1 넘는지 확인
local sharevars highskshare highskmshare highskfshare midskshare midskmshare midskfshare lowskshare lowskmshare lowskfshare

foreach v of local sharevars {
    summarize `v', meanonly
    di as text "`v': min=" %6.4f r(min) "  max=" %6.4f r(max)

    count if `v' > 1 & !missing(`v')
    if r(N) > 0 {
        di as error ">>> `v' has `r(N)' obs exceeding 1"
    }
}

keep LGAFINAL21 year highsk_m highsk_f midsk_m midsk_f lowsk_m lowsk_f ///
    highskshare highskmshare highskfshare ///
    midskshare midskmshare midskfshare ///
    lowskshare lowskmshare lowskfshare 

save "$data/ABS_T2635_total.dta", replace
