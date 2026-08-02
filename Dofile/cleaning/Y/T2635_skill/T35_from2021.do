**********************************************************************
* Created by Heera Lee
* Purpose: T35(Occupation by Sex) -> 지역-연도 패널
*          2021 census (2011, 2016, 2021 년도 정보 포함)
*          T26(2006)과 동일 구조: 시트 하나("T35")에 연도가 "가로 컬럼그룹"으로
*          나란히 있음 (2011: B/C/D=M/F/Persons, 2016: F/G/H, 2021: J/K/L)
*          연령 구분 없음(occupation by SEX만)
*
*          Persons 컬럼(D/H/L)은 스킵, Males/Females만 사용
*          "Inadequately described/Not stated" 행은 스킵
*
*          긁어오는 직업분류(8개, 각각 별도 변수 유지) + Total(그랜드토탈):
*          Managers / Professionals / Technicians and trades workers /
*          Community and personal service workers / Clerical and administrative
*          workers / Sales workers / Machinery operators and drivers / Labourers
*          (2021 라벨엔 "Technicians and trades workers"에 (b) 각주표시가 없음 - 2006과 문구만 다름)
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
**********************************************************************
set more off

local sheet  "T35"
local ext    "xlsx"
local lgavar "LGA2021"
local nfiles = 547

**********************************************************************
* PART 1: 547개 LGA 원자료 -> 필요한 행만 뽑아서 cob`i'.dta로 저장
**********************************************************************
cd "$raw/2021"

forvalues i = 1/`nfiles' {

    * 2021 폴더는 전부 .xlsx라 파일 존재여부만 확인
    capture confirm file "`i'.`ext'"
    if _rc {
        di as error "SKIP: T35 2021 i=`i' (`i'.`ext' not found/locked)"
        continue
    }

    * LGA 라벨 한 줄
    capture noisily import excel using `i'.`ext', sheet("`sheet'") clear
    if _rc {
        di as error "SKIP: T35 2021 i=`i' (`sheet' sheet not found)"
        continue
    }
    keep A
    keep in 2
    ren A lga_info
    gen `lgavar' = `i'
    tempfile lga
    save `lga'.dta, replace

    * 본 데이터: 필요한 행만 라벨 기준으로 (Inadequately described/Not stated 제외)
    import excel using `i'.`ext', sheet("`sheet'") clear
    keep if A=="Managers" | A=="Professionals" | A=="Technicians and trades workers" | ///
            A=="Community and personal service workers" | A=="Clerical and administrative workers" | ///
            A=="Sales workers" | A=="Machinery operators and drivers" | A=="Labourers" | A=="Total"
    keep A B C F G J K
    destring B C F G J K, replace force

    * B/C=2011(M/F), F/G=2016(M/F), J/K=2021(M/F) (원본 시트 직접 확인함)
    rename (B C) (male_2011 female_2011)
    rename (F G) (male_2016 female_2016)
    rename (J K) (male_2021 female_2021)

    gen `lgavar' = `i'
    sort `lgavar'
    merge m:1 `lgavar' using `lga'.dta
    drop _merge

    save "$interim/ABS/Y/T2635/2021/cob`i'.dta", replace
}

**********************************************************************
* PART 2: cob`i'.dta -> long으로 reshape 후 직업분류별 가로(wide)변수 생성,
*          지역-연도 단위로 collapse. 지역별로 long`i'.dta에 각자 저장
*          (공유 누적파일 없음 -> 재실행 안전)
**********************************************************************
cd "$interim/ABS/Y/T2635/2021"

local lgavar "LGA2021"

forvalues i = 1(1)547 {

    use cob`i', clear

    reshape long male_ female_, i(A) j(year)

    * 변수명 규칙: {직업분류}_{성별} (T35은 연령 구분이 없어서 연령코드 없음)
    gen managers_m       = male_   if A=="Managers"
    gen managers_f       = female_ if A=="Managers"
    gen professionals_m  = male_   if A=="Professionals"
    gen professionals_f  = female_ if A=="Professionals"
    gen techtrades_m     = male_   if A=="Technicians and trades workers"
    gen techtrades_f     = female_ if A=="Technicians and trades workers"
    gen comservice_m     = male_   if A=="Community and personal service workers"
    gen comservice_f     = female_ if A=="Community and personal service workers"
    gen clerical_m       = male_   if A=="Clerical and administrative workers"
    gen clerical_f       = female_ if A=="Clerical and administrative workers"
    gen sales_m          = male_   if A=="Sales workers"
    gen sales_f          = female_ if A=="Sales workers"
    gen machinery_m      = male_   if A=="Machinery operators and drivers"
    gen machinery_f      = female_ if A=="Machinery operators and drivers"
    gen labourers_m      = male_   if A=="Labourers"
    gen labourers_f      = female_ if A=="Labourers"
    gen total_m          = male_   if A=="Total"
    gen total_f          = female_ if A=="Total"

    drop male_ female_ A

    collapse (max) ///
        managers_m managers_f professionals_m professionals_f ///
        techtrades_m techtrades_f comservice_m comservice_f ///
        clerical_m clerical_f sales_m sales_f ///
        machinery_m machinery_f labourers_m labourers_f ///
        total_m total_f, ///
        by(year `lgavar' lga_info)

    save "long`i'.dta", replace
}

local files ""
forvalues i = 1(1)547 {
    capture confirm file "long`i'.dta"
    if !_rc local files "`files' long`i'.dta"
}

local first : word 1 of `files'
local rest : list files - first

use "`first'", clear
append using `rest'
save "T35_2021_long.dta", replace

**********************************************************************
* PART 3: LGAFINAL21 크로스워크 머지(한 번만) + 최종 저장
**********************************************************************
use "T35_2021_long.dta", clear

local lgavar "LGA2021"

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

* n:1 지역통폐합 있을 수 있어 사람 수(count)라서 합산으로 마무리
collapse (sum) ///
    managers_m managers_f professionals_m professionals_f ///
    techtrades_m techtrades_f comservice_m comservice_f ///
    clerical_m clerical_f sales_m sales_f ///
    machinery_m machinery_f labourers_m labourers_f ///
    total_m total_f, ///
    by(LGAFINAL21 year)

isid LGAFINAL21 year
tab year

order LGAFINAL21 year
sort LGAFINAL21 year

save "$data/ABS_T35_2021census.dta", replace
