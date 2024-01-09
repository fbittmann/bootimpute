



use "Data/missings_high.dta", clear



cap program drop boot_impute
program define boot_impute, rclass
	preserve
	mi set flong
	mi register imputed wage hours ttl_exp age
	mi impute chained (pmm, knn(5)) age ttl_exp hours wage ///
		= wage0 grade tenure, add(35) rseed(723)

	local mi_r2 = 0
	mi describe
	local mtotal = r(M)
	forvalues i = 1/`mtotal' {
		reg wage hours tenure ttl_exp grade age if _mi_m == `i'
		local mi_r2 = `mi_r2' + e(r2)
	}
	return scalar mi_r2 = `mi_r2' / `mtotal'
	restore
end

*bootstrap result=r(mi_r2), reps(20) seed(632): boot_impute
*estat bootstrap, percentile





*** Parallel ***
parallel initialize 5
parallel bs, expression(result=r(mi_r2)) reps(2000) seed(11 23 45 56 83) saving("Data/res_bootimpute.dta", replace): ///
	boot_impute
estat bootstrap, percentile

