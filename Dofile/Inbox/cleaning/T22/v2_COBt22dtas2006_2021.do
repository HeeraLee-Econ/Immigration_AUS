*************************************STEP 1: 지역코드 + Y 데이터 합치기 
*****************************LGAFINAL21 + COB2021 
clear all
set more off

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS8"

use v2_2016/cob_2016census_fin

append using v2_2021/cob_2021census_fin

collapse (sum) ch_ , by(LGAFINAL21 year inctyp inc_low inc_high hh_type)

tab year // 지역개수 안맞음 

* 안맞는 지역 
drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 

tab year 

ren ch_ hn

/*
drop if inctyp == 15 
drop if hh_type == "tot"
****************************************************
* 0) 정렬
****************************************************
sort LGAFINAL21 year hh_type inc_low

****************************************************
* 1) 그룹 총 가구수 / 누적도수
****************************************************
bys LGAFINAL21 year hh_type: egen double N = total(hn)
bys LGAFINAL21 year hh_type: gen  double cumN = sum(hn)
bys LGAFINAL21 year hh_type: gen  double cumN_prev = cond(_n==1, 0, cumN[_n-1])

****************************************************
* 2) p80 타깃 (상위 20% 시작점)
****************************************************
bys LGAFINAL21 year hh_type: gen double r80 = 0.80 * N

****************************************************
* 3) r80이 "걸리는" bin 표시
****************************************************
bys LGAFINAL21 year hh_type: gen byte hit80 = (cumN >= r80) & (cumN_prev < r80)

****************************************************
* 4) 상위20%에 포함되는 가구수 계산
*    - hit80 bin: (cumN - r80) 만큼만 포함 (bin 내부 선형 보간 가정)
*    - hit80 이후 bin: hn 전부 포함
****************************************************
gen double top20_count_part = .
replace top20_count_part = (cumN - r80) if hit80==1 & (cumN - cumN_prev)>0

gen double top20_count_full = .
replace top20_count_full = hn if cumN_prev >= r80

* top bin(inc_high==.)도 문제 없음: count 기반이라 width 필요 없음

bys LGAFINAL21 year hh_type: egen double top20_count = total(top20_count_part + top20_count_full)

****************************************************
* 5) "상위 20% 구간 share" (전체 가구 대비)
****************************************************
gen double top20_share = top20_count / N if N>0

****************************************************
* 6) (선택) 상위20%가 시작되는 inctyp(구간번호) 저장
****************************************************
bys LGAFINAL21 year hh_type: egen int top20_start_bin = max(inctyp*hit80)
*/


*** 임시용으로 한번 해보기 
keep if hh_type == "one" 

drop if inctyp == 15 
drop if hh_type == "tot"

****************************************************

sort LGAFINAL21 year inc_low

* 1. 그룹 총 가구수
bys LGAFINAL21 year: egen double N = total(hn)

* 2. 누적도수 계산
bys LGAFINAL21 year: gen double cumN = sum(hn)
bys LGAFINAL21 year: gen double cumN_prev = cond(_n==1, 0, cumN[_n-1])

* 3. 목표 순위
bys LGAFINAL21 year: gen double r10 = 0.10 * N
bys LGAFINAL21 year: gen double r90 = 0.90 * N

**** 추가: open-ended top bin 에 만약 상위10% 구간이 걸치게 되는 경우 - dummay variable 
bys LGAFINAL21 year: gen byte hit90 = (cumN >= r90) & (cumN[_n-1] < r90 | _n==1)
gen byte hit90_top = hit90 & (inc_high==.)
bys LGAFINAL21 year: egen byte p90_in_topbin = max(hit90_top)

* 4. 구간 폭 (top bin 제외)
gen double width = inc_high - inc_low
****************************************************
* 5. p10 계산
gen double p10_bin = .
replace p10_bin = inc_low + ///
    ((r10 - cumN_prev)/(cumN - cumN_prev)) * width ///
    if cumN_prev < r10 & cumN >= r10 ///
    & width < . & (cumN - cumN_prev) > 0

bys LGAFINAL21 year: egen double p10 = max(p10_bin)

******************************************************
* 6. p90 계산
gen double p90_bin = .
replace p90_bin = inc_low + ///
    ((r90 - cumN_prev)/(cumN - cumN_prev)) * width ///
    if cumN_prev < r90 & cumN >= r90 ///
    & width < . & (cumN - cumN_prev) > 0

bys LGAFINAL21 year: egen double p90 = max(p90_bin)

sort LGAFINAL21 year inc_low

*********************************************************
* 7. Pareto fill ONLY when p90 is in open-ended top bin
tempvar n_ge3000 n_ge4000 s3000 s4000 alpha p90_pareto

* tail counts by group
bys LGAFINAL21 year: egen double `n_ge3000' = total(hn * (inc_low>=3000))
bys LGAFINAL21 year: egen double `n_ge4000' = total(hn * (inc_low>=4000 & inc_high==.))

* tail shares
gen double `s3000' = `n_ge3000' / N
gen double `s4000' = `n_ge4000' / N

* Pareto shape alpha (needs s4000>0 and s3000>s4000)
gen double `alpha' = .
replace `alpha' = ln(`s3000'/`s4000') / ln(4000/3000) ///
    if p90_in_topbin==1 & `s4000'>0 & `s3000'>`s4000'

gen double `p90_pareto' = .
replace `p90_pareto' = 4000 * (`s4000'/0.10)^(1/`alpha') ///
    if p90_in_topbin==1 & `alpha'<. & `s4000'>=0.10

* fill p90 only when the linear interpolation didn't produce p90
bys LGAFINAL21 year: replace p90 = `p90_pareto' if missing(p90) & `p90_pareto'<.
************************************************************
* 8. p90/p10 index 
* (a) level ratio
gen double p90_p10 = . 
replace p90_p10 = p90/p10 if p10>0 & p90<.

* (b) log ratio (often preferred in regressions)
gen double log_p90_p10 = .
replace log_p90_p10 = ln(p90) - ln(p10) if p10>0 & p90>0

* (optional) sanity
replace p90_p10 = . if p90_p10<=0 | p90_p10==.
replace log_p90_p10 = . if log_p90_p10==.

collapse (mean) p10 p90 p90_p10 log_p90_p10 p90_in_topbin, ///
    by(LGAFINAL21 year)

cd "/Users/ihuila/Desktop/data/2025ABS/afterABS8"

save temp_Y.dta, replace 

/*

*============================================================
* 1) Build (LGA,year) skeleton (master)
*============================================================
* (LGA,year) skeleton
capture confirm string variable hh_type
if _rc==0 {
    encode hh_type, gen(hh)
}
else {
    gen long hh = hh_type
}

tempfile base master
save `base', replace

preserve
    keep LGAFINAL21 year
    duplicates drop
    isid LGAFINAL21 year
    tempfile master
    save `master', replace
restore

use `base', clear
levelsof hh, local(types)

foreach h of local types {

    preserve

		use `base', clear
		keep if hh == `h'
		count
		if r(N)==0 continue
        sort LGAFINAL21 year inc_low

        tempvar N cumN cumN_prev t10 t90 width p10_bin p90_bin ///
               n_ge3000 n_ge4000 s3000 s4000 alpha p90_pareto

        by LGAFINAL21 year: egen double `N' = total(hn)
        by LGAFINAL21 year: gen  double `cumN'      = sum(hn)
        by LGAFINAL21 year: gen  double `cumN_prev' = cond(_n==1,0,`cumN'[_n-1])
        by LGAFINAL21 year: gen  double `t10' = 0.10*`N'
        by LGAFINAL21 year: gen  double `t90' = 0.90*`N'

        gen double `width' = inc_high - inc_low

        gen double `p10_bin' = .
        replace `p10_bin' = inc_low + ((`t10' - `cumN_prev')/(`cumN' - `cumN_prev'))*`width' ///
            if `N'>0 & `cumN_prev' < `t10' & `cumN' >= `t10' & `width'<. & (`cumN'-`cumN_prev')>0

        gen double `p90_bin' = .
        replace `p90_bin' = inc_low + ((`t90' - `cumN_prev')/(`cumN' - `cumN_prev'))*`width' ///
            if `N'>0 & `cumN_prev' < `t90' & `cumN' >= `t90' & `width'<. & (`cumN'-`cumN_prev')>0

        by LGAFINAL21 year: egen double p10 = max(`p10_bin')
        by LGAFINAL21 year: egen double p90 = max(`p90_bin')

        * Pareto (원래 로직 유지)
        by LGAFINAL21 year: egen double `n_ge3000' = total(hn * (inc_low>=3000))
        by LGAFINAL21 year: egen double `n_ge4000' = total(hn * (inc_low>=4000 & inc_high==.))
        gen double `s3000' = `n_ge3000' / `N'
        gen double `s4000' = `n_ge4000' / `N'

        gen double `alpha' = .
        replace `alpha' = ln(`s3000'/`s4000') / ln(4000/3000) if `s4000'>0 & `s3000'>`s4000'

        gen double `p90_pareto' = .
        replace `p90_pareto' = 4000 * (`s4000'/0.10)^(1/`alpha') if `alpha'<. & `s4000'>=0.10
        replace p90 = `p90_pareto' if missing(p90) & `p90_pareto'<.

        gen double p90_p10     = p90/p10 if p10>0 & p90<.
        gen double log_p90_p10 = ln(p90) - ln(p10) if p10>0 & p90>0

        keep LGAFINAL21 year p10 p90 p90_p10 log_p90_p10
        bys LGAFINAL21 year: keep if _n==1
        isid LGAFINAL21 year

        * suffix는 숫자코드로 (가장 안전)
        rename p10         p10_h`h'
        rename p90         p90_h`h'
        rename p90_p10     p90p10_h`h'
        rename log_p90_p10 lnp90p10_h`h'

        tempfile one
        save `one', replace
		restore

    use `master', clear
    merge 1:1 LGAFINAL21 year using `one', nogenerate
    save `master', replace
}
*============================================================
* 3) Final wide panel
*============================================================
use `master', clear
isid LGAFINAL21 year
*/
