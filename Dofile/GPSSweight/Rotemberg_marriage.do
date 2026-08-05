**********************************************************************
* Created by Heera Lee
* Purpose: Rotemberg (2021) / Goldsmith-Pinkham, Sorkin & Swift (2020, GPSS)
*          weight decomposition of the shift-share immigration IV
*          Outcome: married share, age 20-34 (marriedshare_2034)
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
	global output "${main}/Output"
**********************************************************************
capture log close
log using "$output/Log/Rotemberg_marriage.smcl", replace

**********************************************************************
* 0. 국가 코드 리스트 (ABS_immi_rotem.dta의 share91<code>/g_kt<code> 접미사와 동일)
**********************************************************************
local KLIST CAN CHN DEU EGY FJI GBR GRC HKG IDN IND IRL IRN IRQ ITA JPN KOR LBN LKA MYS NLD NZL PHL POL SGP THA USA VNM ZAF ZZZ
local K : word count `KLIST'

**********************************************************************
* 1. 데이터 merge
*    ABS_immi_rotem.dta   : 국가별 share91_k(1991년 출신국 shift-share), g_kt_k(연도별 전국 이민유입)
*    ABS_XY_final.dta     : Y변수, Xit/Zit, baseline/lag control 전부 포함(둘 다 있는 변수는 겹치므로
*                            immi_rotem 쪽에서는 국가별 변수 + pop_i91만 남기고 merge)
**********************************************************************
use "$data/ABS_immi_rotem.dta", clear

keep LGAFINAL21 year pop_i91 share91* g_kt*
drop share91AUS

merge 1:1 LGAFINAL21 year using "$final/ABS_XY_final.dta", assert(3) nogen

**********************************************************************
* 2. 국가명 접미사 -> 국가 순번(1~29)로 치환
*    (foreach 안에서 매번 29개 변수를 문자로 다루는 것보다 forvalues i=1/`K'로 도는 게 간단해서)
**********************************************************************
local i = 1
foreach k of local KLIST {
    capture confirm variable share91`k'
    if !_rc rename share91`k' share91`i'

    capture confirm variable g_kt`k'
    if !_rc rename g_kt`k' g_kt`i'

    local ++i
}

**********************************************************************
* 3. 표본/컨트롤 설정 (ABS_robust.do 결혼 스펙과 동일: baseline lag control +
**********************************************************************
sort LGAFINAL21 year
xtset LGAFINAL21 year
tsset LGAFINAL21 year, delta(5)

global demo fifteenshare_lag bachshare_ageall_lag 

gen sample = 1 if year>=2001 & year<=2021 & !missing(marriedshare_2034)
keep if sample==1

tabulate year, generate(year_)
**********************************************************************
* STEP1: y, x residualize
*   LGA FE(i.LGAFINAL21) + year FE(year_1-year_5) + baseline control($demo)을
*   Rotemberg weight 계산 전에 미리 partial-out (xtivreg2 내부 demeaning을 쓸 수 없으므로
*   FWL을 직접 적용)
**********************************************************************
xi: reg marriedshare_2034 $demo year_1-year_5 i.LGAFINAL21, cluster(LGAFINAL21)
predict yhat, xb
gen p_t_res = marriedshare_2034 - yhat

xi: reg Xit $demo year_1-year_5 i.LGAFINAL21, cluster(LGAFINAL21)
predict xhat, xb
gen immigration_res = Xit - xhat
**********************************************************************
* STEP2: 국가 k별 just-identified instrument
*   bb_k = share91_k * g_kt_k / pop_i91   (Xit/Zit와 동일한 분모로 맞춤)
**********************************************************************
forvalues i = 1/`K' {
    gen sg`i' = share91`i' * g_kt`i'
}
egen z_iv = rowtotal(sg*)
gen z_iv_s = z_iv / pop_i91

forvalues i = 1/`K' {
    gen bb`i' = (share91`i' * g_kt`i') / pop_i91
}

**********************************************************************
* STEP3: z, z_k residualize (bb_k도 동일한 FE+control로 partial-out)
**********************************************************************
xi: reg z_iv_s $demo year_1-year_5 i.LGAFINAL21, cluster(LGAFINAL21)
predict zhat, xb
gen z_iv_res = z_iv_s - zhat

forvalues i = 1/`K' {
    xi: reg bb`i' $demo year_1-year_5 i.LGAFINAL21, cluster(LGAFINAL21)
    predict bbhat`i', xb
    gen zres`i' = bb`i' - bbhat`i'
    drop bbhat`i'
}

* 검증: 국가별로 재조립한 z_iv_res가 실제 분석에서 쓰는 Zit와 같은 계수를 주는지 cross-check
ivreg2 p_t_res (immigration_res = z_iv_res), cl(LGAFINAL21)
scalar b_overall = _b[immigration_res]
di as result "Rotemberg base coef (reconstructed z_iv_res) = " %10.6f b_overall

ivreg2 p_t_res (immigration_res = Zit), cl(LGAFINAL21)
di as result "Main-analysis Zit coef (cross-check)          = " %10.6f _b[immigration_res]

save "$interim/ABS/Rotemberg/Immi_res_marriage.dta", replace

**********************************************************************
* STEP4: Rotemberg weight(alpha_k) 계산
**********************************************************************
forvalues i = 1/`K' {
    gen rw_num`i' = zres`i' * immigration_res
}

preserve
collapse (sum) rw_num1-rw_num`K'

egen rw_total = rowtotal(rw_num*)
di as result "rw_total = " rw_total[1]     // 양수여야 first stage 존재

forvalues i = 1/`K' {
    gen alpha`i' = rw_num`i' / rw_total
}

egen alpha_sum = rowtotal(alpha*)
di as result "Sum of Rotemberg weights = " alpha_sum[1]   // 1이어야 정상

mkmat alpha1-alpha`K' in 1/1, matrix(Rot)
matrix Rotem = Rot'
restore

**********************************************************************
* STEP5: 국가 k별 beta_k (just-identified IV) 계산
**********************************************************************
use "$interim/ABS/Rotemberg/Immi_res_marriage.dta", clear

local gvars
forvalues i = 1/`K' {
    local gvars `gvars' g_kt`i'
}
mkmat `gvars' in 1/1, matrix(Gr)
matrix G = Gr'

matrix B   = J(`K',1,.)
matrix SEB = J(`K',1,.)
matrix KPF = J(`K',1,.)
matrix CDF = J(`K',1,.)

forvalues i = 1/`K' {
    ivreg2 p_t_res (immigration_res = zres`i'), cl(LGAFINAL21) first
    matrix B[`i',1]   = _b[immigration_res]
    matrix SEB[`i',1] = _se[immigration_res]
    matrix KPF[`i',1] = e(widstat)
    matrix CDF[`i',1] = e(cdf)
}

**********************************************************************
* STEP6: 결과 취합 + recomposition 검증 + 전체 결과 CSV
**********************************************************************
matrix ALL = (Rotem, B, SEB, KPF, CDF, G)
matrix colnames ALL = alpha_hat Beta se_Beta KPF CDF Gk
svmat double ALL, names(col)

keep alpha_hat Beta se_Beta KPF CDF Gk
keep in 1/`K'

gen double ab       = alpha_hat * Beta
egen double b_rotem = total(ab)
di as result "========================================"
di as result "Overall IV coef      = " %10.6f b_overall
di as result "Rotemberg recomposed = " %10.6f b_rotem[1]
di as result "Difference            = " %10.8f (b_overall - b_rotem[1])
di as result "========================================"
drop ab b_rotem

gen abs_alpha = abs(alpha_hat)

* 국가명 매칭: KLIST 순서를 그대로 주입 (merge 대신 직접 대입이 더 안전)
gen con_id = _n
gen str5 country = ""
tokenize "`KLIST'"
forvalues i = 1/`K' {
    replace country = "``i''" in `i'
}

order con_id country alpha_hat abs_alpha Beta se_Beta KPF CDF Gk
save "$interim/ABS/Rotemberg/Rotemberg_marriage_results.dta", replace

**********************************************************************
* STEP7: Var(z_k) 계산 (residualized instrument의 분산, GPSS Appendix E)
**********************************************************************
use "$interim/ABS/Rotemberg/Immi_res_marriage.dta", clear

tempfile vz
preserve
forvalues i = 1/`K' {
    gen sq_zres`i' = zres`i'^2
}
collapse (sum) sq_zres1-sq_zres`K'
forvalues i = 1/`K' {
    rename sq_zres`i' Var_zk`i'
}
gen one = 1
reshape long Var_zk, i(one) j(con_id)
drop one
save `vz', replace
restore

use "$interim/ABS/Rotemberg/Rotemberg_marriage_results.dta", clear
merge 1:1 con_id using `vz', nogen
save "$interim/ABS/Rotemberg/Rotemberg_marriage_results.dta", replace

* 전체 29개국 결과 CSV로 바로 export (Panel C에서 top5만 자르기 전, 국가 전체를 눈으로 보고 싶을 때 사용)
export delimited using "$output/Table/RotembergAll_marriage.csv", replace

**********************************************************************
* STEP8: Bubble Plot
*   (KPF 컷오프 / CDF 컷오프) x (ZZZ 포함 / ZZZ 제외) = 4개 버전
*   컷오프 기준값은 두 F-stat 모두 동일하게 5~400 사용 (필요하면 아래에서 조정)
**********************************************************************
local cutlo = 5
local cuthi = 400

local cutstats KPF CDF
local zzzopts  with no

foreach stat of local cutstats {
    foreach zzz of local zzzopts {
        preserve

        drop if `stat' < `cutlo' | `stat' > `cuthi'
        if "`zzz'" == "no" drop if country == "ZZZ"

        gen Beta_pos = Beta if alpha_hat >= 0
        gen Beta_neg = Beta if alpha_hat <  0

        local statlabel = cond("`stat'"=="KPF", "First stage F-statistic", "First stage F-statistic")
        local zzzlabel  = cond("`zzz'"=="with", "ZZZ included", "ZZZ excluded")

        set scheme s2color
        twoway ///
            (scatter Beta_pos `stat' [aw=abs_alpha], ///
                msymbol(Oh) msize(*1) mcolor(navy) mlcolor(navy) mfcolor(none)) ///
            (scatter Beta_neg `stat' [aw=abs_alpha], ///
                msymbol(Dh) msize(*1) mcolor(maroon) mlcolor(maroon) mfcolor(none)) ///
            , ///
            yline(`=scalar(b_overall)', lpattern(dash) lcolor(black) lwidth(medium)) ///
            legend(order(1 "Positive Weights" 2 "Negative Weights") ///
                pos(5) ring(0) size(small) region(fcolor(none) lcolor(black))) ///
            xtitle("`statlabel'") ///
            ytitle("First stage F-statistic estimate") ///
            graphregion(color(white)) plotregion(color(white)) ///
            xlabel(, nogrid) ylabel(, nogrid)

        graph export "$output/Figure/fig_rotemberg_bubble_marriage_`stat'cut_`zzz'ZZZ.pdf", replace
        graph export "$output/Figure/fig_rotemberg_bubble_marriage_`stat'cut_`zzz'ZZZ.png", replace

        restore
    }
}

**********************************************************************
* STEP9: Panel A/B/C 계산 -> 그때그때 csv로 export
*   (LaTeX 표 한 장을 통째로 조립하지 않고, 계산되는 대로 각 Panel을 csv로 저장)
**********************************************************************

* ----- Panel A: 음/양 weight 요약 -----
quietly summarize alpha_hat if alpha_hat <= 0
scalar sum_neg  = r(sum)
scalar mean_neg = r(mean)
quietly summarize alpha_hat if alpha_hat > 0
scalar sum_pos  = r(sum)
scalar mean_pos = r(mean)
scalar sh_neg = abs(sum_neg) / (abs(sum_neg) + sum_pos)
scalar sh_pos = sum_pos      / (abs(sum_neg) + sum_pos)

preserve
clear
set obs 2
gen str8 weight_type = "Negative" in 1
replace weight_type  = "Positive" in 2
gen double sum   = sum_neg  in 1
replace    sum   = sum_pos  in 2
gen double mean  = mean_neg in 1
replace    mean  = mean_pos in 2
gen double share = sh_neg   in 1
replace    share = sh_pos   in 2

* export delimited는 display format을 무시하고 raw 숫자(소수점 십수자리)를 그대로
* 뽑으므로, 소수점 3자리 반올림 문자열로 미리 변환
foreach v of varlist sum mean share {
    gen str12 `v'_str = string(`v', "%9.3f")
    drop `v'
    rename `v'_str `v'
}
order weight_type sum mean share
export delimited using "$output/Table/RotembergA_negpos_marriage.csv", replace
restore

* ----- Panel B: alpha_k, g_k, beta_k, F_k, Var(z_k) 상관관계 -----
corr alpha_hat Gk Beta KPF Var_zk
matrix C = r(C)

preserve
clear
local vnames alpha_hat Gk Beta KPF Var_zk
svmat double C, names(col)
gen variable = ""
local i = 1
foreach v of local vnames {
    replace variable = "`v'" in `i'
    local ++i
}
order variable

foreach v of local vnames {
    gen str12 `v'_str = string(`v', "%9.3f")
    drop `v'
    rename `v'_str `v'
}
order variable `vnames'
export delimited using "$output/Table/RotembergB_correlations_marriage.csv", replace
restore

* ----- Panel C: Rotemberg weight 상위 5개국 -----
use "$interim/ABS/Rotemberg/Rotemberg_marriage_results.dta", clear

egen double total_Gk = total(Gk)
gen double baseline_share = Gk / total_Gk

gen double ci_lb = Beta - 1.96 * se_Beta
gen double ci_ub = Beta + 1.96 * se_Beta

* ZZZ(잔차 국가군) 제외하고 abs_alpha 기준 상위 5개국 선택
gsort -abs_alpha
gen rank_noZZZ = .
local rank = 0
local obs_n = _N
forvalues r = 1/`obs_n' {
    if country[`r'] != "ZZZ" {
        local rank = `rank' + 1
        replace rank_noZZZ = `rank' in `r'
    }
}

keep if rank_noZZZ <= 5
sort rank_noZZZ
keep country alpha_hat Gk Beta se_Beta ci_lb ci_ub baseline_share
order country alpha_hat Gk Beta se_Beta ci_lb ci_ub baseline_share

* export delimited는 display format을 무시하고 raw 숫자를 그대로 뽑음
* -> Gk는 값이 커서 지수표기(%9.1e) 문자열로, 나머지는 소수점 3자리 반올림 문자열로 변환
gen str12 Gk_str = string(Gk, "%9.1e")
drop Gk
rename Gk_str Gk

foreach v of varlist alpha_hat Beta se_Beta ci_lb ci_ub baseline_share {
    gen str12 `v'_str = string(`v', "%9.3f")
    drop `v'
    rename `v'_str `v'
}

order country alpha_hat Gk Beta se_Beta ci_lb ci_ub baseline_share

export delimited using "$output/Table/RotembergC_top5_marriage.csv", replace

log close
**********************************************************************
* END
**********************************************************************
