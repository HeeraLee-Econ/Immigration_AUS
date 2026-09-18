********************************************************************************
* Created by: Claire Sun                                                       *
* Updated by: Nicole Watson & Markus Hahn                                      *
*                              												   *
* Update again by: Jun Sung Kim                                                *
* Purpose of the progam:										               *
* ======================                                                       *
* This program creates an unbalanced and a balanced longitudinal data file,    *
* using the the combined files. The new data files are in Stata's long format. *
* Please note that we use 'tempfile tempdata_w' to create a macro (local) that *
* allows us to access a temporary data file which will be automatically        *
* deleted when this do-file ends.                                              *
********************************************************************************

clear
set memory 1g
set maxvar 32767


// Specify directories (use "." to point to current directory)
local origdatadir "/Users/ihuila/Library/CloudStorage/OneDrive-성균관대학교/applied micro/HILDA/RS_raw"    // Location of original HILDA data files
local newdatadir  "C:\ㅇㅅㅇ\대학교\연구"     // Location to which to write new data files


// SECTION 1: CREATING AN UNBALANCED DATASET (LONG-FORMAT)
// The following code uses the combined files. Since we want the final
// file to be in long format, we need to remove the alphabetic wave
// indicator from the variable names and a create a variable containing
// the numeric wave indicator. For that we use a loop to make things easier.
// Usually not all variables are required. Therefore, in the code we just
// select a few before saving the temporary data file.

local varstokeep hwhmhl hhrhid hhrpid hhpxid hhresp hhstate hhsos ancob losathl ///
                 wsce wscei wscef wscme wscmei wscmef wscoe wscoei wscoef hxypubt hxypbti hxypbtf xpypubt xppubt xppubta hxymvf hxymvfi hxymvff xpmvf xpmvfa xpymvf lscom hsmguse hsmg hsmgi hsmgfg fiprbmr hstenr hsfrea hsmgpd hsmgsch hhmvehk hhmovek hhmove mhreawp mhreast mhreawt mhrealb mhreasm mhreabn mhrealw mhreaas mhreawr mhreahn jsreatr jsmreas hhiage es esempdt hxygroc hxygrci hxygrcf hxyalc hxyalci hxyalcf hxycig hxycigi hxycigf hxymeal hxymli hxymlf hxyhsge hxyhsgi hxyhsgf hxymvf hxymvfi hxymvff hxymcf hxymcfi hxymcff hxywcf hxywcfi hxywcff hxyccf hxyccfi hxyccff hxyclth hxyclti hxycltf hxytel hxytli hxytlf hxyteli hxytlii hxytlif hxyhol hxyholi hxyholf hxyphi hxyphii hxyphif hxyoi hxyoii hxyoif hxyhltp hxyhlpi hxyhlpf hxyphrm hxyphmi hxyphmf hxyhlth hxyhthi hxyhthf hxyelec hxyelei hxyelef hxygas hxygasi hxygasf hxyohf hxyohfi hxyohff hxyutil hxyutli hxyutlf hxyhmrn hxyhmri hxyhmrf hxymvr hxymvri hxymvrf hxyeduc hxyedci hxyedcf hxyncar hxyncri hxyncrf hxyucar hxyucri hxyucrf hxycomp hxycmpi hxycmpf hxytvav hxytvi hxytvf hxywg hxywgi hxywgf hxyfurn hxyfrni hxyfrnf hgenum hgint hsrnt hsrnti hsrntfg hsmg hsmgi hsmgfg hssl hssli hsslfg hifdip hifdin hstenr tifdip tifdin hhwth hhwths hhwte hhwtes esbrd esdtl hgage ancob edhigh1 hhtup hhtuh hhpers mrcurr hgsex jbhruc jbmhruc fiprbuh fiprbeg hiband3 mr1yr mr1yrn ///
				 hsfrea hsllord hstenr ///
				 hxygrcf hxygrci hxygroc xpfood xpfoodf xpfoodi xpgroc xpgroca xpgrocf xpgroci xpgrocs xpygroc ///
				 hxymeal hxymlf hxymli xpmeal xpmeala xpwmeo xpwmeoa xpymeal ///
				 xposml xposmlf xposmli /// 
				 ffbf ffbread ffbrfr ffcake ffcdiet ffcerl ffconf ffdietf ffdinr fffish fffrt fffrts ffleg fflunr ffmilk ffpasta ffpoult ffprocm ffrmeat ffsalt ffscw ffsnack ffspud ffsrw ffveg ffvegs /// 
				 ancob ancobn ancobw4 anaures ancitiz anaucit anengf anyoa /// 
				 hgyob hgsex hhstate hhtype hhfty dodtyp mrcms chkms tchave ///
				 bncoth1 bncoth2 bncotha bncothw helth hglth ///
				 mrcms chkms esbrd esdtl hges ///
				 bmwt bmwtkg bmwtkg bmwtst ///
				 edsscmp edhistn edhists edhigh1 ///
				 hiband hiband2 hiband3 hiband4 tifdin tifdip tifditn tifditp ///
				 hhsos hhssos hhs3sos hhra hhs3ra hhsra ///
				 bnccvs bnfcvs bnfcvsa bnfcvsf bnfcvsh bnfcvsw ///
				 ancob ancobn ancobw4 ancobw4 anbcob anaures anaures anaures ///
				 ghrp ghgh ghbp ghpf ///
				 ghvt ghre ghmh ghsf ///
				 losat losateo losatfs losatft losathl losatlc losatnl losatsf losatyh ///
				 gh1 gh2 gh3a gh3b gh3c gh3d gh3e gh3f gh3g gh3h gh3i gh3j ///
				 gh4a gh4b gh4c gh4d gh5a gh5b gh5c gh6 gh7 gh8 gh9a gh9b ///
				 gh9c gh9d gh9e gh9f gh9g gh9h gh9i gh10 gh11a gh11b gh11c gh11d ///
				 hhmsr hhmove /// 
				 hhwtrps ///
				 tchad ///
				 lssocal ///
				 lssupac lssupcd lssuplf lssuplt lssupnh lssuppi lssuppv lssupsh lssuptp lssupvl /// 
				 hxyalc hxyccf hxycig hxyeduc hxygroc hxyhltp hxyhmrn hxymcf hxymeal /// 
				 hxymvf hxymvr hxyoi hxyphi hxyphrm hxypubt hxyteli hxyutil hxywcf ///
				 jbhruc jbmpgj jbmploj jbmsall jbmsch jbmsflx jbmshrs jbmspay jbmssec jbmswrk jbnewjs ///
				 jbmi61 jbmi62 jbmii2 ///
				 ujlji61 ujlji62 ujljii2 ///
				 pjoti61 pjoti62 pjotii2 ///
				 es esbrd esdtl esempdt esempst ///
				 hhlga ///
				 
				 *^여기다가 변수 추가하기(기존거 지우지 말고 그냥 뒤에다가 필요한 변수명 추가)
				 *///은 띄어쓰기(엔터 기능)
				 *찾을 때 안 나오면 스펠링 다르게 해서 찾기
				 *housing, food expenditure, 사람수, 등
				 *housing allowance: 보조금
* fiprbuh fiprbeg hiband3 added, and equival_scale(1인당 지출을 구하기 위해 가구원 숫자로 나누기(나이에 따라 다르게 해서)) does not exist.

* Wave 21 "u" added. 210c should be changed to 200c if you use wave 20. (I used wave 21)
local i = 0
foreach w in a b c d e f g h i j k l m n o p q r s t u {
	use "`origdatadir'\Combined_`w'210u"

	renpfix `w'      // Strip off wave prefix
	local i = `i'+1  // Increase (wave) counter by 1
 	gen wave = `i'   // Create wave indicator (1, 2, ...)

	// select variables needed
	if ("`varstokeep'"!="") {
		local tokeep                                 // empty to keep list
		foreach var of local varstokeep {            // loop over all selected variables
			capture confirm variable `var'           // check whether variable exists in current wave
			if (!_rc) local tokeep `tokeep' `var'    // mark for inclusion if variable exists
			}
		keep xwaveid wave `tokeep' // keep selected variables
        }

	// Save temporary data file
	tempfile tempdata_`w'
	save "`tempdata_`w''"
}

// The following code appends the temporary data files for each wave to create
// an unbalanced panel.

* Wave 21 "u" added.
clear
foreach w in a b c d e f g h i j k l m n o p q r s t u  {
	append using "`tempdata_`w''"
	}
order xwaveid wave
sort  xwaveid wave


gen year = wave+2000

order year, before(hhrpid)

gen tifdi=tifdip-tifdin

// Save new data set
save "`newdatadir'\long-file-unbalanced", replace


/* Not running this


// SECTION 2: CREATING BALANCED DATASET (LONG-FORMAT)
// We prepare the master file because we want to keep some useful information.
// To create a balanced panel we can use the variable ivwptn which contains
// the interview pattern for each person. If you want keep more variables from
// the master file, you need to change to following code.

use "`origdatadir'\Master_t210c"
keep xwaveid ivwptn // You can keep more variables if you want
merge 1:m xwaveid using "`newdatadir'\long-file-unbalanced", nogen
keep if ivwptn=="XXXXXXXXXXXXXXXXXXXX" // only keep persons responding in every wave
order xwaveid wave
sort  xwaveid wave

// Save new data set
save "`newdatadir'\long-file-balanced", replace

*/
