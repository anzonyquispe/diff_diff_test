* Test Controls with Placebos
clear all
set more off

use "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/_data/wagepan.dta", clear

display "=== Controls with Placebos ==="
did_multiplegt_dyn lwage nr year union, effects(5) placebo(2) controls(hours) graph_off

* Display all e() results
ereturn list

* Export to CSV
tempname fh
file open `fh' using "/Users/anzony.quisperojas/Documents/GitHub/diff_diff_test/CX/stata_controls_placebos.csv", write replace
file write `fh' "Type,Index,Estimate,SE" _n

* Effects
forvalues i = 1/5 {
    local est = e(Effect_`i')
    local se = e(SE_Effect_`i')
    file write `fh' "Effect,`i',`est',`se'" _n
}

* Placebos
forvalues i = 1/2 {
    local est = e(Placebo_`i')
    local se = e(SE_Placebo_`i')
    file write `fh' "Placebo,`i',`est',`se'" _n
}

file close `fh'

display "Results saved to stata_controls_placebos.csv"
