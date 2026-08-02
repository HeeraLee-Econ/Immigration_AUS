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
use  "$interim/HILDA/long_unbalanced.dta", clear 
**********************************************************************
* SECTION 2: CLEANING VARIABLE 
* recode missing values 
* cleaning the variable to use the research 
************************************************************************
* check negative values with income variable 
count if hifdip <0 
count if hifdin <0
count if tifdin <0 
count if tifdip <0
count if tifditp <0 
count if tifditn <0 

mvdecode _all, mv(-10/-1) // missing values 
*************************************************************************
***** demograhpic variables 
* gender: hgsex 
// 1: male, 2: female 
/*
tab hgsex 
gen gender = hgsex -1 
tab gender 
*/ 

* age: hhiage 
tab hhiage 

* education: edhigh1 
tab edhigh1,m 
gen edu = 1 if edhigh1>=1  & edhigh1 <= 3 
replace edu =0 if edhigh1 >=4 & edhigh1 <= 9 

replace edu=. if edhigh1==10 

tab edu,m 

label define edu 1 "high educated(bachelor+)" 0 "low educated"
label values edu edu 

* country of birth: ancob
tab ancob, m
// 1101 == native, other values = other countries
gen native = (ancob==1101) if !missing(ancob)

* panel 선언 (marital / employment flow variable 둘 다 여기서 만든 id, xtset 사용)
egen id = group(xwaveid)
xtset id year

* moving: hhmove
*******************************************************************
*************** employment status: esbrd
tab esbrd, m // 1: employed, 2: unemployed, 3: not in the labor force 

gen employed = 1 if esbrd == 1
replace employed = 0 if esbrd ==2 
replace employed = . if esbrd == 3 

tab esbrd,m
tab employed,m 

label define employed 1 "employed" 0 "unemployed" 
label values employed employed 

***************** labor force 
gen laborfor= 1 if esbrd == 1 | esbrd == 2 
replace laborfor= 0 if esbrd == 3
replace laborfor=. if esbrd==. 

tab esbrd,m 
tab laborfor,m
  
label define laborfor 1 "labor force(employed+unemployed)" 0 "not in the labor force"

label values laborfor laborfor 
**************** skill level defined by occupations 
tab jbmo61, m

// High: Managers(1), Professionals(2)
gen skill = 3 if inlist(jbmo61,1,2)

// Middle: Technicians(3), Community(4), Clerical(5) 
replace skill = 2 if inlist(jbmo61,3,4,5) 

// Low: Sales(6), Machine op(7), Labourers(8)
replace skill = 1 if inlist(jbmo61,6,7,8)        

label define skill 1 "Low" 2 "Middle" 3 "High"
label values skill skill

tab jbmo61, m
tab skill, m

* 배타적 카테고리 검산: laborfor = 실업 + 취업, 취업 = high+middle+low skill
* employed==1인데 skill이 결측인 사람이 있으면 state도 결측으로 빠지므로 미리 확인
count if employed==1 & missing(skill)
local n_miss = r(N)
count if employed==1
di "employed 중 skill 결측 비율(%): " %4.2f 100*`n_miss'/r(N)
tab jbmo61 if employed==1 & missing(skill), m

* employment flow variables (immigration inflow -> displacement/complement 분석용)
* risk set = labor force 내부로 고정 
* state: 1 실업, 2 low-skill 취업, 3 middle-skill 취업, 4 high-skill 취업 (laborfor==1 인 사람만 정의)
gen state = skill + 1 if employed==1        // skill(1/2/3)을 그대로 밀어서 재사용 -> 2/3/4
replace state = 1 if laborfor==1 & employed==0

label define state 1 "unemployed" 2 "low-skill" 3 "middle-skill" 4 "high-skill", replace
label values state state

* employed에서 직접 정의 (skill 미분류 때문에 state가 결측이어도 "작년에 취업했었다"는 사실은 놓치지 않기 위함)
gen was_employed_lag = (L.employed==1) if !missing(L.employed)

* 1) 취업 여부 전환 (labor force 안에서의 job-finding / job-loss hazard)
gen newly_employed = (employed==1) if L.state==1
gen job_loss        = (employed==0) if was_employed_lag==1

* 2) high-skill 신규 진입 (complement/upgrading의 headline 지표)
* !missing(state) 추가: 올해 employed인데 skill 무응답이면 "high-skill 아님(0)"이 아니라 결측(모름)으로 남겨야 함
gen newly_high_skill = (state==4) if L.state!=4 & !missing(L.state) & !missing(state)

* 3) skill upgrade/downgrade - 이번 기/전 기 skill이 둘 다 확인된 취업자만 (직업 미분류로 인한 오분류 방지)
gen skill_upgrade   = (skill > L.skill) if was_employed_lag==1 & employed==1 & !missing(skill) & !missing(L.skill)
gen skill_downgrade = (skill < L.skill) if was_employed_lag==1 & employed==1 & !missing(skill) & !missing(L.skill)

************************************************************
* weekly working hours: jbmhruc(hours per week in main jobs) jbhruc(hours per week in all jobs)
tab jbhruc, m 

* wage: wscei wscmei wscoei wscef wscmef wscoef wschave wscme wscoe wscef
tab wscei, m // current weekly gross wages and salary (all jobs, including imputed)
gen lgwage = ln(wscei) if employed==1
*************************************************************
* current marital status: mrcurr 

* risk set: 작년에 결혼상태가 아니었는가 (id, xtset은 위 country of birth 섹션에서 이미 선언함)
gen was_unmarried_lag = (L.mrcurr != 1) if !missing(L.mrcurr)

* flow variable: risk set 중 올해 결혼상태로 전환했는가
gen newly_married = (mrcurr == 1) if was_unmarried_lag == 1 

* stock variable: 
gen married = 1  if mrcurr == 1 
replace married = 0 if mrcurr >=2 & mrcurr <= 6 // 사실혼, 이혼, 별거, 사별, 아예 미혼 포함 
***************************************************************
tab employed state, m // 여기서 employed == 1 or 2 & !missing(state)
tab was_unmarried_lag newly_married, m
***************************************************************
keep  xwaveid id hhrpid hhrhid year wave hhmove hhiage edhigh1 edu ancob native hgsex esbrd jbmo61 jbmo62 jbm682 jbcmocc mrcms mrcurr mrcdur ///
      employed laborfor skill state was_employed_lag newly_employed job_loss newly_high_skill skill_upgrade skill_downgrade ///
      was_unmarried_lag newly_married married hhlga lgwage jbhruc 
  
save "$interim/HILDA/long_cleanedvar.dta", replace
**********************************************************************
* SECTION 3: IDENTIFIES MOVER AND REGION 
**********************************************************************
use "$interim/HILDA/long_cleanedvar.dta" ,replace 

merge m:1 hhlga using "$raw/Prof_raw/LGAHILDA_ALL_LGAFINAL2021_crosswalk.dta"
// merged with region, crosswalk

br if _merge==1 // HILDA 데이터에서 lga 변수 결측 
keep if _merge==3  
drop _merge  // delete 54 obs 

***************************
* step 1: baseline region

** 특정 지역 분석샘플에서 제외 (ABS 데이터에서도 동일)
drop if LGAFINAL21 == 1120 | LGAFINAL21 == 2079 | LGAFINAL21 == 4069 | LGAFINAL21==9001 // 지방정부 없는 미편입지역, 혹은 원주민 소유 원격지, 해외령 

// 각 사람들 최초관측치 연도 기준 - 거주지역 변수 만들기 
bys id (year): gen LGAFINAL21_base = LGAFINAL21[1]
gen clusterid_base = LGAFINAL21_base

*****************************
* step 2: track internal migration 
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

// 이사한 사람들 직전 관측된 연도로 거주지역 넣기 
sort id year
by id: gen L_LGAFINAL21 = LGAFINAL21[_n-1]

gen mergeLGA = LGAFINAL21
replace mergeLGA = L_LGAFINAL21 if mover==1 & !missing(L_LGAFINAL21)

save "$data/HILDA_Y_long.dta", replace
