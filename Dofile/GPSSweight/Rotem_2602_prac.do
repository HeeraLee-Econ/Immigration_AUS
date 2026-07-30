********************************************************************************
* Rotemberg weights 계산 및 그래프/표 Overleaf export (ONE-PIECE DOFILE)
* Immigration and Manufacturing share (ABS)
********************************************************************************

**********************************
* 국가명별로 id 매기고 데이터 만들기
**********************************
* 국가 코드 리스트
local KLIST CAN CHN DEU EGY FJI GBR GRC HKG IDN IND IRL IRN IRQ ITA JPN KOR LBN LKA MYS NLD NZL PHL POL SGP THA USA VNM ZAF ZZZ

clear
local K = wordcount("`KLIST'")
set obs `K'

gen con_id = _n
gen str5 country = ""

local i = 1
foreach k of local KLIST {
    replace country = "`k'" in `i'
    local ++i
}

order con_id country
save "/Users/ihuila/Desktop/data/2025ABS/afterIV/country_id.dta", replace
**********************************
* 디렉토리
**********************************
cd "/Users/ihuila/Desktop/data/2025ABS/afterIV"

**********************************
* IV + 로템 + Y변수 merge
**********************************
use "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_rotem.dta", clear
merge m:1 LGAFINAL21 year using "/Users/ihuila/Desktop/data/2025ABS/cob_XYZ_final.dta"
drop _merge
save "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_rotem_final.dta", replace

use "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_rotem_final.dta", clear

drop shift91AUS
********************************************
* 변수명 접미사를 con_id 숫자로 치환
*********************************************
local KLIST CAN CHN DEU EGY FJI GBR GRC HKG IDN IND IRL IRN IRQ ITA JPN KOR LBN LKA MYS NLD NZL PHL POL SGP THA USA VNM ZAF ZZZ
local i = 1

foreach k of local KLIST {

    * shift 91
    capture confirm variable shift91`k'
    if !_rc rename shift91`k' shift91`i'
	
    * g_kt
    capture confirm variable g_kt`k'
    if !_rc rename g_kt`k' g_kt`i'
	
    local ++i
}

ds shift91*
display "`r(varlist)'"

ds g_kt*
display "`r(varlist)'"
**********************************
* STEP0: 종속변수 갈음
**********************************
sort LGAFINAL21 year
xtset LGAFINAL21 year
tsset LGAFINAL21 year, delta(5)

gen lag_year = L1.year
gen lag_share_college = L1.share_college 
gen lag_share_popfifold = L1.share_popfifold 

global demo lag_share_college
global demo2 lag_share_college lag_share_popfifold

gen sample = 1 if year>=1996 & year<=2021 
keep if sample==1 

**********************************
* STEP1: residualize y and x
**********************************
sort LGAFINAL21 year
//by LGAFINAL21: gen D1_share_popfifold = share_popfifold - share_popfifold[_n-1]
//by LGAFINAL21: gen D1_share_college   = share_college   - share_college[_n-1]

drop if unempl_rate == . 

tabulate year, generate(year_)
***************STEP1: residualize y,x,z_k (pop i,t-1이 time-varying이므로, z_k도 residualize 필요)
* residualize y
xi: reg unempl_rate $demo year_1-year_5 i.LGAFINAL21 if sample==1 , cl(LGAFINAL21)
predict yhat, xb
gen p_t_res = unempl_rate - yhat

* residualize x// Xit 는 이미 Pop i,t-1 로 나눠진 숫자 
xi: reg Xit $demo year_1-year_5 i.LGAFINAL21 if sample==1, cl(LGAFINAL21)
predict xhat, xb
gen immigration_res = Xit - xhat
*****************************STEP2: instrument 생성 
* z_k,it = shift91 * g_kt / pop i,t-1 
* aggregate bartik IV 
forvalues i=1/29{
    gen sg`i' = shift91`i' * g_kt`i' 
}
egen z_iv = rowtotal(sg*)
gen z_iv_s = z_iv / lag_pop

* k별 just-identified instrument 
forvalues i=1/29 { 
	gen bb`i' = (shift91`i' * g_kt`i') / lag_pop 
}

****************************STEP3: z_k residualize -> bb`k' 도 FE, controls - partial out 
* aggregate z residualize
xi: reg z_iv_s $demo year_1-year_5 i.LGAFINAL21 if sample==1,  cluster(LGAFINAL21)
predict zhat, xb
gen z_iv_res = z_iv_s - zhat

* k별 z_k residualize
forvalues i = 1/29 {
    xi: reg bb`i' $demo year_1-year_5 i.LGAFINAL21 if sample==1,  cluster(LGAFINAL21)
    predict bbhat`i', xb
    gen zres`i' = bb`i' - bbhat`i'
    drop bbhat`i'
}

* === 검증: main analysis와 계수 일치 확인 ===
ivreg2 p_t_res (immigration_res = z_iv_res) if sample==1, cl(LGAFINAL21)
scalar b_overall = _b[immigration_res]
display "Rotemberg base coef  = " %10.6f b_overall
* MAIN results 의 coefficient 와 일치하는지 확인

cd "/Users/ihuila/Desktop/data/2025ABS/tables/rotem/employ"
save "Immi_res.dta", replace
**********************************STEP4: Rotemberg weight 계산 
* 각 k별 분자
forvalues i = 1/29 {
    gen rw_num`i' = zres`i' * immigration_res
}

* collapse: 전체 패널 합산
preserve
collapse (sum) rw_num1-rw_num29

* 분모: sum_k(numerator_k)
egen rw_total = rowtotal(rw_num*)
display "rw_total = " rw_total[1]     // 양수여야 first stage 존재

* alpha_k = numerator_k / rw_total
forvalues i = 1/29 {
    gen alpha`i' = rw_num`i' / rw_total
}

* 합산 검증: 1인지 확인 
egen alpha_sum = rowtotal(alpha*)
list alpha_sum 
display "Sum of Rotemberg weights = " alpha_sum[1]
 
* Matrix 저장
mkmat alpha1-alpha29 in 1/1, matrix(Rot)
matrix Rotem = Rot'

restore
**********************************STEP5: Beta_k 계산(각 k별 just-identified IV)
cd "/Users/ihuila/Desktop/data/2025ABS/tables/rotem/employ"
use "Immi_res.dta", clear

* g_kt matrix (논문용)
local gvars
forvalues i = 1/29 {
    local gvars `gvars' g_kt`i'
}
mkmat `gvars' in 1/1, matrix(Gr)
matrix G = Gr'

matrix B   = J(29,1,.)
matrix SEB = J(29,1,.)
matrix KPF = J(29,1,.)
matrix CDF = J(29,1,.)

est clear
forvalues i = 1/29 {
    ivreg2 p_t_res (immigration_res = zres`i') if sample==1, ///
        cl(LGAFINAL21) first savefirst savefprefix(st`i')
    est store reg`i'
    matrix B[`i',1]   = _b[immigration_res]
    matrix SEB[`i',1] = _se[immigration_res]
    matrix KPF[`i',1] = e(widstat)
    matrix CDF[`i',1] = e(cdf)
}

***********************************************************
* STEP 6: 결과 취합 및 Recomposition 검증
***********************************************************
matrix ALL = (Rotem, B, SEB, KPF, CDF, G)
matrix colnames ALL = alpha_hat Beta se_Beta KPF CDF Gk
svmat double ALL, names(col)

local Kn = rowsof(ALL)
keep alpha_hat Beta se_Beta KPF CDF Gk
keep in 1/`Kn'

* Recomposition 검증: beta_IV = sum_k(alpha_k * beta_k)
gen double ab       = alpha_hat * Beta
egen double b_rotem = total(ab)

display "========================================"
display "Overall IV coef      = " %10.6f b_overall
display "Rotemberg recomposed = " %10.6f b_rotem[1]
display "Difference           = " %10.8f (b_overall - b_rotem[1])
display "========================================"
* 차이가 1e-5 이하면 정상

drop ab b_rotem
gen abs_alpha = abs(alpha_hat)

* Country 매칭
gen con_id = _n
gen str5 country = ""

local KLIST CAN CHN DEU EGY FJI GBR GRC HKG IDN IND IRL IRN IRQ ITA JPN KOR LBN LKA MYS NLD NZL PHL POL SGP THA USA VNM ZAF ZZZ

tokenize "`KLIST'"
forvalues i = 1/29 {
    replace country = "``i''" in `i'
}

order con_id country alpha_hat abs_alpha Beta se_Beta KPF CDF Gk
save "Rotemberg_empl_results.dta", replace
***********************************************************
* STEP 7: Bubble Plot
***********************************************************
preserve
drop if CDF < 5 | CDF > 400
drop if country == "ZZZ"

summ KPF Beta 

cd "/Users/ihuila/Desktop/data/2025ABS/tables/rotem/employ"
set scheme s2color

twoway ///
    (scatter Beta KPF [aw=abs_alpha] if alpha_hat >= 0, ///
        msymbol(Oh) msize(*1) mcolor(navy) mlcolor(navy) mfcolor(none)) ///
    (scatter Beta KPF [aw=abs_alpha] if alpha_hat < 0, ///
        msymbol(Dh) msize(*1) mcolor(maroon) mlcolor(maroon) mfcolor(none)) ///
    , ///
    yline(`=scalar(b_overall)', lpattern(dash) lcolor(black) lwidth(medium)) ///
    legend(order(1 "Positive Weights" 2 "Negative Weights") ///
        pos(5) ring(0) size(small) region(fcolor(none) lcolor(black))) ///
    xtitle("First stage F-statistic") ///
    ytitle("{&beta}{sub:k} estimate") ///
    graphregion(color(white)) plotregion(color(white)) ///
    xlabel(0(10)30, nogrid) ylabel(, nogrid)

graph export "fig_rotemberg_bubble.pdf", replace
graph export "fig_rotemberg_bubble.png", replace
restore
