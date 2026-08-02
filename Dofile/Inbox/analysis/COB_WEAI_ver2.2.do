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
****************************************************************
********************** outcome variable - share 
* unemployment rate 
gen unempl_rate = unemployed/labor_force 
gen fe_unempl_rate = fe_unemployed/fe_labor_force 
gen ma_unempl_rate = ma_unemployed/ma_labor_force 

* manufacutring share 
gen manu_share =  manu_tot / totindus_tot 
gen fe_manu_share = manu_female / totindus_female
gen ma_manu_share = manu_male / totindus_male

** service share 
gen serv_share = service_tot / totindus_tot 
gen fe_serv_share = service_female / totindus_female 
gen ma_serv_share = service_male / totindus_male  

* 세부 서비스산업 
gen consum_serv_share = consum_serv / totindus_tot
gen produc_serv_share = produc_serv / totindus_tot
gen public_serv_share = public_serv / totindus_tot

gen consum_serv_feshare = consum_serv_fe / totindus_female
gen produc_serv_feshare = produc_serv_fe / totindus_female
gen public_serv_feshare = public_serv_fe / totindus_female

gen consum_serv_mashare = consum_serv_ma / totindus_male
gen produc_serv_mashare = produc_serv_ma / totindus_male 
gen public_serv_mashare = public_serv_ma / totindus_male 

* job by skill-level 
gen highsk_share = highsk_tot / totoccu_tot 
gen midsk_share =  midsk_tot / totoccu_tot 
gen lowsk_share =  lowsk_tot / totoccu_tot 

gen highsk_feshare = highsk_female / totoccu_female 
gen midsk_feshare =  midsk_female / totoccu_female  
gen lowsk_feshare =  lowsk_female / totoccu_female  

gen highsk_mashare = highsk_male / totoccu_male 
gen midsk_mashare =  midsk_male / totoccu_male 
gen lowsk_mashare =  lowsk_male / totoccu_male 

*********************************************************
sort LGAFINAL21 year 
tsset LGAFINAL21 year, delta(5)

gen lag_year = L1.year

************************************outcome variable - growth rate 
******share of (ver2.1 )
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
	label var grow`v' "outcome var(ver2.1.)"
}

******number of (ver2.2)
local numbervar /// 
	unemployed ma_unemployed fe_unemployed ///
	manu_tot manu_male manu_female ///
	service_tot service_male service_female ///
	consum_serv consum_serv_ma consum_serv_fe ///
	produc_serv produc_serv_ma produc_serv_fe ///
	public_serv public_serv_ma	public_serv_fe ///
	highsk_tot	highsk_male	highsk_female ///
	midsk_tot 	midsk_male midsk_female ///
	lowsk_tot lowsk_male lowsk_female


foreach v of local numbervar {
	gen grow2`v' = (`v' - L1.`v')/L1.`v'
	label var grow2`v' "outcome var(ver2.2.)"
}

************************************* outcome variable - log 
foreach v of local numbervar {
	gen log_`v' = log(`v')
	gen dlog_`v' = log_`v' - L1.log_`v'
	label var dlog_`v' "outcome var(ver2.3.)"
}

sort LGAFINAL21 year 
order LGAFINAL21 year
order grow* dlog*, last

*********************************outcome variable - log (ver2.3) 
global fixed i.year 
global demo L1.share_popfifold L1.share_college

gen sample = 1 if lag_year>=1996&lag_year<=2016

label var Xit2 "growth rate"
label var Xit3 "difference"
label var Zit2 "growth rate"
label var Zit3 "difference"
************************* 1. 전체 main table ******************
*******************************Version 2.2.*************************
cd "/Users/ihuila/Desktop/data/2025ABS/tables/2-2"
*********************** Table 1 -> 여기부터 코드 수정 
// Table1 (Panel A)
est clear 

xi: reg grow2unemployed Xit2 i.year  if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: reg grow2manu_tot Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store reg2 

xi: reg grow2service_tot Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store reg3 

esttab reg* using Table1.csv, nogap stats(N r2) title("Table 1A: POLS")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace  

// Table 1 (Panel B) : FE
est clear
xi: xtivreg2 grow2unemployed Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m1

xi: xtivreg2 grow2manu_tot Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow2service_tot Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m3 

esttab m* using Table1.csv, nogap stats(N r2) title("Table 1B: FE")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

// Table 1 (Panel C) : FE-IV estimation 
est clear 
xi: xtivreg2 grow2unemployed (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1

xi: xtivreg2 grow2manu_tot (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow2service_tot (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

esttab m* using Table1.csv, nogap stats(N widstat arf arfp) title("Table 1C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append 

*widstat -> KPF 값, weak iv test 
*********************** Table 2 - service sector 세부산업 
// Table1 (Panel A)
* clusterid3 에 시군구코드 변수를 넣으면 됨 
est clear 

xi: reg grow2consum_serv Xit2 i.year  if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: reg grow2produc_serv Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store reg2 

xi: reg grow2public_serv Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store reg3 

esttab reg* using Table2.csv, nogap stats(N r2) title("Table 2A: POLS")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

// Table 1 (Panel B) : FE
est clear
xi: xtivreg2 grow2consum_serv Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m1

xi: xtivreg2 grow2produc_serv Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow2public_serv  Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m3 

esttab m* using Table2.csv, nogap stats(N r2) title("Table 2B: FE")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

// Table 1 (Panel C) : FE-IV estimation 
est clear 
xi: xtivreg2 grow2consum_serv (Xit2 = Zit2) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 grow2produc_serv (Xit2 = Zit2) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow2public_serv (Xit2 = Zit2) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m* using Table2.csv, nogap stats(N widstat arf arfp) title("Table 2C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

*********************** Table 3 - jobs by skill level 
// Table1 (Panel A)
* clusterid3 에 시군구코드 변수를 넣으면 됨 
est clear 

xi: reg grow2highsk_tot Xit2 i.year  if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: reg grow2midsk_tot Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store reg2 

xi: reg grow2lowsk_tot Xit2 i.year if sample==1, vce(cluster LGAFINAL21)
est store reg3 

esttab reg* using Table3.csv, nogap stats(N r2) title("Table 3A: POLS")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

// Table 1 (Panel B) : FE
est clear
xi: xtivreg2 grow2highsk_tot Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m1

xi: xtivreg2 grow2midsk_tot Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow2lowsk_tot  Xit2 i.year if sample==1, fe cluster(LGAFINAL21) savefprefix(fs_) 
est store m3 

esttab m* using Table3.csv, nogap stats(N r2) title("Table 3B: FE")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

// Table 1 (Panel C) : FE-IV estimation 
est clear 
xi: xtivreg2 grow2highsk_tot (Xit2 = Zit2) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 grow2midsk_tot (Xit2 = Zit2) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow2lowsk_tot (Xit2 = Zit2) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m* using Table3.csv, nogap stats(N widstat arf arfp) title("Table 3C: FEIV")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append

*******************Table 4 - HETEROGENEITY 
est clear 
xi: xtivreg2 grow2unemployed (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1

xi: xtivreg2 grow2manu_tot (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow2service_tot (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

xi: xtivreg2 grow2unemployed (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4

xi: xtivreg2 grow2manu_tot (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 

xi: xtivreg2 grow2service_tot (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m6 

esttab m* using Table4.csv, nogap stats(N widstat arf arfp) title("Table 4: HETEROGENEITY1")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 


est clear 
xi: xtivreg2 grow2consum_serv (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1

xi: xtivreg2 grow2produc_serv (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow2public_serv (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

xi: xtivreg2 grow2consum_serv (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4

xi: xtivreg2 grow2produc_serv (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 

xi: xtivreg2  grow2public_serv (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m6 

esttab m* using Table4.csv, nogap stats(N widstat arf arfp) title("Table 4: HETEROGENEITY2")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append 


est clear 
xi: xtivreg2 grow2highsk_tot (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1

xi: xtivreg2 grow2midsk_tot (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 grow2lowsk_tot (Xit2 = Zit2) i.year $demo if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

xi: xtivreg2 grow2highsk_tot (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4

xi: xtivreg2 grow2midsk_tot (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 

xi: xtivreg2 grow2lowsk_tot (Xit2 = Zit2) i.year $demo if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m6 

esttab m* using Table4.csv, nogap stats(N widstat arf arfp) title("Table 4: HETEROGENEITY3")  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append 
