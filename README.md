# election-data

Quick project aggregating a few data sources to predict election voting county-by-county.

Predicting the 2000-2024 elections from population density, education level, income, demographics and religiosity.

Very preliminary results regressing republican vote margin (republican votes - democrat votes) / (total votes) against these predictors in https://github.com/jasontrigg0/election-data/blob/master/election/regressions_2024.csv

Summary of preliminary results:
- 2012 to 2016 stands out as the most dramatic change: education becomes dramatically more important, and county-level outcomes become much more predictable
- density (ie urban / rural) becomes gradually less important from 2000-2024
- religiosity and income remain about constant throughout the 2000-2024 period

NOTE: all of the below is after controlling for education, income, religiosity etc:
- throughout whites are most conservative, african-americans most liberal, hispanics intermediate
- the "other" category is liberal as well, similar to african-americans
- the white-black gap grew 2000 -> 2004 -> 2008 -> 2012 -> 2016 with the biggest jumps in 2012 and 2016
- white-black gap roughly steady 2016-2024
- in 2000,2004 hispanics were more similar to whites, ie in the conservative half
- in 2008 and then 2012 hispanics moved leftward. in 2012 they were equidistant between whites and blacks
- in 2016 hispanics jumped left again, becoming more similar to blacks, ie in the liberal half
- in 2020 and 2024 hispanics drifted back, reaching the middle in 2024
