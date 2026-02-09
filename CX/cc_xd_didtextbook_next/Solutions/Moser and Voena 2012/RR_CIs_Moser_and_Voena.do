*use "C:\Users\dearb\Leopoldo Research Dropbox\David Arboleda\A Mini course DID\Applications\Data sets\Moser and Voena 2012\moser_voena_didtextbook.dta", clear


timer clear
timer on 1


use "C:\Users\de.arboleda\Leopoldo Research Dropbox\David Arboleda\Mini course DID\Applications\Data sets\Moser and Voena 2012\moser_voena_didtextbook.dta", clear


*** 5) Sensitivity analysis of Rambachan and Roth 

gen reltimeminus0 = 0 //Relative time 0 set to be always 0 so that it is automatically omitted.

reghdfe patents reltimeminus18 reltimeminus17 reltimeminus16 reltimeminus15 reltimeminus14 reltimeminus13 reltimeminus12 reltimeminus11 reltimeminus10 reltimeminus9 reltimeminus8 reltimeminus7 reltimeminus6 reltimeminus5 reltimeminus4 reltimeminus3 reltimeminus2 reltimeminus1 reltimeminus0 reltimeplus*, absorb(year treatmentgroup) cluster(subclass)


matrix temp=r(table)'
matrix res=J(40,6,0)
matrix res[19,1]=0
forvalues x = 1/19 {
matrix res[`x',1]=-(19-`x')
matrix res[`x',2]=temp[`x',1]
matrix res[`x',3]=temp[`x',5]
matrix res[`x',4]=temp[`x',6]
}
forvalues x = 1/21 {
matrix res[`x'+19,1]=`x'
matrix res[`x'+19,2]=temp[`x'+19,1]
matrix res[`x'+19,3]=temp[`x'+19,5]
matrix res[`x'+19,4]=temp[`x'+19,6]
}


* Build necessary matrices.There are 39 coefficients of interest (the last, number 41, is just the constant)

mat B = e(b)[1, 1..40]
mat V = e(V)[1..40, 1..40]

local numpost = 21
local numpre = 19

mat lcomb = J(1, `numpost', 0)
	
* Use all coefficients up until the symetric coefficient
	
	forvalues i = 1(1)`numpost'{
		
		mat lcomb[1, `i'] = 1
		
		honestdid, b(B) vcov(V) pre(1/19) post(20/40) l_vec(lcomb) mvec(1) delta(rm)
		
		mata: st_matrix("StataMatrix", `s(HonestEventStudy)'.CI)

		mat res[`numpre' + `i', 5] = StataMatrix[2, 3]
		
		mat res[`numpre' + `i', 6] = StataMatrix[2, 2]
		
		mat lcomb[1, `i'] = 0

	}
	

clear

svmat res

save "C:\Users\de.arboleda\Leopoldo Research Dropbox\David Arboleda\Mini course DID\Applications\Submissions SSC\cc_xd_didtextbook_next\Solutions\Moser and Voena 2012\RR_CIs_Moser_and_Voena_graph.dta", replace

	twoway (scatter res2 res1, xline(0) yline(0) msize(medlarge) msymbol(o) mcolor(navy) legend(off)) ///
	(line res2 res1, lcolor(navy)) (rcap res4 res3 res1, lcolor(maroon)) (rcap res6 res5 res1, lcolor(red) lpattern(dash)), ///
	 title("TWFE Event-study estimates") xtitle("Relative time to year before TWEA") ///
	 ytitle("Effect") xlabel(-18(3)21) yscale(range(-0.25 1)) ylabel(-4(1)4)
 
	 
	 
	 
	 

timer off 1
timer list
