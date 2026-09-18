clear 
cd "/Users/ihuila/Library/CloudStorage/OneDrive-성균관대학교/applied micro/HILDA" 

use long-file-unbalanced

//codebook pjoi61

tab year // 2001~2021년도까지 존재 
gen id = hhrpid 
destring id, replace 

**** outcome variables: internal migration 
* mhreawp mhreast mhreawt mhrealb mhreasm mhreabn mhrealw mhreaas mhreawr mhreahn
* hhmove: household moved address since previous wave 
* hhmovek: distance person moved since last wave 
* hhovek: distnace household moved since last wave 
* hhmovem: distance person moved since last wave (miles)
* hhmvehk: 
* mhyr: year moved to current address 

* dummy moving: hhmove 
tab hhmove 
gen moving = hhmove 
replace moving = . if hhmove <0 

* dummy employment 
gsort hhrpid -year

tab esbrd
gen employ = esbrd 
replace employ =. if esbrd==. | esbrd<0 
replace employ =. if esbrd== 3 
replace employ=1 if esbrd == 1 
replace employ=0 if esbrd==2 
***************************** demographic variables *************************
* gender: hgsex 
tab hgsex 
gen female = hgsex-1 
tab female, m

* age: hgage, 
gen age = hgage 

* education level 
tab edhigh1 

gsort id -year
browse id year edhigh1
by id: gen ed_2001 = edhigh1[_N]
gen highed  = (ed_2001>=1 & ed_2001<=5)
gen lowed = (ed_2001>=8 & ed_2001<=9)

* marital status 
tab mrcurr 

gen marri = mrcurr 
replace marri = . if mrcurr <0 
replace marri = 1 if mrcurr == 1 | mrcurr==2 
replace marri = 0 if mrcurr >=3 & mrcurr <=6 

* state: hhstate 
tab hhstate, m 

* nationality: ancob, anbcob 
tab ancob 
tab ancob year if ancob==-10
tab anbcob year if anbcob== -10 

gen nation = ancob 
replace nation = 1 if ancob == 1101 // native (Australia)
replace nation = 0 if ancob !=1101 & ancob >0 & !missing(ancob)
replace nation = . if ancob < 0 // missing 

tab ancob,m 
tab nation,m 

* industry - ANZSIC2006 
tab pjoi61 
gen indus = pjoi61 
replace indus=. if pjoi61 <0 

tab indus 

tab highed indus, col 


/*
* field of study 
tab edcefd 

gen field = edcefd
replace field = 1 if edcefd >=1 & edcefd <=3 // STEM - natural and physical science, information technology, natural sciences 
replace field = 0 if edcefd >3 
replace field = . if edcefd <0 // missing 
replace field =. if edcefd ==. 

label define field 1 "STEM" 0 "non-STEM"
label values field field 

tab edcefd, m 
tab field,m 

* cultural norm : atwkwms atwkwfs atwkseh atwkwrl atwkmrl atwkmsw atwkcdw atwkbmw atwkwfr atwkmmf atwkmpl atwkpsc

tab atwkwms, m 
count if atwkwms>=1 & atwkwms<=7 

tab atwkmpl, m 
count if atwkmpl>=1 & atwkmpl<=7 

gen polivalue= atwkmpl
replace polivalue=. if atwkmpl == .  | atwkmpl<0 

tab polivalue 

//drop if edcefd == -10 | edcefd== -4 | edcefd == -3 | edcefd== -1 | edcefd == . 
*/
*********************************************************************
//creating moving variables: if they moved LGAs since previous wave, if they ever moved LGAs
gsort id -year 

**create dummy variable to indicate initial wave
egen minyear = min(year), by(id)
gen firstwave = 1 if year==minyear
replace firstwave=0 if firstwave==.

by id: gen movedLGA = (LGAFINAL21 != LGAFINAL21[_n+1]) if firstwave!=1
replace movedLGA=0 if firstwave==1

by id: egen totmovedLGA = total(movedLGA)
gen mover = (totmovedLGA>0)

//will move LGA in future period 
gsort id -year
by id: gen willmoveLGA = (movedLGA[_n-1])

****standard errors - by LGA 
**generate new id variable --> use individual cluster if moved around 
**create new id variable (6 digits) to differentiate from LGA_ALL (4 digits):
gen id_6 = id+100000

by id: gen clusterid1 = LGAFINAL21
by id: replace clusterid1 = id_6 if mover==1

**generate new id variable --> use the LGA_ALL mode as cluster if moved around, tiebreak: minmode
by id: egen clusterid2 = mode(LGAFINAL21), minmode

**generate new id variable --> use the LGA_ALL mode as cluster if moved around, tiebreak: maxmode
by id: egen clusterid3 = mode(LGAFINAL21), maxmode

cd "/Users/ihuila/Library/CloudStorage/OneDrive-성균관대학교/applied micro/HILDA"  
save long_clean.dta, replace
**********************************************************************
***************merge
**************** 도구변수 데이터 
use "/Users/ihuila/Desktop/data/2025ABS/cob_XYZ_final", clear 

sort LGAFINAL21 year 
xtset LGAFINAL21 year 

gen unempl_rate = unemployed/ labor_force 

foreach v in unempl_rate highed_rate labor_force popfifteen Xit Xit2 Xit3 Xit_s Xit2_s Xit3_s Zit Zit2 Zit3 Zit_s Zit2_s Zit3_s  {
    gen `v'_L5 = L5.`v'
}

save "/Users/ihuila/Desktop/data/2025ABS/cob_XYZ_final_HILDAversion", replace 

use long_clean.dta, clear 

// 전년도 지역 변수 만들기, 
sort id year
by id: gen L_LGAFINAL21 = LGAFINAL21[_n-1]

merge m:1 LGAFINAL21 year using "/Users/ihuila/Desktop/data/2025ABS/cob_XYZ_final_HILDAversion"

/*
tab year if _merge==1 // 도구변수에 없는 연도들 
tab year if _merge==2 
tab year if _merge==2 & year>=2001 
br if _merge==2 & year>=2001 
*/

keep if _merge==3 
drop _merge

bys id year: replace Xit  = Xit_L5  if mover==1 & !missing(Xit_L5)

bys id year: replace Xit2 = Xit2_L5 if mover==1 & !missing(Xit2_L5)

bys id year: replace Xit3 = Xit3_L5 if mover==1 & !missing(Xit3_L5)

bys id year: replace Zit = Zit_L5 if mover==1 & !missing(Zit_L5)

bys id year: replace Zit2 = Zit2_L5 if mover==1 & !missing(Zit2_L5)

bys id year: replace Zit3 = Zit3_L5 if mover==1 & !missing(Zit3_L5)

//indicator variables for nonmissing obervations for relevant variables
	//for lscom and hhmove
gen no_missing_lscom=0

replace no_missing_lscom=1 if employ!=. & hhmove!=. & hhmove!=-2 & nation !=. & ancob >0 
 
/*	//for hxy variables
gen no_missing_hxy=0
replace no_missing_hxy=1 if lscom!=. & hhmove!=. & hhmove!=-2 & ancob==1101 & hxytrpi_sh_exc_h!=. & log_housing_cost_A!=.
*/

//variable to identify singletons
bys id: egen obs_pp_lscom=total(no_missing_lscom)
//bys id: egen obs_pp_hxy=total(no_missing_hxy)

//checking sample sizes
count if no_missing_lscom==1 & obs_pp_lscom>1 
**35,167

//count if no_missing_hxy==1 & obs_pp_hxy>1
**152,558

save ABSHILDA_long.dta, replace 
************************************************************************
use ABSHILDA_long.dta, clear 

sort id year 
xtset id year 

global regiondemo highed_rate_L5 unempl_rate_L5 
global regiondemo2 highed_rate_L5 labor_force_L5 
global indidemo i.highed age i.female 

gen sample=1 if employ!=. & hhmove!=. & hhmove!=-2 & nation !=. & ancob >0 
 
xi: xtivreg28 employ i.year  (Xit = Zit) if sample==1, i(id) fe cluster(clusterid3) first // 유의미 
xi: xtivreg28 employ i.year $indidemo  (Xit = Zit) if sample==1, i(id) fe cluster(clusterid3) first // 유의미 
xi: xtivreg28 employ i.year $indidemo $regiondemo2  (Xit = Zit) if sample==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음 

xi: xtivreg28 employ i.year  (Xit2 = Zit2) if sample==1, i(id) fe cluster(clusterid3) first // 유의미 
xi: xtivreg28 employ i.year $indidemo  (Xit2 = Zit2) if sample==1, i(id) fe cluster(clusterid3) first // marginally significant 
xi: xtivreg28 employ i.year $indidemo $regiondemo2  (Xit2 = Zit2) if sample==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음 

xi: xtivreg28 employ i.year  (Xit3 = Zit3) if sample==1, i(id) fe cluster(clusterid3) first // marginally significant , 증가 
xi: xtivreg28 employ i.year $indidemo  (Xit3 = Zit3) if sample==1, i(id) fe cluster(clusterid3) first // marginally significant, 증가 
xi: xtivreg28 employ i.year $indidemo $regiondemo2  (Xit3 = Zit3) if sample==1, i(id) fe cluster(clusterid3) first // marginally significant, 감소 

*******************HETEROGENEITY ANALYSIS*********************************
xi: xtivreg28 employ i.year $indidemo $regiondemo2  (Xit3 = Zit3) if sample==1 & metro2==1, i(id) fe cluster(clusterid3) first // 유의미함, 감소 
xi: xtivreg28 employ i.year $indidemo $regiondemo2  (Xit3 = Zit3) if sample==1 & metro2==0, i(id) fe cluster(clusterid3) first // 유의미하지 않음 


xi: xtivreg28 employ i.year i.highed age $regiondemo2  (Xit3 = Zit3) if sample==1 & female==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음 
xi: xtivreg28 employ i.year i.highed age $regiondemo2  (Xit3 = Zit3) if sample==1 & female==0, i(id) fe cluster(clusterid3) first // 유의미함, 감소

xi: xtivreg28 employ i.year i.female age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음 
xi: xtivreg28 employ i.year i.female age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==0, i(id) fe cluster(clusterid3) first // 유의미하지 않음 

drop sample
gen sample=1 if employ!=. & hhmove!=. & hhmove!=-2 & nation !=. & ancob >0 
 
xi: xtivreg28 employ i.year $indidemo $regiondemo2  (Xit3 = Zit3) if sample==1 & nation==1, i(id) fe cluster(clusterid3) first // 감소 
xi: xtivreg28 employ i.year $indidemo  $regiondemo2  (Xit3 = Zit3) if sample==1 & nation==0, i(id) fe cluster(clusterid3) first // 유의미하지 않음

xi: xtivreg28 employ i.year  age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==1&female==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음 
xi: xtivreg28 employ i.year age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==0&female==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음 
xi: xtivreg28 employ i.year age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==1&female==0, i(id) fe cluster(clusterid3) first // 유의미함 
xi: xtivreg28 employ i.year age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==0&female==0, i(id) fe cluster(clusterid3) first // 유의미하지 않음 
*************************************************************************
******* native들만을 대상으로 
drop sample 
gen sample=1 if employ!=. & hhmove!=. & hhmove!=-2 & nation==1 & ancob >0 
 
 xi: xtivreg28 employ i.year  (Xit = Zit) if sample==1, i(id) fe cluster(clusterid3) first // 유의미, 증가 
xi: xtivreg28 employ i.year $indidemo  (Xit = Zit) if sample==1, i(id) fe cluster(clusterid3) first // 유의미, 증가 
xi: xtivreg28 employ i.year $indidemo $regiondemo2  (Xit = Zit) if sample==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음 

xi: xtivreg28 employ i.year  (Xit2 = Zit2) if sample==1, i(id) fe cluster(clusterid3) first // marginally significant, 증가 
xi: xtivreg28 employ i.year $indidemo  (Xit2 = Zit2) if sample==1, i(id) fe cluster(clusterid3) first // marginally significant, 증가 
xi: xtivreg28 employ i.year $indidemo $regiondemo2  (Xit2 = Zit2) if sample==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음 

xi: xtivreg28 employ i.year  (Xit3 = Zit3) if sample==1, i(id) fe cluster(clusterid3) first //유의미하지 않음 
xi: xtivreg28 employ i.year $indidemo  (Xit3 = Zit3) if sample==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음 
xi: xtivreg28 employ i.year $indidemo $regiondemo2  (Xit3 = Zit3) if sample==1, i(id) fe cluster(clusterid3) first // 유의미, 감소 

********** native에 대한 이질성 분석 
xi: xtivreg28 employ i.year $indidemo $regiondemo2  (Xit3 = Zit3) if sample==1 & metro2==1, i(id) fe cluster(clusterid3) first // 유의미함, 감소 
xi: xtivreg28 employ i.year $indidemo $regiondemo2  (Xit3 = Zit3) if sample==1 & metro2==0, i(id) fe cluster(clusterid3) first // 유의미하지 않음 

xi: xtivreg28 employ i.year i.highed age $regiondemo2  (Xit3 = Zit3) if sample==1 & female==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음 
xi: xtivreg28 employ i.year i.highed age $regiondemo2  (Xit3 = Zit3) if sample==1 & female==0, i(id) fe cluster(clusterid3) first // 유의미함, 감소

xi: xtivreg28 employ i.year i.female age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==1, i(id) fe cluster(clusterid3) first // marginally significant (감소)
xi: xtivreg28 employ i.year i.female age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==0, i(id) fe cluster(clusterid3) first // 유의미하지 않음 

xi: xtivreg28 employ i.year  age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==1&female==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음 
xi: xtivreg28 employ i.year age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==0&female==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음 
xi: xtivreg28 employ i.year age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==1&female==0, i(id) fe cluster(clusterid3) first // 유의미하지 않음 
xi: xtivreg28 employ i.year age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==0&female==0, i(id) fe cluster(clusterid3) first // 유의미함, 감소 

******* immigrants 대상으로 
drop sample 
gen sample=1 if employ!=. & hhmove!=. & hhmove!=-2 & nation==0 & ancob >0 
 
 xi: xtivreg28 employ i.year  (Xit = Zit) if sample==1, i(id) fe cluster(clusterid3) first // 유의미, 증가 
xi: xtivreg28 employ i.year $indidemo  (Xit = Zit) if sample==1, i(id) fe cluster(clusterid3) first // 유의미, 증가 
xi: xtivreg28 employ i.year $indidemo $regiondemo2  (Xit = Zit) if sample==1, i(id) fe cluster(clusterid3) first // marginally significant, 증가 

xi: xtivreg28 employ i.year  (Xit2 = Zit2) if sample==1, i(id) fe cluster(clusterid3) first // marginally significant, 증가 
xi: xtivreg28 employ i.year $indidemo  (Xit2 = Zit2) if sample==1, i(id) fe cluster(clusterid3) first // marginally significant, 증가 
xi: xtivreg28 employ i.year $indidemo $regiondemo2  (Xit2 = Zit2) if sample==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음 

xi: xtivreg28 employ i.year  (Xit3 = Zit3) if sample==1, i(id) fe cluster(clusterid3) first // 유의미함, 증가 
xi: xtivreg28 employ i.year $indidemo  (Xit3 = Zit3) if sample==1, i(id) fe cluster(clusterid3) first // 유의미, 증가 
xi: xtivreg28 employ i.year $indidemo $regiondemo2  (Xit3 = Zit3) if sample==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음

********** immigrants 에 대한 이질성 분석 
xi: xtivreg28 employ i.year i.highed age $regiondemo2  (Xit3 = Zit3) if sample==1 & female==1, i(id) fe cluster(clusterid3) first // 증가 
xi: xtivreg28 employ i.year i.highed age $regiondemo2  (Xit3 = Zit3) if sample==1 & female==0, i(id) fe cluster(clusterid3) first // marginally significant, 감소 

xi: xtivreg28 employ i.year i.female age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음 
xi: xtivreg28 employ i.year i.female age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==0, i(id) fe cluster(clusterid3) first // 유의미하지 않음 

xi: xtivreg28 employ i.year  age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==1&female==1, i(id) fe cluster(clusterid3) first // 유의미하지 않음 
xi: xtivreg28 employ i.year age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==0&female==1, i(id) fe cluster(clusterid3) first // 유의미함. 증가 
xi: xtivreg28 employ i.year age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==1&female==0, i(id) fe cluster(clusterid3) first // 유의미함, 감소 
xi: xtivreg28 employ i.year age $regiondemo2  (Xit3 = Zit3) if sample==1 & highed==0&female==0, i(id) fe cluster(clusterid3) first // 유의미하지 않음 
