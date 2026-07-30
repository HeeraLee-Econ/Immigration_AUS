**********************************************************************
* Created by Heera Lee
* Purpose: T01(Selected Person Characteristics) -> 지역-연도 인구/연령 패널
*          2006 census (1996, 2001, 2006 년도 정보 포함)
*          노동력(Employed/Unemployed/Labour force) 관련 항목은 T13/T33에서 별도 처리
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
**********************************************************************
set more off

local sheet  "T 01"
local lgavar "LGA2006"
local nfiles = 671

capture mkdir "$interim/ABS"
capture mkdir "$interim/ABS/Y/T01"
capture mkdir "$interim/ABS/Y/T01/2006"

**********************************************************************
* PART 1: 671개 LGA 원자료 -> 필요한 행만 뽑아서 cob`i'.dta로 저장
**********************************************************************
cd "$raw/2006"

forvalues i = 1(1)671 {

    * 2006 폴더는 확장자가 xls/xlsx로 섞여있어서 둘 다 확인
    local ext ""
    capture confirm file "`i'.xls"
    if !_rc local ext "xls"
    else {
        capture confirm file "`i'.xlsx"
        if !_rc local ext "xlsx"
    }
    if "`ext'"=="" {
        di as error "SKIP: T01 2006 i=`i' (xls/xlsx not found/locked)"
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

    * 본 데이터: 필요한 행만 라벨 기준으로 (행 위치가 파일마다 달라도 안전)
    import excel using `i'.`ext', sheet("`sheet'") clear
    keep if A=="Total persons(a)" | A=="0-4 years" | A=="5-14 years" | ///
            A=="15-19 years" | A=="20-24 years" | A=="25-34 years" | A=="35-44 years" | ///
            A=="45-54 years" | A=="55-64 years" | A=="65-74 years" | A=="75-84 years" | ///
            A=="85 years and over"
    keep A B C D F G H J K L
    destring B C D F G H J K L, replace force

    * B/C/D=1996, F/G/H=2001, J/K/L=2006 (원본 시트 직접 확인함)
    rename (B C D) (male_1996 female_1996 persons_1996)
    rename (F G H) (male_2001 female_2001 persons_2001)
    rename (J K L) (male_2006 female_2006 persons_2006)

    gen `lgavar' = `i'
    sort `lgavar'
    merge m:1 `lgavar' using `lga'.dta
    drop _merge

    save "$interim/ABS/Y/T01/2006/cob`i'.dta", replace
}
**********************************************************************
* PART 2: cob`i'.dta -> long으로 reshape
* 해당파트 (파트3전까지 한번에 돌려야함)
**********************************************************************
cd "$interim/ABS/Y/T01/2006"

local lgavar "LGA2006"

forvalues i = 1(1)671 {

    use cob`i', clear

    reshape long male_ female_ persons_, i(A) j(year)

    gen totpop   = persons_ if A=="Total persons(a)"
    gen tot_mpop = male_    if A=="Total persons(a)"
    gen tot_fpop = female_  if A=="Total persons(a)"

    local labels `" "15-19 years" "20-24 years" "25-34 years" "35-44 years" "45-54 years" "55-64 years" "65-74 years" "75-84 years" "85 years and over" "'

	gen pop = persons_ if A== "Total persons(a)"
	gen ma_pop = male_ if A== "Total persons(a)"
	gen fe_pop = female_ if A== "Total persons(a)"
	
	gen pop1 = persons_ if A == "15-19 years" //15-19 
	gen pop2 = persons_ if A == "20-24 years" //20-24
	gen pop3 = persons_ if A == "25-34 years" //25-34
	gen pop4 = persons_ if A == "35-44 years" //35-44
	gen pop5 = persons_ if A == "45-54 years" //45-54
	gen pop6 = persons_ if A == "55-64 years" //55-64
	gen pop7 = persons_ if A == "65-74 years" // 65-74
	gen pop8 = persons_ if A == "75-84 years" // 75-84 
	gen pop9 = persons_ if A == "85 years and over" // 85 + 
	
	gen mpop1 = male_ if A == "15-19 years" //15-19 
	gen mpop2 = male_ if A == "20-24 years" //20-24
	gen mpop3 = male_ if A == "25-34 years" //25-34
	gen mpop4 = male_ if A == "35-44 years" //35-44
	gen mpop5 = male_ if A == "45-54 years" //45-54
	gen mpop6 = male_ if A == "55-64 years" //55-64 
	gen mpop7 = male_ if A == "65-74 years" //65-74
	gen mpop8 = male_ if A == "75-84 years" //75-84 
	gen mpop9 = male_ if A == "85 years and over" // 85+ 
	
	gen fpop1 = female_ if A == "15-19 years" //15-19 
	gen fpop2 = female_ if A == "20-24 years" //20-24
	gen fpop3 = female_ if A == "25-34 years" //25-34
	gen fpop4 = female_ if A == "35-44 years" //35-44
	gen fpop5 = female_ if A == "45-54 years" //45-54
	gen fpop6 = female_ if A == "55-64 years" //55-64 
	gen fpop7 = female_ if A == "65-74 years" //65-74
	gen fpop8 = female_ if A == "75-84 years" //75-84 
	gen fpop9 = female_ if A == "85 years and over" // 85+ 

	drop female_* male_* persons_* 
	
    collapse (max) totpop tot_mpop tot_fpop ///
        pop1 pop2 pop3 pop4 pop5 pop6 pop7 pop8 pop9 ///
        mpop1 mpop2 mpop3 mpop4 mpop5 mpop6 mpop7 mpop8 mpop9 ///
        fpop1 fpop2 fpop3 fpop4 fpop5 fpop6 fpop7 fpop8 fpop9, ///
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
save "T01_2006_long.dta", replace
**********************************************************************
* PART 3: 15-64/65+/15+ 연령대 합산 + LGAFINAL21 크로스워크 머지(한 번만) + 최종 저장
**********************************************************************
use "T01_2006_long.dta", clear

local lgavar "LGA2006"

gen popfifold  = pop1+pop2+pop3+pop4+pop5+pop6
gen mpopfifold = mpop1+mpop2+mpop3+mpop4+mpop5+mpop6
gen fpopfifold = fpop1+fpop2+fpop3+fpop4+fpop5+fpop6

gen popold  = pop7+pop8+pop9
gen mpopold = mpop7+mpop8+mpop9
gen fpopold = fpop7+fpop8+fpop9

gen popfifteen  = popfifold + popold
gen mpopfifteen = mpopfifold + mpopold
gen fpopfifteen = fpopfifold + fpopold

drop pop1 pop2 pop3 pop4 pop5 pop6 pop7 pop8 pop9 ///
     mpop1 mpop2 mpop3 mpop4 mpop5 mpop6 mpop7 mpop8 mpop9 ///
     fpop1 fpop2 fpop3 fpop4 fpop5 fpop6 fpop7 fpop8 fpop9

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

* n:1 지역통폐합 있을 수 있어 합산으로 마무리
collapse (sum) totpop tot_mpop tot_fpop popfifteen mpopfifteen fpopfifteen ///
    popold mpopold fpopold popfifold mpopfifold fpopfifold, by(LGAFINAL21 year)

isid LGAFINAL21 year
tab year

order LGAFINAL21 year
sort LGAFINAL21 year

save "$data/ABS_T01_2006census.dta", replace
