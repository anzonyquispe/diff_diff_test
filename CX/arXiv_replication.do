********************************************************************************
* File: arXiv_replication.do
* Purpose: Replicate did_multiplegt_dyn examples with runtime & coefficient export
* OUTPUT: runtime_stata.csv, coefficients_stata.csv
********************************************************************************

clear all
set more off
capture log close _all

global data_path "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data"
global save_path "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/CX"

* Initialize runtime results file (overwrite)
tempname fh
file open `fh' using "$save_path/runtime_stata.csv", write replace
file write `fh' `""Example","Model","Runtime_sec""' _n
file close `fh'

* Initialize coefficients file with Type column
tempname fh2
file open `fh2' using "$save_path/coefficients_stata.csv", write replace
file write `fh2' `""Example","Model","Type","Index","Estimate","SE""' _n
file close `fh2'

********************************************************************************
* WAGEPAN TESTS
********************************************************************************
display _newline(2) "================================================================================"
display "WAGEPAN DATASET"
display "================================================================================"

use "$data_path/wagepan.dta", clear
count

local example "Wagepan"

* Test 1: Baseline
local model "Baseline"
display _newline "--- `example': `model' ---"
timer clear 1
timer on 1
did_multiplegt_dyn lwage nr year union, effects(5) graph_off
timer off 1
qui timer list 1
local t = r(t1)
display "Runtime: `t' seconds"
file open fh using "$save_path/runtime_stata.csv", write append
file write fh `""`example'","`model'",`t'"' _n
file close fh
* Save effects
forvalues i = 1/5 {
    capture local est = e(Effect_`i')
    capture local se = e(se_effect_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Effect",`i',`est',`se'"' _n
    file close fh
}

* Test 2: Placebos
local model "Placebos"
display _newline "--- `example': `model' ---"
timer clear 1
timer on 1
did_multiplegt_dyn lwage nr year union, effects(5) placebo(2) graph_off
timer off 1
qui timer list 1
local t = r(t1)
display "Runtime: `t' seconds"
file open fh using "$save_path/runtime_stata.csv", write append
file write fh `""`example'","`model'",`t'"' _n
file close fh
* Save effects
forvalues i = 1/5 {
    capture local est = e(Effect_`i')
    capture local se = e(se_effect_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Effect",`i',`est',`se'"' _n
    file close fh
}
* Save placebos
forvalues i = 1/2 {
    capture local est = e(Placebo_`i')
    capture local se = e(se_placebo_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Placebo",`i',`est',`se'"' _n
    file close fh
}

* Test 3: Normalized
local model "Normalized"
display _newline "--- `example': `model' ---"
timer clear 1
timer on 1
did_multiplegt_dyn lwage nr year union, effects(5) placebo(2) normalized graph_off
timer off 1
qui timer list 1
local t = r(t1)
display "Runtime: `t' seconds"
file open fh using "$save_path/runtime_stata.csv", write append
file write fh `""`example'","`model'",`t'"' _n
file close fh
* Save effects
forvalues i = 1/5 {
    capture local est = e(Effect_`i')
    capture local se = e(se_effect_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Effect",`i',`est',`se'"' _n
    file close fh
}
* Save placebos
forvalues i = 1/2 {
    capture local est = e(Placebo_`i')
    capture local se = e(se_placebo_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Placebo",`i',`est',`se'"' _n
    file close fh
}

* Test 4: Controls
local model "Controls"
display _newline "--- `example': `model' ---"
timer clear 1
timer on 1
did_multiplegt_dyn lwage nr year union, effects(5) placebo(2) controls(hours) graph_off
timer off 1
qui timer list 1
local t = r(t1)
display "Runtime: `t' seconds"
file open fh using "$save_path/runtime_stata.csv", write append
file write fh `""`example'","`model'",`t'"' _n
file close fh
* Save effects
forvalues i = 1/5 {
    capture local est = e(Effect_`i')
    capture local se = e(se_effect_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Effect",`i',`est',`se'"' _n
    file close fh
}
* Save placebos
forvalues i = 1/2 {
    capture local est = e(Placebo_`i')
    capture local se = e(se_placebo_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Placebo",`i',`est',`se'"' _n
    file close fh
}

* Test 5: Trends_Nonparam
local model "Trends_Nonparam"
display _newline "--- `example': `model' ---"
timer clear 1
timer on 1
did_multiplegt_dyn lwage nr year union, effects(5) placebo(2) trends_nonparam(black) graph_off
timer off 1
qui timer list 1
local t = r(t1)
display "Runtime: `t' seconds"
file open fh using "$save_path/runtime_stata.csv", write append
file write fh `""`example'","`model'",`t'"' _n
file close fh
* Save effects
forvalues i = 1/5 {
    capture local est = e(Effect_`i')
    capture local se = e(se_effect_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Effect",`i',`est',`se'"' _n
    file close fh
}
* Save placebos
forvalues i = 1/2 {
    capture local est = e(Placebo_`i')
    capture local se = e(se_placebo_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Placebo",`i',`est',`se'"' _n
    file close fh
}

* Test 6: Trends_Lin
local model "Trends_Lin"
display _newline "--- `example': `model' ---"
timer clear 1
timer on 1
did_multiplegt_dyn lwage nr year union, effects(5) placebo(2) trends_lin graph_off
timer off 1
qui timer list 1
local t = r(t1)
display "Runtime: `t' seconds"
file open fh using "$save_path/runtime_stata.csv", write append
file write fh `""`example'","`model'",`t'"' _n
file close fh
* Save effects
forvalues i = 1/5 {
    capture local est = e(Effect_`i')
    capture local se = e(se_effect_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Effect",`i',`est',`se'"' _n
    file close fh
}
* Save placebos
forvalues i = 1/2 {
    capture local est = e(Placebo_`i')
    capture local se = e(se_placebo_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Placebo",`i',`est',`se'"' _n
    file close fh
}

* Test 7: Cluster
local model "Cluster"
display _newline "--- `example': `model' ---"
timer clear 1
timer on 1
did_multiplegt_dyn lwage nr year union, effects(5) placebo(2) cluster(hisp) graph_off
timer off 1
qui timer list 1
local t = r(t1)
display "Runtime: `t' seconds"
file open fh using "$save_path/runtime_stata.csv", write append
file write fh `""`example'","`model'",`t'"' _n
file close fh
* Save effects
forvalues i = 1/5 {
    capture local est = e(Effect_`i')
    capture local se = e(se_effect_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Effect",`i',`est',`se'"' _n
    file close fh
}
* Save placebos
forvalues i = 1/2 {
    capture local est = e(Placebo_`i')
    capture local se = e(se_placebo_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Placebo",`i',`est',`se'"' _n
    file close fh
}

* Test 8: Same_Switchers
local model "Same_Switchers"
display _newline "--- `example': `model' ---"
timer clear 1
timer on 1
did_multiplegt_dyn lwage nr year union, effects(5) placebo(2) same_switchers graph_off
timer off 1
qui timer list 1
local t = r(t1)
display "Runtime: `t' seconds"
file open fh using "$save_path/runtime_stata.csv", write append
file write fh `""`example'","`model'",`t'"' _n
file close fh
* Save effects
forvalues i = 1/5 {
    capture local est = e(Effect_`i')
    capture local se = e(se_effect_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Effect",`i',`est',`se'"' _n
    file close fh
}
* Save placebos
forvalues i = 1/2 {
    capture local est = e(Placebo_`i')
    capture local se = e(se_placebo_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Placebo",`i',`est',`se'"' _n
    file close fh
}

* Test 9: Switchers_In
local model "Switchers_In"
display _newline "--- `example': `model' ---"
timer clear 1
timer on 1
did_multiplegt_dyn lwage nr year union, effects(5) placebo(2) switchers(in) graph_off
timer off 1
qui timer list 1
local t = r(t1)
display "Runtime: `t' seconds"
file open fh using "$save_path/runtime_stata.csv", write append
file write fh `""`example'","`model'",`t'"' _n
file close fh
* Save effects
forvalues i = 1/5 {
    capture local est = e(Effect_`i')
    capture local se = e(se_effect_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Effect",`i',`est',`se'"' _n
    file close fh
}
* Save placebos
forvalues i = 1/2 {
    capture local est = e(Placebo_`i')
    capture local se = e(se_placebo_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Placebo",`i',`est',`se'"' _n
    file close fh
}

* Test 10: Switchers_Out
local model "Switchers_Out"
display _newline "--- `example': `model' ---"
timer clear 1
timer on 1
did_multiplegt_dyn lwage nr year union, effects(5) placebo(2) switchers(out) graph_off
timer off 1
qui timer list 1
local t = r(t1)
display "Runtime: `t' seconds"
file open fh using "$save_path/runtime_stata.csv", write append
file write fh `""`example'","`model'",`t'"' _n
file close fh
* Save effects
forvalues i = 1/5 {
    capture local est = e(Effect_`i')
    capture local se = e(se_effect_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Effect",`i',`est',`se'"' _n
    file close fh
}
* Save placebos
forvalues i = 1/2 {
    capture local est = e(Placebo_`i')
    capture local se = e(se_placebo_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Placebo",`i',`est',`se'"' _n
    file close fh
}

********************************************************************************
* FAVARA-IMBS
********************************************************************************
display _newline(2) "================================================================================"
display "FAVARA-IMBS DATASET"
display "================================================================================"

use "$data_path/favara_imbs.dta", clear
count

local example "Favara_Imbs"
local model "Baseline"
display _newline "--- `example': `model' ---"
timer clear 1
timer on 1
did_multiplegt_dyn Dl_hpi county year inter_bra, effects(5) placebo(3) cluster(state_n) graph_off
timer off 1
qui timer list 1
local t = r(t1)
display "Runtime: `t' seconds"
file open fh using "$save_path/runtime_stata.csv", write append
file write fh `""`example'","`model'",`t'"' _n
file close fh
* Save effects
forvalues i = 1/5 {
    capture local est = e(Effect_`i')
    capture local se = e(se_effect_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Effect",`i',`est',`se'"' _n
    file close fh
}
* Save placebos
forvalues i = 1/3 {
    capture local est = e(Placebo_`i')
    capture local se = e(se_placebo_`i')
    file open fh using "$save_path/coefficients_stata.csv", write append
    file write fh `""`example'","`model'","Placebo",`i',`est',`se'"' _n
    file close fh
}

********************************************************************************
* DERYUGINA
********************************************************************************
display _newline(2) "================================================================================"
display "DERYUGINA (2017)"
display "================================================================================"

capture confirm file "$data_path/deryugina_2017.dta"
if _rc == 0 {
    use "$data_path/deryugina_2017.dta", clear
    count

    local example "Deryugina"
    local model "Baseline"
    display _newline "--- `example': `model' ---"
    timer clear 1
    timer on 1
    did_multiplegt_dyn log_curr_trans_ind_gov_pc county_fips year hurricane, effects(11) placebo(11) cluster(county_fips) graph_off
    timer off 1
    qui timer list 1
    local t = r(t1)
    display "Runtime: `t' seconds"
    file open fh using "$save_path/runtime_stata.csv", write append
    file write fh `""`example'","`model'",`t'"' _n
    file close fh
    * Save effects
    forvalues i = 1/11 {
        capture local est = e(Effect_`i')
        capture local se = e(se_effect_`i')
        file open fh using "$save_path/coefficients_stata.csv", write append
        file write fh `""`example'","`model'","Effect",`i',`est',`se'"' _n
        file close fh
    }
    * Save placebos
    forvalues i = 1/11 {
        capture local est = e(Placebo_`i')
        capture local se = e(se_placebo_`i')
        file open fh using "$save_path/coefficients_stata.csv", write append
        file write fh `""`example'","`model'","Placebo",`i',`est',`se'"' _n
        file close fh
    }
}
else {
    display "Dataset not found."
}

********************************************************************************
* GENTZKOW
********************************************************************************
display _newline(2) "================================================================================"
display "GENTZKOW (2011)"
display "================================================================================"

capture confirm file "$data_path/gentzkow.dta"
if _rc == 0 {
    use "$data_path/gentzkow.dta", clear
    count

    local example "Gentzkow"

    * Non-normalized
    local model "Non_Normalized"
    display _newline "--- `example': `model' ---"
    timer clear 1
    timer on 1
    did_multiplegt_dyn prestout cnty90 year numdailies, effects(4) placebo(4) graph_off
    timer off 1
    qui timer list 1
    local t = r(t1)
    display "Runtime: `t' seconds"
    file open fh using "$save_path/runtime_stata.csv", write append
    file write fh `""`example'","`model'",`t'"' _n
    file close fh
    * Save effects
    forvalues i = 1/4 {
        capture local est = e(Effect_`i')
        capture local se = e(se_effect_`i')
        file open fh using "$save_path/coefficients_stata.csv", write append
        file write fh `""`example'","`model'","Effect",`i',`est',`se'"' _n
        file close fh
    }
    * Save placebos
    forvalues i = 1/4 {
        capture local est = e(Placebo_`i')
        capture local se = e(se_placebo_`i')
        file open fh using "$save_path/coefficients_stata.csv", write append
        file write fh `""`example'","`model'","Placebo",`i',`est',`se'"' _n
        file close fh
    }

    * Normalized
    local model "Normalized"
    display _newline "--- `example': `model' ---"
    timer clear 1
    timer on 1
    did_multiplegt_dyn prestout cnty90 year numdailies, effects(4) placebo(4) normalized graph_off
    timer off 1
    qui timer list 1
    local t = r(t1)
    display "Runtime: `t' seconds"
    file open fh using "$save_path/runtime_stata.csv", write append
    file write fh `""`example'","`model'",`t'"' _n
    file close fh
    * Save effects
    forvalues i = 1/4 {
        capture local est = e(Effect_`i')
        capture local se = e(se_effect_`i')
        file open fh using "$save_path/coefficients_stata.csv", write append
        file write fh `""`example'","`model'","Effect",`i',`est',`se'"' _n
        file close fh
    }
    * Save placebos
    forvalues i = 1/4 {
        capture local est = e(Placebo_`i')
        capture local se = e(se_placebo_`i')
        file open fh using "$save_path/coefficients_stata.csv", write append
        file write fh `""`example'","`model'","Placebo",`i',`est',`se'"' _n
        file close fh
    }
}
else {
    display "Dataset not found."
}

********************************************************************************
* SUMMARY
********************************************************************************
display _newline(2) "================================================================================"
display "RESULTS SUMMARY"
display "================================================================================"
display "Runtime saved to: $save_path/runtime_stata.csv"
display "Coefficients saved to: $save_path/coefficients_stata.csv"
display "================================================================================"
