clear all 
set more off 
cd "/Users/ihuila/Desktop/data/2025ABS"
use cob_XYZ_final.dta 

tab year 

sort LGAFINAL21 year 
xtset LGAFINAL21 year 

gen unempl_rate = unemployed/ labor_force 

foreach v in unempl_rate highed_rate {
    gen `v'_L5 = L5.`v'
}

global fixed i.year 
global demo highed_rate_L5 unempl_rate_L5 


// 변수 
*stem_fshare
*stem_share 
*stem_re 
***************************종속변수: STEM 여성비율  *****************************
cd "/Users/ihuila/Desktop/data/2025ABS/tables"

gen sample = (year>=1996)

est clear 
xi: reg stem_fshare $fixed X_share91 if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: xtivreg2 stem_fshare $fixed X_share91 if sample==1, fe cluster(LGAFINAL21) robust first 
est store reg2 

xi: xtivreg2 stem_fshare $fixed (Z_share91 = X_share91) if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(_fs)
est store reg3

esttab reg* using Table1.csv, nogap stats(N cdf kpf arf arfp) title("Table 1")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

esttab reg* , nogap stats(N cdf kpf arf arfp)  title("Table 1")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

est clear 
xi: reg stem_fshare $fixed  $demo X_share91 if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: xtivreg2 stem_fshare $fixed $demo  X_share91 if sample==1, fe cluster(LGAFINAL21) robust first 
est store reg2 

xi: xtivreg2 stem_fshare $fixed $demo (Z_share91 = X_share91) if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(_fs)
est store reg3

esttab reg* using Table1.csv, nogap stats(N cdf arf arfp) title("Table 1_control")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

************************ 종속변수: Natural science 
est clear 

xi: reg natu_fshare $fixed $demo  X_share91 if sample==1, vce(cluster LGAFINAL21)
est store reg1 

xi: xtivreg2 natu_fshare $fixed $demo X_share91 if sample==1, fe cluster(LGAFINAL21) robust first 
est store reg2 

xi: xtivreg2 natu_fshare $fixed $demo (Z_share91 = X_share91) if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(_fs)
est store reg3

esttab reg* using Table2A.csv, nogap stats(N cdf kpf arf arfp)  title("Table 2A")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

************************ 종속변수: Information technology 
xi: reg info_fshare $fixed $demo  X_share91 if sample==1, vce(cluster LGAFINAL21)
est store reg4 

xi: xtivreg2 info_fshare $fixed $demo X_share91 if sample==1, fe cluster(LGAFINAL21) robust first 
est store reg5 

xi: xtivreg2 info_fshare $fixed $demo (Z_share91 = X_share91) if sample==1, fe cluster(LGAFINAL21) robust first savefprefix(_fs)
est store reg6

esttab reg* using Table2A.csv, nogap stats(N cdf kpf arf arfp)  title("Table 2A")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append 
************************ 종속변수: Engineering 
xi: reg engi_fshare $fixed $demo  X_share91 if sample==1, vce(cluster LGAFINAL21)
est store reg7

xi: xtivreg2 engi_fshare $fixed $demo X_share91 if sample==1, fe cluster(LGAFINAL21) robust first 
est store reg8 

esttab reg* using Table2A.csv, nogap stats(N cdf kpf arf arfp)  title("Table 2A")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) append 
********************** HETEROGENEITY ANALYSIS 
est clear 
xi: reg stem_fshare $fixed $demo X_share91 if sample==1&metro2==1, vce(cluster LGAFINAL21)
est store reg1 

xi: xtivreg2 stem_fshare $fixed $demo X_share91 if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first 
est store reg2

xi: xtivreg2 stem_fshare $fixed $demo (Z_share91 = X_share91) if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(_fs)
est store reg3

xi: reg stem_fshare $fixed $demo X_share91 if sample==1&metro2==0, vce(cluster LGAFINAL21)
est store reg4

xi: xtivreg2 stem_fshare $fixed $demo X_share91 if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first 
est store reg5

xi: xtivreg2 stem_fshare $fixed $demo (Z_share91 = X_share91) if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(_fs)
est store reg6 

esttab reg*,  nogap stats(N cdf kpf arf arfp) title("Table 1")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 
********************** HETEROGENEITY ANALYSIS - natural science 
est clear 
xi: reg natu_fshare $fixed $demo X_share91 if sample==1&metro2==1, vce(cluster LGAFINAL21)
est store reg1 

xi: xtivreg2 natu_fshare $fixed $demo X_share91 if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first 
est store reg2

xi: xtivreg2 natu_fshare $fixed $demo (Z_share91 = X_share91) if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(_fs)
est store reg3

xi: reg natu_fshare $fixed $demo X_share91 if sample==1&metro2==0, vce(cluster LGAFINAL21)
est store reg4

xi: xtivreg2 natu_fshare $fixed $demo X_share91 if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first 
est store reg5

xi: xtivreg2 natu_fshare $fixed $demo (Z_share91 = X_share91) if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(_fs)
est store reg6 

esttab reg*,  nogap stats(N cdf kpf arf arfp) title("Table 1")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

********************** HETEROGENEITY ANALYSIS - information technology
est clear 
xi: reg info_fshare $fixed $demo X_share91 if sample==1&metro2==1, vce(cluster LGAFINAL21)
est store reg1 

xi: xtivreg2 info_fshare $fixed $demo X_share91 if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first 
est store reg2

xi: xtivreg2 info_fshare $fixed $demo (Z_share91 = X_share91) if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(_fs)
est store reg3

xi: reg info_fshare $fixed $demo X_share91 if sample==1&metro2==0, vce(cluster LGAFINAL21)
est store reg4

xi: xtivreg2 info_fshare $fixed $demo X_share91 if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first 
est store reg5

xi: xtivreg2 info_fshare $fixed $demo (Z_share91 = X_share91) if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(_fs)
est store reg6 

esttab reg*,  nogap stats(N cdf kpf arf arfp) title("Table 1")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

********************** HETEROGENEITY ANALYSIS - engineering
est clear 
xi: reg engi_fshare $fixed $demo X_share91 if sample==1&metro2==1, vce(cluster LGAFINAL21)
est store reg1 

xi: xtivreg2 engi_fshare $fixed $demo X_share91 if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first 
est store reg2

xi: xtivreg2 engi_fshare $fixed $demo (Z_share91 = X_share91) if sample==1&metro2==1, fe cluster(LGAFINAL21) robust first savefprefix(_fs)
est store reg3

xi: reg engi_fshare $fixed $demo X_share91 if sample==1&metro2==0, vce(cluster LGAFINAL21)
est store reg4

xi: xtivreg2 engi_fshare $fixed $demo X_share91 if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first 
est store reg5

xi: xtivreg2 engi_fshare $fixed $demo (Z_share91 = X_share91) if sample==1&metro2==0, fe cluster(LGAFINAL21) robust first savefprefix(_fs)
est store reg6 

esttab reg*,  nogap stats(N cdf kpf arf arfp) title("Table 1")   r2(%8.3f) b(%8.3f) se(%8.3f) label star(* 0.10 ** 0.05 *** 0.01) replace 

*******************************************************************
************************** Summary Statistics 
summ X_share91 if sample==1, detail
tabstat X_share91 if sample==1, stat(mean med sd min max N)

tabstat stem_fshare if sample==1, stat(mean med sd min max N)
tabstat natu_fshare if sample==1, stat(mean med sd min max N)
tabstat info_fshare if sample==1, stat(mean med sd min max N)
tabstat engi_fshare if sample==1, stat(mean med sd min max N)
