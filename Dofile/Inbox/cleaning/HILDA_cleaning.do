cd "/Users/ihuila/Library/CloudStorage/OneDrive-성균관대학교/applied micro/HILDA" 

use HIDLA_long.dta, clear 

tab year // 2001~2022년도까지 존재 
**** demographic variables 
* gender: hgsex 
tab hgsex 
gen female = hgsex-1 
tab female, m

* age: hgage, 
gen age = hgage 

/*
* education attainment: edhigh1 
gen edu = edhigh1 
replace edu = 1 if edhigh1>=1 & edhigh <=3 // bachelor ~ postgraduate 
replace edu = 0 
*/

* state: hhstate 
tab hhstate, m 

// fmfcob, fmmcob, edcefd, edpsfdn 

* nationality: ancob, anbcob 
tab ancob 
tab ancob year if ancob==-10
tab anbcob year if anbcob== -10 

gen nation = ancob 
replace nation = 1 if ancob == 1101 // native (Australia)
replace nation = 0 if ancob !=1101 & ancob >0 
replace nation = . if ancob < 0 // missing 

tab ancob,m 
tab nation,m 

* field of study 
tab edcefd 

gen field = edcefd
replace field = 1 if edcefd >=1 & edcefd <=3 // STEM - natural and physical science, information technology, natural sciences 
replace field = 0 if edcefd >3 
replace field = . if edcefd <0 // missing 
replace field =. if edcefd ==. 

tab edcefd, m 
tab field,m 

* cultural norm : atwkwms atwkwfs atwkseh atwkwrl atwkmrl atwkmsw atwkcdw atwkbmw atwkwfr atwkmmf atwkmpl atwkpsc

tab atwkwms, m 
tab atwkmpl, m 

gen polivalue= atwkmpl
replace polivalue=. if atwkmpl == .  | atwkmpl<0 

tab polivalue 

//drop if edcefd == -10 | edcefd== -4 | edcefd == -3 | edcefd== -1 | edcefd == . 
tab edcefd hgsex 

reg field nation // insignificant 
reg field nation, cluster(hhstate)

reg polivalue nation // native 일수록 조금 더 open, significant 
reg polivalue nation#female // immigrants 이고 남성인 사람들에 비해.-> 나머지 세그룹 모두 더 open , significant 

