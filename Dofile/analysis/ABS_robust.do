**********************************************************************
* Created by Heera Lee
* Purpose: Analysis at the LGA level, ABS 
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
	global output "${main}/Output"
**********************************************************************
use "$final/ABS_XY_final.dta", clear

sort LGAFINAL21 year 
order LGAFINAL21 year 

// sample 
gen sample = 1 if year >= 2001 & year<=2021 

global demo fifteenshare_lag bachshare_ageall_lag
global demo2 fifteenshare_lag bachshare_ageall_lag fifteen_trend bach_trend

capture log close
log using "$output/Log/Robust_0731.smcl", replace

cd "$output/Table"
**********************************************************************
* Table 6: Leave-out IV (India 제외 - Rotemberg weight 가장 큰 나라)
* baseline control($demo)만 사용, 도구변수만 Zit -> Zit_exclIndia로 교체
**********************************************************************

* 6-1. 노동시장 (전연령 실업률 + 고/중/저숙련 고용률)
eststo clear
eststo r6_1: xi: xtivreg2 unempshare_ageall (Xit = Zit_exclIndia) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first

eststo r6_2: xi: xtivreg2 highskshare       (Xit = Zit_exclIndia) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first

eststo r6_3: xi: xtivreg2 midskshare        (Xit = Zit_exclIndia) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first

eststo r6_4: xi: xtivreg2 lowskshare        (Xit = Zit_exclIndia) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first

esttab r6_1 r6_2 r6_3 r6_4 using "Robust_leave_labor.csv", replace ///
    keep(Xit) label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) nogap ///
    mtitles("Overall" "High-Skill" "Middle-Skill" "Low-Skill") ///
    mgroups("Unemployment Rate" "Employment Rate", pattern(1 0 0 0)) ///
    stats(N cdf widstat arf arfp, ///
        labels("Observations" "C-D F-stat" "K-P F-stat" "A-R F-stat" "A-R p-value") ///
        fmt(%9.0fc %9.3f %9.3f %9.3f %9.3f)) ///
    addnotes("LGA fixed effects: Yes" "Year fixed effects: Yes" "Control variables: Yes" ///
        "Leave-out IV excludes India from the shift-share instrument.")

* 6-2. 노동시장 (성별) - Panel A: Male / Panel B: Female
eststo clear
eststo r6_5: xi: xtivreg2 unempmshare_ageall (Xit = Zit_exclIndia) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first

eststo r6_6: xi: xtivreg2 highskmshare       (Xit = Zit_exclIndia) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first

eststo r6_7: xi: xtivreg2 midskmshare        (Xit = Zit_exclIndia) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first

eststo r6_8: xi: xtivreg2 lowskmshare        (Xit = Zit_exclIndia) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first

esttab r6_5 r6_6 r6_7 r6_8 using "Robust_leave_gender.csv", replace ///
    keep(Xit) label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) nogap ///
    mtitles("Overall" "High-Skill" "Middle-Skill" "Low-Skill") ///
    mgroups("Unemployment Rate" "Employment Rate", pattern(1 0 0 0)) ///
    stats(N cdf widstat arf arfp, ///
        labels("Observations" "C-D F-stat" "K-P F-stat" "A-R F-stat" "A-R p-value") ///
        fmt(%9.0fc %9.3f %9.3f %9.3f %9.3f)) ///
    refcat(Xit "Panel A. Male", nolabel) ///
    addnotes("LGA fixed effects: Yes" "Year fixed effects: Yes" "Control variables: Yes" ///
        "Leave-out IV excludes India from the shift-share instrument.")

eststo clear
eststo r6_9:  xi: xtivreg2 unempfshare_ageall (Xit = Zit_exclIndia) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first

eststo r6_10: xi: xtivreg2 highskfshare       (Xit = Zit_exclIndia) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first

eststo r6_11: xi: xtivreg2 midskfshare        (Xit = Zit_exclIndia) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first

eststo r6_12: xi: xtivreg2 lowskfshare        (Xit = Zit_exclIndia) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first

esttab r6_9 r6_10 r6_11 r6_12 using "Robust_leave_gender.csv", append ///
    keep(Xit) label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) nogap ///
    nomtitle nonumber ///
    stats(N cdf widstat arf arfp, ///
        labels("Observations" "C-D F-stat" "K-P F-stat" "A-R F-stat" "A-R p-value") ///
        fmt(%9.0fc %9.3f %9.3f %9.3f %9.3f)) ///
    refcat(Xit "Panel B. Female", nolabel) ///
    addnotes("LGA fixed effects: Yes" "Year fixed effects: Yes" "Control variables: Yes" ///
        "Leave-out IV excludes India from the shift-share instrument.")

* 6-3. 결혼 (20-34세, overall/male/female)
eststo clear
eststo r6_13: xi: xtivreg2 marriedshare_2034       (Xit = Zit_exclIndia) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first

eststo r6_14: xi: xtivreg2 marriedmaleshare_2034   (Xit = Zit_exclIndia) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first

eststo r6_15: xi: xtivreg2 marriedfemaleshare_2034 (Xit = Zit_exclIndia) i.year $demo  if sample==1, fe cluster(LGAFINAL21) robust first

esttab r6_13 r6_14 r6_15 using "Robust_leave_marriage.csv", replace ///
    keep(Xit) label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) nogap ///
    mtitles("Overall" "Male" "Female") ///
    stats(N cdf widstat arf arfp, ///
        labels("Observations" "C-D F-stat" "K-P F-stat" "A-R F-stat" "A-R p-value") ///
        fmt(%9.0fc %9.3f %9.3f %9.3f %9.3f)) ///
    addnotes("LGA fixed effects: Yes" "Year fixed effects: Yes" "Control variables: Yes" ///
        "Leave-out IV excludes India from the shift-share instrument.")

**********************************************************************
* Table 7: Additional Control ($demo2 = baseline lag + baseline x trend)
* 도구변수는 원래 Zit 그대로, control만 $demo2로 확장
**********************************************************************

* 7-1. 노동시장 (전연령 실업률 + 고/중/저숙련 고용률)
eststo clear
eststo r7_1: xi: xtivreg2 unempshare_ageall (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first

eststo r7_2: xi: xtivreg2 highskshare       (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first

eststo r7_3: xi: xtivreg2 midskshare        (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first

eststo r7_4: xi: xtivreg2 lowskshare        (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first

esttab r7_1 r7_2 r7_3 r7_4 using "Robust_add_labor.csv", replace ///
    keep(Xit bachshare_ageall_lag fifteenshare_lag bach_trend fifteen_trend) label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) nogap ///
    mtitles("Overall" "High-Skill" "Middle-Skill" "Low-Skill") ///
    mgroups("Unemployment Rate" "Employment Rate", pattern(1 0 0 0)) ///
    stats(N cdf widstat arf arfp, ///
        labels("Observations" "C-D F-stat" "K-P F-stat" "A-R F-stat" "A-R p-value") ///
        fmt(%9.0fc %9.3f %9.3f %9.3f %9.3f)) ///
    addnotes("LGA fixed effects: Yes" "Year fixed effects: Yes" ///
        "In addition to the baseline controls, this specification includes the lagged share of the population aged 15-64.")

* 7-2. 노동시장 (성별) - Panel A: Male / Panel B: Female
eststo clear
eststo r7_5: xi: xtivreg2 unempmshare_ageall (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first

eststo r7_6: xi: xtivreg2 highskmshare       (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first

eststo r7_7: xi: xtivreg2 midskmshare       (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first

eststo r7_8: xi: xtivreg2 lowskmshare        (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first

esttab r7_5 r7_6 r7_7 r7_8 using "Robust_add_gender.csv", replace ///
         keep(Xit bachshare_ageall_lag fifteenshare_lag bach_trend fifteen_trend) label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) nogap ///
    mtitles("Overall" "High-Skill" "Middle-Skill" "Low-Skill") ///
    mgroups("Unemployment Rate" "Employment Rate", pattern(1 0 0 0)) ///
    stats(N cdf widstat arf arfp, ///
        labels("Observations" "C-D F-stat" "K-P F-stat" "A-R F-stat" "A-R p-value") ///
        fmt(%9.0fc %9.3f %9.3f %9.3f %9.3f)) ///
    refcat(Xit "Panel A. Male", nolabel) ///
    addnotes("LGA fixed effects: Yes" "Year fixed effects: Yes" ///
        "In addition to the baseline controls, this specification includes the lagged share of the population aged 15-64.")

eststo clear
eststo r7_9:  xi: xtivreg2 unempfshare_ageall (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first

eststo r7_10: xi: xtivreg2 highskfshare       (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first

eststo r7_11: xi: xtivreg2 midskfshare        (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first

eststo r7_12: xi: xtivreg2 lowskfshare        (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first

esttab r7_9 r7_10 r7_11 r7_12 using "Robust_add_gender.csv", append ///
         keep(Xit bachshare_ageall_lag fifteenshare_lag bach_trend fifteen_trend)  label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) nogap ///
    nomtitle nonumber ///
    stats(N cdf widstat arf arfp, ///
        labels("Observations" "C-D F-stat" "K-P F-stat" "A-R F-stat" "A-R p-value") ///
        fmt(%9.0fc %9.3f %9.3f %9.3f %9.3f)) ///
    refcat(Xit "Panel B. Female", nolabel) ///
    addnotes("LGA fixed effects: Yes" "Year fixed effects: Yes" ///
        "In addition to the baseline controls, this specification includes the lagged share of the population aged 15-64.")

* 7-3. 결혼 (20-34세, overall/male/female)
eststo clear
eststo r7_13: xi: xtivreg2 marriedshare_2034       (Xit = Zit) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first

eststo r7_14: xi: xtivreg2 marriedmaleshare_2034   (Xit = Zit) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first

eststo r7_15: xi: xtivreg2 marriedfemaleshare_2034 (Xit = Zit) i.year $demo2  if sample==1, fe cluster(LGAFINAL21) robust first

esttab r7_13 r7_14 r7_15 using "Robust_add_marriage.csv", replace ///
         keep(Xit bachshare_ageall_lag fifteenshare_lag bach_trend fifteen_trend)  label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) nogap ///
    mtitles("Overall" "Male" "Female") ///
    stats(N cdf widstat arf arfp, ///
        labels("Observations" "C-D F-stat" "K-P F-stat" "A-R F-stat" "A-R p-value") ///
        fmt(%9.0fc %9.3f %9.3f %9.3f %9.3f)) ///
    addnotes("LGA fixed effects: Yes" "Year fixed effects: Yes" ///
        "In addition to the baseline controls, this specification includes the lagged share of the population aged 15-64.")

log close
