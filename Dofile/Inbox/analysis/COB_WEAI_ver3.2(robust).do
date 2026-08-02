clear all 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS"
use cob_XYZ_final.dta 

sort LGAFINAL21 year 
xtset LGAFINAL21 year 
tsset LGAFINAL21 year, delta(5)

gen lag_share_college   = L1.share_college 
gen lag_share_popfifold = L1.share_popfifold 

global demo  lag_share_college
global demo2 lag_share_college lag_share_popfifold

*------------------------------------------------------------------------------
* English share dummy (1991 baseline)
*------------------------------------------------------------------------------
preserve
    keep if year == 1991
    gen high_eng91 = (share_eng >= share_noneng) ///
        if !missing(share_eng)
    label define lbl_eng91 0 "Low English share" 1 "High English share" 
    label values high_eng91 lbl_eng91
    keep LGAFINAL21 high_eng91 share_eng
    duplicates drop LGAFINAL21, force
    tempfile eng91_dummy
    save `eng91_dummy', replace
restore

merge m:1 LGAFINAL21 using `eng91_dummy', nogenerate

global hetero_higheng "high_eng91 == 1 & !missing(high_eng91)"
global hetero_loweng  "high_eng91 == 0 & !missing(high_eng91)"

gen sample = 1 if year >= 1996 & year <= 2021 

*------------------------------------------------------------------------------
* Common stats() macros
*------------------------------------------------------------------------------
global stat_ols ///
    stats(N r2, ///
          fmt(%9.0fc %8.3f) ///
          labels("Observations" "R-squared"))

global stat_feiv ///
    stats(fs_coef fs_se cdf widstat sy_cv10 sy_cv15 arf arfp N, ///
          fmt(%8.3f %8.3f %8.3f %8.2f %8.2f %8.3f %8.3f %9.0fc) ///
          labels("First stage: Immigration share" ///
                 "\ \ \ \ (SE)" ///
				 "C-D F-stat" ///
                 "KP F-statistic" ///
                 "Stock-Yogo CV (10\%)" ///
                 "Stock-Yogo CV (15\%)" ///
                 "AR F-statistic" ///
                 "AR p-value" ///
                 "Observations"))

cd "/Users/ihuila/Desktop/data/2025ABS/tables/3-2"

**************************** add controls 
est clear

* --- Col (1): Unemployment ---
xi: xtivreg2 unempl_rate (Xit2 = Zit2) i.year $demo2 ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mA1

* --- Col (2): High skill ---
xi: xtivreg2 share_highsk (Xit2 = Zit2) i.year $demo2 ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mA2

* --- Col (3): Mid skill ---
xi: xtivreg2 share_midsk (Xit2 = Zit2) i.year $demo2 ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mA3

* --- Col (4): Low skill ---
xi: xtivreg2 share_lowsk (Xit2 = Zit2) i.year $demo2 ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mA4


esttab mA* using Table_RB_add.csv, ///
    nogap $stat_feiv ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) replace

*********************************************************************************8
********************* leave out IV 
est clear

* --- Col (1): Unemployment ---
xi: xtivreg2 unempl_rate (Xit2 = Zit2_leave_IND) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mA1

* --- Col (2): High skill ---
xi: xtivreg2 share_highsk (Xit2 = Zit2_leave_IND) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mA2

* --- Col (3): Mid skill ---
xi: xtivreg2 share_midsk (Xit2 = Zit2_leave_IND) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mA3

* --- Col (4): Low skill ---
xi: xtivreg2 share_lowsk (Xit2 = Zit2_leave_IND) i.year $demo ///
    if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store tmp_2nd
quietly estimates restore fs_Xit2
local fs_b = e(b)[1,1]
local fs_s = sqrt(e(V)[1,1])
quietly estimates restore tmp_2nd
estadd scalar fs_coef = `fs_b'
estadd scalar fs_se   = `fs_s'
estadd scalar sy_cv10 = 16.38
estadd scalar sy_cv15 =  8.96
est store mA4

esttab mA* using Table_RB_leaveout.csv, ///
    nogap $stat_feiv ///
    title("Robustness: Leave-out IV (excl. India)") ///
    mtitles("Unemployment" "High skill" "Mid skill" "Low skill") ///
    b(%8.3f) se(%8.3f) ///
    label star(* 0.10 ** 0.05 *** 0.01) replace
	
	
***********************************************
est clear 
xi: xtivreg2 unempl_rate (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 ma_unempl_rate (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 fe_unempl_rate (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m*, nogap stats(N widstat arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

est clear 
xi: xtivreg2 share_highsk (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 share_midsk (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 share_lowsk (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m* , nogap stats(N widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

est clear 
xi: xtivreg2 share_mar (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 share_marmale (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 share_marfemale (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m*, nogap stats(N widstat arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

*************************** leave out IV 
est clear 
xi: xtivreg2 unempl_rate (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 ma_unempl_rate (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 fe_unempl_rate (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m*, nogap stats(N widstat arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

est clear 
xi: xtivreg2 share_highsk (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 share_midsk (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 share_lowsk (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m* , nogap stats(N widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

est clear 
xi: xtivreg2 share_mar (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 share_marmale (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 

xi: xtivreg2 share_marfemale (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m3 

esttab m*, nogap stats(N widstat arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

********************************* robustness check 
est clear 
xi: xtivreg2 share_highsk (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 share_mhighsk (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 
xi: xtivreg2 share_fhighsk (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

xi: xtivreg2 share_midsk (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4 

xi: xtivreg2 share_mmidsk (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 
xi: xtivreg2 share_fmidsk (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m6 

xi: xtivreg2 share_lowsk (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m7 

xi: xtivreg2 share_mlowsk (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m8
xi: xtivreg2 share_flowsk (Xit2 = Zit2) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m9 

esttab m*, nogap stats(N widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

est clear 
xi: xtivreg2 share_highsk (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m1 

xi: xtivreg2 share_mhighsk (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m2 
xi: xtivreg2 share_fhighsk (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m3 

xi: xtivreg2 share_midsk (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m4 

xi: xtivreg2 share_mmidsk (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m5 
xi: xtivreg2 share_fmidsk (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) 
est store m6 

xi: xtivreg2 share_lowsk (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m7 

xi: xtivreg2 share_mlowsk (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m8
xi: xtivreg2 share_flowsk (Xit2 = Zit2_leave_IND) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)  
est store m9 

esttab m*, nogap stats(N widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)
