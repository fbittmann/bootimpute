




********************************************************************************
/*First, we imputed the dataset once and save the imputed one for later */
use "Data/missings_high.dta", clear


mi set flong
mi register imputed age ttl_exp hours wage
mi impute chained (pmm, knn(5)) age ttl_exp hours wage ///
	= wage0 grade tenure, add(35) rseed(723) dots
gen newid = idcode
compress
save "Data/imputed.dta", replace

********************************************************************************

use "Data/imputed.dta", clear

*** Point Estimate ***
/*Using the imputed dataset, we compute the point estimate of interest*/
tempfile file
tempname name
postfile `name' r2 using `file', replace

mi describe
local mtotal = r(M)
forvalues i = 1/`mtotal' {
	reg wage hours tenure ttl_exp grade age if _mi_m == `i'
	post `name' (e(r2))
}
postclose `name'
preserve
use `file', clear
sum r2, det			//The arithmetic mean is the imputed point estimate
restore


/*Next, we write a program that repeatedly draws bootstrap resamples and always
resamples an entire dataset. This means that for each selected case, all imputations
of this case are retained*/
cap program drop impute_boot
program define impute_boot, rclass
	use "Data/imputed.dta", clear
	mi describe
	local mtotal = r(M)
	bsample, cluster(idcode) idcluster(newid)
	local mi_r2 = 0

	forvalues i = 1/`mtotal' {
		reg wage hours tenure ttl_exp grade age if _mi_m == `i'
		local mi_r2 = `mi_r2' + e(r2)
	}
	local mi_r2 = `mi_r2' / `mtotal'
	return scalar mi_r2 = `mi_r2'
end

*impute_boot		//Here we can test the program with a single draw
*return list

/*Here we can now generate a bootstrap CI by running the program many times.
A new dataset is generated and the centiles of interest computed.
2.5 and 97.5 for a 95% CI
5 and 95 for a 90% CI... and so on
*/
simulate result=r(mi_r2), reps(50) seed(123): impute_boot
centile result, centile(2.5 97.5)
centile result, centile(5 95)





*** Parallel ***
/*The same as above but using parallel to speed things up. Requires parallel from SSC*/
parallel initialize 5
parallel sim, expression(result=r(mi_r2)) reps(2000) seed(11 22 55 69 99) ///
	saving("Data/res_imputeboot", replace): ///
	impute_boot
centile result, centile(2.5 97.5)
sum *, det





/*** THIS DOES NOT WORK ***	
bootstrap e(r2), reps(500) dots(50) seed(7234) cluster(idcode) idcluster(newid): ///
	reg wage hours tenure ttl_exp grade age
estat bootstrap, bc
*/	
