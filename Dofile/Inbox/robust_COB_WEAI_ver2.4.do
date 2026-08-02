clear all 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS"
use cob_XYZ_final.dta 

tab year 

sort LGAFINAL21 year 
xtset LGAFINAL21 year 
****************************************************************
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

************************************outcome variable - growth rate (version2.4)
*******************************Version 2.4.*************************
cd "/Users/ihuila/Desktop/data/2025ABS/tables/2-4/robustness"
*********************** Table 1 -> 여기부터 코드 수정 
// Table1 (Panel A)
est clear 

xi: reg growunempl_rate Xit2_other i.year  if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: reg growmanu_share Xit2_other i.year if sample==1, vce(cluster LGAFINAL21)
est store reg2 

xi: reg growserv_share Xit2_other i.year if sample==1, vce(cluster LGAFINAL21)
est store reg3 

esttab reg* using Table1.csv, nogap stats(N r2) title("Table 1A: POLS")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace  

// Table 1 (Panel B) : FE
est clear
xi: xtivreg2 growunempl_rate Xit2_other i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m1

xi: xtivreg2 growmanu_share Xit2_other i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m2 

xi: xtivreg2 growserv_share Xit2_other i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m3 

esttab m* using Table1.csv, nogap stats(N r2) title("Table 1B: FE")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

// Table 1 (Panel C) : FE-IV estimation 
est clear 
xi: xtivreg2 growunempl_rate (Xit2_other = Zit2_other) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1

xi: xtivreg2 growmanu_share (Xit2_other = Zit2_other) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 growserv_share (Xit2_other = Zit2_other) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

esttab m* using Table1.csv, nogap stats(N widstat arf arfp) title("Table 1C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append 

*widstat -> KPF 값, weak iv test 
*********************** Table 2 - service sector 세부산업 
// Table1 (Panel A)
* clusterid3 에 시군구코드 변수를 넣으면 됨 
est clear 

xi: reg growconsum_serv_share Xit2_other i.year  if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: reg growproduc_serv_share Xit2_other i.year if sample==1, vce(cluster LGAFINAL21)
est store reg2 

xi: reg growpublic_serv_share Xit2_other i.year if sample==1, vce(cluster LGAFINAL21)
est store reg3 

esttab reg* using Table2.csv, nogap stats(N r2) title("Table 2A: POLS")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

// Table 1 (Panel B) : FE
est clear
xi: xtivreg2 growconsum_serv_share Xit2_other i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m1

xi: xtivreg2 growproduc_serv_share Xit2_other i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m2 

xi: xtivreg2 growpublic_serv_share Xit2_other i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m3 

esttab m* using Table2.csv, nogap stats(N r2) title("Table 2B: FE")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

// Table 1 (Panel C) : FE-IV estimation 
est clear 
xi: xtivreg2 growconsum_serv_share (Xit2_other = Zit2_other) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 growproduc_serv_share (Xit2_other = Zit2_other) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 growpublic_serv_share (Xit2_other = Zit2_other) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m* using Table2.csv, nogap stats(N widstat arf arfp) title("Table 2C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

*********************** Table 3 - jobs by skill level 
// Table1 (Panel A)
* clusterid3 에 시군구코드 변수를 넣으면 됨 
est clear 

xi: reg growhighsk_share Xit2_other i.year  if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: reg growmidsk_share Xit2_other i.year if sample==1, vce(cluster LGAFINAL21)
est store reg2 

xi: reg growlowsk_share Xit2_other i.year if sample==1, vce(cluster LGAFINAL21)
est store reg3 

esttab reg* using Table3.csv, nogap stats(N r2) title("Table 3A: POLS")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

// Table 1 (Panel B) : FE
est clear
xi: xtivreg2 growhighsk_share Xit2_other i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m1

xi: xtivreg2 growmidsk_share Xit2_other i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m2 

xi: xtivreg2 growlowsk_share  Xit2_other i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m3 

esttab m* using Table3.csv, nogap stats(N r2) title("Table 3B: FE")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

// Table 1 (Panel C) : FE-IV estimation 
est clear 
xi: xtivreg2 growhighsk_share (Xit2_other = Zit2_other) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 growmidsk_share (Xit2_other = Zit2_other) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 growlowsk_share (Xit2_other = Zit2_other) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m* using Table3.csv, nogap stats(N widstat arf arfp) title("Table 3C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

*******************Table 4 - HETEROGENEITY 
est clear 
xi: xtivreg2 growunempl_rate (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1

xi: xtivreg2 growmanu_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 growserv_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

xi: xtivreg2 growunempl_rate (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4

xi: xtivreg2 growmanu_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 

xi: xtivreg2 growserv_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m6 

esttab m* using Table4.csv, nogap stats(N widstat arf arfp) title("Table 4: HETEROGENEITY1")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 


est clear 
xi: xtivreg2 growconsum_serv_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1

xi: xtivreg2 growproduc_serv_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 growpublic_serv_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

xi: xtivreg2 growconsum_serv_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4

xi: xtivreg2 growproduc_serv_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 

xi: xtivreg2 growpublic_serv_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m6 

esttab m* using Table4.csv, nogap stats(N widstat arf arfp) title("Table 4: HETEROGENEITY2")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append 


est clear 
xi: xtivreg2 growhighsk_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1

xi: xtivreg2 growmidsk_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 growlowsk_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

xi: xtivreg2 growhighsk_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4

xi: xtivreg2 growmidsk_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 

xi: xtivreg2 growlowsk_share (Xit2_other = Zit2_other) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m6 

esttab m* using Table4.csv, nogap stats(N widstat arf arfp) title("Table 4: HETEROGENEITY3")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append 
*******************************************************************
********************Summary statistics 
*******************************************************************
tabstat Xit2 if lag_year>=1996 & lag_year<=2016,  stat (mean sd min max N)

*************version 2.1. 
tabstat growunempl_rate if lag_year>=1996&lag_year<=2016 , stat (mean sd min max N)
br growunempl_rate if sample==1 // 1412, 1441, 2414, 2882, 3016, 3084, 

// 1412번째 관측치 -> 2006년에 unemployment rate: 0 이라서 분모가 0임에 따라 -> 2011년 관측치(1412번째 관측치) 에서 결측 
br if _n==1411 | _n==1412 | _n==1413 // 
br if _n==1440 | _n==1441 // 이것도 마찬가지 경우 
br if _n==2413 | _n==2414 // 이것도 마찬가지 경우
br if _n==2881 | _n==2882 // 이것도 마찬가지 경우
br if _n==3015 | _n==3016 // 이것도 마찬가지 경우
br if _n==3083 | _n==3084 // 이것도 마찬가지 경우

tabstat growunempl_rate if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat growmanu_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat growserv_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)

tabstat growconsum_serv_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat growproduc_serv_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat growpublic_serv_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)

tabstat growhighsk_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat growmidsk_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat growlowsk_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
*************version 2.2. 
tabstat grow2unemployed if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat grow2manu_tot if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat grow2service_tot if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)

tabstat grow2consum_serv if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat grow2produc_serv if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat grow2public_serv if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)

tabstat grow2highsk_tot if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat grow2midsk_tot if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat grow2lowsk_tot if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
*************version 2.3.  (로그차분)
tabstat dlog_unemployed if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat dlog_manu_tot if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat dlog_service_tot if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)

tabstat dlog_consum_serv if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat dlog_produc_serv if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat dlog_public_serv if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)

tabstat dlog_highsk_tot if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat dlog_midsk_tot if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat dlog_lowsk_tot if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
