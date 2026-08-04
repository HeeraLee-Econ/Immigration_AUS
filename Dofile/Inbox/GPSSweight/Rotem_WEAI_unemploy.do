********************************************************************************
* Rotemberg weights 계산 및 그래프/표 Overleaf export (ONE-PIECE DOFILE)
* Immigration and Manufacturing share (ABS)
********************************************************************************

**********************************
* 국가명별로 id 매기고 데이터 만들기
**********************************
* 국가 코드 리스트
local KLIST CAN CHN DEU EGY FJI GBR GRC HKG IDN IND IRL IRN IRQ ITA JPN KOR LBN LKA MYS NLD NZL PHL POL SGP THA USA VNM ZAF ZZZ

* (참고) 기존처럼 country_id.dta를 만들고 저장도 해두되,
*       최종 매칭은 _n 기반 merge가 아니라 KLIST로 직접 주입(안전)합니다.
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

//drop if year==1991
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

	* shift91_new 
	capture confirm variable shift91`k'_new 
    if !_rc rename shift91`k'_new shift91`i'_new
	
    * g_kt
    capture confirm variable g_kt`k'
    if !_rc rename g_kt`k' g_kt`i'

    local ++i
}

ds shift91*
display "`r(varlist)'"
ds shift91*_new 
display "`r(varlist)'"
ds g_kt*
display "`r(varlist)'"
**********************************
* STEP0: 종속변수 갈음
**********************************
sort LGAFINAL21 year
xtset LGAFINAL21 year

**********************************
* 필요한 변수 생성 (control/outcome)
**********************************
***********1. marriage rate 
gen mar_male20 = mar_male2 + mar_male3 + mar_male4  // 20-34세 결혼한 남성
gen mar_female20 = mar_female2 + mar_female3 + mar_female4  // 20-34세 결혼한 여성 
gen mar_to20 = mar_male20 + mar_female20 

gen male20 = to_male2 + to_male3 + to_male4  // 전체 20-34세 남성 
gen female20 = to_female2 + to_female3 + to_female4  // 전체 20-34세 여성 
gen to20 = male20 + female20 

// marriage rate 
gen share_marmale = mar_male20/ male20 
gen share_marfemale = mar_female20/ female20 
gen share_mar =  mar_to20 / to20

// check 
count if share_marmale > 1 
count if share_marfemale > 1
count if share_mar > 1 

br if share_marmale > 1 // 결측, LGAFINAL21 : 5107 - 20-34세 남성 x 
br if share_marfemale > 1 // 결측 LGAFINAL21 : 5107 - 20-34세 여성 x 
br if share_mar > 1 // 결측 LGAFINAL21 : 5107 - 20-34세 여성 x 
*********************************************************************
***********2. unemployment rate 
gen college = bach + grad + postgrad
gen fe_college = fe_bach + fe_grad + fe_postgrad

gen share_college = collegeov / popfifteen
gen share_fe_college = fe_collegeov / fe_popfifteen

gen share_popfifteen = popfifteen / pop
gen share_popfifold  = popfifold  / pop

gen unempl_rate = unemployed/labor_force
gen ma_unempl_rate = ma_unemployed / ma_labor_force 
gen fe_unempl_rate = fe_unemployed / fe_labor_force 

// check 
count if share_college > 1 // 없음 
count if share_popfifold > 1 // 없음 
count if share_fe_college > 1 // 없음 

count if unempl_rate > 1 // 없음 
count if ma_unempl_rate > 1 // 없음 
count if fe_unempl_rate > 1 // 없음 
**************************************
sort LGAFINAL21 year
tsset LGAFINAL21 year, delta(5)

//gen lag_year = L1.year

global fixed i.year
global demo L1.share_popfifold L1.share_college 

gen sample = 1 if year>=1996 & year<=2021 
**********************************
* STEP1: residualize y and x
**********************************
/*
sort LGAFINAL21 year
by LGAFINAL21: gen D1_share_popfifold = share_popfifold - share_popfifold[_n-1]
by LGAFINAL21: gen D1_share_college   = share_college   - share_college[_n-1]

keep if lag_year>=1996 & lag_year<=2016
drop if growempl_rate1 == .
*/

tabulate year, generate(year_)

* residualize y
xi: reg unempl_rate $demo year_2-year_7 i.LGAFINAL21, cl(LGAFINAL21)
predict yhat, xb
gen p_t_res = unempl_rate - yhat

* residualize x
xi: reg Xit $demo year_2-year_7 i.LGAFINAL21, cl(LGAFINAL21)
predict xhat, xb
gen immigration_res = Xit - xhat

* z_iv = sum_k (shift91k * g_kt k)
forvalues i=1/29{
    gen sg`i' = shift91`i'_new * g_kt`i'
}
egen z_iv = rowtotal(sg*)

save "Immi_res.dta", replace
***********************************************************
* Rotemberg weights 계산
***********************************************************
forvalues i=1/29{
    gen rw_denom`i' = g_kt`i' * shift91`i'_new * immigration_res
}

egen rw_denom_sum = rowtotal(rw_denom*)
collapse (sum) rw_denom*

forvalues i=1/29{
    gen rotem`i' = rw_denom`i'/rw_denom_sum
}

keep rotem*

* Rotemberg weight만 matrix로 남기기
mkmat rotem1-rotem29 in 1/1, matrix(Rot)
matrix Rotem = Rot'

egen rotem_sum = rowtotal(rotem*)
list rotem_sum
**********************************
* Beta_k (각각의 share로 IV regression 한 추정치)
**********************************
cd "/Users/ihuila/Desktop/data/2025ABS/afterIV"
use "Immi_res.dta", clear

matrix B   = J(29,1,.)
matrix KPF = J(29,1,.)
matrix CDF = J(29,1,.)
matrix SEB = J(29,1,.)

local gvars
forvalues i = 1/29 {
    local gvars `gvars' g_kt`i'
}
mkmat `gvars' in 1/1, matrix(Gr)
matrix G = Gr'

* 각 k별 just-identified instrument bbk = g_kt2k * shift91k
forvalues i=1/29 {
    gen bb`i' = g_kt`i' * shift91`i'_new 
}

* 전체 Bartik(z_iv) 회귀 (figure yline용 overall beta 저장)
ivreg2 p_t_res (immigration_res = z_iv), cl(LGAFINAL21) first savefirst savefprefix(st_all)
scalar b_overall = _b[immigration_res]

cd "/Users/ihuila/Desktop/data/2025ABS/tables/rotem/unemploy"
est clear

forvalues i = 1/29 {
    ivreg2 p_t_res (immigration_res = bb`i'), cl(LGAFINAL21) first savefirst savefprefix(st`i')
    est store reg`i'
    matrix B[`i',1]   = _b[immigration_res]
	matrix SEB[`i',1] = _se[immigration_res]
    matrix KPF[`i',1] = e(widstat)
    matrix CDF[`i',1] = e(cdf)
}

esttab reg* using rotem_ivreg_unempl.csv, nogap ///
    stats(N cdf arf arfp widstat) title("Table: IV regression with each share") ///
    r2(%8.3f) b(%8.3f) se(%8.3f) star(* 0.10 ** 0.05 *** 0.01) replace

esttab st* using rotem_ivreg_unempl.csv, nogap ///
    stats(N cdf arf arfp) title("Table: IV regression with each share") ///
    r2(%8.3f) b(%8.3f) se(%8.3f) star(* 0.10 ** 0.05 *** 0.01) append

**********************************
* Matrix로 정리한 후, 데이터에 변수들로 추가
**********************************
matrix ALL = (Rotem, B, SEB, KPF, CDF, G)
matrix colnames ALL = alpha_hat Beta se_Beta KPF CDF Gk
svmat double ALL, names(col)

local K = rowsof(ALL)
keep alpha_hat Beta se_Beta KPF CDF Gk
keep in 1/`K'

* === QUICK CHECK: overall IV vs Rotemberg recomposition ===
gen double ab = alpha_hat * Beta
egen double b_rotem = total(ab)

display "overall IV coef        = " %10.6f b_overall
display "Rotemberg recomposed   = " %10.6f b_rotem[1]
display "difference             = " %10.8f (b_overall - b_rotem[1])

drop ab b_rotem
* === END CHECK ===

gen abs_alpha = abs(alpha_hat)

**********************************
* country 매칭 
**********************************
gen con_id = _n
gen str5 country = ""

local KLIST CAN CHN DEU EGY FJI GBR GRC HKG IDN IND IRL IRN IRQ ITA JPN KOR LBN LKA MYS NLD NZL PHL POL SGP THA USA VNM ZAF ZZZ
forvalues i=1/`K' {
    local cc : word `i' of `KLIST'
    replace country = "`cc'" in `i'
}

order con_id country alpha_hat abs_alpha Beta KPF CDF Gk
save "Rotemberg_unempl_results.dta", replace
**********************************
* Var(z_k) 계산 (baseline share shift91k의 지역 간 분산)
* - 기존 분석 바꾸지 않음: Immi_res.dta에서 year==1996만 사용해 variance 계산
**********************************
tempfile vz
preserve
use "/Users/ihuila/Desktop/data/2025ABS/afterIV/Immi_res.dta", clear
keep if year==1996 

* shift91k가 LGA별 baseline share라고 가정하고 분산 계산
keep LGAFINAL21 shift91*_new
collapse (sd) shift91*_new, by()

forvalues i=1/29 {
    gen varz`i' = shift91`i'_new^2
}
keep varz*
gen one = 1
reshape long varz, i(one) j(con_id)
drop one
rename varz Var_zk
save `vz', replace
restore

merge 1:1 con_id using `vz', nogen
**********************************
* Figure 1: Rotemberg bubble plot -> Overleaf export (PDF/EPS)
**********************************
preserve

drop if country == "ZZZ" // figure, table 에서만 빼고 분석에서는 포함 
drop if KPF < 5
drop if KPF > 400

summ abs_alpha if KPF >=5 & KPF <=400 
summ KPF Beta 

cd "/Users/ihuila/Desktop/data/2025ABS/tables/rotem/unemploy"
set scheme s2color

** 아래의 코드를 실행하고 -> 수동으로 negative weight 부분의 bubble 을 hide 한 후에 저장 
* 1) positive bubble plot을 일단 저장
twoway ///
    (scatter Beta KPF [aw=abs_alpha] if alpha_hat >= 0, ///
        msymbol(Oh) msize(*1) mcolor(navy) mlcolor(navy) mfcolor(none)), ///
    name(gpos, replace) nodraw

* 2) legend 전용 "negative" 키를 addplot로 붙이기
twoway ///
    (scatter Beta KPF [aw=abs_alpha] if alpha_hat >= 0, ///
        msymbol(Oh) msize(*1) mcolor(navy) mlcolor(navy) mfcolor(none)) ///
    (scatteri 0 0, msymbol(Dh) msize(*1) mcolor(maroon) mlcolor(maroon) mfcolor(none)), ///
    legend(on order(1 "Positive Weights" 2 "Negative Weights") ///
        pos(5) ring(0) size(small) region(fcolor(none) lcolor(black))) ///
    yline(`=b_overall', lpattern(dash) lcolor(black)) ///
    xtitle("First stage F-statistic") ///
    ytitle("{&beta}{sub:k} estimate") ///
    graphregion(color(white)) plotregion(color(white)) ///
    xlabel(0(10)50, nogrid) ///
	ylabel(-0.6(0.2)0.6, nogrid angle(0)) ///
	yscale(range(-0.6 0.6))

/*
graph export "fig_rotemberg_bubble.pdf", replace
graph export "fig_rotemberg_bubble.png", replace
*/

restore

**********************************
* Table (LaTeX): Correlations + Top5 Rotemberg weights  (SYNTAX-FIXED)
**********************************
preserve
drop if country=="ZZZ"

* Panel I correlations
corr alpha_hat Gk Beta KPF Var_zk
matrix C = r(C)

* Top5 (exclude ZZZ) + CI
gsort -abs_alpha
keep in 1/5

capture confirm variable se_Beta
if _rc {
    di as error "se_Beta not found. Include SEB in matrix ALL and keep se_Beta."
    error 111
}

gen double ci_lb = Beta - 1.96*se_Beta
gen double ci_ub = Beta + 1.96*se_Beta
gen str40 ci95 = "(" + string(ci_lb,"%6.3f") + "," + string(ci_ub,"%6.3f") + ")"

* ---- export .dta (verification)
save "/Users/ihuila/Desktop/data/2025ABS/tables/rotem/unemploy/panelII_top5_table.dta", replace

* ---- write LaTeX (single table)
cd "/Users/ihuila/Desktop/data/2025ABS/tables/rotem/unemploy"
capture file close tex
file open tex using "tab_rotemberg_summary.tex", write replace

file write tex "\begin{table}[H]\centering" _n
file write tex "\begin{threeparttable}" _n
file write tex "\caption{Summary of Rotemberg weights -- Employment}" _n
file write tex "\label{TA:rotem}" _n
file write tex "" _n

file write tex "{\small" _n
file write tex "\renewcommand{\arraystretch}{1}" _n
file write tex "\begin{tabular}{lccccc}" _n
file write tex "\hline\hline" _n

* ---------------- Panel A
file write tex "\multicolumn{6}{l}{\textbf{Panel A: Correlations}} \\" _n
file write tex " & $\hat{\alpha}_k$ & $g_k$ & $\hat{\beta}_k$ & $\hat{F}_k$ & Var$(z_k)$ \\ \cline{2-6}" _n

local rn1 "$\hat{\alpha}_k$"
local rn2 "$g_k$"
local rn3 "$\hat{\beta}_k$"
local rn4 "$\hat{F}_k$"
local rn5 "Var$(z_k)$"

forvalues i=1/5 {
    local line "`rn`i''"

    forvalues j=1/5 {
        if (`j'==`i') {
            local line "`line' &  1.000"
        }
        else if (`j' < `i') {
            scalar __tmp = C[`i',`j']
            local sval : display %6.3f __tmp
            local line "`line' & `sval'"
        }
        else {
            local line "`line' & "
        }
    }

    * last row has [0.2em] exactly like your template
    if (`i'==5) file write tex "`line' \\ [0.2em]" _n
    else        file write tex "`line' \\" _n
}

* ---------------- Panel B: Top5 origin countries 
file write tex "\multicolumn{6}{l}{\textbf{Panel B: Top 5 Rotemberg weight origin countries}} \\" _n
file write tex " & $\hat{\alpha}_k$ & $g_k$ & $\hat{\beta}_k$ & 95\% C.I. & \\ \cline{2-5}" _n

forvalues r=1/5 {
    local ctry = country[`r']
    local sa : display %6.3f alpha_hat[`r']
    local sg : display %6.3f Gk[`r']
    local sb : display %6.3f Beta[`r']
    local sci = ci95[`r']

    * keep 6 columns by leaving the last column empty
    file write tex "`ctry' &  `sa' &  `sg' &  `sb' & `sci' & \\" _n
}

file write tex "\hline\hline" _n
file write tex "\end{tabular}" _n
file write tex "}" _n

* =========================
* Notes (flushleft)
* =========================
file write tex "\begin{tablenotes}[flushleft]" _n
file write tex "\scriptsize" _n
file write tex "\item \textit{Notes:} The table reports statistics about the Rotemberg weights, following \jk{Goldsmith-Pinkham et al.(2020). Panel A reports correlations between the weights ($\hat{\alpha}_k$), the national component of immigrants ($g_k$), the first stage $F$-statistics for the just-identified IVs ($\hat{F}_k$), and the variance in the origin country shares across LGA (Var$(z_k)$). Panel B reports the top five origin countries according to the Rotemberg weights. The 95 effects CI are the weak instrument robust confidence intervals obtained with the Chernozhukov and Hansen (2008) method with a range from -10 to 10. The coefficients $\hat{\beta}_k$ are based on the regression of Table \ref{TA:Main2}, column 3, where the outcome is the change 1996--2021 in the stock of immigrants, and the control variables include the lagged share of college graduates and population aged 15 to 64. We computed the Rotemberg decomposition using Goldsmith-Pinkham et al.(2020).'s Stata package.} The Rotemberg decomposition is computed using the full set of origin countries, including the residual other countries group. For ease of presentation, this residual group is excluded from the table and figures only." _n
file write tex "\end{tablenotes}" _n

file write tex "" _n
file write tex "\end{threeparttable}" _n
file write tex "\end{table}" _n

file close tex
restore
**********************************
**********************************
list con_id country alpha_hat Beta KPF in 1/29, noobs

gsort -abs_alpha
br
********************************************************************************
* END
********************************************************************************
