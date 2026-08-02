**********************************************************************
**********************************************************************  
* Created by Heera Lee 

* Purpose of the program: 
* ======================                                                       *
* This program creates an unbalanced and a balanced longitudinal data file,    *
* using the the combined files. The new data files are in Stata's long format. *
* Please note that we use 'tempfile tempdata_w' to create a macro (local) that *
* allows us to access a temporary data file which will be automatically        *
* deleted when this do-file ends. 
* for analysis (regional level explanatory var - individual level outcomes)
* ====================== 
* Immigration in Australia 
* HILDA panel data clean do-file
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
	global output "${main}/Output"
**********************************************************************
use "$final/ABS_HILDA_final.dta", clear

sort id year
xtset id year

global regiondemo2 fifteenshare_lag bachshare_ageall_lag fifteen_trend bach_trend
global indidemo edu hhiage i.hgsex

// Log
capture log close
log using "$output/Log/pilot_0731_HILDA.log", replace 

**********************************************************************
* sample indicator (merge_ABS_HILDA.do에서 만든 no_missing_*/obs_pp_* 기반)
**********************************************************************
gen sample_emp      = 1 if no_missing_emp==1      & obs_pp_emp>=3
gen sample_marriage = 1 if no_missing_marriage==1 & obs_pp_marriage>=3
**********************************************************************
* table 1 - employment (flow + level)
**********************************************************************
est clear

xi: xtivreg2 employed         i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store m1

xi: xtivreg2 newly_employed   i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store m2

xi: xtivreg2 job_loss         i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store m3

xi: xtivreg2 newly_high_skill i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store m4

xi: xtivreg2 skill_upgrade    i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store m5

xi: xtivreg2 skill_downgrade  i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store m6

esttab m1 m2 m3 m4 m5 m6, nogap stats(N cdf widstat arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

**********************************************************************
* table 2 - marriage (flow + level)
**********************************************************************
est clear

xi: xtivreg2 married       i.year $indidemo $regiondemo2 (Xit = Zit) if sample_marriage==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store m1

xi: xtivreg2 newly_married i.year $indidemo $regiondemo2 (Xit = Zit) if sample_marriage==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store m2

esttab m1 m2, nogap stats(N cdf widstat arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01)

**********************************************************************
* heterogeneity analysis - native vs immigrant (native==1/0 기준)
* table 1/2의 outcome 전부를 native/immigrant로 나눠서 재실행
**********************************************************************
est clear

* native (native==1)
xi: xtivreg2 employed         i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1 & native==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store n1

xi: xtivreg2 newly_employed   i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1 & native==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store n2

xi: xtivreg2 job_loss         i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1 & native==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store n3

xi: xtivreg2 newly_high_skill i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1 & native==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store n4

xi: xtivreg2 skill_upgrade    i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1 & native==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store n5

xi: xtivreg2 skill_downgrade  i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1 & native==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store n6

xi: xtivreg2 married          i.year $indidemo $regiondemo2 (Xit = Zit) if sample_marriage==1 & native==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store n7

xi: xtivreg2 newly_married    i.year $indidemo $regiondemo2 (Xit = Zit) if sample_marriage==1 & native==1, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store n8

esttab n1 n2 n3 n4 n5 n6 n7 n8, nogap stats(N cdf widstat arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) title(Native, native==1)

* immigrant (native==0)
xi: xtivreg2 employed         i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1 & native==0, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store i1

xi: xtivreg2 newly_employed   i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1 & native==0, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store i2

xi: xtivreg2 job_loss         i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1 & native==0, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store i3

xi: xtivreg2 newly_high_skill i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1 & native==0, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store i4

xi: xtivreg2 skill_upgrade    i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1 & native==0, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store i5

xi: xtivreg2 skill_downgrade  i.year $indidemo $regiondemo2 (Xit = Zit) if sample_emp==1 & native==0, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store i6

xi: xtivreg2 married          i.year $indidemo $regiondemo2 (Xit = Zit) if sample_marriage==1 & native==0, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store i7

xi: xtivreg2 newly_married    i.year $indidemo $regiondemo2 (Xit = Zit) if sample_marriage==1 & native==0, i(id) fe cluster(clusterid3) robust first savefprefix(fs_)
est store i8

esttab i1 i2 i3 i4 i5 i6 i7 i8, nogap stats(N cdf widstat arf arfp) r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) title(Immigrant, native==0)

log close
