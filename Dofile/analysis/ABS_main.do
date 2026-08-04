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

// Log 
capture log close
log using "$output/Log/Main_0731.smcl", replace

**********************************************************************
* 논문용 최종 테이블 (esttab -> .csv export)
**********************************************************************
cd "$output/Table"

**********************************************************************
* Table 1: Summary statistics
**********************************************************************
estpost summarize Xit if sample==1
esttab using "summary.csv", replace ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") ///
    nomtitle nonumber label noobs ///
    refcat(Xit "Panel A. Immigration Exposure", nolabel)

estpost summarize unempshare_ageall highskshare midskshare lowskshare if sample==1
esttab using "summary.csv", append ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") ///
    nomtitle nonumber label noobs ///
    refcat(unempshare_ageall "Panel B. Labor Market Outcomes (Overall)", nolabel)

// employment by gender 
estpost summarize unempmshare_ageall unempfshare_ageall ///
    highskmshare highskfshare midskmshare midskfshare lowskmshare lowskfshare if sample==1
esttab using "summary.csv", append ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") ///
    nomtitle nonumber label noobs ///
    refcat(unempmshare_ageall "Panel C. Labor Market Outcomes (By Gender)", nolabel)

// marriage 
estpost summarize marriedshare_2034 marriedmaleshare_2034 marriedfemaleshare_2034 if sample==1
esttab using "summary.csv", append ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") ///
    nomtitle nonumber label noobs ///
    refcat(marriedshare_2034 "Panel D. Marriage Outcomes", nolabel)

**********************************************************************
* Table 3: The Effects of Immigration on Labor Market Outcomes
* (Panel A: Pooled OLS / Panel B: FE / Panel C: FE-IV)
**********************************************************************
* Panel A - Pooled OLS (with controls)
eststo clear
eststo a1: xi: reg unempshare_ageall Xit i.year $demo if sample==1, vce(cluster LGAFINAL21)
eststo a2: xi: reg highskshare       Xit i.year $demo if sample==1, vce(cluster LGAFINAL21)
eststo a3: xi: reg midskshare        Xit i.year $demo if sample==1, vce(cluster LGAFINAL21)
eststo a4: xi: reg lowskshare        Xit i.year $demo if sample==1, vce(cluster LGAFINAL21)

esttab a1 a2 a3 a4 using "Table3.csv", replace ///
    keep(Xit) label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) nogap ///
    mtitles("Overall" "High-Skill" "Middle-Skill" "Low-Skill") ///
    mgroups("Unemployment Rate" "Employment Rate", pattern(1 0 0 0)) ///
    stats(N, labels("Observations") fmt(%9.0fc)) ///
    refcat(Xit "Panel A. Pooled OLS Estimation", nolabel) ///
    addnotes("LGA fixed effects: Yes" "Year fixed effects: Yes" "Control variables: Yes")

* Panel B - FE (with controls)
eststo clear
eststo b1: xi: xtivreg2 unempshare_ageall Xit i.year $demo if sample==1, ///
cluster(LGAFINAL21) robust first fe 
eststo b2: xi: xtivreg2 highskshare       Xit i.year $demo if sample==1, ///
cluster(LGAFINAL21) robust first fe 
eststo b3: xi: xtivreg2 midskshare        Xit i.year $demo if sample==1, ///
cluster(LGAFINAL21) robust first fe 
eststo b4: xi: xtivreg2 lowskshare        Xit i.year $demo if sample==1, ///
cluster(LGAFINAL21) robust first fe 

esttab b1 b2 b3 b4 using "Table3.csv", append ///
    keep(Xit) label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) nogap ///
    nomtitle nonumber ///
    stats(N, labels("Observations") fmt(%9.0fc)) ///
    refcat(Xit "Panel B. FE Estimation", nolabel) ///
    addnotes("LGA fixed effects: Yes" "Year fixed effects: Yes" "Control variables: Yes")

* Panel C - FE-IV (with controls)
eststo clear
eststo c1: xi: xtivreg2 unempshare_ageall (Xit = Zit) i.year $demo if sample==1, cluster(LGAFINAL21) robust first fe
eststo c2: xi: xtivreg2 highskshare       (Xit = Zit) i.year $demo if sample==1, cluster(LGAFINAL21) robust first fe
eststo c3: xi: xtivreg2 midskshare        (Xit = Zit) i.year $demo if sample==1, cluster(LGAFINAL21) robust first fe
eststo c4: xi: xtivreg2 lowskshare        (Xit = Zit) i.year $demo if sample==1, cluster(LGAFINAL21) robust first fe

esttab c1 c2 c3 c4 using "Table3.csv", append ///
    keep(Xit) label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) nogap ///
    nomtitle nonumber ///
    stats(N cdf widstat arf arfp, ///
        labels("Observations" "C-D F-stat" "K-P F-stat" "A-R F-stat" "A-R p-value") ///
        fmt(%9.0fc %9.3f %9.3f %9.3f %9.3f)) ///
    refcat(Xit "Panel C. FE-IV Estimation", nolabel) ///
    addnotes("LGA fixed effects: Yes" "Year fixed effects: Yes" "Control variables: Yes")

**********************************************************************
* Table 4: The Effects of Immigration on Labor Market Outcomes by Gender
* (Panel A: Male / Panel B: Female, FE-IV만)
**********************************************************************
* Panel A - Male
eststo clear
eststo ma1: xi: xtivreg2 unempmshare_ageall (Xit = Zit) i.year $demo if sample==1, cluster(LGAFINAL21) robust first fe
eststo ma2: xi: xtivreg2 highskmshare       (Xit = Zit) i.year $demo if sample==1, cluster(LGAFINAL21) robust first fe
eststo ma3: xi: xtivreg2 midskmshare        (Xit = Zit) i.year $demo if sample==1, cluster(LGAFINAL21) robust first fe
eststo ma4: xi: xtivreg2 lowskmshare        (Xit = Zit) i.year $demo if sample==1, cluster(LGAFINAL21) robust first fe

esttab ma1 ma2 ma3 ma4 using "Table4.csv", replace ///
    keep(Xit) label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) nogap ///
    mtitles("Overall" "High-Skill" "Middle-Skill" "Low-Skill") ///
    mgroups("Unemployment Rate" "Employment Rate", pattern(1 0 0 0)) ///
    stats(N cdf widstat arf arfp, ///
        labels("Observations" "C-D F-stat" "K-P F-stat" "A-R F-stat" "A-R p-value") ///
        fmt(%9.0fc %9.3f %9.3f %9.3f %9.3f)) ///
    refcat(Xit "Panel A. Male", nolabel) ///
    addnotes("LGA fixed effects: Yes" "Year fixed effects: Yes" "Control variables: Yes")

* Panel B - Female
eststo clear
eststo fe1: xi: xtivreg2 unempfshare_ageall (Xit = Zit) i.year $demo if sample==1, cluster(LGAFINAL21) robust first fe
eststo fe2: xi: xtivreg2 highskfshare       (Xit = Zit) i.year $demo if sample==1, cluster(LGAFINAL21) robust first fe
eststo fe3: xi: xtivreg2 midskfshare        (Xit = Zit) i.year $demo if sample==1, cluster(LGAFINAL21) robust first fe
eststo fe4: xi: xtivreg2 lowskfshare        (Xit = Zit) i.year $demo if sample==1, cluster(LGAFINAL21) robust first fe

esttab fe1 fe2 fe3 fe4 using "Table4.csv", append ///
    keep(Xit) label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) nogap ///
    nomtitle nonumber ///
    stats(N cdf widstat arf arfp, ///
        labels("Observations" "C-D F-stat" "K-P F-stat" "A-R F-stat" "A-R p-value") ///
        fmt(%9.0fc %9.3f %9.3f %9.3f %9.3f)) ///
    refcat(Xit "Panel B. Female", nolabel) ///
    addnotes("LGA fixed effects: Yes" "Year fixed effects: Yes" "Control variables: Yes")

**********************************************************************
* Table 5: The Effects of Immigration on Marriage Share (FE-IV만, panel 없음)
**********************************************************************
eststo clear
eststo t5_1: xi: xtivreg2 marriedshare_2034       (Xit = Zit) i.year $demo marriagemktsexratio_2034 if sample==1, cluster(LGAFINAL21) robust first fe
eststo t5_2: xi: xtivreg2 marriedmaleshare_2034   (Xit = Zit) i.year $demo marriagemktsexratio_2034 if sample==1, cluster(LGAFINAL21) robust first fe
eststo t5_3: xi: xtivreg2 marriedfemaleshare_2034 (Xit = Zit) i.year $demo marriagemktsexratio_2034 if sample==1, cluster(LGAFINAL21) robust first fe

esttab t5_1 t5_2 t5_3 using "Table5.csv", replace ///
    keep(Xit) label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) nogap ///
    mtitles("Overall" "Male" "Female") ///
    stats(N cdf widstat arf arfp, ///
        labels("Observations" "C-D F-stat" "K-P F-stat" "A-R F-stat" "A-R p-value") ///
        fmt(%9.0fc %9.3f %9.3f %9.3f %9.3f)) ///
    addnotes("LGA fixed effects: Yes" "Year fixed effects: Yes" "Control variables: Yes")

**********************************************************************
* Table 6: Heterogeneity Analysis by English-Speaking Immigrant Concentration
* (High-English 3열 + Low-English 3열, FE-IV만)
**********************************************************************
* heterogeneity analysis

preserve
    keep if year == 2001

    * 더미 생성 (2001년 baseline 기준, median split)
    summarize share_eng, detail
    local med_eng = r(p50)

    gen high_eng01 = (share_eng >= `med_eng') ///
        if !missing(share_eng)

    label define lbl_eng01 ///
        0 "Low English share" ///
        1 "High English share"
    label values high_eng01 lbl_eng01

    * 확인
    tab high_eng01
    tabstat share_eng, ///
        by(high_eng01) stats(n mean median sd min max)

    rename share_eng share_eng01
    keep LGAFINAL21 high_eng01 share_eng01
    duplicates drop LGAFINAL21, force

    tempfile eng01_dummy
    save `eng01_dummy', replace
restore

merge m:1 LGAFINAL21 using `eng01_dummy', nogenerate

* Global 정의
global hetero_higheng "high_eng01 == 1 & !missing(high_eng01)"
global hetero_loweng  "high_eng01 == 0 & !missing(high_eng01)"

* 최종 확인
tab high_eng01 year
**********************************************************************
eststo clear
eststo t6_1: xi: xtivreg2 marriedshare_2034       (Xit = Zit) i.year $demo marriagemktsexratio_2034 if sample==1 & $hetero_higheng, cluster(LGAFINAL21) robust first fe

eststo t6_2: xi: xtivreg2 marriedmaleshare_2034   (Xit = Zit) i.year $demo marriagemktsexratio_2034 if sample==1 & $hetero_higheng, cluster(LGAFINAL21) robust first fe

eststo t6_3: xi: xtivreg2 marriedfemaleshare_2034 (Xit = Zit) i.year $demo marriagemktsexratio_2034 if sample==1 & $hetero_higheng, cluster(LGAFINAL21) robust first fe

eststo t6_4: xi: xtivreg2 marriedshare_2034       (Xit = Zit) i.year $demo marriagemktsexratio_2034 if sample==1 & $hetero_loweng, cluster(LGAFINAL21) robust first fe

eststo t6_5: xi: xtivreg2 marriedmaleshare_2034   (Xit = Zit) i.year $demo marriagemktsexratio_2034 if sample==1 & $hetero_loweng, cluster(LGAFINAL21) robust first fe

eststo t6_6: xi: xtivreg2 marriedfemaleshare_2034 (Xit = Zit) i.year $demo marriagemktsexratio_2034 if sample==1 & $hetero_loweng, cluster(LGAFINAL21) robust first fe

esttab t6_1 t6_2 t6_3 t6_4 t6_5 t6_6 using "Table6.csv", replace ///
    keep(Xit) label b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) nogap ///
    mtitles("Marriage Share" "Male" "Female" "Marriage Share" "Male" "Female") ///
    mgroups("High English-Speaking Share" "Low English-Speaking Share", pattern(1 0 0 1 0 0)) ///
    stats(N cdf widstat arf arfp, ///
        labels("Observations" "C-D F-stat" "K-P F-stat" "A-R F-stat" "A-R p-value") ///
        fmt(%9.0fc %9.3f %9.3f %9.3f %9.3f)) ///
    addnotes("LGA fixed effects: Yes" "Year fixed effects: Yes" "Control variables: Yes" ///
        "Regions are classified as high (low) English-speaking if the share of immigrants from" ///
        "English-speaking countries in 1996 is above (below) the sample median.")

log close 
