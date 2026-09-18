********************************************************************************
* HILDA data cleaning (Waves 1--21)
* for Jin and Kim, Business and immigrant's life satisfaction
* Date: 2025.6.10.
* Updated:
********************************************************************************

* HILDA data directory
cd "/Users/ihuila/Library/CloudStorage/OneDrive-성균관대학교/applied micro/HILDA"

clear
set memory 1g

// Specify directories (use "." to point to current directory)
local origdatadir "/Users/ihuila/Library/CloudStorage/OneDrive-성균관대학교/applied micro/HILDA"     // Location of original HILDA data files
local newdatadir  "/Users/ihuila/Library/CloudStorage/OneDrive-성균관대학교/applied micro/HILDA/Clean"     // Location to which to write new data files


// SECTION 1: CREATING AN UNBALANCED DATASET (LONG-FORMAT)
// The following code uses the combined files. Since we want the final
// file to be in long format, we need to remove the alphabetic wave
// indicator from the variable names and a create a variable containing
// the numeric wave indicator. For that we use a loop to make things easier.
// Usually not all variables are required. Therefore, in the code we just
// select a few before saving the temporary data file.

local varstokeep hwhmhl hhrhid hhrpid hhpxid hhresp hhstate hhsos ancob losathl ///
                 hstenr hsfrea hsmgpd hsmgsch hhmvehk hhmovek hhmove mhreawp mhreast mhreawt mhrealb mhreasm mhreabn mhrealw mhreaas mhreawr mhreahn jsreatr jsmreas hhiage es esempdt hgenum hgint hsrnt hsrnti hsrntfg hsmg hsmgi hsmgfg hssl hssli hsslfg hifdip hifdin tifdip tifdin hhwth hhwths hhwte hhwtes esbrd esdtl hgage edhigh1 hhtup hhtuh hhpers mrcurr hgsex 
				 *equival_scale
* fiprbuh fiprbeg hiband3 added, and equival_scale does not exist.

* Wave 21 "u" and 22 "v" added. 220c should be changed to 200c if you use wave 20. (I used wave 21)
local i = 0
foreach w in a b c d e f g h i j k l m n o p q r s t u v {
	use "`origdatadir'\Combined_`w'220c"

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
foreach w in a b c d e f g h i j k l m n o p q r s t u v {
	append using "`tempdata_`w''"
	}
order xwaveid wave
sort  xwaveid wave


gen year = wave+2000

order year, before(hhrpid)

gen tifdi=tifdip-tifdin
