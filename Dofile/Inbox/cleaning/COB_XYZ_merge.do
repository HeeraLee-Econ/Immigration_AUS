clear 
set more off
cd "/Users/ihuila/Desktop/data/2025ABS"

// T04: marriage 
use afterABS5/cob_final 

// T22: couple family, income 
merge m:1 LGAFINAL21 year using afterABS8/cob_final 

tab year if _merge==1 // _merge==1 은 T22 가 2006~2021년도까지라서
drop _merge 

// T23: one parent family, income 
merge m:1 LGAFINAL21 year using afterABS9/cob_final

tab year if _merge==1 // _merge==1 은 T23이 2006~2021년도까지라서 
drop _merge 

// T32: field of study 
merge m:1 LGAFINAL21 year using afterABS7/cob_final.dta

tab year if _merge==1 
drop _merge // _merge==1 은 T32이 2006~2021년도까지라서 


/*
// merge with tempfile 
merge m:1 LGAFINAL21 year using afterABS8/temp_Y.dta 
drop _merge 
*/

// T34: occupation 
merge m:1 LGAFINAL21 year using afterABS4/cob_final 
drop _merge
 
// T35: industry 
merge m:1 LGAFINAL21 year using afterABS2/cob_final 
drop _merge 



// T26: 임금 우위 가구비율 
merge m:1 LGAFINAL21 year using afterABS/cob_final
 
tab year if _merge==1 //1991~2001년은 T26 데이터 없음 
drop _merge 


save "/Users/ihuila/Desktop/data/2025ABS/Y_final.dta", replace 
*****************IV merge 
merge m:1 LGAFINAL21 year using "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_0907.dta"

drop _merge 

// robustness check (leave-out IV)
merge m:1 LGAFINAL21 year using "/Users/ihuila/Desktop/data/2025ABS/afterIV/IV_leaveout.dta"

drop _merge 
/*
merge m:1 LGAFINAL21 year using "/Users/ihuila/Desktop/data/2025ABS/afterIV/IVasian_0930.dta"
drop _merge 
*/
***************** 통제변수 merge
merge m:1 LGAFINAL21 year using "/Users/ihuila/Desktop/data/2025ABS/afterControl/control_final.dta"

drop _merge

**************** generate variable 
***********1. marriage rate 
gen mar_male20 = mar_male2 + mar_male3 + mar_male4  // 20-34세 결혼한 남성
gen mar_female20 = mar_female2 + mar_female3 + mar_female4  // 20-34세 결혼한 여성 
gen mar_to20 = mar_male20 + mar_female20 

gen male20 = to_male2 + to_male3 + to_male4  // 전체 20-34세 남성 
gen female20 = to_female2 + to_female3 + to_female4  // 전체 20-34세 여성 
gen to20 = male20 + female20 

// marriage rate 
gen share_marmale = mar_male20/ male20 
gen share_marfemale = mar_female20/ female20 
gen share_mar =  mar_to20 / to20

// check 
count if share_marmale > 1 
count if share_marfemale > 1
count if share_mar > 1 

br if share_marmale > 1 // 결측, LGAFINAL21 : 5107 - 20-34세 남성 x 
br if share_marfemale > 1 // 결측 LGAFINAL21 : 5107 - 20-34세 여성 x 
br if share_mar > 1 // 결측 LGAFINAL21 : 5107 - 20-34세 여성 x

***********2. unemployment rate 
gen unempl_rate = unemployed/labor_force
gen ma_unempl_rate = ma_unemployed / ma_labor_force 
gen fe_unempl_rate = fe_unemployed / fe_labor_force 

// check 
count if unempl_rate > 1 // 없음 
count if ma_unempl_rate > 1 // 없음 
count if fe_unempl_rate > 1 // 없음 
***********3. number of child 
*** couple family 
egen coup_onetot = rowtotal(coup_onech1 coup_onech2 coup_onech3 coup_onech4 coup_onech5 coup_onech6 coup_onech7 coup_onech8 coup_onech9 coup_onech10 coup_onech11 coup_onech12 coup_onech13 coup_onech14)

egen coup_twotot = rowtotal(coup_twoch1 coup_twoch2 coup_twoch3 coup_twoch4 coup_twoch5 coup_twoch6 coup_twoch7 coup_twoch8 coup_twoch9 coup_twoch10 coup_twoch11 coup_twoch12 coup_twoch13 coup_twoch14)

egen coup_thrtot = rowtotal(coup_thrch1 coup_thrch2 coup_thrch3 coup_thrch4 coup_thrch5 coup_thrch6 coup_thrch7 coup_thrch8 coup_thrch9 coup_thrch10 coup_thrch11 coup_thrch12 coup_thrch13 coup_thrch14)

egen coup_fortot = rowtotal(coup_forch1 coup_forch2 coup_forch3 coup_forch4 coup_forch5 coup_forch6 coup_forch7 coup_forch8 coup_forch9 coup_forch10 coup_forch11 coup_forch12 coup_forch13 coup_forch14)

egen coup_tot = rowtotal(coup_onetot coup_twotot coup_thrtot coup_fortot)
**************generate var 
gen share_couonech = coup_onetot / coup_tot
gen share_coutwoch = coup_twotot / coup_tot
gen share_couthrch = coup_thrtot / coup_tot
gen share_couforch = coup_fortot / coup_tot

count if share_couonech > 1  & share_couonech !=. // 0 
br if  share_couonech > 1  & share_couonech !=. // 0 
count if share_coutwoch > 1  & share_coutwoch !=. // 0
count if share_couthrch > 1  & share_couthrch !=. // 0 
count if share_couforch > 1  & share_couforch !=. // 0 

**** one parents family 
egen onep_onetot = rowtotal(onep_onech1 onep_onech2 onep_onech3 onep_onech4 onep_onech5 onep_onech6 onep_onech7 onep_onech8 onep_onech9 onep_onech10 onep_onech11 onep_onech12 onep_onech13 onep_onech14)

egen onep_twotot = rowtotal(onep_twoch1 onep_twoch2 onep_twoch3 onep_twoch4 onep_twoch5 onep_twoch6 onep_twoch7 onep_twoch8 onep_twoch9 onep_twoch10 onep_twoch11 onep_twoch12 onep_twoch13 onep_twoch14)

egen onep_thrtot = rowtotal(onep_thrch1 onep_thrch2 onep_thrch3 onep_thrch4 onep_thrch5 onep_thrch6 onep_thrch7 onep_thrch8 onep_thrch9 onep_thrch10 onep_thrch11 onep_thrch12 onep_thrch13 onep_thrch14)

egen onep_fortot = rowtotal(onep_forch1 onep_forch2 onep_forch3 onep_forch4 onep_forch5 onep_forch6 onep_forch7 onep_forch8 onep_forch9 onep_forch10 onep_forch11 onep_forch12 onep_forch13 onep_forch14)

egen onep_tot = rowtotal(onep_onetot onep_twotot onep_thrtot onep_fortot)

gen share_oneponech = onep_onetot / onep_tot 
gen share_oneptwoch = onep_twotot / onep_tot 
gen share_onepthrch = onep_thrtot / onep_tot 
gen share_onepforch = onep_fortot / onep_tot 

count if share_oneponech > 1  & share_oneponech !=. // 0 
br if share_oneponech > 1  & share_oneponech !=. 
count if share_oneptwoch > 1  & share_oneptwoch !=. // 0 
count if share_onepthrch > 1  & share_onepthrch !=. // 0 
count if share_onepforch > 1  & share_onepforch !=. // 0 

gen share_coup_onechtop = coup_onech14 / coup_onetot 
gen share_coup_twochtop = coup_twoch14 / coup_twotot 
gen share_coup_thrchtop = coup_thrch14 / coup_thrtot 
gen share_coup_forchtop = coup_forch14 / coup_fortot 

count if share_coup_onechtop > 1 & share_coup_onechtop!=. 
count if share_coup_twochtop > 1 & share_coup_twochtop!=. 
count if share_coup_thrchtop > 1 & share_coup_thrchtop!=. 
count if share_coup_forchtop > 1 & share_coup_forchtop!=.

gen share_onep_onechtop = onep_onech14 / onep_onetot 
gen share_onep_twochtop = onep_twoch14 / onep_twotot 
gen share_onep_thrchtop = onep_thrch14 / onep_thrtot 
gen share_onep_forchtop = onep_forch14 / onep_fortot 

count if share_onep_onechtop > 1 & share_onep_onechtop!=. 
count if share_onep_twochtop > 1 & share_onep_twochtop!=. 
count if share_onep_thrchtop > 1 & share_onep_thrchtop!=. 
count if share_onep_forchtop > 1 & share_onep_forchtop!=.

egen coup_topbin = rowtotal(coup_onech14 coup_twoch14 coup_thrch14 coup_forch14)
egen onep_topbin = rowtotal(onep_onech14 onep_twoch14 onep_thrch14 onep_forch14)

gen share_coup_top = coup_topbin / coup_tot
gen share_onep_top = onep_topbin / onep_tot 

count if share_coup_top >1 & share_coup_top!=. 
count if share_onep_top >1 & share_onep_top!=. 


/*
egen coup_max = rowmax(coup_onech1-coup_onech14)
gen max_bin = .

forvalues i = 1/14 {
    replace max_bin = `i' if coup_onech`i' == coup_max
}
*/

/*
gen share_couonech = coup_onech15 / coup_totalfam15 
gen share_coutwoch = coup_twoch15 / coup_totalfam15 
gen share_couthrch = coup_thrch15 / coup_totalfam15 
gen share_couforch = coup_forch15 / coup_totalfam15 

count if share_couonech > 1  & share_couonech !=. // 1
br if  share_couonech > 1  & share_couonech !=. // 5107, year:2006 - 435
// 실제 데이터셋이랑 비교해보니까 동일함.

count if share_coutwoch > 1  & share_coutwoch !=. // 0
count if share_couthrch > 1  & share_couthrch !=. // 0 
count if share_couforch > 1  & share_couforch !=. // 0 

*** one parents family 
gen share_oneponech = onep_onech15 / onep_totalfam15 
gen share_oneptwoch = onep_twoch15 / onep_totalfam15 
gen share_onepthrch = onep_thrch15 / onep_totalfam15 
gen share_onepforch = onep_forch15 / onep_totalfam15 

count if share_oneponech > 1  & share_oneponech !=. // 12
br if share_oneponech > 1  & share_oneponech !=. 
count if share_oneptwoch > 1  & share_oneptwoch !=. // 2 
count if share_onepthrch > 1  & share_onepthrch !=. // 0 
count if share_onepforch > 1  & share_onepforch !=. // 0 

*/
***********4. STEM share: 20-34세 
egen stem_m = rowtotal(mal20_1 mal25_1 mal20_2 mal25_2 mal20_3 mal25_3)
egen stem_f = rowtotal(fem20_1 fem25_1 fem20_2 fem25_2 fem20_3 fem25_3)
gen stem_t = stem_m + stem_f 

egen field_mal2034 = rowtotal(mal20_1 mal20_2 mal20_3 mal20_4 mal20_5 mal20_6 mal20_7 mal20_8 mal20_9 mal20_10 mal20_11 mal20_12 mal20_13 mal25_1 mal25_2 mal25_3 mal25_4 mal25_5 mal25_6 mal25_7 mal25_8 mal25_9 mal25_10 mal25_11 mal25_12 mal25_13) 

egen field_fem2034 = rowtotal(fem20_1 fem20_2 fem20_3 fem20_4 fem20_5 fem20_6 fem20_7 fem20_8 fem20_9 fem20_10 fem20_11 fem20_12 fem20_13 fem25_1 fem25_2 fem25_3 fem25_4 fem25_5 fem25_6 fem25_7 fem25_8 fem25_9 fem25_10 fem25_11 fem25_12 fem25_13)
gen field_2034 = field_mal2034 + field_fem2034 

gen share_stemm = stem_m / field_mal2034 
gen share_stemf = stem_f / field_fem2034 
gen share_stem = stem_t / field_2034 

count if share_stemm > 1 & share_stemm !=. 
count if share_stemf > 1 & share_stemf !=. 
count if share_stem > 1 & share_stem !=. 

/*
egen nstem_m = rowtotal()
egen nstem_f = rowtotal()
gen share_nstemm 
gen share_nstemf 
*/

***********5. skill level - jobs 
gen share_highsk = highsk_tot / labor_force 
gen share_mhighsk = highsk_male / ma_labor_force 
gen share_fhighsk = highsk_female / fe_labor_force 

gen share_midsk = midsk_tot /  labor_force 
gen share_mmidsk = midsk_male / ma_labor_force  
gen share_fmidsk = midsk_female / fe_labor_force 

gen share_lowsk = lowsk_tot /  labor_force 
gen share_mlowsk = lowsk_male / ma_labor_force  
gen share_flowsk = lowsk_female / fe_labor_force 

count if share_highsk > 1
count if share_midsk > 1
count if share_lowsk > 1 

count if share_mhighsk > 1 
count if share_mmidsk > 1
count if share_mlowsk > 1 

count if share_fhighsk > 1 
count if share_fmidsk > 1
count if share_flowsk > 1 
************6. couple families, income comparison 
gen share_fhigh = ct6_female_higher / ct6_total 
gen share_same = ct6_same / ct6_total 
gen share_mhigh = ct6_male_higher / ct6_total 

count if share_fhigh > 1 & share_fhigh !=. 
count if share_same > 1 & share_same !=. 
count if share_fhigh > 1 & share_fhigh !=. 

*************** control variable 
gen college = bach + grad + postgrad
gen fe_college = fe_bach + fe_grad + fe_postgrad

gen share_college = collegeov / popfifteen
gen share_fe_college = fe_collegeov / fe_popfifteen

gen share_popfifteen = popfifteen / pop
gen share_popfifold  = popfifold  / pop

// check 
count if share_college > 1 // 없음 
count if share_popfifold > 1 // 없음 
count if share_fe_college > 1 // 없음 


cd "/Users/ihuila/Desktop/data/2025ABS"
save cob_XYZ_final,replace 
