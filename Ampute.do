


*** Felix Bittmann, 2024 ***
*In this Do-File we create an amputed dataset, that is, missingness is artificially generated

*** Prepare Dataset ***
webuse nlswork, clear
save "Data/nlswork.dta", replace		//Download once and save for later
use "Data/nlswork.dta", clear
xtset, clear
keep year idcode age grade ln_wage hours ttl_exp tenure
gen wage = exp(ln_wage)
drop ln_wage
drop if wage > 45
keep if inlist(year, 88, 82)
reshape wide age grade wage hours ttl_exp tenure, i(idcode) j(year)
drop age82 grade82 ttl_exp82 tenure82 hours82
rename wage82 wage0
rename age88 age
rename grade88 grade
rename ttl_exp88 ttl_exp
rename tenure88 tenure
rename hours88 hours
rename wage88 wage
egen totalmiss = rowmiss(_all)
drop if totalmiss > 0
drop totalmiss

label var wage "Wage"
label var ttl_exp "Total work experience"
label var hours "Hours per week"
label var age "Age"
label var wage0 "Wage (t-1)"
label var tenure "Current work experience"
label var grade "Completed school years"


********************************************************************************
*** Draw subsample for analyses ***
********************************************************************************
set seed 3435
sample 500, count
label data "Complete NLSW88 data, nomissing"
save "Data/complete.dta", replace


********************************************************************************
*** Generate missing data MAR ***
********************************************************************************
use "Data/complete.dta", replace
set seed 45645611

local corr = 0.03				//Correlation between variables and missingnss
local missfactor = 0.84			//Amount of missing information

*** Wage ***
gen missing_wage = 0.5 < logistic((`corr' * 1.8) * wage0 + `corr' *  age + `corr' *  grade ///
	+ `corr' *  ttl_exp + `corr' * tenure + `corr' * grade + `corr' * hours - rnormal(5.5 * `missfactor', 1))
sum missing_wage
local share_wage = r(mean)
pwcorr missing_wage wage0 age grade ttl_exp tenure grade hours


*** Age ***
gen missing_age = 0.5 < logistic(`corr' * wage0 + `corr' *  wage + `corr' *  grade ///
	+ `corr' *  ttl_exp + `corr' * tenure + `corr' * grade + `corr' * hours - rnormal(4.3 * `missfactor', 1))
sum missing_age
local share_age = r(mean)
pwcorr missing_age wage0 wage grade ttl_exp tenure grade hours


*** Experience ***
gen missing_ttl_exp = 0.5 < logistic(`corr' * wage0 + `corr' *  wage + `corr' *  grade ///
	+ `corr' *  age + `corr' * tenure + `corr' * grade + `corr' * hours - rnormal(5 * `missfactor', 1))
sum missing_ttl_exp
local share_ttl_exl = r(mean)
pwcorr missing_ttl_exp wage0 wage grade tenure age hours


*** Hours ***
gen missing_hours = 0.5 < logistic(`corr' * wage0 + `corr' *  wage + `corr' *  grade ///
	+ `corr' *  age + `corr' * tenure + `corr' * grade + `corr' * ttl_exp - rnormal(4.5 * `missfactor', 1))
sum missing_hours
local share_hours = r(mean)
pwcorr missing_hours wage0 wage grade tenure age ttl_exp


*** Correlation table ***
eststo C1: estpost correlate missing_wage hours age ttl_exp grade tenure wage0
eststo C2: estpost correlate missing_age wage hours ttl_exp grade tenure wage0
eststo C3: estpost correlate missing_hours wage age ttl_exp grade tenure wage0
eststo C4: estpost correlate missing_ttl_exp wage hours age grade tenure wage0
esttab C1 C2 C3 C4 using "Output/correlations_high.rtf", label not rtf replace nogaps ///
	mtitles("Missing wage" "Missing age" "Missing hours" "Missing ttl_exp")




replace wage = . if missing_wage == 1
replace age = . if missing_age == 1
replace ttl_exp = . if missing_ttl_exp == 1
replace hours = . if missing_hours == 1

egen average_miss = rowmean(missing_wage missing_age missing_ttl_exp missing_hours)
sum average_miss
egen totalmiss = rowmiss(wage age ttl_exp hours)
fre totalmiss
gen anymiss = totalmiss > 0
sum anymiss wage age ttl_exp hours
misstable sum wage age ttl_exp hours

reg wage ttl_exp hours age

gen ymissing = missing(wage)
label var ymissing "Wage data is missing"

label data "Incomplete NLSW88 data, missings created"
save "Data/missings_high.dta", replace
