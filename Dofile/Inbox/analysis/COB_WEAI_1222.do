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

************************* 1. 전체 main table ******************
cd "/Users/ihuila/Desktop/data/2025ABS/tables"

*********************** Table 1 
// Table1 (Panel A)
* clusterid3 에 시군구코드 변수를 넣으면 됨 
est clear 

xi: reg grow_unempl_rate Xit2 i.year  if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: reg grow_manu_share Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store reg2 

xi: reg grow_serv_share Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store reg3 

esttab reg* using Table1.csv, nogap stats(N r2) title("Table 1A: POLS")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace  

// Table 1 (Panel B) : FE
est clear
xi: xtivreg2 grow_unempl_rate Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m1

xi: xtivreg2 grow_manu_share Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow_serv_share Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m3 

esttab m* using Table1.csv, nogap stats(N r2) title("Table 1B: FE")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

// Table 1 (Panel C) : FE-IV estimation 
est clear 
xi: xtivreg2 grow_unempl_rate (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1

xi: xtivreg2 grow_manu_share (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow_serv_share (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

esttab m* , nogap stats(N widstat cdf arf arfp) title("Table 1C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

*widstat -> KPF 값, weak iv test 

esttab m* using Table1.csv, nogap stats(N kpf cdf arf arfp) title("Table 1C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

*********************** Table 2 - about educational attainment  
// Table1 (Panel A)
* clusterid3 에 시군구코드 변수를 넣으면 됨 
est clear 

xi: reg grow_share_college Xit2 i.year  if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: reg grow_share_fe_college Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store reg2 

xi: reg grow_fe_stem_share Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store reg3 

esttab reg* using Table2.csv, nogap stats(N r2) title("Table 2A: POLS")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

// Table 1 (Panel B) : FE
est clear
xi: xtivreg2 grow_share_college Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m1

xi: xtivreg2 grow_share_fe_college Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow_fe_stem_share Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m3 

esttab m* using Table2.csv, nogap stats(N r2) title("Table 2B: FE")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

// Table 1 (Panel C) : FE-IV estimation 
est clear 
xi: xtivreg2 grow_share_college (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 grow_share_fe_college (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow_fe_stem_share (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m* using Table2.csv, nogap stats(N cdf arf arfp) title("Table 2C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

*******************Table 3 - HETEROGENEITY 
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

esttab m* using Table3.csv, nogap stats(N cdf arf arfp) title("Table 3: HETEROGENEITY1")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)
*******************Table 4 - HETEROGENEITY 
est clear 
xi: xtivreg2 grow_share_college (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 grow_share_fe_college (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2

xi: xtivreg2 grow_fe_stem_share (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

xi: xtivreg2 grow_share_college (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4 

xi: xtivreg2 grow_share_fe_college (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 

xi: xtivreg2 grow_fe_stem_share (Xit2 = Zit2) i.year $demo2  if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m6  

esttab m* using Table4.csv, nogap stats(N cdf arf arfp) title("Table 4: HETEROGENEITY2")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

********************Table 1 - Summary statistics 
tabstat grow_unempl_rate if lag_year>=1996&lag_year<=2016 , stat (mean sd min max N)
br grow_unempl_rate if sample==1 // 1412, 1441, 2414, 2882, 3016, 3084, 

// 1412번째 관측치 -> 2006년에 unemployment rate: 0 이라서 분모가 0임에 따라 -> 2011년 관측치(1412번째 관측치) 에서 결측 
br if _n==1411 | _n==1412 | _n==1413 // 
br if _n==1440 | _n==1441 // 이것도 마찬가지 경우 
br if _n==2413 | _n==2414 // 이것도 마찬가지 경우
br if _n==2881 | _n==2882 // 이것도 마찬가지 경우
br if _n==3015 | _n==3016 // 이것도 마찬가지 경우
br if _n==3083 | _n==3084 // 이것도 마찬가지 경우

tabstat Xit2 if lag_year>=1996 & lag_year<=2016,  stat (mean sd min max N)

tabstat grow_unempl_rate if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat grow_manu_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat grow_serv_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)

tabstat grow_share_college if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat grow_share_fe_college if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat grow_fe_stem_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
