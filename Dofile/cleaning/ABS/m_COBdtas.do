**********************************************************************  
* Created by Heera Lee 
* Purpose: creates immigration shock explanatory/instrumental variables
* 2001 census: 1991, 1996, 2001 / 2016 census: 2006, 2011, 2016 / 2021 census: 2021
**********************************************************************
clear all
	global main "/Users/ihuila/Research/AUS_immigration"
	global raw "${main}/Data raw"
	global data "${main}/Data cleaned"
	global interim "${main}/Data interim"
	global final "${main}/Data final"
**********************************************************************
set more off

foreach y in 1991 1996 2001 2006 2011 2016 2021 {

    * ---- 연도별 파라미터 ----
    if inlist(`y', 1991, 1996, 2001) {
        local census  "2001"
        local lgavar  "LGA2001"
        local nfiles  = 625
        local born    "Born elsewhere overseas(i)"
        local agglist `" Argentina Austria "Bosnia and Herzegovina(a)" Cambodia Chile Croatia(a) Cyprus France "Macedonia, FYROM (a)(d)" Malta Hungary Mauritius "Not stated" "Overseas visitors" "Papua New Guinea" Portugal Romania "Russian Federation" Spain "Taiwan (Province of China)" Turkey Ukraine "Yugoslavia, Federal Republic of(a)(f)" "Yugoslavia, Former nfd(a)(h)" "Yugoslavia, Former(g)" "'
    }
    else if inlist(`y', 2006, 2011, 2016) {
        local census  "2016"
        local lgavar  "LGA2016"
        local nfiles  = 544
        local born    "Born elsewhere(e)"
        local agglist `" Zimbabwe Pakistan "Country of Birth not stated" Croatia "The Former Yugoslav Republic of Macedonia" Malta Turkey "'
    }
    else if `y'==2021 {
        local census  "2021"
        local lgavar  "LGA2021"
        local nfiles  = 547
        local born    "Born elsewhere(e)"
        local agglist `" Afghanistan Bangladesh Nepal Pakistan "Country of birth not stated" Croatia Taiwan "'
    }

	 * 같은 census table 안에서 어느 T열(=어느 해)을 쓸지
    if `y'==1991 | `y'==2006      local Tcol "T1"
    else if `y'==1996 | `y'==2011 local Tcol "T2"
    else if `y'==2001 | `y'==2016 | `y'==2021 local Tcol "T3"

    cd "$interim/ABS/X/`census'"          // <- 이 줄 추가: cob*.dta들이 있는 폴더로 이동
	
    * ---- LGA crosswalk ----
    import excel using "$raw/LGAFINAL_ALL_2021H.xlsx", sheet("`lgavar'") first clear
    if `y'==2021 drop lga_code2021
    sort `lgavar'
    tempfile lgacode
    save `lgacode'.dta, replace

    * ---- 지역별 cob 파일 append ----
    use cob1.dta, clear
    ren A cob
    foreach var of local agglist {
        replace cob = "`born'" if cob=="`var'"
    }
    collapse (sum) M1 F1 T1 M2 F2 T2 M3 F3 T3, by(`lgavar' lga_info cob)
    tempfile all
    save `all'.dta, replace

    forvalues i = 2/`nfiles' {
        use cob`i'.dta, clear
        ren A cob
        foreach var of local agglist {
            replace cob = "`born'" if cob=="`var'"
        }
        collapse (sum) M1 F1 T1 M2 F2 T2 M3 F3 T3, by(`lgavar' lga_info cob)
        append using `all'.dta
        save `all'.dta, replace
    }
	
	* ---- crosswalk 머지 ----
	sort `lgavar'
	merge m:1 `lgavar' using `lgacode'.dta
	tab _merge
	drop _merge
	tempfile temp401
	save `temp401'.dta, replace

    collapse (sum) M1 F1 T1 M2 F2 T2 M3 F3 T3, by(LGAFINAL21 cob)
    drop if cob=="Total" | cob=="Overseas visitors"

    * ---- cob명 정리 (census vintage별로 다름) ----
    if "`census'"=="2001" {
        replace cob = "China" if cob=="China (excludes SARs and Taiwan Province)(b)"
        replace cob = "Hong Kong" if cob=="Hong Kong (SAR of China)(b)"
        replace cob = "Indonesia" if cob=="Indonesia(c)"
        replace cob = "United Kingdom" if cob=="United Kingdom(e)"
    }
    else {
        replace cob = "Australia" if cob=="Australia(b)"
        replace cob = "China" if cob=="China (excludes SARs and Taiwan)(c)"
        replace cob = "Hong Kong" if cob=="Hong Kong (SAR of China)(c)"
        replace cob = "United Kingdom" if cob=="United Kingdom, Channel Islands and Isle of Man(d)"
    }
    replace cob = "Born elsewhere" if cob=="`born'"

    * ---- 국가코드 매핑 (7개 파일에서 100% 동일했던 블록 -> 한 번만) ----
    gen countrycode = "AUS" if cob=="Australia"
    replace countrycode = "CAN" if cob=="Canada"
    replace countrycode = "CHN" if cob=="China"
    replace countrycode = "EGY" if cob=="Egypt"
    replace countrycode = "FJI" if cob=="Fiji"
    replace countrycode = "DEU" if cob=="Germany"
    replace countrycode = "GRC" if cob=="Greece"
    replace countrycode = "HKG" if cob=="Hong Kong"
    replace countrycode = "IND" if cob=="India"
    replace countrycode = "IDN" if cob=="Indonesia"
    replace countrycode = "IRQ" if cob=="Iraq"
    replace countrycode = "IRL" if cob=="Ireland"
    replace countrycode = "ITA" if cob=="Italy"
    replace countrycode = "JPN" if cob=="Japan"
    replace countrycode = "KOR" if cob=="Korea, Republic of (South)"
    replace countrycode = "LBN" if cob=="Lebanon"
    replace countrycode = "MYS" if cob=="Malaysia"
    replace countrycode = "NLD" if cob=="Netherlands"
    replace countrycode = "NZL" if cob=="New Zealand"
    replace countrycode = "PHL" if cob=="Philippines"
    replace countrycode = "POL" if cob=="Poland"
    replace countrycode = "SGP" if cob=="Singapore"
    replace countrycode = "ZAF" if cob=="South Africa"
    replace countrycode = "LKA" if cob=="Sri Lanka"
    replace countrycode = "THA" if cob=="Thailand"
    replace countrycode = "GBR" if cob=="United Kingdom"
    replace countrycode = "USA" if cob=="United States of America"
    replace countrycode = "VNM" if cob=="Viet Nam" | cob=="Vietnam"
    replace countrycode = "IRN" if cob=="Iran"
    replace countrycode = "ZZZ" if cob=="Born elsewhere"

    ren `Tcol' pop
    keep cob LGAFINAL21 pop countrycode
    gen year = `y'

    egen cob_id = group(countrycode)

    gen pop_immi = pop
    replace pop_immi = . if cob=="Australia"
    
	bysort LGAFINAL21: egen totimmi = total(pop_immi)
    bysort LGAFINAL21: egen tot_pop = total(pop)
    
	sort countrycode
    by countrycode: egen national_pop = total(pop_immi)
	
    gen share_cob = pop_immi/national_pop

    sort LGAFINAL21 cob
    save "$interim/ABS/X/COB`y'_robust_from`census'_v501.dta", replace
	
    * ---- 1991년만: immigrant share 91 base-year share 추가 생성 ----
    if `y'==1991 {
        use "$interim/ABS/X/COB1991_robust_from2001_v501.dta", clear
        sort countrycode
        bysort LGAFINAL21 year: gen share91 = pop_immi / national_pop
        keep LGAFINAL21 year countrycode share91 tot_pop
        reshape wide share91 tot_pop, i(LGAFINAL21 year) j(countrycode) string
        keep LGAFINAL21 year share91* tot_popAUS
        ren tot_popAUS pop_i91
        save "$interim/ABS/X/COB1991_robust_from2001_v502.dta", replace
    }
}
