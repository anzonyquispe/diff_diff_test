********************************************************************************
* File: benchmark_wolfers_stata.do
* Purpose: Comprehensive DID Estimators Benchmark (Stata)
* Replicates: benchmark_wolfers_complete.R and benchmark_wolfers_python.ipynb
*
* Estimators compared:
*   1. did_multiplegt_dyn - De Chaisemartin & D'Haultfoeuille (2024)
*   2. csdid - Callaway & Sant'Anna (2021)
*   3. did_imputation - Borusyak, Jaravel & Spiess (2024)
*   4. eventstudyinteract - Sun & Abraham (2021)
*   5. reghdfe - Standard Two-Way Fixed Effects
*
* Dataset: wolfers2006_didtextbook.dta
* Specification: div_rate ~ udl | state + year, weight(stpop)
*
* UPDATED 2026-02-06: Per Clément's email, now using 13 effects and 13 placebos
* NOTE: csdid uses bootstrap for inference (affects runtime comparison)
*
* OUTPUT: benchmark_results_stata.csv
********************************************************************************

clear all
set more off
capture log close
set seed 12345

* Set paths - MODIFY THESE FOR YOUR SYSTEM
global data_path "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"
global save_path "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/CX"

* Log file
log using "$save_path/benchmark_wolfers_stata.log", replace text

********************************************************************************
* INSTALL REQUIRED PACKAGES (if not already installed)
********************************************************************************
display _n "Checking/installing required packages..."

foreach pkg in did_multiplegt_dyn csdid did_imputation eventstudyinteract reghdfe ftools {
    capture which `pkg'
    if _rc != 0 {
        display "Installing `pkg'..."
        ssc install `pkg', replace
    }
    else {
        display "`pkg' - OK"
    }
}

* ftools is required for reghdfe
capture which ftools
if _rc != 0 {
    ssc install ftools, replace
}
ftools, compile

********************************************************************************
* SETUP: Create results storage
********************************************************************************
display _n "========================================================================"
display "COMPREHENSIVE BENCHMARK: DID Estimators Comparison (Stata)"
display "========================================================================"
display "Date: $S_DATE $S_TIME"
display "Packages: did_multiplegt_dyn, csdid, did_imputation, eventstudyinteract, reghdfe"
display ""

* Temp file for results
global results_file "$save_path/temp_benchmark_results.dta"

* Create empty results dataset
clear
gen str20 scenario = ""
gen str30 package = ""
gen long rows = .
gen double time_seconds = .
gen str20 status = ""
gen double coefficient = .
gen double std_error = .
save "$results_file", replace

********************************************************************************
* HELPER PROGRAM: Store benchmark result
********************************************************************************
capture program drop store_result
program define store_result
    syntax, scenario(string) package(string) rows(integer) time(real) status(string) ///
           [coef(real 0) se(real 0)]

    preserve
    use "$results_file", clear
    local N = _N + 1
    set obs `N'
    replace scenario = "`scenario'" in `N'
    replace package = "`package'" in `N'
    replace rows = `rows' in `N'
    replace time_seconds = `time' in `N'
    replace status = "`status'" in `N'
    if `coef' != 0 {
        replace coefficient = `coef' in `N'
    }
    if `se' != 0 {
        replace std_error = `se' in `N'
    }
    save "$results_file", replace
    restore
end

********************************************************************************
* HELPER PROGRAM: Create synthetic data by duplicating groups
* Each replication gets unique state IDs: state + (replication-1) * max_state
********************************************************************************
capture program drop create_synthetic_data
program define create_synthetic_data
    syntax, multiplier(integer)

    if `multiplier' == 1 {
        exit
    }

    * Get max state value from original data
    quietly summarize state
    local max_state = r(max)

    * Save original data
    tempfile original
    save `original'

    * Start with empty dataset, then append each replication with offset IDs
    clear

    forvalues i = 1/`multiplier' {
        * Load fresh copy of original
        preserve
        use `original', clear

        * Calculate offset for this replication
        local offset = (`i' - 1) * `max_state'

        * Apply offset to state ID (creates unique state for each replication)
        quietly replace state = state + `offset'

        * Save this replication
        tempfile rep`i'
        save `rep`i''
        restore

        * Append to main dataset
        append using `rep`i''
    }

    * Verify unique state-year combinations
    quietly duplicates report state year
    display "Created synthetic data with " _N " observations"
    display "Unique states: "
    quietly distinct state
    display r(ndistinct)
end

********************************************************************************
* LOAD AND PREPARE DATA
********************************************************************************
display _n "Loading data..."
use "$data_path/wolfers2006_didtextbook.dta", clear

local orig_N = _N
display "Original data rows: `orig_N'"
display "Variables: "
describe, short

* Create first_treat variable for CS/SA estimators
* first_treat = first year when udl == 1, or 0 for never-treated
bysort state (year): gen first_udl = year if udl == 1
bysort state: egen first_treat = min(first_udl)
replace first_treat = 0 if missing(first_treat)
gen first_treat_imp = first_treat
replace first_treat_imp = . if first_treat ==0
drop first_udl

* Create relative time variable
gen rel_time = year - first_treat if first_treat > 0
replace rel_time = -1000 if first_treat == 0

* Summary statistics
display _n "Data summary:"
display "  Unique states: "
quietly distinct state
display r(ndistinct)
summarize year, meanonly
display "  Year range: " r(min) " - " r(max)
tab first_treat, missing


replace rel_timeminus9=(year==cohort-1-9)
gen rel_timeminus10=(year==cohort-1-10)
gen rel_timeminus11=(year==cohort-1-11)
gen rel_timeminus12=(year==cohort-1-12)
gen rel_timeminus13=(year<=cohort-1-13)
drop rel_time14 rel_time15 rel_time16
replace rel_time13=(year>=cohort-1+13)

* Save prepared data
tempfile wolfers_base
save `wolfers_base'

********************************************************************************
* SCENARIO 1: Original Data (~1,683 rows)
********************************************************************************
display _n "========================================================================"
display "SCENARIO 1: Original Data (`orig_N' rows)"
display "========================================================================"

local scenario "Original (1.7K)"
local n_rows = `orig_N'

* -------------------------------------------------------------------------
* 1. did_multiplegt_dyn (De Chaisemartin & D'Haultfoeuille)
* -------------------------------------------------------------------------
display _n "1. Running did_multiplegt_dyn..."
use `wolfers_base', clear

timer clear 1
timer on 1

capture noisily did_multiplegt_dyn div_rate state year udl, ///
    effects(13) placebo(13) weight(stpop) graph_off

local rc = _rc
timer off 1
quietly timer list 1
local elapsed = r(t1)

if `rc' == 0 {
    local coef = e(Effect_1)
    local se = e(se_effect_1)
    display "   Time: " %6.2f `elapsed' "s - SUCCESS"
    display "   Effect_1: " %8.4f `coef'
    store_result, scenario("`scenario'") package("did_multiplegt_dyn") ///
        rows(`n_rows') time(`elapsed') status("completed") coef(`coef') se(`se')
}
else {
    display "   Time: " %6.2f `elapsed' "s - ERROR"
    store_result, scenario("`scenario'") package("did_multiplegt_dyn") ///
        rows(`n_rows') time(`elapsed') status("error")
}

* -------------------------------------------------------------------------
* 2. csdid (Callaway & Sant'Anna)
* NOTE: csdid uses bootstrap for inference - runtime will be slower than
*       analytical SE estimators
* -------------------------------------------------------------------------
display _n "2. Running csdid (Callaway-Sant'Anna) [uses bootstrap]..."
use `wolfers_base', clear

timer clear 1
timer on 1

capture noisily csdid div_rate [weight=stpop], ivar(state) time(year) gvar(cohort) notyet agg(event) long2


local rc = _rc
timer off 1
quietly timer list 1
local elapsed = r(t1)

if `rc' == 0 {
    * Get ATT estimate
    capture matrix b = e(b)
    if _rc == 0 {
        local coef = b[1,1]
    }
    else {
        local coef = .
    }
    display "   Time: " %6.2f `elapsed' "s - SUCCESS"
    store_result, scenario("`scenario'") package("csdid-CS") ///
        rows(`n_rows') time(`elapsed') status("completed") coef(`coef')
}
else {
    display "   Time: " %6.2f `elapsed' "s - ERROR"
    store_result, scenario("`scenario'") package("csdid-CS") ///
        rows(`n_rows') time(`elapsed') status("error")
}

* -------------------------------------------------------------------------
* 3. did_imputation (Borusyak, Jaravel & Spiess)
* -------------------------------------------------------------------------
display _n "3. Running did_imputation (Borusyak-Jaravel-Spiess)..."
use `wolfers_base', clear

timer clear 1
timer on 1

capture noisily did_imputation div_rate state year first_treat_imp [aw=stpop], horizons(0/12) autosample minn(0) pre(13)


local rc = _rc
timer off 1
quietly timer list 1
local elapsed = r(t1)

if `rc' == 0 {
    * Get coefficient from first horizon
    capture matrix b = e(b)
    if _rc == 0 {
        local coef = b[1,1]
    }
    else {
        local coef = .
    }
    display "   Time: " %6.2f `elapsed' "s - SUCCESS"
    store_result, scenario("`scenario'") package("did_imputation-BJS") ///
        rows(`n_rows') time(`elapsed') status("completed") coef(`coef')
}
else {
    display "   Time: " %6.2f `elapsed' "s - ERROR"
    store_result, scenario("`scenario'") package("did_imputation-BJS") ///
        rows(`n_rows') time(`elapsed') status("error")
}

* -------------------------------------------------------------------------
* 4. eventstudyinteract (Sun & Abraham)
* -------------------------------------------------------------------------
display _n "4. Running eventstudyinteract (Sun-Abraham)..."
use `wolfers_base', clear

* Prepare for eventstudyinteract - need relative time dummies
* Keep only observations with valid relative time
drop if rel_time == -1000
keep if rel_time >= -9 & rel_time <= 16

* Create cohort variable (first_treat already exists)
* Generate relative time indicators
forvalues k = 9(-1)2 {
    gen g_`k' = (rel_time == -`k')
}
* ref period is -1
forvalues k = 0/16 {
    gen g`k' = (rel_time == `k')
}

timer clear 1
timer on 1

capture noisily eventstudyinteract div_rate rel_time* [aweight=stpop], absorb(i.state i.year) cohort(first_treat_imp) control_cohort(controlgroup) vce(cluster state)

local rc = _rc
timer off 1
quietly timer list 1
local elapsed = r(t1)

if `rc' == 0 {
    capture matrix b = e(b_iw)
    if _rc == 0 & rowsof(b) > 0 {
        local coef = b[1,1]
    }
    else {
        local coef = .
    }
    display "   Time: " %6.2f `elapsed' "s - SUCCESS"
    store_result, scenario("`scenario'") package("eventstudyinteract-SA") ///
        rows(`n_rows') time(`elapsed') status("completed") coef(`coef')
}
else {
    display "   Time: " %6.2f `elapsed' "s - ERROR"
    store_result, scenario("`scenario'") package("eventstudyinteract-SA") ///
        rows(`n_rows') time(`elapsed') status("error")
}



********************************************************************************
* SCENARIO 2: Synthetic Data 100x (~168,300 rows)
********************************************************************************
display _n "========================================================================"
display "SCENARIO 2: Synthetic Data 100x"
display "========================================================================"

use `wolfers_base', clear
create_synthetic_data, multiplier(100)

local n_rows = _N
display "Synthetic data rows: `n_rows'"

local scenario "100x (168K)"

tempfile wolfers_100x
save `wolfers_100x'

* -------------------------------------------------------------------------
* 1. did_multiplegt_dyn - 100x
* -------------------------------------------------------------------------
display _n "1. Running did_multiplegt_dyn on 100x data..."
use `wolfers_100x', clear

timer clear 1
timer on 1

capture noisily did_multiplegt_dyn div_rate state year udl, ///
    effects(13) placebo(13) weight(stpop) graph_off

local rc = _rc
timer off 1
quietly timer list 1
local elapsed = r(t1)

if `rc' == 0 {
    display "   Time: " %6.2f `elapsed' "s - SUCCESS"
    store_result, scenario("`scenario'") package("did_multiplegt_dyn") ///
        rows(`n_rows') time(`elapsed') status("completed")
}
else {
    display "   Time: " %6.2f `elapsed' "s - ERROR"
    store_result, scenario("`scenario'") package("did_multiplegt_dyn") ///
        rows(`n_rows') time(`elapsed') status("error")
}

* -------------------------------------------------------------------------
* 2. csdid - 100x
* -------------------------------------------------------------------------
display _n "2. Running csdid on 100x data..."
use `wolfers_100x', clear

timer clear 1
timer on 1

capture noisily csdid div_rate [weight=stpop], ivar(state) time(year) gvar(cohort) notyet agg(event) long2

local rc = _rc
timer off 1
quietly timer list 1
local elapsed = r(t1)

if `rc' == 0 {
    display "   Time: " %6.2f `elapsed' "s - SUCCESS"
    store_result, scenario("`scenario'") package("csdid-CS") ///
        rows(`n_rows') time(`elapsed') status("completed")
}
else {
    display "   Time: " %6.2f `elapsed' "s - ERROR"
    store_result, scenario("`scenario'") package("csdid-CS") ///
        rows(`n_rows') time(`elapsed') status("error")
}

* -------------------------------------------------------------------------
* 3. did_imputation - 100x
* -------------------------------------------------------------------------
display _n "3. Running did_imputation on 100x data..."
use `wolfers_100x', clear

timer clear 1
timer on 1

capture noisily did_imputation div_rate state year first_treat_imp [aw=stop],  horizons(0/12) autosample minn(0) pre(13)

local rc = _rc
timer off 1
quietly timer list 1
local elapsed = r(t1)

if `rc' == 0 {
    display "   Time: " %6.2f `elapsed' "s - SUCCESS"
    store_result, scenario("`scenario'") package("did_imputation-BJS") ///
        rows(`n_rows') time(`elapsed') status("completed")
}
else {
    display "   Time: " %6.2f `elapsed' "s - ERROR"
    store_result, scenario("`scenario'") package("did_imputation-BJS") ///
        rows(`n_rows') time(`elapsed') status("error")
}

* -------------------------------------------------------------------------
* 4. eventstudyinteract (Sun & Abraham)
* -------------------------------------------------------------------------
display _n "4. Running eventstudyinteract (Sun-Abraham)..."
use `wolfers_100x', clear

timer clear 1
timer on 1

capture noisily eventstudyinteract div_rate rel_time* [aweight=stpop], absorb(i.state i.year) cohort(first_treat_imp) control_cohort(controlgroup) vce(cluster state)

local rc = _rc
timer off 1
quietly timer list 1
local elapsed = r(t1)

if `rc' == 0 {
    capture matrix b = e(b_iw)
    if _rc == 0 & rowsof(b) > 0 {
        local coef = b[1,1]
    }
    else {
        local coef = .
    }
    display "   Time: " %6.2f `elapsed' "s - SUCCESS"
    store_result, scenario("`scenario'") package("eventstudyinteract-SA") ///
        rows(`n_rows') time(`elapsed') status("completed") coef(`coef')
}
else {
    display "   Time: " %6.2f `elapsed' "s - ERROR"
    store_result, scenario("`scenario'") package("eventstudyinteract-SA") ///
        rows(`n_rows') time(`elapsed') status("error")
}



********************************************************************************
* SCENARIO 3: Synthetic Data 1000x (~1,683,000 rows)
********************************************************************************
display _n "========================================================================"
display "SCENARIO 3: Synthetic Data 1000x"
display "========================================================================"

use `wolfers_base', clear
create_synthetic_data, multiplier(1000)

local n_rows = _N
display "Synthetic data rows: `n_rows'"

local scenario "1000x (1.68M)"

tempfile wolfers_1000x
save `wolfers_1000x'

* -------------------------------------------------------------------------
* 1. did_multiplegt_dyn - 1000x
* -------------------------------------------------------------------------
display _n "1. Running did_multiplegt_dyn on 1000x data..."
use `wolfers_1000x', clear

timer clear 1
timer on 1

capture noisily did_multiplegt_dyn div_rate state year udl, ///
    effects(13) placebo(13) weight(stpop) graph_off

local rc = _rc
timer off 1
quietly timer list 1
local elapsed = r(t1)

if `rc' == 0 {
    display "   Time: " %6.2f `elapsed' "s - SUCCESS"
    store_result, scenario("`scenario'") package("did_multiplegt_dyn") ///
        rows(`n_rows') time(`elapsed') status("completed")
}
else {
    display "   Time: " %6.2f `elapsed' "s - ERROR"
    store_result, scenario("`scenario'") package("did_multiplegt_dyn") ///
        rows(`n_rows') time(`elapsed') status("error")
}

* -------------------------------------------------------------------------
* 2. did_imputation - 1000x
* -------------------------------------------------------------------------
display _n "2. Running did_imputation on 1000x data..."
use `wolfers_1000x', clear

timer clear 1
timer on 1

capture noisily did_imputation div_rate state year first_treat_imp [aw=stop],  horizons(0/12) autosample minn(0) pre(13)

local rc = _rc
timer off 1
quietly timer list 1
local elapsed = r(t1)

if `rc' == 0 {
    display "   Time: " %6.2f `elapsed' "s - SUCCESS"
    store_result, scenario("`scenario'") package("did_imputation-BJS") ///
        rows(`n_rows') time(`elapsed') status("completed")
}
else {
    display "   Time: " %6.2f `elapsed' "s - ERROR"
    store_result, scenario("`scenario'") package("did_imputation-BJS") ///
        rows(`n_rows') time(`elapsed') status("error")
}

* -------------------------------------------------------------------------
* 3. csdid - 1000x
* -------------------------------------------------------------------------
display _n "2. Running csdid on 1000x data..."
use `wolfers_1000x', clear

timer clear 1
timer on 1

capture noisily csdid div_rate [weight=stpop], ivar(state) time(year) gvar(cohort) notyet agg(event)

local rc = _rc
timer off 1
quietly timer list 1
local elapsed = r(t1)

if `rc' == 0 {
    display "   Time: " %6.2f `elapsed' "s - SUCCESS"
    store_result, scenario("`scenario'") package("csdid-CS") ///
        rows(`n_rows') time(`elapsed') status("completed")
}
else {
    display "   Time: " %6.2f `elapsed' "s - ERROR"
    store_result, scenario("`scenario'") package("csdid-CS") ///
        rows(`n_rows') time(`elapsed') status("error")
}


* -------------------------------------------------------------------------
* 4. eventstudyinteract (Sun & Abraham)
* -------------------------------------------------------------------------
display _n "4. Running eventstudyinteract (Sun-Abraham)..."
use `wolfers_1000x', clear

timer clear 1
timer on 1

capture noisily eventstudyinteract div_rate rel_time* [aweight=stpop], absorb(i.state i.year) cohort(first_treat_imp) control_cohort(controlgroup) vce(cluster state)

local rc = _rc
timer off 1
quietly timer list 1
local elapsed = r(t1)

if `rc' == 0 {
    capture matrix b = e(b_iw)
    if _rc == 0 & rowsof(b) > 0 {
        local coef = b[1,1]
    }
    else {
        local coef = .
    }
    display "   Time: " %6.2f `elapsed' "s - SUCCESS"
    store_result, scenario("`scenario'") package("eventstudyinteract-SA") ///
        rows(`n_rows') time(`elapsed') status("completed") coef(`coef')
}
else {
    display "   Time: " %6.2f `elapsed' "s - ERROR"
    store_result, scenario("`scenario'") package("eventstudyinteract-SA") ///
        rows(`n_rows') time(`elapsed') status("error")
}



********************************************************************************
* SUMMARY OF RESULTS
********************************************************************************
display _n "========================================================================"
display "SUMMARY OF RESULTS"
display "========================================================================"

use "$results_file", clear
drop if missing(scenario)

list scenario package rows time_seconds status coefficient, noobs clean

* Create pivot table manually
display _n _n "PIVOT TABLE (Time in seconds):"
display "========================================================================"

preserve
reshape wide time_seconds, i(package) j(scenario) string
list package time_seconds*, noobs clean
restore

* Save results to CSV
export delimited using "$save_path/benchmark_results_stata.csv", replace

display _n "Results saved to: $save_path/benchmark_results_stata.csv"

* Summary statistics
display _n "Runtime Statistics:"
summarize time_seconds if status == "completed"

* Clean up
capture erase "$results_file"

display _n "========================================================================"
display "BENCHMARK COMPLETE"
display "========================================================================"
display "Date: $S_DATE $S_TIME"

log close
