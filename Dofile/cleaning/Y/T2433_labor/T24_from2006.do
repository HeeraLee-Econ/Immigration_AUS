**********************************************************************
* Created by Heera Lee
* Purpose: T24(Labour Force Status by Age by Sex) -> 지역-연도 패널
*          2006 census (1996, 2001, 2006 년도 정보 포함)
*          T 24a(Males,1996+2001) + T 24b(Males,2006)
*          T 24c(Females,1996+2001) + T 24d(Females,2006) 시트를 사용
*          (T 24e/T 24f = Persons는 스킵)
*          T04처럼 한 시트 안에 연도가 "세로 행블록"으로 쌓여있음
*          (마커: "1996 CENSUS - MALES" 등) -> fill-down으로 year 부여
*          T24는 "Total" 라벨이 연도블록당 한 번만 나와서(T22/T31과 달리) 소계/총계
*          구분 로직이 필요 없음
*
*          컬럼: A=연령 라벨, B=Employed 풀타임(마커 검출용, 값 자체는 안 씀),
*                F=Employed Total, J=Unemployed Total, L=Total labour force,
*                M=Not in the labour force, O=Total(grand, 노동가능인구 전체)
*                (C/D/E/G/H/I/K/N은 스킵 - 세부분류/구분선/status not stated)
*
*          긁어오는 연령: 15-19/20-24/25-29/30-34/35-39/40-44 (15~44세) + ageall(=원자료
*          맨아래 "Total"행, 전연령 합, "가로행 total")
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
**********************************************************************
* PART 1: 671개 LGA 원자료 -> T24a+T24b(Males) / T24c+T24d(Females) 합쳐서
*          cob`i'.dta 저장 (아직 long 형태: 연도 x 성별 x 연령별로 한 행씩)
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
        di as error "SKIP: T24 2006 i=`i' (xls/xlsx not found/locked)"
        continue
    }

    * LGA 라벨 한 줄 (T 24a 기준)
    capture noisily import excel using `i'.`ext', sheet("T 24a") clear
    if _rc {
        di as error "SKIP: T24 2006 i=`i' (T 24a sheet not found)"
        continue
    }
    keep A
    keep in 2
    ren A lga_info
    gen `lgavar' = `i'
    tempfile lga
    save `lga'.dta, replace

    * ---- T 24a: MALES, 1996+2001 두 연도블록 ----
    import excel using `i'.`ext', sheet("T 24a") clear
    keep A B F J L M O

    gen year = .
    replace year = 1996 if B=="1996 CENSUS - MALES"
    replace year = 2001 if B=="2001 CENSUS - MALES"
    forvalues r = 1/30 {
        replace year = year[_n-1] if missing(year) & _n>1
    }

    keep if inlist(A, "15-19 years","20-24 years","25-29 years","30-34 years","35-39 years","40-44 years","Total")

    rename (F J L M O) (employed unemployed laborforce notinlf grandtotal)
    destring employed unemployed laborforce notinlf grandtotal, replace force

    keep year A employed unemployed laborforce notinlf grandtotal
    tempfile parta
    save `parta'.dta, replace

    * ---- T 24b: MALES, 2006 한 연도블록 ----
    import excel using `i'.`ext', sheet("T 24b") clear
    keep A B F J L M O

    gen year = .
    replace year = 2006 if B=="2006 CENSUS - MALES"
    forvalues r = 1/30 {
        replace year = year[_n-1] if missing(year) & _n>1
    }

    keep if inlist(A, "15-19 years","20-24 years","25-29 years","30-34 years","35-39 years","40-44 years","Total")

    rename (F J L M O) (employed unemployed laborforce notinlf grandtotal)
    destring employed unemployed laborforce notinlf grandtotal, replace force

    keep year A employed unemployed laborforce notinlf grandtotal
    append using `parta'.dta
    gen sex = "m"

    tempfile males
    save `males'.dta, replace

    * ---- T 24c: FEMALES, 1996+2001 두 연도블록 ----
    import excel using `i'.`ext', sheet("T 24c") clear
    keep A B F J L M O

    gen year = .
    replace year = 1996 if B=="1996 CENSUS - FEMALES"
    replace year = 2001 if B=="2001 CENSUS - FEMALES"
    forvalues r = 1/30 {
        replace year = year[_n-1] if missing(year) & _n>1
    }

    keep if inlist(A, "15-19 years","20-24 years","25-29 years","30-34 years","35-39 years","40-44 years","Total")

    rename (F J L M O) (employed unemployed laborforce notinlf grandtotal)
    destring employed unemployed laborforce notinlf grandtotal, replace force

    keep year A employed unemployed laborforce notinlf grandtotal
    tempfile partc
    save `partc'.dta, replace

    * ---- T 24d: FEMALES, 2006 한 연도블록 ----
    import excel using `i'.`ext', sheet("T 24d") clear
    keep A B F J L M O

    gen year = .
    replace year = 2006 if B=="2006 CENSUS - FEMALES"
    forvalues r = 1/30 {
        replace year = year[_n-1] if missing(year) & _n>1
    }

    keep if inlist(A, "15-19 years","20-24 years","25-29 years","30-34 years","35-39 years","40-44 years","Total")

    rename (F J L M O) (employed unemployed laborforce notinlf grandtotal)
    destring employed unemployed laborforce notinlf grandtotal, replace force

    keep year A employed unemployed laborforce notinlf grandtotal
    append using `partc'.dta
    gen sex = "f"

    append using `males'.dta

    gen `lgavar' = `i'
    sort `lgavar' year
    merge m:1 `lgavar' using `lga'.dta
    drop _merge

    save "$interim/ABS/Y/T2433/2006/cob`i'.dta", replace
}

**********************************************************************
* PART 2: cob`i'.dta -> {노동상태}_{성별}_{연령} 가로(wide)변수 생성,
*          지역-연도 단위로 collapse. 지역별로 long`i'.dta에 각자 저장
*          (공유 누적파일 없음 -> 재실행 안전)
**********************************************************************
cd "$interim/ABS/Y/T2433/2006"

local lgavar "LGA2006"

forvalues i = 1(1)671 {

    use cob`i', clear

    * 변수명 규칙: {노동상태}_{성별}_{연령코드}
    *   노동상태: employed/unemployed/laborforce(=total labour force)/notinlf(=not in the labour force)/
    *             grandtotal(전체, "가로행 total"의 원천)
    *   연령코드: 1519/2024/2529/3034/3539/4044(15~44세) / ageall(원자료 맨아래 Total행, 전연령 합)
    gen employed_m_1519   = employed if A=="15-19 years" & sex=="m"
    gen employed_m_2024   = employed if A=="20-24 years" & sex=="m"
    gen employed_m_2529   = employed if A=="25-29 years" & sex=="m"
    gen employed_m_3034   = employed if A=="30-34 years" & sex=="m"
    gen employed_m_3539   = employed if A=="35-39 years" & sex=="m"
    gen employed_m_4044   = employed if A=="40-44 years" & sex=="m"
    gen employed_m_ageall = employed if A=="Total" & sex=="m"

    gen employed_f_1519   = employed if A=="15-19 years" & sex=="f"
    gen employed_f_2024   = employed if A=="20-24 years" & sex=="f"
    gen employed_f_2529   = employed if A=="25-29 years" & sex=="f"
    gen employed_f_3034   = employed if A=="30-34 years" & sex=="f"
    gen employed_f_3539   = employed if A=="35-39 years" & sex=="f"
    gen employed_f_4044   = employed if A=="40-44 years" & sex=="f"
    gen employed_f_ageall = employed if A=="Total" & sex=="f"

    gen unemployed_m_1519   = unemployed if A=="15-19 years" & sex=="m"
    gen unemployed_m_2024   = unemployed if A=="20-24 years" & sex=="m"
    gen unemployed_m_2529   = unemployed if A=="25-29 years" & sex=="m"
    gen unemployed_m_3034   = unemployed if A=="30-34 years" & sex=="m"
    gen unemployed_m_3539   = unemployed if A=="35-39 years" & sex=="m"
    gen unemployed_m_4044   = unemployed if A=="40-44 years" & sex=="m"
    gen unemployed_m_ageall = unemployed if A=="Total" & sex=="m"

    gen unemployed_f_1519   = unemployed if A=="15-19 years" & sex=="f"
    gen unemployed_f_2024   = unemployed if A=="20-24 years" & sex=="f"
    gen unemployed_f_2529   = unemployed if A=="25-29 years" & sex=="f"
    gen unemployed_f_3034   = unemployed if A=="30-34 years" & sex=="f"
    gen unemployed_f_3539   = unemployed if A=="35-39 years" & sex=="f"
    gen unemployed_f_4044   = unemployed if A=="40-44 years" & sex=="f"
    gen unemployed_f_ageall = unemployed if A=="Total" & sex=="f"

    gen laborforce_m_1519   = laborforce if A=="15-19 years" & sex=="m"
    gen laborforce_m_2024   = laborforce if A=="20-24 years" & sex=="m"
    gen laborforce_m_2529   = laborforce if A=="25-29 years" & sex=="m"
    gen laborforce_m_3034   = laborforce if A=="30-34 years" & sex=="m"
    gen laborforce_m_3539   = laborforce if A=="35-39 years" & sex=="m"
    gen laborforce_m_4044   = laborforce if A=="40-44 years" & sex=="m"
    gen laborforce_m_ageall = laborforce if A=="Total" & sex=="m"

    gen laborforce_f_1519   = laborforce if A=="15-19 years" & sex=="f"
    gen laborforce_f_2024   = laborforce if A=="20-24 years" & sex=="f"
    gen laborforce_f_2529   = laborforce if A=="25-29 years" & sex=="f"
    gen laborforce_f_3034   = laborforce if A=="30-34 years" & sex=="f"
    gen laborforce_f_3539   = laborforce if A=="35-39 years" & sex=="f"
    gen laborforce_f_4044   = laborforce if A=="40-44 years" & sex=="f"
    gen laborforce_f_ageall = laborforce if A=="Total" & sex=="f"

    gen notinlf_m_1519   = notinlf if A=="15-19 years" & sex=="m"
    gen notinlf_m_2024   = notinlf if A=="20-24 years" & sex=="m"
    gen notinlf_m_2529   = notinlf if A=="25-29 years" & sex=="m"
    gen notinlf_m_3034   = notinlf if A=="30-34 years" & sex=="m"
    gen notinlf_m_3539   = notinlf if A=="35-39 years" & sex=="m"
    gen notinlf_m_4044   = notinlf if A=="40-44 years" & sex=="m"
    gen notinlf_m_ageall = notinlf if A=="Total" & sex=="m"

    gen notinlf_f_1519   = notinlf if A=="15-19 years" & sex=="f"
    gen notinlf_f_2024   = notinlf if A=="20-24 years" & sex=="f"
    gen notinlf_f_2529   = notinlf if A=="25-29 years" & sex=="f"
    gen notinlf_f_3034   = notinlf if A=="30-34 years" & sex=="f"
    gen notinlf_f_3539   = notinlf if A=="35-39 years" & sex=="f"
    gen notinlf_f_4044   = notinlf if A=="40-44 years" & sex=="f"
    gen notinlf_f_ageall = notinlf if A=="Total" & sex=="f"

    gen grandtotal_m_1519   = grandtotal if A=="15-19 years" & sex=="m"
    gen grandtotal_m_2024   = grandtotal if A=="20-24 years" & sex=="m"
    gen grandtotal_m_2529   = grandtotal if A=="25-29 years" & sex=="m"
    gen grandtotal_m_3034   = grandtotal if A=="30-34 years" & sex=="m"
    gen grandtotal_m_3539   = grandtotal if A=="35-39 years" & sex=="m"
    gen grandtotal_m_4044   = grandtotal if A=="40-44 years" & sex=="m"
    gen grandtotal_m_ageall = grandtotal if A=="Total" & sex=="m"

    gen grandtotal_f_1519   = grandtotal if A=="15-19 years" & sex=="f"
    gen grandtotal_f_2024   = grandtotal if A=="20-24 years" & sex=="f"
    gen grandtotal_f_2529   = grandtotal if A=="25-29 years" & sex=="f"
    gen grandtotal_f_3034   = grandtotal if A=="30-34 years" & sex=="f"
    gen grandtotal_f_3539   = grandtotal if A=="35-39 years" & sex=="f"
    gen grandtotal_f_4044   = grandtotal if A=="40-44 years" & sex=="f"
    gen grandtotal_f_ageall = grandtotal if A=="Total" & sex=="f"

    drop employed unemployed laborforce notinlf grandtotal A sex

    collapse (max) ///
        employed_m_1519 employed_m_2024 employed_m_2529 employed_m_3034 employed_m_3539 employed_m_4044 employed_m_ageall ///
        employed_f_1519 employed_f_2024 employed_f_2529 employed_f_3034 employed_f_3539 employed_f_4044 employed_f_ageall ///
        unemployed_m_1519 unemployed_m_2024 unemployed_m_2529 unemployed_m_3034 unemployed_m_3539 unemployed_m_4044 unemployed_m_ageall ///
        unemployed_f_1519 unemployed_f_2024 unemployed_f_2529 unemployed_f_3034 unemployed_f_3539 unemployed_f_4044 unemployed_f_ageall ///
        laborforce_m_1519 laborforce_m_2024 laborforce_m_2529 laborforce_m_3034 laborforce_m_3539 laborforce_m_4044 laborforce_m_ageall ///
        laborforce_f_1519 laborforce_f_2024 laborforce_f_2529 laborforce_f_3034 laborforce_f_3539 laborforce_f_4044 laborforce_f_ageall ///
        notinlf_m_1519 notinlf_m_2024 notinlf_m_2529 notinlf_m_3034 notinlf_m_3539 notinlf_m_4044 notinlf_m_ageall ///
        notinlf_f_1519 notinlf_f_2024 notinlf_f_2529 notinlf_f_3034 notinlf_f_3539 notinlf_f_4044 notinlf_f_ageall ///
        grandtotal_m_1519 grandtotal_m_2024 grandtotal_m_2529 grandtotal_m_3034 grandtotal_m_3539 grandtotal_m_4044 grandtotal_m_ageall ///
        grandtotal_f_1519 grandtotal_f_2024 grandtotal_f_2529 grandtotal_f_3034 grandtotal_f_3539 grandtotal_f_4044 grandtotal_f_ageall, ///
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
save "T24_2006_long.dta", replace

**********************************************************************
* PART 3: LGAFINAL21 크로스워크 머지(한 번만) + 최종 저장
**********************************************************************
use "T24_2006_long.dta", clear

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
    employed_m_1519 employed_m_2024 employed_m_2529 employed_m_3034 employed_m_3539 employed_m_4044 employed_m_ageall ///
    employed_f_1519 employed_f_2024 employed_f_2529 employed_f_3034 employed_f_3539 employed_f_4044 employed_f_ageall ///
    unemployed_m_1519 unemployed_m_2024 unemployed_m_2529 unemployed_m_3034 unemployed_m_3539 unemployed_m_4044 unemployed_m_ageall ///
    unemployed_f_1519 unemployed_f_2024 unemployed_f_2529 unemployed_f_3034 unemployed_f_3539 unemployed_f_4044 unemployed_f_ageall ///
    laborforce_m_1519 laborforce_m_2024 laborforce_m_2529 laborforce_m_3034 laborforce_m_3539 laborforce_m_4044 laborforce_m_ageall ///
    laborforce_f_1519 laborforce_f_2024 laborforce_f_2529 laborforce_f_3034 laborforce_f_3539 laborforce_f_4044 laborforce_f_ageall ///
    notinlf_m_1519 notinlf_m_2024 notinlf_m_2529 notinlf_m_3034 notinlf_m_3539 notinlf_m_4044 notinlf_m_ageall ///
    notinlf_f_1519 notinlf_f_2024 notinlf_f_2529 notinlf_f_3034 notinlf_f_3539 notinlf_f_4044 notinlf_f_ageall ///
    grandtotal_m_1519 grandtotal_m_2024 grandtotal_m_2529 grandtotal_m_3034 grandtotal_m_3539 grandtotal_m_4044 grandtotal_m_ageall ///
    grandtotal_f_1519 grandtotal_f_2024 grandtotal_f_2529 grandtotal_f_3034 grandtotal_f_3539 grandtotal_f_4044 grandtotal_f_ageall, ///
    by(LGAFINAL21 year)

isid LGAFINAL21 year
tab year

order LGAFINAL21 year
sort LGAFINAL21 year

* collapse는 라벨을 지워버리므로 최종 저장 직전에 한 번만 라벨링
* {노동상태}: employed=취업, unemployed=실업, laborforce=총노동력(경제활동인구),
*             notinlf=비경제활동인구, grandtotal=전체("가로행 total")
* {연령}: 1519~4044=15세단위 연령대(15~44세), ageall=원자료 맨아래 Total행(전연령 합)
label var employed_m_1519   "취업(Employed), 남, 15-19세 - 명"
label var employed_m_2024   "취업(Employed), 남, 20-24세 - 명"
label var employed_m_2529   "취업(Employed), 남, 25-29세 - 명"
label var employed_m_3034   "취업(Employed), 남, 30-34세 - 명"
label var employed_m_3539   "취업(Employed), 남, 35-39세 - 명"
label var employed_m_4044   "취업(Employed), 남, 40-44세 - 명"
label var employed_m_ageall "취업(Employed), 남, 전연령 합(원자료 세로Total행) - 명"

label var employed_f_1519   "취업(Employed), 여, 15-19세 - 명"
label var employed_f_2024   "취업(Employed), 여, 20-24세 - 명"
label var employed_f_2529   "취업(Employed), 여, 25-29세 - 명"
label var employed_f_3034   "취업(Employed), 여, 30-34세 - 명"
label var employed_f_3539   "취업(Employed), 여, 35-39세 - 명"
label var employed_f_4044   "취업(Employed), 여, 40-44세 - 명"
label var employed_f_ageall "취업(Employed), 여, 전연령 합(원자료 세로Total행) - 명"

label var unemployed_m_1519   "실업(Unemployed), 남, 15-19세 - 명"
label var unemployed_m_2024   "실업(Unemployed), 남, 20-24세 - 명"
label var unemployed_m_2529   "실업(Unemployed), 남, 25-29세 - 명"
label var unemployed_m_3034   "실업(Unemployed), 남, 30-34세 - 명"
label var unemployed_m_3539   "실업(Unemployed), 남, 35-39세 - 명"
label var unemployed_m_4044   "실업(Unemployed), 남, 40-44세 - 명"
label var unemployed_m_ageall "실업(Unemployed), 남, 전연령 합(원자료 세로Total행) - 명"

label var unemployed_f_1519   "실업(Unemployed), 여, 15-19세 - 명"
label var unemployed_f_2024   "실업(Unemployed), 여, 20-24세 - 명"
label var unemployed_f_2529   "실업(Unemployed), 여, 25-29세 - 명"
label var unemployed_f_3034   "실업(Unemployed), 여, 30-34세 - 명"
label var unemployed_f_3539   "실업(Unemployed), 여, 35-39세 - 명"
label var unemployed_f_4044   "실업(Unemployed), 여, 40-44세 - 명"
label var unemployed_f_ageall "실업(Unemployed), 여, 전연령 합(원자료 세로Total행) - 명"

label var laborforce_m_1519   "총노동력(Total labour force), 남, 15-19세 - 명"
label var laborforce_m_2024   "총노동력(Total labour force), 남, 20-24세 - 명"
label var laborforce_m_2529   "총노동력(Total labour force), 남, 25-29세 - 명"
label var laborforce_m_3034   "총노동력(Total labour force), 남, 30-34세 - 명"
label var laborforce_m_3539   "총노동력(Total labour force), 남, 35-39세 - 명"
label var laborforce_m_4044   "총노동력(Total labour force), 남, 40-44세 - 명"
label var laborforce_m_ageall "총노동력(Total labour force), 남, 전연령 합(원자료 세로Total행) - 명"

label var laborforce_f_1519   "총노동력(Total labour force), 여, 15-19세 - 명"
label var laborforce_f_2024   "총노동력(Total labour force), 여, 20-24세 - 명"
label var laborforce_f_2529   "총노동력(Total labour force), 여, 25-29세 - 명"
label var laborforce_f_3034   "총노동력(Total labour force), 여, 30-34세 - 명"
label var laborforce_f_3539   "총노동력(Total labour force), 여, 35-39세 - 명"
label var laborforce_f_4044   "총노동력(Total labour force), 여, 40-44세 - 명"
label var laborforce_f_ageall "총노동력(Total labour force), 여, 전연령 합(원자료 세로Total행) - 명"

label var notinlf_m_1519   "비경제활동인구(Not in labour force), 남, 15-19세 - 명"
label var notinlf_m_2024   "비경제활동인구(Not in labour force), 남, 20-24세 - 명"
label var notinlf_m_2529   "비경제활동인구(Not in labour force), 남, 25-29세 - 명"
label var notinlf_m_3034   "비경제활동인구(Not in labour force), 남, 30-34세 - 명"
label var notinlf_m_3539   "비경제활동인구(Not in labour force), 남, 35-39세 - 명"
label var notinlf_m_4044   "비경제활동인구(Not in labour force), 남, 40-44세 - 명"
label var notinlf_m_ageall "비경제활동인구(Not in labour force), 남, 전연령 합(원자료 세로Total행) - 명"

label var notinlf_f_1519   "비경제활동인구(Not in labour force), 여, 15-19세 - 명"
label var notinlf_f_2024   "비경제활동인구(Not in labour force), 여, 20-24세 - 명"
label var notinlf_f_2529   "비경제활동인구(Not in labour force), 여, 25-29세 - 명"
label var notinlf_f_3034   "비경제활동인구(Not in labour force), 여, 30-34세 - 명"
label var notinlf_f_3539   "비경제활동인구(Not in labour force), 여, 35-39세 - 명"
label var notinlf_f_4044   "비경제활동인구(Not in labour force), 여, 40-44세 - 명"
label var notinlf_f_ageall "비경제활동인구(Not in labour force), 여, 전연령 합(원자료 세로Total행) - 명"

label var grandtotal_m_1519   "전체(Grand Total, 가로행 total), 남, 15-19세 - 명"
label var grandtotal_m_2024   "전체(Grand Total, 가로행 total), 남, 20-24세 - 명"
label var grandtotal_m_2529   "전체(Grand Total, 가로행 total), 남, 25-29세 - 명"
label var grandtotal_m_3034   "전체(Grand Total, 가로행 total), 남, 30-34세 - 명"
label var grandtotal_m_3539   "전체(Grand Total, 가로행 total), 남, 35-39세 - 명"
label var grandtotal_m_4044   "전체(Grand Total, 가로행 total), 남, 40-44세 - 명"
label var grandtotal_m_ageall "전체 x 전연령 합(grand total), 남 - 명"

label var grandtotal_f_1519   "전체(Grand Total, 가로행 total), 여, 15-19세 - 명"
label var grandtotal_f_2024   "전체(Grand Total, 가로행 total), 여, 20-24세 - 명"
label var grandtotal_f_2529   "전체(Grand Total, 가로행 total), 여, 25-29세 - 명"
label var grandtotal_f_3034   "전체(Grand Total, 가로행 total), 여, 30-34세 - 명"
label var grandtotal_f_3539   "전체(Grand Total, 가로행 total), 여, 35-39세 - 명"
label var grandtotal_f_4044   "전체(Grand Total, 가로행 total), 여, 40-44세 - 명"
label var grandtotal_f_ageall "전체 x 전연령 합(grand total), 여 - 명"

save "$data/ABS_T24_2006census.dta", replace
