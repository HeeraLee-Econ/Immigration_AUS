**********************************************************************
* Created by Heera Lee
* Purpose: T33(Labour Force Status by Age by Sex) -> 지역-연도 패널
*          2021 census (2011, 2016, 2021 년도 정보 포함)
*          T33a(Males) + T33b(Females) 시트를 사용 (T33c=Persons는 스킵)
*          T31/T22처럼 한 시트 안에 연도가 "세로 행블록"으로 3번 쌓여있음
*          (마커: "2011 CENSUS - MALES" 등, T24처럼 a/b/c/d로 안 쪼개지고
*          한 시트에 3개 연도블록이 다 들어있음 - 2021 T31과 동일 구조)
*          -> fill-down으로 year 부여. T33도 "Total" 라벨이 연도블록당 한 번만
*          나와서 T24와 마찬가지로 소계/총계 구분 로직이 필요 없음
*
*          주의: 2006 T24와 컬럼 배치가 다름! T24는 F=Employed Total 다음에
*          빈 컬럼(G)이 있고 J=Unemployed Total 다음에도 빈 컬럼(K)이 있어서
*          L=Total labour force / M=Not in labour force / O=Total(grand) 였는데,
*          T33(2021)은 Unemployed Total(J) 다음에 빈 컬럼이 없어서
*          K=Total labour force / L=Not in labour force / N=Total(grand) 로
*          한 칸씩 당겨짐 (직접 원자료 확인해서 컬럼 재검증함)
*
*          컬럼: A=연령 라벨, B=Employed 풀타임(마커 검출용, 값 자체는 안 씀),
*                F=Employed Total, J=Unemployed Total, K=Total labour force,
*                L=Not in the labour force, N=Total(grand, 노동가능인구 전체)
*                (C/D/E/G/H/I/M은 스킵 - 세부분류/구분선/status not stated)
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

local ext    "xlsx"
local lgavar "LGA2021"
local nfiles = 547

**********************************************************************
* PART 1: 547개 LGA 원자료 -> T33a(Males)+T33b(Females) 합쳐서 cob`i'.dta 저장
*          (아직 long 형태: 연도 x 성별 x 연령별로 한 행씩)
**********************************************************************
cd "$raw/2021"

forvalues i = 1/`nfiles' {

    * 2021 폴더는 전부 .xlsx라 파일 존재여부만 확인
    capture confirm file "`i'.`ext'"
    if _rc {
        di as error "SKIP: T33 2021 i=`i' (`i'.`ext' not found/locked)"
        continue
    }

    * LGA 라벨 한 줄 (T33a 기준)
    capture noisily import excel using `i'.`ext', sheet("T33a") clear
    if _rc {
        di as error "SKIP: T33 2021 i=`i' (T33a sheet not found)"
        continue
    }
    keep A
    keep in 2
    ren A lga_info
    gen `lgavar' = `i'
    tempfile lga
    save `lga'.dta, replace

    * ---- T33a: MALES, 2011+2016+2021 세 연도블록 ----
    import excel using `i'.`ext', sheet("T33a") clear
    keep A B F J K L N

    gen year = .
    replace year = 2011 if B=="2011 CENSUS - MALES"
    replace year = 2016 if B=="2016 CENSUS - MALES"
    replace year = 2021 if B=="2021 CENSUS - MALES"
    forvalues r = 1/30 {
        replace year = year[_n-1] if missing(year) & _n>1
    }

    keep if inlist(A, "15-19 years","20-24 years","25-29 years","30-34 years","35-39 years","40-44 years","Total")

    rename (F J K L N) (employed unemployed laborforce notinlf grandtotal)
    destring employed unemployed laborforce notinlf grandtotal, replace force

    keep year A employed unemployed laborforce notinlf grandtotal
    gen sex = "m"

    tempfile sheeta
    save `sheeta'.dta, replace

    * ---- T33b: FEMALES, 2011+2016+2021 세 연도블록 ----
    import excel using `i'.`ext', sheet("T33b") clear
    keep A B F J K L N

    gen year = .
    replace year = 2011 if B=="2011 CENSUS - FEMALES"
    replace year = 2016 if B=="2016 CENSUS - FEMALES"
    replace year = 2021 if B=="2021 CENSUS - FEMALES"
    forvalues r = 1/30 {
        replace year = year[_n-1] if missing(year) & _n>1
    }

    keep if inlist(A, "15-19 years","20-24 years","25-29 years","30-34 years","35-39 years","40-44 years","Total")

    rename (F J K L N) (employed unemployed laborforce notinlf grandtotal)
    destring employed unemployed laborforce notinlf grandtotal, replace force

    keep year A employed unemployed laborforce notinlf grandtotal
    gen sex = "f"

    append using `sheeta'.dta

    gen `lgavar' = `i'
    sort `lgavar' year
    merge m:1 `lgavar' using `lga'.dta
    drop _merge

    save "$interim/ABS/Y/T2433/2021/cob`i'.dta", replace
}

**********************************************************************
* PART 2: cob`i'.dta -> {노동상태}_{성별}_{연령} 가로(wide)변수 생성,
*          지역-연도 단위로 collapse. 지역별로 long`i'.dta에 각자 저장
*          (공유 누적파일 없음 -> 재실행 안전)
**********************************************************************
cd "$interim/ABS/Y/T2433/2021"

local lgavar "LGA2021"

forvalues i = 1(1)547 {

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
forvalues i = 1(1)547 {
    capture confirm file "long`i'.dta"
    if !_rc local files "`files' long`i'.dta"
}

local first : word 1 of `files'
local rest : list files - first

use "`first'", clear
append using `rest'
save "T33_2021_long.dta", replace

**********************************************************************
* PART 3: LGAFINAL21 크로스워크 머지(한 번만) + 최종 저장
**********************************************************************
use "T33_2021_long.dta", clear

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

save "$data/ABS_T33_2021census.dta", replace
