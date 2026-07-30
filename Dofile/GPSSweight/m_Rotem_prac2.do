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

***국가코드 
* 공유 접미사(국가코드) 목록 자동 수집: share91* 기준으로 뽑아 사용
drop share_cobAUS91 
drop share_cobZZZ91 

*********************************************
* 변수명 접미사를 con_id 숫자로 치환
*********************************************
* 국가 리스트와 순서 일치
local KLIST CAN CHN DEU EGY FJI GBR GRC HKG IDN IND IRL IRN IRQ ITA JPN KOR LBN LKA MYS NLD NZL PHL POL SGP THA USA VNM ZAF
local i = 1

foreach k of local KLIST {

    * share_cob 변수를 숫자 첨자로 변경
    capture confirm variable share_cob`k'91
    if !_rc rename share_cob`k'91 share_cob`i'_91

	* immi_kt 계열
    capture confirm variable immi_kt_`k'
    if !_rc rename immi_kt_`k' immi_kt_`i'
	
    * immi_kt_s 계열
    capture confirm variable immi_kt_`k'_s
    if !_rc rename immi_kt_`k'_s immi_kt_`i'_s

	* d_kt 계열
    capture confirm variable d_kt_`k'
    if !_rc rename d_kt_`k' d_kt_`i'
	
    * d_kt_s 계열
    capture confirm variable d_kt_`k'_s
    if !_rc rename d_kt_`k'_s d_kt_`i'_s

	* g_kt 계열
    capture confirm variable g_kt_`k'
    if !_rc rename g_kt_`k' g_kt_`i'
	
    * g_kt_s 계열
    capture confirm variable g_kt_`k'_s
    if !_rc rename g_kt_`k'_s g_kt_`i'_s

    local ++i
}

ds share_cob*91
display "`r(varlist)'"

ds immi_kt_*_s
display "`r(varlist)'"

**********************************
* STEP1: residualize y and x 
**********************************
qui xi: reg stem_fshare i.year i.LGAFINAL21 , cl(LGAFINAL21)
predict yhat, xb
gen p_t_res=stem_fshare-yhat

qui xi: reg d_kt_s i.year i.LGAFINAL21 , cl(LGAFINAL21)
predict xhat, xb
gen immigration_res=d_kt_s-xhat

save "Immi_res.dta", replace
***********************************************************
forv i = 1/28{
	gen rw_denom`i' = d_kt_`i'_s * share_cob`i'_91 * immigration_res
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

list rotem_sum // sum 이 1인지 확인 -> 거의 1에 가까움 
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

mkmat d_kt_1_s-d_kt_28_s in 1/1, matrix(Gr)

matrix G= Gr'

forvalues i = 1/28 {
	quietly ivreg2 p_t_res (immigration_res = share_cob`i'_91), cl(LGAFINAL21) first savefirst savefprefix(st`i') nocons
	est store reg`i'
	matrix B[`i',1]=_b[immigration_res]
	matrix KPF[`i',1]=e(widstat)
	matrix CDF[`i',1]=e(cdf)
}


esttab reg* using rotem_ivreg_stem.csv, nogap stats(N cdf arf arfp) title("Table: IV regression with each share") r2(%8.3f) b(%8.3f) se(%8.3f) star(* 0.10 ** 0.05 *** 0.01) replace
esttab st* using rotem_ivreg_stem.csv, nogap stats(N cdf arf arfp) title("Table: IV regression with each share") r2(%8.3f) b(%8.3f) se(%8.3f) star(* 0.10 ** 0.05 *** 0.01) append 

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
save "Rotemberg_results.dta", replace
******* 일단 여기서부터 코드 조정해봐야 함 
** 스케일 조정 
* 1) Beta 요약 후 평균/최솟값/최댓값 저장
summ Beta
scalar bmean = r(mean)
scalar bmin  = r(min)
scalar bmax  = r(max)

gen alpha_sum = sum(alpha_hat) // 1이 맞음 

drop if KPF < 1 
drop if KPF > 400 

scatter Beta KPF [w=abs_alpha] if alpha_hat >= 0, msymbol(Oh) || scatter Beta KPF [w=abs_alpha] if alpha_hat < 0, msymbol(Dh) legend(order(1 "Positive weights" 2 "Negative weights") pos(5) ring(0) size(small) region(fcolor(none) lcolor(black) lwidth(thin))) yline(0.036) xlabel(0(10)50, nogrid) ylabel(-0.2(0.1)0.2, nogrid)

scatter Beta CDF [w=abs_alpha] if alpha_hat >= 0, msymbol(Oh) || scatter Beta CDF [w=abs_alpha] if alpha_hat < 0, msymbol(Dh) legend(order(1 "Positive weights" 2 "Negative weights") pos(5) ring(0) size(small) region(fcolor(none) lcolor(black) lwidth(thin))) yline(-0.035) xlabel(0(20)80, nogrid) ylabel(-0.8(0.1)0.1, nogrid)
