**********************************************************************
* Created by Heera Lee
* Purpose: append T01 and construct variables for analysis
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
**********************************************************************
use "$data/ABS_T01_2006census.dta", clear 
append using "$data/ABS_T01_2021census.dta"

drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 // 지방정부 없는 미편입지역, 혹은 원주민 소유 원격지, 해외령 

tab year // 496 * 6, 1996~2021

* totpop/tot_mpop/tot_fpop는 그대로 유지 + share 변수 추가 생성
gen maleshare    = tot_mpop / totpop
gen femaleshare  = tot_fpop / totpop
gen oldshare     = popold / totpop
gen fifteenshare = popfifteen / totpop

keep maleshare femaleshare oldshare fifteenshare totpop tot_mpop tot_fpop LGAFINAL21 year 

save "$data/ABS_T01_total.dta", replace 

