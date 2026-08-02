clear all 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS"
use cob_XYZ_final.dta 

tab year 

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
****************************with control variables 
*************************about employment (table1)
******* version - growth rate => 더 잘나옴 
est clear 
xi: xtivreg2 grow_unempl_rate (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1

xi: xtivreg2 grow_manu_share (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow_serv_share (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

esttab m*, nogap stats(N cdf arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

******* version - difference 
est clear 
xi: xtivreg2 diff_unempl_rate (Xit3 = Zit3) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1

xi: xtivreg2 diff_manu_share (Xit3 = Zit3) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 diff_serv_share (Xit3 = Zit3) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

esttab m*, nogap stats(N cdf arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

*************************about education (table2)
******* version - growth rate 
est clear 
xi: xtivreg2 grow_share_college (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 grow_share_fe_college (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow_share_ma_college (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

xi: xtivreg2 grow_fe_stem_share (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m4 

xi: xtivreg2 grow_ma_stem_share (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m5 

esttab m*, nogap stats(N cdf arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

******* version - difference 
est clear
xi: xtivreg2 diff_share_college (Xit3 = Zit3) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 diff_share_fe_college (Xit3 = Zit3) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 diff_share_ma_college (Xit3 = Zit3) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

xi: xtivreg2 diff_fe_stem_share (Xit3 = Zit3) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m4 

xi: xtivreg2 diff_ma_stem_share (Xit3 = Zit3) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m5 

esttab m*, nogap stats(N cdf arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 
*******************************************************************************
**********************HETEROGENEITY ANALYSIS 
********* about employment 
est clear 
xi: xtivreg2 grow_unempl_rate (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1

xi: xtivreg2 grow_manu_share (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow_serv_share (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

xi: xtivreg2 grow_unempl_rate (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4

xi: xtivreg2 grow_manu_share (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 

xi: xtivreg2 grow_serv_share (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m6 

esttab m*, nogap stats(N cdf arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

******* about educational attainment 
est clear 
xi: xtivreg2 grow_share_college (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 grow_share_college (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow_share_fe_college (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

xi: xtivreg2 grow_share_fe_college (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4 

xi: xtivreg2 grow_share_ma_college (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 

xi: xtivreg2 grow_share_ma_college (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m6 

xi: xtivreg2 grow_fe_stem_share (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m7 

xi: xtivreg2 grow_fe_stem_share (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m8 

xi: xtivreg2 grow_ma_stem_share (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m9 

xi: xtivreg2 grow_ma_stem_share (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m10 

esttab m*, nogap stats(N cdf arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

