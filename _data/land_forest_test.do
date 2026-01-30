//// Keep some vignete in the github page explaining the numerical
//// precision of R
//// I nned to check the new 5 example with bengixue
//// DAvid wage DATA
//// Testing infraestructure: run all the tests based on the file dataset ++ all the tests david run 
//// Match Stata
//// Python and R with all the tests and the polars
//// Date: he is going to prese

* Number of effects/placebos
cd "/Users/anzony.quisperojas/Documents/GitHub/did_multiplegt_dyn_py/data"
import delimited "/Users/anzony.quisperojas/Library/CloudStorage/Dropbox/India_forest_land/A_MicroData/_redo_datagen.csv"

* Base variables
local y = "peragri"
local g = "subdistrict_id"
local t = "year"
local d = "post_ror_data_entry"
// egen dist = group(pc11_s_id pc11_d_id)
* Number of effects/placebos
local n_eff = 10
local n_pl = 8

scalar t1 = c(current_time)
// did_multiplegt_dyn `y' `g' `t' `d', graph_off effects(`n_eff') placebo(`n_pl') switchers(in) trends_lin
did_multiplegt_dyn `y' `g' `t' `d', effects(`n_eff') placebo(`n_pl') switchers(in) trends_lin
scalar t2 = c(current_time)
display (clock(t2, "hms") - clock(t1, "hms")) / 1000 " seconds"
stop
