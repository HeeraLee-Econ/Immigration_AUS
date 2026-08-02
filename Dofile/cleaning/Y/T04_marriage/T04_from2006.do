**********************************************************************
* Created by Heera Lee
* Purpose: T04(Marital Status by Age by Sex) -> 지역-연도 패널
*          2006 census (1996, 2001, 2006 년도 정보 포함)
*          T 04a 시트(1996, 2001 두 연도블록) + T 04b 시트(2006 한 연도블록)를 합침
*          시트 안에서 연도가 "가로 컬럼"이 아니라 "세로 행블록"으로 쌓여있어서
*          (예: 1996 CENSUS 표시행 -> 15-19...Total 행들 -> 2001 CENSUS 표시행 -> ...)
*          연도 표시행(marker row)을 찾아서 fill-down으로 year를 채워준 뒤 사용.
*
*          긁어오는 항목: Married(M/F), Never married(M/F), Total(M/F만, Persons는 제외)
*          긁어오는 연령대: 15-19 ~ 35-39 (5세단위 5개 구간) + 가로(연령합산) Total
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
**********************************************************************
set more off

local lgavar "LGA2006"
local nfiles = 671

capture mkdir "$interim/ABS"
capture mkdir "$interim/ABS/Y/T04"
capture mkdir "$interim/ABS/Y/T04/2006"

* 긁어올 연령대 + Total (가로 라벨)
local agelabels `" "15-19 years" "20-24 years" "25-29 years" "30-34 years" "35-39 years" "Total" "'

**********************************************************************
* PART 1: 671개 LGA 원자료 -> T04a(1996,2001) + T04b(2006) 합쳐서 cob`i'.dta 저장
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
        di as error "SKIP: T04 2006 i=`i' (xls/xlsx not found/locked)"
        continue
    }

    * LGA 라벨 한 줄 (T 04a 기준)
    capture noisily import excel using `i'.`ext', sheet("T 04a") clear
    if _rc {
        di as error "SKIP: T04 2006 i=`i' (T 04a sheet not found)"
        continue
    }
    keep A
    keep in 2
    ren A lga_info
    gen `lgavar' = `i'
    tempfile lga
    save `lga'.dta, replace

    * ---- T 04a: 1996 + 2001 두 연도블록 ----
    import excel using `i'.`ext', sheet("T 04a") clear
    keep A B C N O Q R

    gen year = .
    replace year = 1996 if B=="1996 CENSUS"
    replace year = 2001 if B=="2001 CENSUS"
    forvalues r = 1/30 {
        replace year = year[_n-1] if missing(year) & _n>1
    }

    keep if inlist(A, "15-19 years","20-24 years","25-29 years","30-34 years","35-39 years","Total")

    rename (B C) (married_m married_f)
    rename (N O) (nevermarried_m nevermarried_f)
    rename (Q R) (totpop_m totpop_f)
    destring married_m married_f nevermarried_m nevermarried_f totpop_m totpop_f, replace force

    tempfile parta
    save `parta'.dta, replace

    * ---- T 04b: 2006 한 연도블록 ----
    import excel using `i'.`ext', sheet("T 04b") clear
    keep A B C N O Q R

    gen year = .
    replace year = 2006 if B=="2006 CENSUS"
    forvalues r = 1/30 {
        replace year = year[_n-1] if missing(year) & _n>1
    }

    keep if inlist(A, "15-19 years","20-24 years","25-29 years","30-34 years","35-39 years","Total")

    rename (B C) (married_m married_f)
    rename (N O) (nevermarried_m nevermarried_f)
    rename (Q R) (totpop_m totpop_f)
    destring married_m married_f nevermarried_m nevermarried_f totpop_m totpop_f, replace force

    append using `parta'.dta

    gen `lgavar' = `i'
    sort `lgavar' year
    merge m:1 `lgavar' using `lga'.dta
    drop _merge

    save "$interim/ABS/Y/T04/2006/cob`i'.dta", replace
}

**********************************************************************
* PART 2: cob`i'.dta -> 연령대별로 가로(wide)변수 생성, 지역-연도 단위로 collapse
*          지역별로 long`i'.dta에 각자 저장 (공유 누적파일 없음 -> 재실행 안전)
**********************************************************************
cd "$interim/ABS/Y/T04/2006"

local lgavar "LGA2006"
	
forvalues i = 1(1)671 {

    use cob`i', clear

    * 변수명 규칙: {혼인상태}_{성별}_{연령코드}
    *   혼인상태: married(기혼) / nevermarried(미혼) / totpop(원자료의 "가로" Total 컬럼그룹 = 혼인상태 전체합)
    *   연령코드: 1519~3539(5세단위) / ageall(원자료의 "세로" Total 행 = 해당 혼인상태의 전연령 합)
    gen married_m_1519   = married_m if A=="15-19 years"
    gen married_m_2024   = married_m if A=="20-24 years"
    gen married_m_2529   = married_m if A=="25-29 years"
    gen married_m_3034   = married_m if A=="30-34 years"
    gen married_m_3539   = married_m if A=="35-39 years"
    gen married_m_ageall = married_m if A=="Total"

    gen married_f_1519   = married_f if A=="15-19 years"
    gen married_f_2024   = married_f if A=="20-24 years"
    gen married_f_2529   = married_f if A=="25-29 years"
    gen married_f_3034   = married_f if A=="30-34 years"
    gen married_f_3539   = married_f if A=="35-39 years"
    gen married_f_ageall = married_f if A=="Total"

    gen nevermarried_m_1519   = nevermarried_m if A=="15-19 years"
    gen nevermarried_m_2024   = nevermarried_m if A=="20-24 years"
    gen nevermarried_m_2529   = nevermarried_m if A=="25-29 years"
    gen nevermarried_m_3034   = nevermarried_m if A=="30-34 years"
    gen nevermarried_m_3539   = nevermarried_m if A=="35-39 years"
    gen nevermarried_m_ageall = nevermarried_m if A=="Total"

    gen nevermarried_f_1519   = nevermarried_f if A=="15-19 years"
    gen nevermarried_f_2024   = nevermarried_f if A=="20-24 years"
    gen nevermarried_f_2529   = nevermarried_f if A=="25-29 years"
    gen nevermarried_f_3034   = nevermarried_f if A=="30-34 years"
    gen nevermarried_f_3539   = nevermarried_f if A=="35-39 years"
    gen nevermarried_f_ageall = nevermarried_f if A=="Total"

    gen totpop_m_1519   = totpop_m if A=="15-19 years"
    gen totpop_m_2024   = totpop_m if A=="20-24 years"
    gen totpop_m_2529   = totpop_m if A=="25-29 years"
    gen totpop_m_3034   = totpop_m if A=="30-34 years"
    gen totpop_m_3539   = totpop_m if A=="35-39 years"
    gen totpop_m_ageall = totpop_m if A=="Total" // From sheet T04 

    gen totpop_f_1519   = totpop_f if A=="15-19 years"
    gen totpop_f_2024   = totpop_f if A=="20-24 years"
    gen totpop_f_2529   = totpop_f if A=="25-29 years"
    gen totpop_f_3034   = totpop_f if A=="30-34 years"
    gen totpop_f_3539   = totpop_f if A=="35-39 years"
    gen totpop_f_ageall = totpop_f if A=="Total" // From sheet T04 

    drop married_m married_f nevermarried_m nevermarried_f totpop_m totpop_f

    collapse (max) ///
        married_m_1519 married_m_2024 married_m_2529 married_m_3034 married_m_3539 married_m_ageall ///
        married_f_1519 married_f_2024 married_f_2529 married_f_3034 married_f_3539 married_f_ageall ///
        nevermarried_m_1519 nevermarried_m_2024 nevermarried_m_2529 nevermarried_m_3034 nevermarried_m_3539 nevermarried_m_ageall ///
        nevermarried_f_1519 nevermarried_f_2024 nevermarried_f_2529 nevermarried_f_3034 nevermarried_f_3539 nevermarried_f_ageall ///
        totpop_m_1519 totpop_m_2024 totpop_m_2529 totpop_m_3034 totpop_m_3539 totpop_m_ageall ///
        totpop_f_1519 totpop_f_2024 totpop_f_2529 totpop_f_3034 totpop_f_3539 totpop_f_ageall, ///
        by(year `lgavar' lga_info)

    save "long`i'.dta", replace
}

local files ""
forvalues i = 1(1)671 {
    capture confirm file "long`i'.dta"
    if !_rc local files "`files' long`i'.dta"
}

local first : word 1 of `files'
local rest : list files - first

use "`first'", clear
append using `rest'
save "T04_2006_long.dta", replace

**********************************************************************
* PART 3: LGAFINAL21 크로스워크 머지(한 번만) + 최종 저장
**********************************************************************
use "T04_2006_long.dta", clear

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

* n:1 지역통폐합 있을 수 있어 사람 수(count)라서 합산으로 마무리
collapse (sum) ///
    married_m_1519 married_m_2024 married_m_2529 married_m_3034 married_m_3539 married_m_ageall ///
    married_f_1519 married_f_2024 married_f_2529 married_f_3034 married_f_3539 married_f_ageall ///
    nevermarried_m_1519 nevermarried_m_2024 nevermarried_m_2529 nevermarried_m_3034 nevermarried_m_3539 nevermarried_m_ageall ///
    nevermarried_f_1519 nevermarried_f_2024 nevermarried_f_2529 nevermarried_f_3034 nevermarried_f_3539 nevermarried_f_ageall ///
    totpop_m_1519 totpop_m_2024 totpop_m_2529 totpop_m_3034 totpop_m_3539 totpop_m_ageall ///
    totpop_f_1519 totpop_f_2024 totpop_f_2529 totpop_f_3034 totpop_f_3539 totpop_f_ageall, ///
    by(LGAFINAL21 year)

isid LGAFINAL21 year
tab year

order LGAFINAL21 year
sort LGAFINAL21 year

* collapse는 라벨을 지워버리므로 최종 저장 직전에 한 번만 라벨링
* {혼인상태}: married=기혼, nevermarried=미혼, totpop=원자료 "가로" Total컬럼(모든 혼인상태 합=인구수)
* {연령}: 1519~3539=5세단위 연령대, ageall=원자료 "세로" Total행(해당 혼인상태의 전연령 합)
label var married_m_1519      "기혼(Married), 남, 15-19세 - 명"
label var married_m_2024      "기혼(Married), 남, 20-24세 - 명"
label var married_m_2529      "기혼(Married), 남, 25-29세 - 명"
label var married_m_3034      "기혼(Married), 남, 30-34세 - 명"
label var married_m_3539      "기혼(Married), 남, 35-39세 - 명"
label var married_m_ageall    "기혼(Married), 남, 전연령 합(원자료 세로 Total행) - 명"

label var married_f_1519      "기혼(Married), 여, 15-19세 - 명"
label var married_f_2024      "기혼(Married), 여, 20-24세 - 명"
label var married_f_2529      "기혼(Married), 여, 25-29세 - 명"
label var married_f_3034      "기혼(Married), 여, 30-34세 - 명"
label var married_f_3539      "기혼(Married), 여, 35-39세 - 명"
label var married_f_ageall    "기혼(Married), 여, 전연령 합(원자료 세로 Total행) - 명"

label var nevermarried_m_1519   "미혼(Never married), 남, 15-19세 - 명"
label var nevermarried_m_2024   "미혼(Never married), 남, 20-24세 - 명"
label var nevermarried_m_2529   "미혼(Never married), 남, 25-29세 - 명"
label var nevermarried_m_3034   "미혼(Never married), 남, 30-34세 - 명"
label var nevermarried_m_3539   "미혼(Never married), 남, 35-39세 - 명"
label var nevermarried_m_ageall "미혼(Never married), 남, 전연령 합(원자료 세로 Total행) - 명"

label var nevermarried_f_1519   "미혼(Never married), 여, 15-19세 - 명"
label var nevermarried_f_2024   "미혼(Never married), 여, 20-24세 - 명"
label var nevermarried_f_2529   "미혼(Never married), 여, 25-29세 - 명"
label var nevermarried_f_3034   "미혼(Never married), 여, 30-34세 - 명"
label var nevermarried_f_3539   "미혼(Never married), 여, 35-39세 - 명"
label var nevermarried_f_ageall "미혼(Never married), 여, 전연령 합(원자료 세로 Total행) - 명"

label var totpop_m_1519      "전체 혼인상태 합(원자료 가로 Total컬럼), 남, 15-19세 - 명"
label var totpop_m_2024      "전체 혼인상태 합(원자료 가로 Total컬럼), 남, 20-24세 - 명"
label var totpop_m_2529      "전체 혼인상태 합(원자료 가로 Total컬럼), 남, 25-29세 - 명"
label var totpop_m_3034      "전체 혼인상태 합(원자료 가로 Total컬럼), 남, 30-34세 - 명"
label var totpop_m_3539      "전체 혼인상태 합(원자료 가로 Total컬럼), 남, 35-39세 - 명"
label var totpop_m_ageall    "전체 혼인상태 x 전연령 합(grand total), 남 - 명"

label var totpop_f_1519      "전체 혼인상태 합(원자료 가로 Total컬럼), 여, 15-19세 - 명"
label var totpop_f_2024      "전체 혼인상태 합(원자료 가로 Total컬럼), 여, 20-24세 - 명"
label var totpop_f_2529      "전체 혼인상태 합(원자료 가로 Total컬럼), 여, 25-29세 - 명"
label var totpop_f_3034      "전체 혼인상태 합(원자료 가로 Total컬럼), 여, 30-34세 - 명"
label var totpop_f_3539      "전체 혼인상태 합(원자료 가로 Total컬럼), 여, 35-39세 - 명"
label var totpop_f_ageall    "전체 혼인상태 x 전연령 합(grand total), 여 - 명"

save "$data/ABS_T04_2006census.dta", replace
