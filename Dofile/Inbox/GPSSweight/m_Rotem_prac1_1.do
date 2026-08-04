********************************************************************************
* Rotemberg weights 계산 및 그래프 그리기

* Immigration and Manufacutring share (ABS)
********************************************************************************
* 국가명별로 id 매기고 데이터 만ㄷ들 
* 국가 코드 리스트
local KLIST CAN CHN DEU EGY FJI GBR GRC HKG IDN IND IRL IRN IRQ ITA JPN KOR LBN LKA MYS NLD NZL PHL POL SGP THA USA VNM ZAF ZZZ

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
local KLIST CAN CHN DEU EGY FJI GBR GRC HKG IDN IND IRL IRN IRQ ITA JPN KOR LBN LKA MYS NLD NZL PHL POL SGP THA USA VNM ZAF ZZZ
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
********************************
***************** 필요한 변수 생성
****** college_share 
/*
** 대졸자 여성 수
gen fe_college = fe_bach + fe_grad + fe_postgrad 
gen ma_college = ma_bach + ma_grad + ma_postgrad 

* 대졸자 수 
gen college = bach + grad + postgrad 
*/

* 여성 대졸자 비율 
gen share_fe_college = fe_collegeov / fe_popfifteen 
* 남성 대졸자 비율 
gen share_ma_college = ma_collegeov / ma_popfifteen
* 대졸자 비율 
gen share_college = collegeov / popfifteen 

* 여성 준학사이상 비율  
gen share_fe_dip = fe_dipov / fe_popfifteen 
* 남성 준학사이상 비율  
gen share_ma_dip = ma_dipov / ma_popfifteen
* 준학사이상 비율  
gen share_dip = dipov / popfifteen 

**********labor market outcomes 
* unemployment rate 
gen unempl_rate = unemployed/labor_force 
gen ma_unempl_rate = ma_unemployed/ma_labor_force 
gen fe_unempl_rate = fe_unemployed/fe_labor_force 

* 전문직종 종사자 share 
gen prof_share = boss/tot35

* 전문직종 종사자 남성 share 
gen ma_prof_share = boss_male/tot35_male 

* 전문직종 종사자 여성 share 
gen fe_prof_share = boss_female/tot35_female 

/*
* STEM 전체 share 
gen stem_share = stem_t / dipov

* STEM 남성 share
gen ma_stem_share = stem_m / ma_dipov

* STEM 여성 share 
gen fe_stem_share = stem_f / fe_dipov
*/

* STEM 전체 share 
gen stem_share = stem_t / popfifteen

* STEM 남성 share
gen ma_stem_share = stem_m / ma_popfifteen

* STEM 여성 share 
gen fe_stem_share = stem_f / fe_popfifteen

*** manufacturing share 
// manu_share

** 여성 manu_share 
gen fe_manu_share = manu_female / totindus_female

** 남성 manu_share 
gen ma_manu_share = manu_male / totindus_male

**** service share 
// serv_share 

* 여성 female share 
gen fe_serv_share = service_female / totindus_female 

* 남성 male share  
gen ma_serv_share = service_male / totindus_male  

** 여성임금이 상위 가구비율 
// share_fehigh

gen highsame = same + fehigh 
gen share_highsame = highsame / tot_fam 

gen share_popfifteen = popfifteen / pop 
gen share_popfifold = popfifold / pop 
***************************************lagged variable 
sort LGAFINAL21 year 
tsset LGAFINAL21 year, delta(5)

gen lag_year = L1.year

local varlist ///
    share_fe_college share_ma_college share_college ///
    unempl_rate ma_unempl_rate fe_unempl_rate ///
    prof_share ma_prof_share fe_prof_share ///
    stem_share ma_stem_share fe_stem_share ///
    manu_share ma_manu_share fe_manu_share ///
    serv_share ma_serv_share fe_serv_share ///
    share_fehigh share_highsame ///
	unemployed college labor_force popfifteen popfifold share_popfifteen share_popfifold

sort LGAFINAL21 year 
foreach v of local varlist {
	gen diff_`v' = `v' - L1.`v'
	
	gen grow_`v' = (`v' - L1.`v')/L1.`v'
}

order LGAFINAL21 year
order grow* diff*, last

global fixed i.year 
global demo L1.share_popfifold L1.share_college
global demo2 L1.share_popfifold 

gen sample = 1 if lag_year>=1996&lag_year<=2016

label var Xit2 "growth rate"
label var Xit3 "difference"
label var Zit2 "growth rate"
label var Zit3 "difference"
**********************************
* STEP1: residualize y and x 
**********************************
drop sample 
xi: xtreg grow_unempl_rate $demo i.year if lag_year >=1996 & lag_year<=2016, fe cl(LGAFINAL21)
gen sample=e(sample)
predict yhat, xb
gen p_t_res=grow_unempl_rate-yhat

xi: xtreg Xit2 i.year if lag_year >=1996 & lag_year<=2016&sample==1, fe cl(LGAFINAL21) //샘플수 2480개라서 2474개로 맞추기 
predict xhat, xb
gen immigration_res=Xit2-xhat

/*
qui xi: reg grow_unempl_rate $demo i.year i.LGAFINAL21 if lag_year >=1996 & lag_year<=2016, cl(LGAFINAL21)
predict yhat, xb
gen p_t_res=grow_unempl_rate-yhat

qui xi: reg Xit2 i.year i.LGAFINAL21 if lag_year >=1996 & lag_year<=2016, cl(LGAFINAL21)
predict xhat, xb
gen immigration_res=Xit2-xhat
*/

forvalues i=1/29{
	gen sg`i' = shift91`i' * g_kt2`i' 
}

egen z_iv = rowtotal(sg*)

save "Immi_res.dta", replace
 
***********************************************************
forv i = 1/29{
	gen rw_denom`i' = g_kt2`i' * shift91`i' * immigration_res
}

egen rw_denom_sum = rowtotal(rw_denom*)
collapse (sum) rw_denom*

forv i = 1/29{
	gen rotem`i' = rw_denom`i'/rw_denom_sum
}


keep rotem*
**********************************
* Rotemberg weight만 matrix로 남기기 
**********************************
mkmat rotem1-rotem29 in 1/1, matrix(Rot)
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
matrix B = J(29,1,.)
matrix KPF = J(29,1,.)
matrix CDF = J(29,1,.)

mkmat g_kt21-g_kt229 in 1/1, matrix(Gr)

matrix G= Gr'

ivreg2 p_t_res (immigration_res = z_iv) i.year $demo if lag_year>=1996 & lag_year<=2016, cl(LGAFINAL21) first savefirst savefprefix(st`i') 

/*
xi: xtivreg2 grow_unempl_rate (Xit2 = z_iv) $demo i.year  if lag_year>=1996 & lag_year<=2016, fe cl(LGAFINAL21) first savefirst savefprefix(st`i') 

xi: xtivreg2 p_t_res (immigration_res = shift912) if lag_year>=1996 & lag_year<=2016, cl(LGAFINAL21) first savefirst savefprefix(st`i') 

ivreg2 p_t_res (immigration_res = shift913) if lag_year>=1996 & lag_year<=2016, cl(LGAFINAL21) first savefirst savefprefix(st`i') nocons

ivreg2 p_t_res (immigration_res = shift914) if lag_year>=1996 & lag_year<=2016, cl(LGAFINAL21) first savefirst savefprefix(st`i') nocons

ivreg2 p_t_res (immigration_res = shift915)  if lag_year>=1996 & lag_year<=2016, cl(LGAFINAL21) first savefirst savefprefix(st`i') nocons

ivreg2 p_t_res (immigration_res = shift916)  if lag_year>=1996 & lag_year<=2016, cl(LGAFINAL21) first savefirst savefprefix(st`i') nocons

ivreg2 p_t_res (immigration_res = shift917)  if lag_year>=1996 & lag_year<=2016, cl(LGAFINAL21) first savefirst savefprefix(st`i') nocons
*/


forvalues i = 1/29 {
	ivreg2 p_t_res (immigration_res = shift91`i') if lag_year>=1996 & lag_year<=2016, cl(LGAFINAL21) first savefirst savefprefix(st`i') nocons
	est store reg`i'
	matrix B[`i',1]=_b[immigration_res]
	matrix KPF[`i',1]=e(widstat)
	matrix CDF[`i',1]=e(cdf)
}

esttab reg* using rotem_ivreg_manu.csv, nogap stats(N cdf arf arfp) title("Table: IV regression with each share") r2(%8.3f) b(%8.3f) se(%8.3f) star(* 0.10 ** 0.05 *** 0.01) replace
esttab st* using rotem_ivreg_manu.csv, nogap stats(N cdf arf arfp) title("Table: IV regression with each share") r2(%8.3f) b(%8.3f) se(%8.3f) star(* 0.10 ** 0.05 *** 0.01) append 

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

scatter Beta KPF [w=abs_alpha] if alpha_hat >= 0, msymbol(Oh) || scatter Beta KPF [w=abs_alpha] if alpha_hat < 0, msymbol(Dh) legend(order(1 "Positive weights" 2 "Negative weights") pos(5) ring(0) size(small) region(fcolor(none) lcolor(black) lwidth(thin))) yline(0.003) xlabel(0(10)50, nogrid) ylabel(-0.8(0.1)0.1, nogrid)

scatter Beta CDF [w=abs_alpha] if alpha_hat >= 0, msymbol(Oh) || scatter Beta CDF [w=abs_alpha] if alpha_hat < 0, msymbol(Dh) legend(order(1 "Positive weights" 2 "Negative weights") pos(5) ring(0) size(small) region(fcolor(none) lcolor(black) lwidth(thin))) yline(-0.035) xlabel(0(20)80, nogrid) ylabel(-0.8(0.1)0.1, nogrid)

