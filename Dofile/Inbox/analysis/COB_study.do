clear all 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS"
use cob_XYZ_final.dta 

tab year 

sort LGAFINAL21 year 
xtset LGAFINAL21 year 

gen unempl_rate = unemployed/ labor_force 

foreach v in unempl_rate highed_rate labor_force popfifteen {
    gen `v'_L5 = L5.`v'
}

global fixed i.year 
global demo highed_rate_L5 unempl_rate_L5 
global demo2 highed_rate_L5 labor_force_L5 

gen sample = (year>=1996)

***** 더미변수 만들기 - 기준연도1996년도 
** metropolitan dummy는 연도에 상관없이 쭉 동일하기 때문에 따로 변수 안만들어도 됨 

/*
** 싱글 비율 
summ p_nofemale if year==1996
scalar mean_single = r(mean)
gen high_single = 1 if p_nofemale >= mean_single 
replace high_single = 0 if p_nofemale < mean_single 

** 이민자 비율 
gen immi_share = totimmi / tot_pop 
summ immi_share if year==1996
scalar mean_immi = r(mean)
gen high_immi = 1 if immi_share >= mean_immi 
replace high_immi = 0 if immi_share < mean_immi 

drop immi_share 
*/

**************************pilot study(no control)*********************************
xi: xtivreg2 manu_share (Xit = Zit) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 

xi: xtivreg2 manu_share (Xit2 = Zit2) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 manu_share (Xit3 = Zit3) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 

xi: xtivreg2 serv_share (Xit = Zit) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 serv_share (Xit2 = Zit2) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 

xi: xtivreg2 serv_share (Xit3 = Zit3) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

****** manufacturing - male 
xi: xtivreg2 manu_mshare (Xit = Zit) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 

xi: xtivreg2 manu_mshare (Xit2 = Zit2) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) //유의미하지 않음 

xi: xtivreg2 manu_mshare (Xit3 = Zit3) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 

****** manufacturing - female 
xi: xtivreg2 manu_fshare (Xit = Zit) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 

xi: xtivreg2 manu_fshare (Xit2 = Zit2) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) //유의미하지 않음 

xi: xtivreg2 manu_fshare (Xit3 = Zit3) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 

****** service - male 
xi: xtivreg2 serv_mshare (Xit = Zit) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 증가 

xi: xtivreg2 serv_mshare (Xit2 = Zit2) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) //유의미하지 않음 

xi: xtivreg2 serv_mshare (Xit3 = Zit3) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 증가 

****** service - female 
xi: xtivreg2 serv_fshare (Xit = Zit) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 

xi: xtivreg2 serv_fshare (Xit2 = Zit2) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) //유의미하지 않음 

xi: xtivreg2 serv_fshare (Xit3 = Zit3) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 


**************************pilot study(no control)*********************************
xi: xtivreg2 manu_share (Xit = Zit) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 

xi: xtivreg2 manu_share (Xit2 = Zit2) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 manu_share (Xit3 = Zit3) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 

xi: xtivreg2 serv_share (Xit = Zit) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 serv_share (Xit2 = Zit2) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 

xi: xtivreg2 serv_share (Xit3 = Zit3) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 
******************************with control variables 
****** manufacturing - male 
xi: xtivreg2 manu_mshare (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // Marginally significant, 감소 

xi: xtivreg2 manu_mshare (Xit2 = Zit2) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) //유의미하지 않음 

xi: xtivreg2 manu_mshare (Xit3 = Zit3) i.year  $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 

****** manufacturing - female 
xi: xtivreg2 manu_fshare (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 

xi: xtivreg2 manu_fshare (Xit2 = Zit2) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) //유의미하지 않음 

xi: xtivreg2 manu_fshare (Xit3 = Zit3) i.year  $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 

****** service - male 
xi: xtivreg2 serv_mshare (Xit = Zit) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 증가 

xi: xtivreg2 serv_mshare (Xit2 = Zit2) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) //유의미하지 않음 

xi: xtivreg2 serv_mshare (Xit3 = Zit3) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 증가 

****** service - female 
xi: xtivreg2 serv_fshare (Xit = Zit) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 serv_fshare (Xit2 = Zit2) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) //유의미하지 않음 

xi: xtivreg2 serv_fshare (Xit3 = Zit3) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하고, 감소 
*************************************************************************
xi: xtivreg2 stem_fshare (Xit = Zit) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 stem_fshare (Xit2 = Zit2) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 stem_fshare (Xit3 = Zit3) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 stem_re (Xit = Zit) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 stem_re (Xit2 = Zit2) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 stem_re (Xit3 = Zit3) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 
**** scale 변경한 걸로 
xi: xtivreg2 manu_share (Xit_s = Zit_s) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 manu_share (Xit2_s = Zit2_s) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 manu_share (Xit3_s = Zit3_s) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 serv_share (Xit_s = Zit_s) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 serv_share (Xit2_s = Zit2_s) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 serv_share (Xit3_s = Zit3_s) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 stem_fshare (Xit_s = Zit_s) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 stem_fshare (Xit2_s = Zit2_s) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 stem_fshare (Xit3_s = Zit3_s) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 stem_re (Xit_s = Zit_s) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 stem_re (Xit2_s = Zit2_s) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 stem_re (Xit3_s = Zit3_s) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 unempl_rate (Xit_s = Zit_s) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 unempl_rate (Xit2_s = Zit2_s) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 unempl_rate (Xit2 = Zit2) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 unempl_rate (Xit3_s = Zit3_s) i.year if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

****************************************************************************
************************* w/ control variable 
xi: xtivreg2 manu_share (Xit = Zit) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 manu_share (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 manu_share (Xit2 = Zit2) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 manu_share (Xit3 = Zit3) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 serv_share (Xit = Zit) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 serv_share (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미함 

xi: xtivreg2 serv_share (Xit3 = Zit3) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 stem_fshare (Xit = Zit) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 stem_fshare (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 stem_fshare (Xit3 = Zit3) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 stem_re (Xit = Zit) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 stem_re (Xit2 = Zit2) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 stem_re (Xit3 = Zit3) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 
**** scale 변경한 걸로 
xi: xtivreg2 manu_share (Xit_s = Zit_s) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 manu_share (Xit2_s = Zit2_s) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 manu_share (Xit3_s = Zit3_s) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 serv_share (Xit_s = Zit_s) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 serv_share (Xit2_s = Zit2_s) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 serv_share (Xit3_s = Zit3_s) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 stem_fshare (Xit_s = Zit_s) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 stem_fshare (Xit2_s = Zit2_s) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 stem_fshare (Xit3_s = Zit3_s) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 stem_re (Xit_s = Zit_s) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 

xi: xtivreg2 stem_re (Xit2_s = Zit2_s) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 stem_re (Xit3_s = Zit3_s) i.year $demo if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미한데, 계수가 작음 


xi: xtivreg2 unempl_rate (Xit_s = Zit_s) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 unempl_rate (Xit2_s = Zit2_s) i.year  $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 unempl_rate (Xit3_s = Zit3_s) i.year $demo2 if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

************************HETEROGENEITY ANALYSIS (1)
xi: xtivreg2 stem_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if metro2==1&year>=1996 , fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 대도시에서는 유의미하게 증가 

xi: xtivreg2 stem_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if metro2==0&year>=1996, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 대도시 아닌 지역에서는 - 유의미하지 않음 

xi: xtivreg2 stem_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_immi==1&year>=1996 , fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 이민자 밀집지역에서는 유의미하게 증가 

xi: xtivreg2 stem_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_immi==0&year>=1996, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 stem_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_single==1&year>=1996 , fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하게 증가 

xi: xtivreg2 stem_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_single==0&year>=1996, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // marginally significant 
************************ 엔지니어링 종사자 여성비율 
xi: xtivreg2 engi_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if metro2==1&year>=1996 , fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 대도시에서는 유의미하게 증가 

xi: xtivreg2 engi_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if metro2==0&year>=1996, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 대도시 아닌 지역에서는 - 유의미하지 않음 

xi: xtivreg2 engi_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_immi==1&year>=1996 , fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 이민자 밀집지역에서는 유의미하게 증가 

xi: xtivreg2 engi_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_immi==0&year>=1996, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 engi_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_single==1&year>=1996 , fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하게 증가 

xi: xtivreg2 engi_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_single==0&year>=1996, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

************************ natural science 
xi: xtivreg2 natu_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if metro2==1&year>=1996 , fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 natu_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if metro2==0&year>=1996, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 natu_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_immi==1&year>=1996 , fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 natu_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_immi==0&year>=1996, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 natu_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_single==1&year>=1996 , fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 natu_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_single==0&year>=1996, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 (marginally significant)
************************ information and technology 
xi: xtivreg2 info_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if metro2==1&year>=1996 , fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하게 증가 

xi: xtivreg2 info_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if metro2==0&year>=1996, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 info_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_immi==1&year>=1996 , fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하게 증가 

xi: xtivreg2 info_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_immi==0&year>=1996, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하지 않음 

xi: xtivreg2 info_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_single==1&year>=1996 , fe cluster(LGAFINAL21) robust first savefprefix(fs_) // 유의미하게 증가 

xi: xtivreg2 info_fshare (X_share91 = Z_share91) i.year L5.highed_rate  L5.unempl_rate if high_single==0&year>=1996, fe cluster(LGAFINAL21) robust first savefprefix(fs_) // (marginally significant)


