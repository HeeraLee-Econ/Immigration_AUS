**********************************************************************
* Created by Heera Lee
* Purpose: append T01 and construct variables for analysis
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
**********************************************************************
use "$data/ABS_T04_2006census.dta", clear 
append using "$data/ABS_T04_2021census.dta"

drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 // 지방정부 없는 미편입지역, 혹은 원주민 소유 원격지, 해외령 

tab year // 496 * 6, 1996~2021

**********************************************************************
* 연령버전별 합산: 20-34세(prime marriageable age, 메인 스펙) / 15-39세(robustness)
**********************************************************************
* 20-34
gen married_m_2034      = married_m_2024      + married_m_2529      + married_m_3034
gen married_f_2034      = married_f_2024      + married_f_2529      + married_f_3034
gen nevermarried_m_2034 = nevermarried_m_2024 + nevermarried_m_2529 + nevermarried_m_3034
gen nevermarried_f_2034 = nevermarried_f_2024 + nevermarried_f_2529 + nevermarried_f_3034
gen totpop_m_2034       = totpop_m_2024       + totpop_m_2529       + totpop_m_3034
gen totpop_f_2034       = totpop_f_2024       + totpop_f_2529       + totpop_f_3034

* 15-39
gen married_m_1539      = married_m_1519      + married_m_2024      + married_m_2529      + married_m_3034      + married_m_3539
gen married_f_1539      = married_f_1519      + married_f_2024      + married_f_2529      + married_f_3034      + married_f_3539
gen nevermarried_m_1539 = nevermarried_m_1519 + nevermarried_m_2024 + nevermarried_m_2529 + nevermarried_m_3034 + nevermarried_m_3539
gen nevermarried_f_1539 = nevermarried_f_1519 + nevermarried_f_2024 + nevermarried_f_2529 + nevermarried_f_3034 + nevermarried_f_3539
gen totpop_m_1539       = totpop_m_1519       + totpop_m_2024       + totpop_m_2529       + totpop_m_3034       + totpop_m_3539
gen totpop_f_1539       = totpop_f_1519       + totpop_f_2024       + totpop_f_2529       + totpop_f_3034       + totpop_f_3539

**********************************************************************
* share/비율 변수: married share, married m/f share, never married m/f share,
*                  + 결혼시장 성비(marriage market sex ratio = 미혼남/미혼여)
**********************************************************************
* 20-34
gen marriedshare_2034          = (married_m_2034 + married_f_2034) / (totpop_m_2034 + totpop_f_2034)
gen marriedmaleshare_2034      = married_m_2034 / totpop_m_2034
gen marriedfemaleshare_2034    = married_f_2034 / totpop_f_2034
gen nevermarriedmaleshare_2034   = nevermarried_m_2034 / totpop_m_2034
gen nevermarriedfemaleshare_2034 = nevermarried_f_2034 / totpop_f_2034
gen marriagemktsexratio_2034   = nevermarried_m_2034 / nevermarried_f_2034
gen nevermarriedshare_2034     = (nevermarried_m_2034 + nevermarried_f_2034) / (totpop_m_2034 + totpop_f_2034)

* 20-34세 남/여 비율 (totpop_m/totpop_f 기준)
gen share_2034 = (totpop_m_2034 + totpop_f_2034) / (totpop_m_ageall + totpop_f_ageall)
gen maleshare_2034   = totpop_m_2034 / (totpop_m_2034 + totpop_f_2034)
gen femaleshare_2034 = totpop_f_2034 / (totpop_m_2034 + totpop_f_2034)

* 15-39
gen marriedshare_1539          = (married_m_1539 + married_f_1539) / (totpop_m_1539 + totpop_f_1539)
gen marriedmaleshare_1539      = married_m_1539 / totpop_m_1539
gen marriedfemaleshare_1539    = married_f_1539 / totpop_f_1539
gen nevermarriedmaleshare_1539   = nevermarried_m_1539 / totpop_m_1539
gen nevermarriedfemaleshare_1539 = nevermarried_f_1539 / totpop_f_1539
gen marriagemktsexratio_1539   = nevermarried_m_1539 / nevermarried_f_1539
gen nevermarriedshare_1539     = (nevermarried_m_1539 + nevermarried_f_1539) / (totpop_m_1539 + totpop_f_1539)

keep LGAFINAL21 year ///
    married_m_2034 married_f_2034 nevermarried_m_2034 nevermarried_f_2034 totpop_m_2034 totpop_f_2034 ///
    married_m_1539 married_f_1539 nevermarried_m_1539 nevermarried_f_1539 totpop_m_1539 totpop_f_1539 ///
    marriedshare_2034 marriedmaleshare_2034 marriedfemaleshare_2034 ///
    nevermarriedmaleshare_2034 nevermarriedfemaleshare_2034 nevermarriedshare_2034 marriagemktsexratio_2034 ///
    share_2034 maleshare_2034 femaleshare_2034 ///
    marriedshare_1539 marriedmaleshare_1539 marriedfemaleshare_1539 ///
    nevermarriedmaleshare_1539 nevermarriedfemaleshare_1539 nevermarriedshare_1539 marriagemktsexratio_1539 totpop_f_2034 totpop_f_1539 totpop_m_2034 totpop_m_1539

* 주요 변수 라벨링
label var marriedshare_2034          "Married share (age 20-34, both sexes)"
label var marriedmaleshare_2034      "Married share (age 20-34, male)"
label var marriedfemaleshare_2034    "Married share (age 20-34, female)"
label var nevermarriedshare_2034     "Never married share (age 20-34, both sexes)"
label var nevermarriedmaleshare_2034 "Never married share (age 20-34, male)"
label var nevermarriedfemaleshare_2034 "Never married share (age 20-34, female)"
label var marriagemktsexratio_2034   "Marriage market sex ratio (age 20-34, unmarried male / unmarried female)"
label var share_2034                 "Share of total population aged 20-34"
label var maleshare_2034             "Male share of population aged 20-34"
label var femaleshare_2034           "Female share of population aged 20-34"

label var marriedshare_1539          "Married share (age 15-39, both sexes)"
label var marriedmaleshare_1539      "Married share (age 15-39, male)"
label var marriedfemaleshare_1539    "Married share (age 15-39, female)"
label var nevermarriedshare_1539     "Never married share (age 15-39, both sexes)"
label var nevermarriedmaleshare_1539 "Never married share (age 15-39, male)"
label var nevermarriedfemaleshare_1539 "Never married share (age 15-39, female)"
label var marriagemktsexratio_1539   "Marriage market sex ratio (age 15-39, unmarried male / unmarried female)"

**********************************************************************
* 체크: share 변수들이 1을 넘지 않는지 확인 (marriagemktsexratio는 제외)
**********************************************************************
local sharevars marriedshare_2034 marriedmaleshare_2034 marriedfemaleshare_2034 ///
    share_2034 maleshare_2034 femaleshare_2034 ///
    marriedshare_1539 marriedmaleshare_1539 marriedfemaleshare_1539 ///

foreach v of local sharevars {
    summarize `v', meanonly
    di as text "`v': min=" %6.4f r(min) "  max=" %6.4f r(max)

    count if `v' > 1 & !missing(`v')
    if r(N) > 0 {
        di as error ">>> `v' has `r(N)' obs exceeding 1"
    }
}

save "$data/ABS_T04_total.dta", replace


