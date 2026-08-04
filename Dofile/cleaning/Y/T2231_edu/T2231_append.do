**********************************************************************
* Created by Heera Lee
* Purpose: append T22(2006census), T31(2021census) and construct variables for analysis
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
**********************************************************************
use "$data/ABS_T22_2006census.dta", clear 
append using "$data/ABS_T31_2021census.dta"

drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 // 지방정부 없는 미편입지역, 혹은 원주민 소유 원격지, 해외령 

tab year // 496 * 6, 1996~2021

**********************************************************************
* 20-34세 합산: T22/T31은 이미 원자료에서 25-34가 한 구간이라 2024+2534만 더하면 됨
* (T04/T24와 달리 2529/3034로 안 쪼개져 있음)
**********************************************************************
gen postgrad_m_2034   = postgrad_m_2024   + postgrad_m_2534
gen postgrad_f_2034   = postgrad_f_2024   + postgrad_f_2534
gen graddip_m_2034    = graddip_m_2024    + graddip_m_2534
gen graddip_f_2034    = graddip_f_2024    + graddip_f_2534
gen bachelor_m_2034   = bachelor_m_2024   + bachelor_m_2534
gen bachelor_f_2034   = bachelor_f_2024   + bachelor_f_2534
gen grandtotal_m_2034 = grandtotal_m_2024 + grandtotal_m_2534
gen grandtotal_f_2034 = grandtotal_f_2024 + grandtotal_f_2534

**********************************************************************
* bach+ = postgrad + graddip + bachelor (advdip/diploma는 bachelor 미만이라 제외)
**********************************************************************
* 전 연령대(ageall)
gen bach_m_ageall = postgrad_m_ageall + graddip_m_ageall + bachelor_m_ageall
gen bach_f_ageall = postgrad_f_ageall + graddip_f_ageall + bachelor_f_ageall

gen bachshare_ageall  = (bach_m_ageall + bach_f_ageall) / (grandtotal_m_ageall + grandtotal_f_ageall)
gen bachmshare_ageall = bach_m_ageall / grandtotal_m_ageall
gen bachfshare_ageall = bach_f_ageall / grandtotal_f_ageall

* 20-34세
gen bach_m_2034 = postgrad_m_2034 + graddip_m_2034 + bachelor_m_2034
gen bach_f_2034 = postgrad_f_2034 + graddip_f_2034 + bachelor_f_2034

gen bachshare_2034  = (bach_m_2034 + bach_f_2034) / (grandtotal_m_2034 + grandtotal_f_2034)
gen bachmshare_2034 = bach_m_2034 / grandtotal_m_2034
gen bachfshare_2034 = bach_f_2034 / grandtotal_f_2034

label var bachshare_ageall  "Bachelor's degree or higher share (all ages, both sexes)"
label var bachmshare_ageall "Bachelor's degree or higher share (all ages, male)"
label var bachfshare_ageall "Bachelor's degree or higher share (all ages, female)"
label var bachshare_2034    "Bachelor's degree or higher share (age 20-34, both sexes)"
label var bachmshare_2034   "Bachelor's degree or higher share (age 20-34, male)"
label var bachfshare_2034   "Bachelor's degree or higher share (age 20-34, female)"

keep LGAFINAL21 year bachshare_ageall bachmshare_ageall bachfshare_ageall bachshare_2034 bachmshare_2034 bachfshare_2034 

* check 
local bachshare_ageall bachmshare_ageall bachfshare_ageall bachshare_2034 bachmshare_2034 bachfshare_2034

foreach v of local sharevars {
    summarize `v', meanonly
    di as text "`v': min=" %6.4f r(min) "  max=" %6.4f r(max)

    count if `v' > 1 & !missing(`v')
    if r(N) > 0 {
        di as error ">>> `v' has `r(N)' obs exceeding 1"
    }
}

save "$data/ABS_T2231_total.dta", replace 
