***** STEP4: metropolitan area 
clear 

import excel "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_metrostatus1.xlsx", sheet("LGAFINAL_Metro") firstrow clear

gen metro2 = 1 if metro == 1 | outermetro == 1 
replace metro2 = 0 if metro2==. 

cd "/Users/ihuila/Desktop/data/2025ABS/afterControl"

save metropolitan.dta, replace 

clear 
import excel using "/Users/ihuila/Desktop/data/2025ABS/rawdata/LGAFINAL_ALL_2021H.xlsx", sheet("LGA2001") firstrow clear 

merge m:1 LGAFINAL using metropolitan.dta 

drop if _merge!=3 
drop _merge 

cd "/Users/ihuila/Library/CloudStorage/OneDrive-성균관대학교/applied micro/HILDA"
save metropolitan.dta, replace 
