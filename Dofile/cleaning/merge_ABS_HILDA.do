**********************************************************************  
* Created by Heera Lee 

* Purpose of the program: 
* ======================                                                       *
* This program creates an unbalanced and a balanced longitudinal data file,    *
* using the the combined files. The new data files are in Stata's long format. *
* Please note that we use 'tempfile tempdata_w' to create a macro (local) that *
* allows us to access a temporary data file which will be automatically        *
* deleted when this do-file ends. 
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
**********************************************************************
use "$final/ABS_XY_final.dta" , clear 

gen mergeLGA = LGAFINAL21  // merge키가 되는 변수 만들기 

// MERGE WITH ABS - immigration, other variable data (at LGA level) 
merge 1:m mergeLGA year using "$data/HILDA_Y_long.dta" // HILDA 에서 현재거주지 기준으로 일단 merge 

/*
tab year if _merge==1 
tab year if _merge==2 // ABS - HILDA 연도 어긋난 샘플이라서 
*/

keep if _merge==3 
drop _merge 
// obs = 106,699
***********************************************
// IDENTIFIES singleton AND CONSTRUCT flag variable 

* 완결성 indicator만 만들어두고, 실제 drop은 안 함
gen no_missing_emp      = (employed!=. & edu!=. & hhiage!=. & hgsex!=.)
gen no_missing_marriage = (mrcurr!=.   & edu!=. & hhiage!=. & hgsex!=.)

bys id: egen obs_pp_emp      = total(no_missing_emp)
bys id: egen obs_pp_marriage = total(no_missing_marriage)

save "$final/ABS_HILDA_final.dta" , replace 
