**********************************************************************  
* Created by Heera Lee 

* Purpose of the program: 
* =====================                                                      
* This program creates immigration shock (explanatory variables and instrumental variables)
* ====================== 
* Immigration in Australia 
* ABS (Australia Burea of Statistics) 
* 2001 census: 1991, 1996, 2001 
* 2016 census: 2006, 2011, 2016 
* 2021 census: 2011, 2016, 2021 (only using 2021 information)
********************************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
	
set more off
************************************************************************
cd "$raw/2016"

forvalues i = 1(1)544 {
import excel using `i'.xls, sheet("T 08") clear
keep A
keep in 2
ren A lga_info
compress
gen LGA2016 = `i'
sort LGA2016
tempfile lga
save `lga'.dta, replace

import excel using `i'.xls, sheet("T 08") clear

keep in 11/47 
keep A B C D F G H J K L
drop if A==""

replace B = "" if B==".."
replace C = "" if C==".."
replace D = "" if D==".."
replace F = "" if F==".."
replace G = "" if G==".."
replace H = "" if H==".."
replace J = "" if J==".."
replace K = "" if K==".."
replace L = "" if L==".."

destring B C D F G H J K L, replace

drop if B==. & C==. & D==. & F==. & G==. & H==. & J==. & K==. & L==.

ren B M1
ren C F1
ren D T1

ren F M2
ren G F2
ren H T2

ren J M3
ren K F3
ren L T3

gen LGA2016 = `i'

sort LGA2016
merge m:1 LGA2016 using `lga'.dta
drop _merge

compress
save "$interim/ABS/X/2016/cob`i'.dta", replace
}

