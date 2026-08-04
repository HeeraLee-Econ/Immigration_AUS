********************************************************************************
* Rotemberg weights 계산 및 그래프 그리기

* Immigration and Manufacutring share (ABS)
********************************************************************************
* 국가명별로 id 매기고 데이터 만ㄷ들 
* 국가 코드 리스트
local KLIST CAN CHN DEU EGY FJI GBR GRC HKG IDN IND IRL IRN IRQ ITA JPN KOR LBN LKA MYS NLD NZL PHL POL SGP THA USA VNM ZAF

* 국가 코드 매핑용 데이터셋 만들기
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

* 디렉토리 
**********************************
cd "/Users/ihuila/Desktop/data/2025ABS/afterIV"

** IV + 로템 + Y변수 merge 
use "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_rotem.dta", clear

merge m:1 LGAFINAL21 year using "/Users/ihuila/Desktop/data/2025ABS/cob_XYZ_final.dta"

drop _merge 

save "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_rotem_final.dta", replace 
**********************************
* Share divided by pop_i0
**********************************
use "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_rotem_final.dta", clear 

drop if year==1991 // 1991년도는 분석 샘플에 미포함 

drop shift91AUS
********************************************
* 변수명 접미사를 con_id 숫자로 치환
*********************************************
* 국가 리스트와 순서 일치
local KLIST CAN CHN DEU EGY FJI GBR GRC HKG IDN IND IRL IRN IRQ ITA JPN KOR LBN LKA MYS NLD NZL PHL POL SGP THA USA VNM ZAF
local i = 1

foreach k of local KLIST {

    * shift 91 
    capture confirm variable shift91`k'
    if !_rc rename shift91`k' shift91`i'

	* g_kt2 
    capture confirm variable g_kt2`k'
    if !_rc rename g_kt2`k' g_kt2`i'
	
    * g_kt3 
    capture confirm variable g_kt3`k'
    if !_rc rename g_kt3`k' g_kt3`i'

    local ++i
}

ds shift91* 
display "`r(varlist)'"

ds g_kt2*
display "`r(varlist)'"
**********************************
* STEP0: 종속변수 갈음 
sort LGAFINAL21 year 
xtset LGAFINAL21 year 
********************************필요한 변수 생성 **********
********************** control variable 
** number of college graduates 
gen college = bach + grad + postgrad 

** number of female college graduates 
gen fe_college = fe_bach + fe_grad + fe_postgrad 

** share of college graduates 
gen share_college = collegeov / popfifteen

** share of female college graduates 
gen share_fe_college = fe_collegeov / fe_popfifteen 

* 15세 이상 인구 share 
gen share_popfifteen = popfifteen / pop 

* 15-64세 인구 share 
gen share_popfifold = popfifold / pop 

********************** outcome variable - share 
* unemployment rate 
gen unempl_rate = unemployed/labor_force 
gen fe_unempl_rate = fe_unemployed/fe_labor_force 
gen ma_unempl_rate = ma_unemployed/ma_labor_force 

* manufacutring share 
gen manu_share =  manu_tot / labor_force 
gen fe_manu_share = manu_female / fe_labor_force 
gen ma_manu_share = manu_male / ma_labor_force 

** service share 
gen serv_share = service_tot / labor_force 
gen fe_serv_share = service_female / fe_labor_force 
gen ma_serv_share = service_male / ma_labor_force 

* 세부 서비스산업 
gen consum_serv_share = consum_serv / labor_force 
gen produc_serv_share = produc_serv / labor_force 
gen public_serv_share = public_serv / labor_force 

gen consum_serv_feshare = consum_serv_fe / fe_labor_force 
gen produc_serv_feshare = produc_serv_fe / fe_labor_force 
gen public_serv_feshare = public_serv_fe / fe_labor_force 

gen consum_serv_mashare = consum_serv_ma / ma_labor_force 
gen produc_serv_mashare = produc_serv_ma / ma_labor_force 
gen public_serv_mashare = public_serv_ma / ma_labor_force 

* job by skill-level 
gen highsk_share = highsk_tot / labor_force 
gen midsk_share =  midsk_tot / labor_force 
gen lowsk_share =  lowsk_tot / labor_force 

gen highsk_feshare = highsk_female / fe_labor_force 
gen midsk_feshare =  midsk_female / fe_labor_force 
gen lowsk_feshare =  lowsk_female / fe_labor_force 

gen highsk_mashare = highsk_male / ma_labor_force 
gen midsk_mashare =  midsk_male / ma_labor_force 
gen lowsk_mashare =  lowsk_male / ma_labor_force 
*********************************************************
sort LGAFINAL21 year 
tsset LGAFINAL21 year, delta(5)

gen lag_year = L1.year
************************************outcome variable - growth rate 
******share of (ver2.4) -> version 2.1 의 변주인데 분모를 labor force로 통일시킴 
local sharevar ///
    unempl_rate ma_unempl_rate fe_unempl_rate ///
    manu_share ma_manu_share fe_manu_share ///
    serv_share ma_serv_share fe_serv_share ///
	consum_serv_share consum_serv_mashare consum_serv_feshare /// 
	produc_serv_share produc_serv_mashare  produc_serv_feshare /// 
	public_serv_share public_serv_mashare public_serv_feshare /// 
	highsk_share highsk_mashare highsk_feshare /// 
	midsk_share midsk_mashare midsk_feshare /// 
	lowsk_share lowsk_mashare lowsk_feshare 
	
foreach v of local sharevar { 
	gen grow`v' = (`v' - L1.`v')/L1.`v'
	label var grow`v' "outcome var(ver2.4.)"
}

*********************************outcome variable - log (ver2.3) 
global fixed i.year 
global demo L1.share_popfifold L1.share_college

gen sample = 1 if lag_year>=1996&lag_year<=2016


**********************************
* STEP1: residualize y and x 
*********************************
********
* 김준성: 저는 lagged variable을 따로 만들었고, year더미도 따로 만들었는데 원래 희라학생이 했던 방법대로 해도 상관은 없을 것 같아요.
* sample도 미리 drop해서 2474개 observation만 남겼습니다.
sort LGAFINAL21 year
by LGAFINAL21: gen D1_share_popfifold=share_popfifold-share_popfifold[_n-1]
by LGAFINAL21: gen D1_share_college=share_college-share_college[_n-1]

keep if lag_year >=1996 & lag_year<=2016
drop if growunempl_rate ==. 

tabulate year, generate(year_)
********

* residualize 
xi: reg growunempl_rate D1_share_popfifold D1_share_college year_2-year_5 i.LGAFINAL21, cl(LGAFINAL21)
predict yhat, xb
gen p_t_res=growunempl_rate-yhat

xi: reg Xit2_other D1_share_popfifold D1_share_college year_2-year_5 i.LGAFINAL21, cl(LGAFINAL21) //샘플수 2480개라서 2474개로 맞추기 
predict xhat, xb
gen immigration_res=Xit2_other-xhat


forvalues i=1/28{
	gen sg`i' = shift91`i' * g_kt2`i' 
}

egen z_iv = rowtotal(sg*)

save "Immi_res.dta", replace
 
***********************************************************
forv i = 1/28{
	gen rw_denom`i' = g_kt2`i' * shift91`i' * immigration_res
}

egen rw_denom_sum = rowtotal(rw_denom*)
collapse (sum) rw_denom*

forv i = 1/28{
	gen rotem`i' = rw_denom`i'/rw_denom_sum
}


keep rotem*
**********************************
* Rotemberg weight만 matrix로 남기기 
**********************************
mkmat rotem1-rotem28 in 1/1, matrix(Rot)
mat Rotem=Rot'

egen rotem_sum = rowtotal(rotem*)

list rotem_sum // sum 이 1인지 확인 -> 합이 1임 
**********************************
* Beta_k (각각의 share로 IV regression 한 추정치
**********************************
cd "/Users/ihuila/Desktop/data/2025ABS/afterIV"
use  "Immi_res.dta", clear 
**********************************
* B: Beta_k, KPF: Kleibergen-Paap F = Olea-Montiel & Pflueger F 
* (when there is only one endog x and one z)
* CDF: Cragg-Donald, G: g_k (shocks)
**********************************
matrix B = J(28,1,.)
matrix KPF = J(28,1,.)
matrix CDF = J(28,1,.)

local gvars
forvalues i = 1/28 {
    local gvars `gvars' g_kt2`i'
}

mkmat `gvars' in 1/1, matrix(Gr)
matrix G = Gr'

* 김준성: bb1~bb29까지를 91년 share에 g_kt를 곱한 것으로 만들었어요. 이걸 각각의 IV로 써서 해 보세요~
forvalues i=1(1)28 {
	gen bb`i'= g_kt2`i' * shift91`i'
} 

ivreg2 p_t_res (immigration_res = z_iv) , cl(LGAFINAL21) first savefirst savefprefix(st`i') 

xtivreg28 growunempl_rate (Xit2_other = z_iv) D1_share_popfifold D1_share_college year_2-year_5, fe cl(LGAFINAL21) first savefirst savefprefix(st`i') 


cd "/Users/ihuila/Desktop/data/2025ABS/afterIV/rotem/robustness"
est clear

forvalues i = 1/28 {
	* 김준성: nocons 옵션을 아래에서 없앴습니다
	ivreg2 p_t_res (immigration_res = bb`i'), cl(LGAFINAL21) first savefirst savefprefix(st`i') 
	est store reg`i'
	matrix B[`i',1]=_b[immigration_res]
	matrix KPF[`i',1]=e(widstat)
	matrix CDF[`i',1]=e(cdf)
}

esttab reg* using rotem_ivreg_unempl.csv, nogap stats(N cdf arf arfp widstat) title("Table: IV regression with each share") r2(%8.3f) b(%8.3f) se(%8.3f) star(* 0.10 ** 0.05 *** 0.01) replace
esttab st* using rotem_ivreg_unempl.csv, nogap stats(N cdf arf arfp) title("Table: IV regression with each share") r2(%8.3f) b(%8.3f) se(%8.3f) star(* 0.10 ** 0.05 *** 0.01) append 

**********************************
* Matrix로 정리한 후, 데이터에 변수들로 추가
**********************************
* 이제 결합 (괄호 필수, 대소문자 주의)
matrix ALL = (Rotem, B, KPF, CDF, G) 
matrix colnames ALL = alpha_hat Beta KPF CDF Gk
svmat double ALL, names(col)

local K = rowsof(ALL)
keep alpha_hat Beta KPF CDF Gk 
keep in 1/`K'

gen abs_alpha=abs(alpha_hat)
**********************************
* 미리 준비한 국가명 (countries of origin) 리스트 
**********************************
gen con_id = _n
merge 1:1 con_id using "/Users/ihuila/Desktop/data/2025ABS/afterIV/country_id.dta"

drop _merge 
save "Rotemberg_unempl_results.dta", replace
******* 일단 여기서부터 코드 조정해봐야 함 
** 스케일 조정 
* 1) Beta 요약 후 평균/최솟값/최댓값 저장
summ Beta
scalar bmean = r(mean)
scalar bmin  = r(min)
scalar bmax  = r(max)

gen alpha_sum = sum(alpha_hat) // 1이 맞음 

drop if KPF < 5
drop if KPF > 400 

scatter Beta KPF [w=abs_alpha] if alpha_hat >= 0, msymbol(Oh) || scatter Beta KPF [w=abs_alpha] if alpha_hat < 0, msymbol(Dh) legend(order(1 "Positive weights" 2 "Negative weights") pos(5) ring(0) size(small) region(fcolor(none) lcolor(black) lwidth(thin))) yline(-0.62309) xlabel(0(10)50, nogrid) ylabel(-20(10)30, nogrid)

*scatter Beta CDF [w=abs_alpha] if alpha_hat >= 0, msymbol(Oh) || scatter Beta CDF [w=abs_alpha] if alpha_hat < 0, msymbol(Dh) legend(order(1 "Positive weights" 2 "Negative weights") pos(5) ring(0) size(small) region(fcolor(none) lcolor(black) lwidth(thin))) yline(-0.035) xlabel(0(20)80, nogrid) ylabel(-0.8(0.1)0.1, nogrid)

