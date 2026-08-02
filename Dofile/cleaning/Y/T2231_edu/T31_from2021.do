**********************************************************************
* Created by Heera Lee
* Purpose: T31(Highest Non-School Qualification: Level of Education by Age by Sex) -> 지역-연도 패널
*          2021 census (2011, 2016, 2021 년도 정보 포함)
*          T31a(Males) + T31b(Females) 시트를 사용 (T31c=Persons는 스킵)
*          T22(2006)와 마찬가지로 한 시트 안에 연도가 "세로 행블록"으로 3번 쌓여있음
*          (마커: "2011 CENSUS - MALES" 등) -> fill-down으로 year 부여
*
*          컬럼: A=교육수준 라벨, B=15-19, C=20-24, D=25-34, ..., K=Total(그 교육수준의 전연령 합)
*          긁어오는 교육수준(4개, 각각 별도 변수 유지): Postgraduate Degree Level / Graduate Diploma and
*          Graduate Certificate Level / Bachelor Degree Level / Advanced Diploma and Diploma Level
*          (= "diploma 이상", 2021 라벨엔 뒤에 "Level"이 붙음 - 2006과 문구만 다름)
*          + 전체총계행(grandtotal, 모든 교육수준 합) - 단, 한 연도블록에 "Total"이라는 라벨이
*          두 번 나옴(자격증 소계 Total, 그리고 맨 마지막 전체총계 Total) -> 두 번째 등장한 Total만
*          grandtotal로 사용 (자격증 소계는 사용 안 함)
*
*          긁어오는 연령: 15-19 / 20-24 / 25-34 (원자료에 이미 이렇게 묶여있음) + ageall(=컬럼K,
*          해당 행의 전연령 합계) -> "세로 total"은 각 diploma 카테고리의 ageall 값,
*          "가로 total"은 grandtotal 카테고리(연령별 값 + 그 자체의 ageall)
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
* PART 1: 547개 LGA 원자료 -> T31a(Males)+T31b(Females) 합쳐서 cob`i'.dta 저장
*          (아직 long 형태: 연도 x 성별 x 교육수준 카테고리별로 한 행씩)
**********************************************************************
cd "$raw/2021"

forvalues i = 1/`nfiles' {

    * 2021 폴더는 전부 .xlsx라 파일 존재여부만 확인
    capture confirm file "`i'.`ext'"
    if _rc {
        di as error "SKIP: T31 2021 i=`i' (`i'.`ext' not found/locked)"
        continue
    }

    * LGA 라벨 한 줄 (T31a 기준)
    capture noisily import excel using `i'.`ext', sheet("T31a") clear
    if _rc {
        di as error "SKIP: T31 2021 i=`i' (T31a sheet not found)"
        continue
    }
    keep A
    keep in 2
    ren A lga_info
    gen `lgavar' = `i'
    tempfile lga
    save `lga'.dta, replace

    * ---- T31a: MALES, 2011+2016+2021 세 연도블록 ----
    import excel using `i'.`ext', sheet("T31a") clear
    keep A B C D K

    gen year = .
    replace year = 2011 if B=="2011 CENSUS - MALES"
    replace year = 2016 if B=="2016 CENSUS - MALES"
    replace year = 2021 if B=="2021 CENSUS - MALES"
    forvalues r = 1/30 {
        replace year = year[_n-1] if missing(year) & _n>1
    }

    replace A = strtrim(A)
    gen rownum = _n
    gen istotal = (A=="Total")
    bysort year (rownum): gen occurrence_num = sum(istotal)

    gen keep_row = 0
    replace keep_row = 1 if inlist(A, "Postgraduate Degree Level","Graduate Diploma and Graduate Certificate Level", ///
        "Bachelor Degree Level","Advanced Diploma and Diploma Level")
    replace keep_row = 1 if istotal==1 & occurrence_num==2
    keep if keep_row==1

    gen catcode = ""
    replace catcode = "postgrad"   if A=="Postgraduate Degree Level"
    replace catcode = "graddip"    if A=="Graduate Diploma and Graduate Certificate Level"
    replace catcode = "bachelor"   if A=="Bachelor Degree Level"
    replace catcode = "advdip"     if A=="Advanced Diploma and Diploma Level"
    replace catcode = "grandtotal" if istotal==1 & occurrence_num==2

    rename (B C D K) (v1519 v2024 v2534 vageall)
    destring v1519 v2024 v2534 vageall, replace force

    keep year catcode v1519 v2024 v2534 vageall
    gen sex = "m"

    tempfile sheeta
    save `sheeta'.dta, replace

    * ---- T31b: FEMALES, 2011+2016+2021 세 연도블록 ----
    import excel using `i'.`ext', sheet("T31b") clear
    keep A B C D K

    gen year = .
    replace year = 2011 if B=="2011 CENSUS - FEMALES"
    replace year = 2016 if B=="2016 CENSUS - FEMALES"
    replace year = 2021 if B=="2021 CENSUS - FEMALES"
    forvalues r = 1/30 {
        replace year = year[_n-1] if missing(year) & _n>1
    }

    replace A = strtrim(A)
    gen rownum = _n
    gen istotal = (A=="Total")
    bysort year (rownum): gen occurrence_num = sum(istotal)

    gen keep_row = 0
    replace keep_row = 1 if inlist(A, "Postgraduate Degree Level","Graduate Diploma and Graduate Certificate Level", ///
        "Bachelor Degree Level","Advanced Diploma and Diploma Level")
    replace keep_row = 1 if istotal==1 & occurrence_num==2
    keep if keep_row==1

    gen catcode = ""
    replace catcode = "postgrad"   if A=="Postgraduate Degree Level"
    replace catcode = "graddip"    if A=="Graduate Diploma and Graduate Certificate Level"
    replace catcode = "bachelor"   if A=="Bachelor Degree Level"
    replace catcode = "advdip"     if A=="Advanced Diploma and Diploma Level"
    replace catcode = "grandtotal" if istotal==1 & occurrence_num==2

    rename (B C D K) (v1519 v2024 v2534 vageall)
    destring v1519 v2024 v2534 vageall, replace force

    keep year catcode v1519 v2024 v2534 vageall
    gen sex = "f"

    append using `sheeta'.dta

    gen `lgavar' = `i'
    sort `lgavar' year
    merge m:1 `lgavar' using `lga'.dta
    drop _merge

    save "$interim/ABS/Y/T2231/2021/cob`i'.dta", replace
}
**********************************************************************
* PART 2: cob`i'.dta -> {교육수준}_{성별}_{연령} 가로(wide)변수 생성,
*          지역-연도 단위로 collapse. 지역별로 long`i'.dta에 각자 저장
*          (공유 누적파일 없음 -> 재실행 안전)
**********************************************************************
cd "$interim/ABS/Y/T2231/2021"

local lgavar "LGA2021"

forvalues i = 1(1)547 {

    use cob`i', clear

    * 변수명 규칙: {교육수준}_{성별}_{연령코드}
    *   교육수준: postgrad/graddip/bachelor/advdip(=diploma 이상 4개 개별 유지) / grandtotal(모든 교육수준 합, "가로 total")
    *   연령코드: 1519/2024/2534(원자료 그대로) / ageall(원자료 컬럼K=해당 교육수준의 전연령 합, "세로 total")
    gen postgrad_m_1519   = v1519   if catcode=="postgrad" & sex=="m"
    gen postgrad_m_2024   = v2024   if catcode=="postgrad" & sex=="m"
    gen postgrad_m_2534   = v2534   if catcode=="postgrad" & sex=="m"
    gen postgrad_m_ageall = vageall if catcode=="postgrad" & sex=="m"

    gen postgrad_f_1519   = v1519   if catcode=="postgrad" & sex=="f"
    gen postgrad_f_2024   = v2024   if catcode=="postgrad" & sex=="f"
    gen postgrad_f_2534   = v2534   if catcode=="postgrad" & sex=="f"
    gen postgrad_f_ageall = vageall if catcode=="postgrad" & sex=="f"

    gen graddip_m_1519   = v1519   if catcode=="graddip" & sex=="m"
    gen graddip_m_2024   = v2024   if catcode=="graddip" & sex=="m"
    gen graddip_m_2534   = v2534   if catcode=="graddip" & sex=="m"
    gen graddip_m_ageall = vageall if catcode=="graddip" & sex=="m"

    gen graddip_f_1519   = v1519   if catcode=="graddip" & sex=="f"
    gen graddip_f_2024   = v2024   if catcode=="graddip" & sex=="f"
    gen graddip_f_2534   = v2534   if catcode=="graddip" & sex=="f"
    gen graddip_f_ageall = vageall if catcode=="graddip" & sex=="f"

    gen bachelor_m_1519   = v1519   if catcode=="bachelor" & sex=="m"
    gen bachelor_m_2024   = v2024   if catcode=="bachelor" & sex=="m"
    gen bachelor_m_2534   = v2534   if catcode=="bachelor" & sex=="m"
    gen bachelor_m_ageall = vageall if catcode=="bachelor" & sex=="m"

    gen bachelor_f_1519   = v1519   if catcode=="bachelor" & sex=="f"
    gen bachelor_f_2024   = v2024   if catcode=="bachelor" & sex=="f"
    gen bachelor_f_2534   = v2534   if catcode=="bachelor" & sex=="f"
    gen bachelor_f_ageall = vageall if catcode=="bachelor" & sex=="f"

    gen advdip_m_1519   = v1519   if catcode=="advdip" & sex=="m"
    gen advdip_m_2024   = v2024   if catcode=="advdip" & sex=="m"
    gen advdip_m_2534   = v2534   if catcode=="advdip" & sex=="m"
    gen advdip_m_ageall = vageall if catcode=="advdip" & sex=="m"

    gen advdip_f_1519   = v1519   if catcode=="advdip" & sex=="f"
    gen advdip_f_2024   = v2024   if catcode=="advdip" & sex=="f"
    gen advdip_f_2534   = v2534   if catcode=="advdip" & sex=="f"
    gen advdip_f_ageall = vageall if catcode=="advdip" & sex=="f"

    gen grandtotal_m_1519   = v1519   if catcode=="grandtotal" & sex=="m"
    gen grandtotal_m_2024   = v2024   if catcode=="grandtotal" & sex=="m"
    gen grandtotal_m_2534   = v2534   if catcode=="grandtotal" & sex=="m"
    gen grandtotal_m_ageall = vageall if catcode=="grandtotal" & sex=="m"

    gen grandtotal_f_1519   = v1519   if catcode=="grandtotal" & sex=="f"
    gen grandtotal_f_2024   = v2024   if catcode=="grandtotal" & sex=="f"
    gen grandtotal_f_2534   = v2534   if catcode=="grandtotal" & sex=="f"
    gen grandtotal_f_ageall = vageall if catcode=="grandtotal" & sex=="f"

    drop v1519 v2024 v2534 vageall catcode sex

    collapse (max) ///
        postgrad_m_1519 postgrad_m_2024 postgrad_m_2534 postgrad_m_ageall ///
        postgrad_f_1519 postgrad_f_2024 postgrad_f_2534 postgrad_f_ageall ///
        graddip_m_1519 graddip_m_2024 graddip_m_2534 graddip_m_ageall ///
        graddip_f_1519 graddip_f_2024 graddip_f_2534 graddip_f_ageall ///
        bachelor_m_1519 bachelor_m_2024 bachelor_m_2534 bachelor_m_ageall ///
        bachelor_f_1519 bachelor_f_2024 bachelor_f_2534 bachelor_f_ageall ///
        advdip_m_1519 advdip_m_2024 advdip_m_2534 advdip_m_ageall ///
        advdip_f_1519 advdip_f_2024 advdip_f_2534 advdip_f_ageall ///
        grandtotal_m_1519 grandtotal_m_2024 grandtotal_m_2534 grandtotal_m_ageall ///
        grandtotal_f_1519 grandtotal_f_2024 grandtotal_f_2534 grandtotal_f_ageall, ///
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
save "T31_2021_long.dta", replace

**********************************************************************
* PART 3: LGAFINAL21 크로스워크 머지(한 번만) + 최종 저장
**********************************************************************
use "T31_2021_long.dta", clear

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
    postgrad_m_1519 postgrad_m_2024 postgrad_m_2534 postgrad_m_ageall ///
    postgrad_f_1519 postgrad_f_2024 postgrad_f_2534 postgrad_f_ageall ///
    graddip_m_1519 graddip_m_2024 graddip_m_2534 graddip_m_ageall ///
    graddip_f_1519 graddip_f_2024 graddip_f_2534 graddip_f_ageall ///
    bachelor_m_1519 bachelor_m_2024 bachelor_m_2534 bachelor_m_ageall ///
    bachelor_f_1519 bachelor_f_2024 bachelor_f_2534 bachelor_f_ageall ///
    advdip_m_1519 advdip_m_2024 advdip_m_2534 advdip_m_ageall ///
    advdip_f_1519 advdip_f_2024 advdip_f_2534 advdip_f_ageall ///
    grandtotal_m_1519 grandtotal_m_2024 grandtotal_m_2534 grandtotal_m_ageall ///
    grandtotal_f_1519 grandtotal_f_2024 grandtotal_f_2534 grandtotal_f_ageall, ///
    by(LGAFINAL21 year)

isid LGAFINAL21 year
tab year

order LGAFINAL21 year
sort LGAFINAL21 year

* collapse는 라벨을 지워버리므로 최종 저장 직전에 한 번만 라벨링
* {교육수준}: postgrad=대학원 학위, graddip=대학원 디플로마/자격증, bachelor=학사, advdip=고급디플로마/디플로마
*             (이 4개=diploma 이상), grandtotal=모든 교육수준 합("가로 total", 분모로 사용 가능)
* {연령}: 1519/2024/2534=원자료 연령대 그대로, ageall=원자료 컬럼K(해당 교육수준의 전연령 합, "세로 total")
label var postgrad_m_1519   "대학원학위(Postgraduate), 남, 15-19세 - 명"
label var postgrad_m_2024   "대학원학위(Postgraduate), 남, 20-24세 - 명"
label var postgrad_m_2534   "대학원학위(Postgraduate), 남, 25-34세 - 명"
label var postgrad_m_ageall "대학원학위(Postgraduate), 남, 전연령 합(세로 total) - 명"

label var postgrad_f_1519   "대학원학위(Postgraduate), 여, 15-19세 - 명"
label var postgrad_f_2024   "대학원학위(Postgraduate), 여, 20-24세 - 명"
label var postgrad_f_2534   "대학원학위(Postgraduate), 여, 25-34세 - 명"
label var postgrad_f_ageall "대학원학위(Postgraduate), 여, 전연령 합(세로 total) - 명"

label var graddip_m_1519   "대학원디플로마/자격증(Grad Dip/Cert), 남, 15-19세 - 명"
label var graddip_m_2024   "대학원디플로마/자격증(Grad Dip/Cert), 남, 20-24세 - 명"
label var graddip_m_2534   "대학원디플로마/자격증(Grad Dip/Cert), 남, 25-34세 - 명"
label var graddip_m_ageall "대학원디플로마/자격증(Grad Dip/Cert), 남, 전연령 합(세로 total) - 명"

label var graddip_f_1519   "대학원디플로마/자격증(Grad Dip/Cert), 여, 15-19세 - 명"
label var graddip_f_2024   "대학원디플로마/자격증(Grad Dip/Cert), 여, 20-24세 - 명"
label var graddip_f_2534   "대학원디플로마/자격증(Grad Dip/Cert), 여, 25-34세 - 명"
label var graddip_f_ageall "대학원디플로마/자격증(Grad Dip/Cert), 여, 전연령 합(세로 total) - 명"

label var bachelor_m_1519   "학사(Bachelor), 남, 15-19세 - 명"
label var bachelor_m_2024   "학사(Bachelor), 남, 20-24세 - 명"
label var bachelor_m_2534   "학사(Bachelor), 남, 25-34세 - 명"
label var bachelor_m_ageall "학사(Bachelor), 남, 전연령 합(세로 total) - 명"

label var bachelor_f_1519   "학사(Bachelor), 여, 15-19세 - 명"
label var bachelor_f_2024   "학사(Bachelor), 여, 20-24세 - 명"
label var bachelor_f_2534   "학사(Bachelor), 여, 25-34세 - 명"
label var bachelor_f_ageall "학사(Bachelor), 여, 전연령 합(세로 total) - 명"

label var advdip_m_1519   "고급디플로마/디플로마(Adv Dip/Diploma), 남, 15-19세 - 명"
label var advdip_m_2024   "고급디플로마/디플로마(Adv Dip/Diploma), 남, 20-24세 - 명"
label var advdip_m_2534   "고급디플로마/디플로마(Adv Dip/Diploma), 남, 25-34세 - 명"
label var advdip_m_ageall "고급디플로마/디플로마(Adv Dip/Diploma), 남, 전연령 합(세로 total) - 명"

label var advdip_f_1519   "고급디플로마/디플로마(Adv Dip/Diploma), 여, 15-19세 - 명"
label var advdip_f_2024   "고급디플로마/디플로마(Adv Dip/Diploma), 여, 20-24세 - 명"
label var advdip_f_2534   "고급디플로마/디플로마(Adv Dip/Diploma), 여, 25-34세 - 명"
label var advdip_f_ageall "고급디플로마/디플로마(Adv Dip/Diploma), 여, 전연령 합(세로 total) - 명"

label var grandtotal_m_1519   "전체 교육수준 합(원자료 맨아래 총계행, 가로 total), 남, 15-19세 - 명"
label var grandtotal_m_2024   "전체 교육수준 합(원자료 맨아래 총계행, 가로 total), 남, 20-24세 - 명"
label var grandtotal_m_2534   "전체 교육수준 합(원자료 맨아래 총계행, 가로 total), 남, 25-34세 - 명"
label var grandtotal_m_ageall "전체 교육수준 x 전연령 합(grand total), 남 - 명"

label var grandtotal_f_1519   "전체 교육수준 합(원자료 맨아래 총계행, 가로 total), 여, 15-19세 - 명"
label var grandtotal_f_2024   "전체 교육수준 합(원자료 맨아래 총계행, 가로 total), 여, 20-24세 - 명"
label var grandtotal_f_2534   "전체 교육수준 합(원자료 맨아래 총계행, 가로 total), 여, 25-34세 - 명"
label var grandtotal_f_ageall "전체 교육수준 x 전연령 합(grand total), 여 - 명"

save "$data/ABS_T31_2021census.dta", replace
