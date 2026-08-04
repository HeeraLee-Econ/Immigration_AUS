********************************************************************************
* Rotemberg weights 계산 및 그래프 그리기
* Data: Economic Connectedness (social capital) and immigration
********************************************************************************

**********************************
* 디렉토리 
**********************************
cd "D:\Dropbox\0_08_External_research_projects\2025_재정네트워크\Rotem"

**********************************
* 데이터 불러오기
**********************************

use "Immi_practice.dta", clear

**********************************
* residualize y and x
**********************************
qui xi: reg soc_cap i.statefip, cl(statefip)
predict yhat, xb
gen soc_cap_res=soc_cap-yhat

qui xi: reg immigration i.statefip, cl(statefip)
predict xhat, xb
gen immigration_res=immigration-xhat

**********************************
* GPSS IV
**********************************
forvalues i=1(1)49 {
	gen sg`i'=share1960s`i'*g`i'
}
egen z_iv=rowtotal(sg*)

save "Immi_practice_resid.dta", replace

ivreg2 soc_cap_res (immigration_res = z_iv), cl(statefip) first
weakivtest

**********************************
* Rotemberg weight 계산
* 코드는 Goldsmith-Pinkham 의 bartik_weight 코드 이용할 때와 같은 결과 도출
* bartik_weight, y(soc_cap_res) x(immigration_res) z(share1960s*) weightstub(g*)
* mat A=r(alpha)
* mat list A  
**********************************

forv i = 1/49{
	gen rw_denom`i' = g`i'*share1960s`i'*immigration_res
}

egen rw_denom_sum = rowtotal(rw_denom*)
collapse (sum) rw_denom*

forv i = 1/49{
	gen rotem`i' = rw_denom`i'/rw_denom_sum
}

keep rotem*

**********************************
* Rotemberg weight만 matrix로 남기기
**********************************

mkmat rotem1-rotem49 in 1/1, matrix(Rot)
mat Rotem=Rot'

**********************************
* Beta_k (각각의 share로 IV regression 한 추정치
**********************************

use  "Immi_practice_resid.dta", clear

**********************************
* B: Beta_k, KPF: Kleibergen-Paap F = Olea-Montiel & Pflueger F 
* (when there is only one endog x and one z)
* CDF: Cragg-Donald, G: g_k (shocks)
**********************************

matrix B = J(49,1,.)
matrix KPF = J(49,1,.)
matrix CDF = J(49,1,.)

mkmat g1-g49 in 1/1, matrix(Gr)

matrix G= Gr'

forvalues i = 1/49 {
	quietly ivreg2 soc_cap_res (immigration_res = share1960s`i'), cl(statefip) first savefirst savefprefix(st`i') nocons
	est store reg`i'
	matrix B[`i',1]=_b[immigration_res]
	matrix KPF[`i',1]=e(widstat)
	matrix CDF[`i',1]=e(cdf)
}

*esttab reg* using rotem_ivreg_sc_1960s.csv, nogap stats(N cdf arf arfp) title("Table: IV regression with each share") r2(%8.3f) b(%8.3f) se(%8.3f) star(* 0.10 ** 0.05 *** 0.01) replace
*esttab st* using rotem_ivreg_sc_1960s.csv, nogap stats(N r2) title("Table: IV regression with each share") r2(%8.3f) b(%8.3f) se(%8.3f) star(* 0.10 ** 0.05 *** 0.01) append

**********************************
* Matrix로 정리한 후, 데이터에 변수들로 추가
**********************************

matrix ALL= A, Rotem, B, KPF, CDF, G
matrix colnames ALL = alpha_hat0 alpha_hat1 Beta KPF CDF Gk
svmat double ALL, names(col)

* matrix list Rotem
* matrix list B
* matrix list KPF
* matrix list CDF
* matrix list Gr

local K = rowsof(ALL)
keep alpha_hat* Beta KPF CDF Gk 
keep in 1/`K'
gen abs_alpha=abs(alpha_hat0)

**********************************
* Check coefficient equivalence
**********************************
 gen ab= alpha_hat1*Beta
 egen beta_gpss=sum(ab)
 
**********************************

**********************************
* 미리 준비한 국가명(countries of origin) 리스트 
**********************************

gen bpl_final= _n

merge 1:1 bpl_final using "BPL_countries.dta"
drop _merge

save "Rotemberg_results_nopop.dta", replace

********************************************
* 그래프 작성, extreme 값 삭제 후 draw, 단순한 버전
********************************************

* sum (check min and max of beta and KPF)
* GPSS estimate 확인
quietly sum ab
local bg = r(sum)
disp "`bg'"
 
drop if KPF<10
*drop if KPF>400

* Positive weight만 있을 경우
scatter Beta KPF [w=abs_alpha] if alpha_hat0 >= 0, msymbol(Oh) legend(order(1 "Positive weights" 2 "Negative weights") pos(5) ring(0) size(small) region(fcolor(none) lcolor(black) lwidth(thin))) yline(`bg') xlabel(0(10)50, nogrid) ylabel(-2(0.5)2, nogrid) 

* Positive와 negative가 모두 있을 경우
scatter Beta KPF [w=abs_alpha] if alpha_hat1 >= 0, msymbol(Oh) || scatter Beta KPF [w=abs_alpha] if alpha_hat1 < 0, msymbol(Dh) legend(order(1 "Positive weights" 2 "Negative weights") pos(5) ring(0) size(small) region(fcolor(none) lcolor(black) lwidth(thin))) yline(-1) xlabel(0(10)50, nogrid) ylabel(-10(2)10, nogrid)

scatter Beta CDF [w=abs_alpha] if alpha_hat1 >= 0, msymbol(Oh) || scatter Beta CDF [w=abs_alpha] if alpha_hat1 < 0, msymbol(Dh) legend(order(1 "Positive weights" 2 "Negative weights") pos(5) ring(0) size(small) region(fcolor(none) lcolor(black) lwidth(thin))) yline(-1.312) xlabel(0(20)80, nogrid) ylabel(-6(2)6, nogrid)


********************************************
* 그래프 작성, extreme 값 삭제 후 draw, full 버전
********************************************

* Weight 부호 확인하지 않고 그리기
* GPSS estimate 확인
quietly sum ab
local bg = r(sum)
disp "`bg'"


* 1) 표본 수 체크 (결측 제외)
quietly count if alpha_hat1 >= 0 & !missing(Beta, KPF, abs_alpha)
local Npos = r(N)

quietly count if alpha_hat1 < 0  & !missing(Beta, KPF, abs_alpha)
local Nneg = r(N)

* 2) 그릴 플롯 목록을 동적으로 구성
local plots
if `Npos' > 0 {
    local plots `plots' (scatter Beta KPF if alpha_hat1 >= 0 [aw=abs_alpha], msymbol(Oh))
}
if `Nneg' > 0 {
    local plots `plots' (scatter Beta KPF if alpha_hat1 < 0  [aw=abs_alpha], msymbol(Dh))
}

* 3) 범례 옵션 구성 (존재하는 시리즈만 라벨링)
local legpos "pos(5) ring(0) size(small) region(fcolor(none) lcolor(black) lwidth(thin))"
local legopt
if `Npos' > 0 & `Nneg' > 0 {
    local legopt legend(order(1 "Positive weights" 2 "Negative weights") `legpos')
}
else if `Npos' > 0 {
    local legopt legend(label(1 "Positive weights") `legpos')
}
else if `Nneg' > 0 {
    local legopt legend(label(1 "Negative weights") `legpos')
}
else {
    di as err "No observations to plot."
    exit
}

* 4) 최종 그래프
twoway `plots', ///
    `legopt' ///
    yline(-1) ///
    xlabel(0(10)50, nogrid) ///
    ylabel(-2(0.5)2, nogrid)
