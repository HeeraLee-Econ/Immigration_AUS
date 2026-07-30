*************STEP1: cob_2001census + cob_2016census + cob_2021census 머지하기 
clear 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS/afterABS/"

use 2016/cob_2016census_fin.dta 

append using 2021/cob_2021census_fin

rename ct6_Total, lower 

collapse (sum) ct1_female_higher ct1_male_higher ct1_same ct2_female_higher ct2_male_higher ct2_same ct3_female_higher ct3_male_higher ct3_same ct4_female_higher ct4_male_higher ct4_same ct5_female_higher ct5_male_higher ct5_same ct6_total ct6_female_higher ct6_male_higher ct6_same, by(LGAFINAL21 year)

tab year 

* 안맞는 지역 
drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 

tab year // 496개 
*************STEP2: label define 
label define ctlabel ///
    1 "Couple family with no children" ///
    2 "Couple family with children under 15 years and dependent students" ///
    3 "Couple family with children under 15 years and no dependent students" ///
    4 "Couple family with no children under 15 years and with dependent students" ///
    5 "Couple family with no children under 15 years and non-dependent children only" ///
    6 "Total couple families"

	foreach v of varlist ct* {
    * ct 번호 추출 (ct1_, ct2_ ...)
    local ct = substr("`v'", 3, 1)

    * couple type 설명 불러오기
    local ctdesc : label ctlabel `ct'

    * 나머지 타입 설명
    local rest = substr("`v'", 6, .)
    local rest = subinstr("`rest'", "_", " ", .)

    label variable `v' "`ctdesc' – `rest'"
}

/*
gen share_fehigh = fehigh / tot_fam 
gen share_same = same/tot_fam 
gen share_mahigh = mahigh/tot_fam 

label variable tot_fam "sheet about family_total family"
*/ 

save cob_final, replace 
