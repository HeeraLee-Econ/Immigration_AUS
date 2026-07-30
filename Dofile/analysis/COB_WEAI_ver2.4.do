clear all 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS"
use cob_XYZ_final.dta 

tab year 

sort LGAFINAL21 year 
xtset LGAFINAL21 year 
*********************************************************
sort LGAFINAL21 year 
tsset LGAFINAL21 year, delta(5)

gen lag_year = L1.year
************************************outcome variable - growth rate 
******share of (ver2.4) -> version 2.1 의 변주인데 분모를 labor force로 통일시킴 
local sharevar ///
    unempl_rate empl_rate1 empl_rate2 manu_share serv_share ///
	highsk_share midsk_share lowsk_share 
	
	///consum_serv_share produc_serv_share public_serv_share 
	///lowsk_mashare lowsk_feshare 
	/// midsk_mashare midsk_feshare 
	/// highsk_mashare highsk_feshare /// 
	
foreach v of local sharevar { 
	gen grow`v' = (`v' - L1.`v')/L1.`v'
	label var grow`v' "outcome var(ver2.4.)"
} 
*********************************outcome variable - log (ver2.3) 
global fixed i.year 
global demo L1.share_popfifold L1.share_college

gen sample = 1 if lag_year>=1996&lag_year<=2016

label var Xit2 "growth rate"
label var Xit3 "difference"
label var Zit2 "growth rate"
label var Zit3 "difference"
************************************outcome variable - growth rate (version2.4)
*******************************Version 2.4.*************************
cd "/Users/ihuila/Desktop/data/2025ABS/tables/2-4"
*********************** 
*********************** Table 1 
// Table1 (Panel A) - denominator: pop15+ 
est clear 

xi: reg growempl_rate1 Xit2 i.year  if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: xtivreg2 growempl_rate1 Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store reg2 

xi: xtivreg2 growempl_rate1 (Xit2 = Zit2) i.year  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store reg3 

xi: xtivreg2 growempl_rate1 (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store reg4 

esttab reg*, nogap stats(N r2 widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 

esttab reg* using Table1.csv, nogap stats(N r2 widstat arf arfp) title("Table 1C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

// Table1 (Panel A) - denominator: labor force 
est clear 

xi: reg growempl_rate2 Xit2 i.year  if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: xtivreg2 growempl_rate2 Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store reg2 

xi: xtivreg2 growempl_rate2 (Xit2 = Zit2) i.year  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store reg3 

xi: xtivreg2 growempl_rate2 (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store reg4 

esttab reg*, nogap stats(N r2 widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) 

esttab reg* using Table1_ver2.csv, nogap stats(N r2 widstat arf arfp) title("Table 1C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

*widstat -> KPF 값, weak iv test 
*********************** Table 2 - service sector 세부산업 
// Table2  (Panel A)
est clear 

xi: reg growmanu_share Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: reg growserv_share Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store reg2 

esttab reg* using Table2.csv, nogap stats(N r2) title("Table 2A: POLS")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

// Table 1 (Panel B) : FE
est clear

xi: xtivreg2 growmanu_share Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m1 

xi: xtivreg2 growserv_share Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m2 

esttab m* using Table2.csv, nogap stats(N r2) title("Table 2B: FE")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

// Table 1 (Panel C) : FE-IV estimation 
est clear 
xi: xtivreg2 growmanu_share (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 growserv_share (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

esttab m* using Table2.csv, nogap stats(N widstat arf arfp) title("Table 2C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append
*********************** Table 3 - jobs by skill level 
// Table1 (Panel A)
* clusterid3 에 시군구코드 변수를 넣으면 됨 
est clear 

xi: reg growhighsk_share Xit2 i.year  if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: reg growmidsk_share Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store reg2 

xi: reg growlowsk_share Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store reg3 

esttab reg* using Table3.csv, nogap stats(N r2) title("Table 3A: POLS")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

// Table 1 (Panel B) : FE
est clear
xi: xtivreg2 growhighsk_share Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m1

xi: xtivreg2 growmidsk_share Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m2 

xi: xtivreg2 growlowsk_share  Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m3 

esttab m* using Table3.csv, nogap stats(N r2) title("Table 3B: FE")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

// Table 1 (Panel C) : FE-IV estimation 
est clear 
xi: xtivreg2 growhighsk_share (Xit2 = Zit2) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 growmidsk_share (Xit2 = Zit2) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 growlowsk_share (Xit2 = Zit2) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m* using Table3.csv, nogap stats(N widstat arf arfp) title("Table 3C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

*******************Table 4 - HETEROGENEITY 
est clear 

xi: xtivreg2 growempl_rate1 (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 growmanu_share (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 growserv_share (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

xi: xtivreg2  growempl_rate1 (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4 

xi: xtivreg2 growmanu_share (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 

xi: xtivreg2 growserv_share (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m6 

esttab m* using Table4.csv, nogap stats(N widstat arf arfp) title("Table 4: HETEROGENEITY1")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 
*********************************

est clear 
xi: xtivreg2 growhighsk_share (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1

xi: xtivreg2 growmidsk_share (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 growlowsk_share (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

xi: xtivreg2 growhighsk_share (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4

xi: xtivreg2 growmidsk_share (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 

xi: xtivreg2 growlowsk_share (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m6 

esttab m* using Table4.csv, nogap stats(N widstat arf arfp) title("Table 4: HETEROGENEITY3")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append 
*******************************************************************
********************Summary statistics 
*******************************************************************
tabstat Xit2 if lag_year>=1996 & lag_year<=2016,  stat (mean sd min max N)

*************version 2.1. 
tabstat growempl_rate1 if lag_year>=1996&lag_year<=2016 , stat (mean sd min max N)
br growunempl_rate if sample==1 // 1412, 1441, 2414, 2882, 3016, 3084, 

// 1412번째 관측치 -> 2006년에 unemployment rate: 0 이라서 분모가 0임에 따라 -> 2011년 관측치(1412번째 관측치) 에서 결측 
br if _n==1411 | _n==1412 | _n==1413 // 
br if _n==1440 | _n==1441 // 이것도 마찬가지 경우 
br if _n==2413 | _n==2414 // 이것도 마찬가지 경우
br if _n==2881 | _n==2882 // 이것도 마찬가지 경우
br if _n==3015 | _n==3016 // 이것도 마찬가지 경우
br if _n==3083 | _n==3084 // 이것도 마찬가지 경우

tabstat Xit2 if lag_year >= 1996  & lag_year<=2021,  stat (mean sd min max N)

tabstat growempl_rate1 if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)

tabstat growmanu_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat growserv_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)

tabstat growhighsk_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat growmidsk_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
tabstat growlowsk_share if lag_year>=1996 & lag_year<=2021,  stat (mean sd min max N)
