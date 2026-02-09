********************************************************************************
* File: test_did_multiplegt_dyn_comprehensive.do
* Purpose: Comprehensive test of did_multiplegt_dyn with timing and results export
* OUTPUT: runtime_Stata.csv, coefficients_Stata.csv
********************************************************************************

clear all
set more off

* Set paths
global data_path "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"
global save_path "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/CX"

* Use global macros for temp files (accessible inside programs)
global runtime_file "$save_path/temp_runtime_Stata.dta"
global coef_file "$save_path/temp_coef_Stata.dta"

* Create empty runtime results dataset
clear
gen str50 Example = ""
gen str50 Model = ""
gen double Runtime_sec = .
gen str20 Platform = ""
save "$runtime_file", replace

* Create empty coefficients results dataset
clear
gen str50 Example = ""
gen str50 Model = ""
gen str20 Type = ""
gen int Index = .
gen double Estimate = .
gen double SE = .
save "$coef_file", replace

********************************************************************************
* Helper program to run tests and capture results
********************************************************************************
capture program drop run_did_test
program define run_did_test
    syntax, example(string) model(string) [*]

    display _n "--- `example' : `model' ---"

    * Start timer
    timer clear 1
    timer on 1

    * Run command
    capture noisily did_multiplegt_dyn $y $g $t $d, graph_off `options'
    local rc = _rc

    * Stop timer
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)

    display "Runtime: `elapsed' seconds"
    display ""

    * Store runtime
    preserve
    use "$runtime_file", clear
    local N = _N + 1
    set obs `N'
    replace Example = "`example'" in `N'
    replace Model = "`model'" in `N'
    replace Runtime_sec = `elapsed' in `N'
    replace Platform = "Stata" in `N'
    save "$runtime_file", replace
    restore

    * Extract and store coefficients if successful
    if `rc' == 0 {
        * Extract effects
        forvalues j = 1/20 {
            capture confirm scalar e(Effect_`j')
            if _rc == 0 {
                preserve
                use "$coef_file", clear
                local N = _N + 1
                set obs `N'
                replace Example = "`example'" in `N'
                replace Model = "`model'" in `N'
                replace Type = "Effect" in `N'
                replace Index = `j' in `N'
                replace Estimate = e(Effect_`j') in `N'
                capture replace SE = e(se_effect_`j') in `N'
                save "$coef_file", replace
                restore
            }
            else {
                continue, break
            }
        }

        * Extract placebos
        forvalues j = 1/20 {
            capture confirm scalar e(Placebo_`j')
            if _rc == 0 {
                preserve
                use "$coef_file", clear
                local N = _N + 1
                set obs `N'
                replace Example = "`example'" in `N'
                replace Model = "`model'" in `N'
                replace Type = "Placebo" in `N'
                replace Index = `j' in `N'
                replace Estimate = e(Placebo_`j') in `N'
                capture replace SE = e(se_placebo_`j') in `N'
                save "$coef_file", replace
                restore
            }
            else {
                continue, break
            }
        }

        * Extract average effect
        capture confirm scalar e(Av_tot_effect)
        if _rc == 0 {
            preserve
            use "$coef_file", clear
            local N = _N + 1
            set obs `N'
            replace Example = "`example'" in `N'
            replace Model = "`model'" in `N'
            replace Type = "Avg_Effect" in `N'
            replace Index = 0 in `N'
            replace Estimate = e(Av_tot_effect) in `N'
            capture replace SE = e(se_avg_total_effect) in `N'
            save "$coef_file", replace
            restore
        }
    }
end

********************************************************************************
* WAGEPAN TESTS
********************************************************************************
display _n "================================================================================"
display "WAGEPAN DATASET"
display "================================================================================" _n

use "$data_path/wagepan.dta", clear
display "Data loaded: " _N " observations"

* Define global variables for wagepan
global y lwage
global g nr
global t year
global d union

local n_eff = 5
local n_pl = 2

* 1. Baseline
run_did_test, example(Wagepan) model(Baseline) effects(`n_eff')

* 2. Placebos
run_did_test, example(Wagepan) model(Placebos) effects(`n_eff') placebo(`n_pl')

* 3. Normalized
run_did_test, example(Wagepan) model(Normalized) effects(`n_eff') placebo(`n_pl') normalized

* 4. Controls
run_did_test, example(Wagepan) model(Controls) effects(`n_eff') placebo(`n_pl') controls(hours)

* 5. Trends_Nonparam
run_did_test, example(Wagepan) model(Trends_Nonparam) effects(`n_eff') placebo(`n_pl') trends_nonparam(black)

* 6. Trends_Lin
run_did_test, example(Wagepan) model(Trends_Lin) effects(`n_eff') placebo(`n_pl') trends_lin

* 7. Continuous
run_did_test, example(Wagepan) model(Continuous) effects(`n_eff') placebo(`n_pl') continuous(1)

* 8. Weight
run_did_test, example(Wagepan) model(Weight) effects(`n_eff') placebo(`n_pl') weight(educ)

* 9. Cluster
run_did_test, example(Wagepan) model(Cluster) effects(`n_eff') placebo(`n_pl') cluster(hisp)

* 10. Same_Switchers
run_did_test, example(Wagepan) model(Same_Switchers) effects(`n_eff') placebo(`n_pl') same_switchers

* 11. Same_Switchers_Placebo
run_did_test, example(Wagepan) model(Same_Switchers_Placebo) effects(`n_eff') placebo(`n_pl') same_switchers same_switchers_pl

* 12. Switchers_In
run_did_test, example(Wagepan) model(Switchers_In) effects(`n_eff') placebo(`n_pl') switchers(in)

* 13. Switchers_Out
run_did_test, example(Wagepan) model(Switchers_Out) effects(`n_eff') placebo(`n_pl') switchers(out)

* 14. Only_Never_Switchers
run_did_test, example(Wagepan) model(Only_Never_Switchers) effects(`n_eff') placebo(`n_pl') only_never_switchers

* 15. CI_Level_90
run_did_test, example(Wagepan) model(CI_Level_90) effects(`n_eff') placebo(`n_pl') ci_level(90)

* 16. CI_Level_99
run_did_test, example(Wagepan) model(CI_Level_99) effects(`n_eff') placebo(`n_pl') ci_level(99)

* 17. Less_Conservative_SE
run_did_test, example(Wagepan) model(Less_Conservative_SE) effects(`n_eff') placebo(`n_pl') less_conservative_se

* 18. Bootstrap - Run without bootstrap for comparison (bootstrap not available in Python/R)
run_did_test, example(Wagepan) model(Bootstrap) effects(`n_eff') placebo(`n_pl')

* 19. Dont_Drop_Larger_Lower
run_did_test, example(Wagepan) model(Dont_Drop_Larger_Lower) effects(`n_eff') placebo(`n_pl') dont_drop_larger_lower

* 20. Effects_Equal
run_did_test, example(Wagepan) model(Effects_Equal) effects(`n_eff') placebo(`n_pl') effects_equal(all)

********************************************************************************
* FAVARA-IMBS TESTS
********************************************************************************
display _n "================================================================================"
display "FAVARA-IMBS DATASET"
display "================================================================================" _n

capture {
    use "$data_path/favara_imbs.dta", clear
    display "Data loaded: " _N " observations"

    global y Dl_hpi
    global g county
    global t year
    global d inter_bra

    run_did_test, example(Favara_Imbs) model(Baseline) effects(5) placebo(3) cluster(state_n)
}
if _rc != 0 {
    display "Dataset not found or error"
}

********************************************************************************
* DERYUGINA TESTS
********************************************************************************
display _n "================================================================================"
display "DERYUGINA (2017)"
display "================================================================================" _n

capture confirm file "$data_path/deryugina_2017.dta"
if _rc == 0 {
    use "$data_path/deryugina_2017.dta", clear
    display "Data loaded: " _N " observations"

    global y log_curr_trans_ind_gov_pc
    global g county_fips
    global t year
    global d hurricane

    run_did_test, example(Deryugina) model(Baseline) effects(11) placebo(11) cluster(county_fips)
}
else {
    display "Dataset not found."
}

********************************************************************************
* GENTZKOW TESTS
********************************************************************************
display _n "================================================================================"
display "GENTZKOW (2011)"
display "================================================================================" _n

capture confirm file "$data_path/gentzkow.dta"
if _rc == 0 {
    use "$data_path/gentzkow.dta", clear
    display "Data loaded: " _N " observations"

    global y prestout
    global g cnty90
    global t year
    global d numdailies

    run_did_test, example(Gentzkow) model(Non_Normalized) effects(4) placebo(4)
    run_did_test, example(Gentzkow) model(Normalized) effects(4) placebo(4) normalized
}
else {
    display "Dataset not found."
}

********************************************************************************
* SAVE RESULTS
********************************************************************************
display _n "================================================================================"
display "RUNTIME SUMMARY (Stata)"
display "================================================================================" _n

use "$runtime_file", clear
drop if missing(Example)
list, noobs clean

summarize Runtime_sec
display _n "Total runtime: " r(sum) " seconds"

export delimited using "$save_path/runtime_Stata.csv", replace

display _n "COEFFICIENTS SUMMARY"
use "$coef_file", clear
drop if missing(Example)
list in 1/40, noobs clean

export delimited using "$save_path/coefficients_Stata.csv", replace

* Clean up temp files
capture erase "$runtime_file"
capture erase "$coef_file"

display _n "Results saved to:"
display "  - $save_path/runtime_Stata.csv"
display "  - $save_path/coefficients_Stata.csv"

display _n "================================================================================"
display "COMPLETE"
display "================================================================================"
