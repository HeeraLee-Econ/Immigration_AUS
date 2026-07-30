**********************************************************************
* Created by Heera Lee
* Purpose: T02(Selected Medians and Averages) -> 지역-연도 패널
*          2006 census (1996, 2001, 2006 년도 정보 포함)
*          성별 구분 없음. 시트 안에 좌측 블록(A=라벨,B/C/D=연도)과
*          우측 블록(F=라벨,G/H/I=연도)이 나란히 있어서 둘을 합쳐서 씀.
*
* 주의: PART 3(LGAFINAL21 크로스워크 머지 시 n:1 통폐합 지역을 median/average를
*       어떻게 집계할지)는 아직 방식 미정 -> 여기서는 PART 1, 2까지만.
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
**********************************************************************
set more off

local sheet  "T 02"
local lgavar "LGA2006"
local nfiles = 671

capture mkdir "$interim/ABS"
capture mkdir "$interim/ABS/Y/T02"
capture mkdir "$interim/ABS/Y/T02/2006"

**********************************************************************
* PART 1: 671개 LGA 원자료 -> 좌/우 블록 합쳐서 표준 라벨로 cob`i'.dta 저장
**********************************************************************
cd "$raw/2006"

forvalues i = 1/`nfiles' {

    * 2006 폴더는 확장자가 xls/xlsx로 섞여있어서 둘 다 확인
    local ext ""
    capture confirm file "`i'.xls"
    if !_rc local ext "xls"
    else {
        capture confirm file "`i'.xlsx"
        if !_rc local ext "xlsx"
    }
    if "`ext'"=="" {
        di as error "SKIP: T02 2006 i=`i' (xls/xlsx not found/locked)"
        continue
    }

    * LGA 라벨 한 줄
    import excel using `i'.`ext', sheet("`sheet'") clear
    keep A
    keep in 2
    ren A lga_info
    gen `lgavar' = `i'
    tempfile lga
    save `lga'.dta, replace

    * 좌측 블록: A=라벨, B/C/D=1996/2001/2006
    import excel using `i'.`ext', sheet("`sheet'") clear
    keep if A=="Median age of persons" | A=="Median individual income ($/weekly)" | ///
            A=="Median family income ($/weekly)" | A=="Median household income ($/weekly)"
    keep A B C D
    rename (B C D) (val_1996 val_2001 val_2006)
    destring val_1996 val_2001 val_2006, replace force
    tempfile leftblk
    save `leftblk'.dta, replace

    * 우측 블록: F=라벨, G/H/I=1996/2001/2006 -> 좌측과 같은 모양으로 맞춰서 append
    import excel using `i'.`ext', sheet("`sheet'") clear
    keep if F=="Median housing loan repayment ($/monthly)" | F=="Median rent ($/weekly)" | ///
            F=="Average number of persons per bedroom" | F=="Average household size"
    keep F G H I
    ren F A
    rename (G H I) (val_1996 val_2001 val_2006)
    destring val_1996 val_2001 val_2006, replace force

    append using `leftblk'.dta

    * 라벨을 census vintage와 상관없이 통일된 이름으로 표준화 (2006 문구 기준)
    replace A = "med_age"          if A=="Median age of persons"
    replace A = "med_inc_pers"     if A=="Median individual income ($/weekly)"
    replace A = "med_inc_fam"      if A=="Median family income ($/weekly)"
    replace A = "med_inc_hh"       if A=="Median household income ($/weekly)"
    replace A = "med_mortgage"     if A=="Median housing loan repayment ($/monthly)"
    replace A = "med_rent"         if A=="Median rent ($/weekly)"
    replace A = "avg_pers_bedroom" if A=="Average number of persons per bedroom"
    replace A = "avg_hh_size"      if A=="Average household size"

    gen `lgavar' = `i'
    sort `lgavar'
    merge m:1 `lgavar' using `lga'.dta
    drop _merge

    save "$interim/ABS/Y/T02/2006/cob`i'.dta", replace
}

**********************************************************************
* PART 2: cob`i'.dta -> long으로 reshape, 표준 라벨별 변수 생성
*          지역별로 long`i'.dta에 각자 저장 (공유 누적파일 없음 -> 재실행 안전)
**********************************************************************
cd "$interim/ABS/Y/T02/2006"

local lgavar "LGA2006"
local nfiles = 671

forvalues i = 1/`nfiles' {

    capture confirm file "cob`i'.dta"
    if _rc continue

    use cob`i', clear

	reshape long val_, i(A) j(year)

    gen med_age          = val_ if A=="med_age"
    gen med_inc_pers     = val_ if A=="med_inc_pers"
    gen med_inc_fam      = val_ if A=="med_inc_fam"
    gen med_inc_hh       = val_ if A=="med_inc_hh"
    gen med_mortgage     = val_ if A=="med_mortgage"
    gen med_rent         = val_ if A=="med_rent"
    gen avg_pers_bedroom = val_ if A=="avg_pers_bedroom"
    gen avg_hh_size      = val_ if A=="avg_hh_size"

	drop val_* 
	
    collapse (max) med_age med_inc_pers med_inc_fam med_inc_hh ///
        med_mortgage med_rent avg_pers_bedroom avg_hh_size, ///
        by(year `lgavar' lga_info)

    save "long`i'.dta", replace
}

local files ""
forvalues i = 1/`nfiles' {
    capture confirm file "long`i'.dta"
    if !_rc local files "`files' long`i'.dta"
}

local first : word 1 of `files'
local rest : list files - first

use "`first'", clear
append using `rest'
save "T02_2006_long.dta", replace
*********************************************************************
* PART 3: LGAFINAL21 크로스워크 머지(한 번만) + 최종 저장
**********************************************************************
use "T02_2006_long.dta" ,clear 

local lgavar "LGA2006"

preserve
    import excel using "$raw/LGAFINAL_ALL_2021H.xlsx", sheet("`lgavar'") first clear
    sort `lgavar'
    tempfile lgacode
    save `lgacode'.dta, replace
restore

merge m:1 `lgavar' using `lgacode'.dta
tab _merge
keep if _merge==3
drop _merge

/*
* T01에서 만든 인구수(totpop)를 LGA2006 x year 기준으로 가져옴
preserve
    use "$interim/ABS/Y/T01/2006/T01_2006_long.dta", clear
    keep `lgavar' year totpop
    tempfile poplink
    save `poplink'.dta, replace
restore

merge m:1 `lgavar' year using `poplink'.dta
keep if _merge==3
drop _merge
*/

//Median 정보라서 collapse (mean) 사용 
collapse (mean) med_age med_inc_pers med_inc_fam med_inc_hh ///
    med_mortgage med_rent avg_pers_bedroom avg_hh_size, ///
    by(LGAFINAL21 year)

isid LGAFINAL21 year 
tab year 

save "$data/ABS_T02_2006census.dta", replace 
