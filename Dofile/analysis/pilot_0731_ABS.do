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
log using "$output/Log/pilot_0731.smcl", replace
**********************************************************************
* table 1 - unemployment 
* unemployment share (전연령 / 20-34세 / 15-39세, 각각 overall/male/female)

est clear

* 전연령
xi: xtivreg2 unempshare_ageall  (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m1

xi: xtivreg2 unempmshare_ageall (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m2

xi: xtivreg2 unempfshare_ageall (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m3

esttab m*, nogap stats(N cdf widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)


* 20-34세
xi: xtivreg2 unempshare_2034  (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m4

xi: xtivreg2 unempmshare_2034 (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m5

xi: xtivreg2 unempfshare_2034 (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m6

esttab m4 m5 m6, nogap stats(N cdf widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

* 15-39세
xi: xtivreg2 unempshare_1539  (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m7

xi: xtivreg2 unempmshare_1539 (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m8

xi: xtivreg2 unempfshare_1539 (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m9

esttab m7 m8 m9, nogap stats(N cdf widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)


* table 2 - skill composition 
* skill 구성비 (고숙련 / 중숙련 / 저숙련, 각각 overall/male/female)

est clear

* 고숙련
xi: xtivreg2 highskshare  (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m1

xi: xtivreg2 highskmshare (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m2

xi: xtivreg2 highskfshare (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m3

esttab m1 m2 m3, nogap stats(N cdf widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

* 중숙련
xi: xtivreg2 midskshare  (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m4

xi: xtivreg2 midskmshare (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m5

xi: xtivreg2 midskfshare (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m6

esttab m4 m5 m6, nogap stats(N cdf widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

* 저숙련
xi: xtivreg2 lowskshare  (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m7

xi: xtivreg2 lowskmshare (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m8

xi: xtivreg2 lowskfshare (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m9

esttab m7 m8 m9, nogap stats(N cdf widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

* table 3 - marriage
* 기혼 비율 (20-34세 / 15-39세, 각각 overall/male/female)

est clear

* 20-34세
xi: xtivreg2 marriedshare_2034       (Xit = Zit) i.year $demo2 marriagemktsexratio_2034 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m1

xi: xtivreg2 marriedmaleshare_2034   (Xit = Zit) i.year $demo2 marriagemktsexratio_2034 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m2

xi: xtivreg2 marriedfemaleshare_2034 (Xit = Zit) i.year $demo2 marriagemktsexratio_2034 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m3

esttab m1 m2 m3, nogap stats(N cdf widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

* 15-39세
xi: xtivreg2 marriedshare_1539       (Xit = Zit) i.year $demo2 marriagemktsexratio_1539 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m4

xi: xtivreg2 marriedmaleshare_1539   (Xit = Zit) i.year $demo2 marriagemktsexratio_1539 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m5

xi: xtivreg2 marriedfemaleshare_1539 (Xit = Zit) i.year $demo2 marriagemktsexratio_1539 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store m6

esttab m4 m5 m6, nogap stats(N cdf widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

*************
* heterogeneity analysis

preserve
    keep if year == 1996

    * 더미 생성 (1996년 baseline 기준, share_eng는 rename해서 merge 충돌 방지)
    gen high_eng96 = (share_eng >= share_noneng) ///
        if !missing(share_eng)

    label define lbl_eng96 ///
        0 "Low English share" ///
        1 "High English share"
    label values high_eng96 lbl_eng96

    * 확인
    tab high_eng96
    tabstat share_eng, ///
        by(high_eng96) stats(n mean sd min max)

    rename share_eng share_eng96
    keep LGAFINAL21 high_eng96 share_eng96
    duplicates drop LGAFINAL21, force

    tempfile eng96_dummy
    save `eng96_dummy', replace
restore

merge m:1 LGAFINAL21 using `eng96_dummy', nogenerate

* Global 정의
global hetero_higheng "high_eng96 == 1 & !missing(high_eng96)"
global hetero_loweng  "high_eng96 == 0 & !missing(high_eng96)"

* 최종 확인
tab high_eng96 year

**********************************************************************
* heterogeneity 회귀: High English share vs Low English share 그룹별로
* table1/2/3 headline 변수(전연령/2034 overall) 나눠서 비교
**********************************************************************
est clear

* High English share 그룹
xi: xtivreg2 unempshare_ageall (Xit = Zit) i.year $demo2 if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store h1

xi: xtivreg2 highskshare       (Xit = Zit) i.year $demo2 if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store h2

xi: xtivreg2 lowskshare        (Xit = Zit) i.year $demo2 if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store h3

xi: xtivreg2 marriedshare_2034 (Xit = Zit) i.year $demo2 marriagemktsexratio_2034 if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store h4

xi: xtivreg2 marriedmaleshare_2034 (Xit = Zit) i.year $demo2 marriagemktsexratio_2034 if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store h5

xi: xtivreg2 marriedfemaleshare_2034 (Xit = Zit) i.year $demo2 marriagemktsexratio_2034 if sample==1 & $hetero_higheng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store h6

esttab h1 h2 h3 h4 h5 h6, nogap stats(N cdf widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) title(High English share)

* Low English share 그룹
xi: xtivreg2 unempshare_ageall (Xit = Zit) i.year $demo2 if sample==1 & $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store l1

xi: xtivreg2 highskshare       (Xit = Zit) i.year $demo2 if sample==1 & $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store l2

xi: xtivreg2 lowskshare        (Xit = Zit) i.year $demo2 if sample==1 & $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store l3

xi: xtivreg2 marriedshare_2034 (Xit = Zit) i.year $demo2 marriagemktsexratio_2034 if sample==1 & $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store l4

xi: xtivreg2 marriedmaleshare_2034 (Xit = Zit) i.year $demo2 marriagemktsexratio_2034 if sample==1 & $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store l5

xi: xtivreg2 marriedfemaleshare_2034 (Xit = Zit) i.year $demo2 marriagemktsexratio_2034 if sample==1 & $hetero_loweng, fe cluster(LGAFINAL21) robust first savefprefix(fs_)
est store l6 

esttab l1 l2 l3 l4 l5 l6, nogap stats(N cdf widstat arf arfp)  r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) title(Low English share)

log close
