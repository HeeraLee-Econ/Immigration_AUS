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

sort LGAFINAL21 year
tabulate year, generate(year_)
***************STEP1: residualize y,x,z_k (pop i,t-1이 time-varying이므로, z_k도 residualize 필요)
* residualize y
xi: reg unempl_rate $demo year_1-year_5 i.LGAFINAL21 if sample==1 , cl(LGAFINAL21)
predict yhat, xb
gen p_t_res = unempl_rate - yhat

* residualize x// Xit 는 이미 Pop i,t-1 로 나눠진 숫자 
xi: reg Xit2 $demo year_1-year_5 i.LGAFINAL21 if sample==1, cl(LGAFINAL21)
predict xhat, xb
gen immigration_res = Xit2 - xhat
*****************************STEP2: instrument 생성 
* z_k,it = shift91 * g_kt / pop i,t-1 
* aggregate bartik IV 
forvalues i=1/29{
    gen sg`i' = shift91`i' * g_kt`i' 
}
egen z_iv = rowtotal(sg*)
gen z_iv_s = z_iv / pop_i91 

* k별 just-identified instrument 
forvalues i=1/29 { 
	gen bb`i' = (shift91`i' * g_kt`i') / pop_i91 
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
scalar b_overall_unempl = _b[immigration_res]
display "Rotemberg base coef  = " %10.6f b_overall_unempl
* MAIN results 의 coefficient 와 일치하는지 확인

cd "/Users/ihuila/Desktop/data/2025ABS/tables/rotem/3-2/unemploy"
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
cd "/Users/ihuila/Desktop/data/2025ABS/tables/rotem/3-2/unemploy"
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

gen double ab       = alpha_hat * Beta
egen double b_rotem = total(ab)
display "========================================"
display "Overall IV coef      = " %10.6f b_overall_unempl
display "Rotemberg recomposed = " %10.6f b_rotem[1]
display "Difference           = " %10.8f (b_overall_unempl - b_rotem[1])
display "========================================"
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
save "Rotemberg_unempl_results.dta", replace
***********************************************************
* STEP7: Panel D scalar 계산
* -> Immi_res.dta 로 돌아가서 패널 변수 사용
* !! 실행 전 확인: list con_id country alpha_hat in 1/5
*    -> top2, top5 con_id 번호를 zres** 에 반영
***********************************************************
use "Immi_res.dta", clear

* --- Var(z_k) --- 분산계산은 residualized 된 instrument 에 대한 variance, 
tempfile vz
preserve
* zres = residualized instrument (GPSS Appendix E: Var(Z_k^perp))
* 전체 패널 사용 (time-varying residual이므로 연도 필터 불필요)
forvalues i = 1/29 {
    gen sq_zres`i' = zres`i'^2
}
collapse (sum) sq_zres1-sq_zres29
forvalues i = 1/29 {
    rename sq_zres`i' Var_zk`i'
}
gen one = 1
reshape long Var_zk, i(one) j(con_id)
drop one
save `vz', replace
restore

// Var(z_k) is computed using residualized instruments across all LGA-year observations

/*
keep if year == 1996
keep LGAFINAL21 shift91*
collapse (sd) shift91*, by()
forvalues i = 1/29 {
    gen varz`i' = shift91`i'^2
}

keep varz*
gen one = 1
reshape long varz, i(one) j(con_id)
drop one
rename varz Var_zk
save `vz', replace
restore
*/

* Rotemberg 결과에 Var_zk만 merge (baseline_share 블록 삭제)
use "Rotemberg_unempl_results.dta", clear
merge 1:1 con_id using `vz', nogen
save "Rotemberg_unempl_results.dta", replace

/*
* Rotemberg_unempl_results.dta에서 top5 con_id 자동 추출
preserve
use "Rotemberg_unempl_results.dta", clear
drop if country == "ZZZ" 
gsort -abs_alpha

* top2 국가명 헤더용으로 저장
local top2_label ""
local top2_ids   ""
forvalues r = 1/2 {
    local id  = con_id[`r']
    local ctry = country[`r']
    local top2_ids   "`top2_ids' zres`id'"
    if `r' == 1 local top2_label "`ctry'"
    if `r' == 2 local top2_label "`top2_label' \& `ctry'"   // LaTeX & 이스케이프
}

* top5 zres ids
local top5_ids ""
forvalues r = 1/5 {
    local id = con_id[`r']
    local top5_ids "`top5_ids' zres`id'"
}

display "Top 2 label : `top2_label'"
display "Top 2 instruments: `top2_ids'"
display "Top 5 instruments: `top5_ids'"
restore

* OLS
xi: reg p_t_res immigration_res, cl(LGAFINAL21)
scalar b_ols  = _b[immigration_res]
scalar se_ols = _se[immigration_res]

* Top 2 IV (자동)
ivreg2 p_t_res (immigration_res = `top2_ids'), cl(LGAFINAL21) first
scalar b_iv_top2     = _b[immigration_res]
scalar se_iv_top2    = _se[immigration_res]
//scalar F_iv_top2     = e(widstat)
scalar p_overid_top2 = e(jp)

* Top 5 IV (자동)
ivreg2 p_t_res (immigration_res = `top5_ids'), cl(LGAFINAL21) first
scalar b_iv_top5     = _b[immigration_res]
scalar se_iv_top5    = _se[immigration_res]
//scalar F_iv_top5     = e(widstat)
scalar p_overid_top5 = e(jp)

* All shares (just-identified)
ivreg2 p_t_res (immigration_res = z_iv_res), cl(LGAFINAL21) first
scalar b_iv_all  = _b[immigration_res]
scalar se_iv_all = _se[immigration_res]
//scalar F_iv_all  = e(widstat)
scalar p_overid_all = e(jp)
*/

***********************************************************
* STEP8: Bubble Plot
***********************************************************
preserve
drop if KPF < 5 | KPF > 400 // KPF 기준으로 필터를 걸면 너무 관측치가 줄어들어서 그림이 안예쁨
drop if country == "ZZZ"
/*
drop if country == "ZZZ" 
summ Beta, detail 

// y값 기준으로 필터걸어서 그림그리기 
_pctile Beta, p(5 90)
local ylo = floor(r(r1) * 10) / 10   // 소수점 1자리로 내림
local yhi = ceil(r(r2)  * 10) / 10   // 소수점 1자리로 올림

* b_overall 점선이 범위 안에 들어오도록 보정
local b_val = scalar(b_overall)
if `b_val' < `ylo' local ylo = floor(`b_val' * 2) / 2
if `b_val' > `yhi' local yhi = ceil(`b_val'  * 2) / 2

* 제외 관측치 확인
count if Beta < `ylo' | Beta > `yhi'
display "제외: " r(N) "개 | 범위: [`ylo', `yhi']"
*/

set scheme s2color
twoway ///
    (scatter Beta KPF [aw=abs_alpha] if alpha_hat >= 0, ///
        msymbol(Oh) msize(*1) mcolor(navy) mlcolor(navy) mfcolor(none)) ///
    (scatter Beta KPF [aw=abs_alpha] if alpha_hat <  0, ///
        msymbol(Dh) msize(*1) mcolor(maroon) mlcolor(maroon) mfcolor(none)) ///
    , ///
    yline(`=scalar(b_overall_unempl)', lpattern(dash) lcolor(black) lwidth(medium)) ///
    legend(order(1 "Positive Weights" 2 "Negative Weights") ///
        pos(5) ring(0) size(small) region(fcolor(none) lcolor(black))) ///
    xtitle("First stage F-statistic") ///
    ytitle("{&beta}{sub:k} estimate") ///
    graphregion(color(white)) plotregion(color(white)) ///
    xlabel(, nogrid) ylabel(, nogrid)

graph export "fig_rotemberg_bubble.pdf", replace
graph export "fig_rotemberg_bubble.png", replace
restore

***********************************************************
* STEP9: LaTeX Table (Panel A~C만, Panel D 제거)      *** 수정: Panel D 전체 삭제 ***
***********************************************************
preserve

* ---------------------------------------------------
* Panel A: ZZZ 포함 상태에서 계산
* ---------------------------------------------------
quietly summarize alpha_hat if alpha_hat <= 0
scalar sum_neg  = r(sum)
scalar mean_neg = r(mean)
quietly summarize alpha_hat if alpha_hat > 0
scalar sum_pos  = r(sum)
scalar mean_pos = r(mean)
scalar sh_neg = abs(sum_neg) / (abs(sum_neg) + sum_pos)
scalar sh_pos = sum_pos      / (abs(sum_neg) + sum_pos)

* ---------------------------------------------------
* Panel B: ZZZ 포함 상태에서 상관계수 계산
* ---------------------------------------------------
corr alpha_hat Gk Beta KPF Var_zk
matrix C = r(C)

* ---------------------------------------------------
* Panel C: Top 5 계산 (계산 자체는 ZZZ 포함, table 안에 표시는 안함)
* ---------------------------------------------------
* 전체 Gk 합산 (ZZZ 포함 상태에서)
egen double total_Gk = total(Gk)
gen double baseline_share = Gk / total_Gk

gen double ci_lb = Beta - 1.96 * se_Beta
gen double ci_ub = Beta + 1.96 * se_Beta
gen str40 ci95 = "(" + string(ci_lb,"%6.3f") + ", " + string(ci_ub,"%6.3f") + ")"

* ZZZ 제외하고 abs_alpha 기준 상위 5개국 선택
* → ZZZ가 top5 안에 있어도 건너뛰고 5개 채움
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

* top 5만 유지
keep if rank_noZZZ <= 5
sort rank_noZZZ

save "panelC_top5_table.dta", replace

* LaTeX 작성
capture file close tex
file open tex using "tab_rotemberg_summary.tex", write replace

file write tex "\begin{table}[H]\centering" _n
file write tex "\begin{threeparttable}" _n
file write tex "\caption{Summary of Rotemberg Weights -- Unemployment}" _n
file write tex "\label{TA:rotem_unempl}" _n
file write tex "{\small\renewcommand{\arraystretch}{1}" _n
file write tex "\begin{tabular}{lccccc}" _n
file write tex "\hline\hline" _n

* ----- Panel A -----
file write tex "\multicolumn{6}{l}{\textbf{\textit{Panel A: Negative and positive weights}}} \\" _n
file write tex " & Sum & Mean & Share & & \\ \cline{2-4}" _n

local s_sumneg  : display %6.3f scalar(sum_neg)
local s_meanneg : display %6.3f scalar(mean_neg)
local s_shneg   : display %6.3f scalar(sh_neg)
local s_sumpos  : display %6.3f scalar(sum_pos)
local s_meanpos : display %6.3f scalar(mean_pos)
local s_shpos   : display %6.3f scalar(sh_pos)

file write tex "Negative & `s_sumneg' & `s_meanneg' & `s_shneg' & & \\" _n
file write tex "Positive & `s_sumpos' & `s_meanpos' & `s_shpos' & & \\" _n
file write tex " & & & & & \\" _n

* ----- Panel B -----
file write tex "\multicolumn{6}{l}{\textbf{\textit{Panel B: Correlations}}} \\" _n
file write tex " & $\hat{\alpha}_k$ & $g_k$ & $\hat{\beta}_k$ & $\hat{F}_k$ & Var$(z_k)$ \\ \cline{2-6}" _n

local rn1 "$\hat{\alpha}_k$"
local rn2 "$g_k$"
local rn3 "$\hat{\beta}_k$"
local rn4 "$\hat{F}_k$"
local rn5 "Var$(z_k)$"

forvalues i = 1/5 {
    local line "`rn`i''"
    forvalues j = 1/5 {
        if (`j' == `i')      local line "`line' & 1.000"
        else if (`j' < `i') {
            scalar __tmp = C[`i',`j']
            local sval : display %6.3f scalar(__tmp)
            local line "`line' & `sval'"
        }
        else                 local line "`line' & "
    }
    if (`i' == 5) file write tex "`line' \\ [0.2em]" _n
    else          file write tex "`line' \\" _n
}
file write tex " & & & & & \\" _n

* ----- Panel C -----
file write tex "\multicolumn{6}{l}{\textbf{\textit{Panel C: Top 5 origin countries}}} \\" _n
file write tex " & $\hat{\alpha}_k$ & $g_k$ & $\hat{\beta}_k$ & 95\% C.I. & Share \\ \cline{2-6}" _n

forvalues r = 1/5 {
    local ctry   = country[`r']
    local sa     : display %6.3f alpha_hat[`r']
    local sg     : display %6.3f Gk[`r']
    local sb     : display %6.3f Beta[`r']
    local sci    = ci95[`r']
    local sshare : display %6.3f baseline_share[`r']
    file write tex "`ctry' & `sa' & `sg' & `sb' & `sci' & `sshare' \\" _n
}

file write tex "\hline\hline" _n
file write tex "\end{tabular}}" _n
file write tex "\begin{tablenotes}[flushleft]\scriptsize" _n
file write tex "\item \textit{Notes:} This table reports statistics about the Rotemberg weights, " _n
file write tex "following Goldsmith-Pinkham et al.\ (2020). " _n
file write tex "Panel A reports the sum, mean, and share of negative and positive Rotemberg weights $\hat{\alpha}_k$. " _n
file write tex "Panel B reports correlations between the weights ($\hat{\alpha}_k$), " _n
file write tex "the national component of immigrants ($g_k$), " _n
file write tex "the just-identified coefficients ($\hat{\beta}_k$), " _n
file write tex "the first-stage F-statistics ($\hat{F}_k$), " _n
file write tex "and the variance of origin country shares across LGAs (Var$(z_k)$). " _n
file write tex "Panel C reports the top five origin countries by Rotemberg weight; " _n
file write tex "95\% CIs are $\hat{\beta}_k \pm 1.96 \cdot \hat{se}_k$; " _n
file write tex "Share is each origin country's share of total immigrants ($g_k$) across all origin countries." _n
file write tex "The residual country group (ZZZ) is excluded from the table and figures only." _n
file write tex "\end{tablenotes}" _n
file write tex "\end{threeparttable}" _n
file write tex "\end{table}" _n

file close tex
restore
**********************************
list con_id country alpha_hat Beta KPF in 1/29, noobs
gsort -abs_alpha
br
********************************************************************************
* END
*************************************************************
