**********************************************************************
* Created by Heera Lee
* Purpose: append T02 and construct variables for analysis
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
**********************************************************************
use "$data/ABS_T02_2006census.dta", clear 
append using "$data/ABS_T02_2021census.dta"

drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 // 지방정부 없는 미편입지역, 혹은 원주민 소유 원격지, 해외령 

tab year // 496 * 6, 1996~2021

save "$data/ABS_T02_total.dta", replace 
