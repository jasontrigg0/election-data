#download raw data into /raw
#process by county id (called fips) into /fips
#process by election into /election

#land area data from census counties 2011
#https://www.census.gov/library/publications/2011/compendia/usa-counties-2011.html#LND
"raw/county_area.csv" <-
    mkdir -p raw
    wget https://www2.census.gov/library/publications/2011/compendia/usa-counties/excel/LND01.xls -O - | any2csv > $OUTPUT0

"fips/county_area.csv" <- "raw/county_area.csv"
    python3 process_county_area.py -f $INPUT0 > $OUTPUT0


#can't find the same type of data for 2000-2010 and 2010-2019, which is strange
#hope they're compatible, both from census.gov

#county population data 2000-2010
#"County Intercensal" dataset
#https://www.census.gov/data/datasets/time-series/demo/popest/intercensal-2000-2010-counties.html
"raw/county_pop_2000s.csv" <-
    wget https://www2.census.gov/programs-surveys/popest/datasets/2000-2010/intercensal/county/co-est00int-sexracehisp.csv -O - | iconv -f latin1 -t utf-8 > $OUTPUT0

"fips/county_pop_2000s.csv" <- "raw/county_pop_2000s.csv"
    python3 process_county_intercensal.py -f $INPUT0 > $OUTPUT0

#county population data 2010-2019
#"County Population by Characteristics" dataset:
#https://www.census.gov/data/tables/time-series/demo/popest/2010s-counties-detail.html
"raw/county_pop_2010s.csv" <-
    wget https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/asrh/cc-est2019-alldata.csv -O - | iconv -f latin1 -t utf-8 > $OUTPUT0

"fips/county_pop_2010s.csv" <- "raw/county_pop_2010s.csv"
    python3 process_county_characteristics.py -f $INPUT0 > $OUTPUT0



#maybe the best source of general county-level data is the ACS
#they produce -yearly- reports that only have data for large geographies (60k+) and
#5-year reports that have data for every geography, those the 5 year reports don't go far back
#options to pull ACS data:
#  A) "summary files" located at https://www.census.gov/programs-surveys/acs/data/data-via-ftp.html
#     this has all the data but seems annoying to process.
#     could try using this https://github.com/gregbehm/censusACS
#     or following the instructions listed at the bottom of the readmy
#  B) Pull tables from https://data.census.gov/
#     note: click "Customize Table" to choose the county-level data
#  C) ACS API - this is easiest, but only certain data is available
#     https://www.census.gov/data/developers/data-sets/acs-5year.2014.html
#     need to get an api key which is easy and then
#     it's oddly hard to find which variable names you want to query
#     easiest for me was to find the subject I wanted eg S0101,
#     https://www.census.gov/acs/www/data/data-tables-and-tools/subject-tables/
#     pull the corresponding table from (B) above and use the data with overlays file
#     eg ACSST5Y2018.S1901_data_with_overlays_2020-11-14T164124.csv
#     to find the field information
#     After that you can download the field, eg S1501_C02_015E with the below
#     https://api.census.gov/data/'${yr}'/acs/acs5/subject?get=NAME,S1501_C02_015E&for=county:*&in=state:*&key=02a10f5e915cd2eeb46008d651b1017b33f7494b

"%acs" <-
    for yr in 2010 2014 2018;
    do
      wget 'https://api.census.gov/data/'${yr}'/acs/acs5/subject?get=NAME,S1501_C02_015E&for=county:*&in=state:*&key=02a10f5e915cd2eeb46008d651b1017b33f7494b' -O - | pawk -p 'write_line(eval(l.replace("null","\"\"").replace("[[","[").replace("]]","]").rstrip(",")))' > raw/acs/edu_${yr}.csv;
      wget 'https://api.census.gov/data/'${yr}'/acs/acs5/subject?get=NAME,S1901_C01_012E&for=county:*&in=state:*&key=02a10f5e915cd2eeb46008d651b1017b33f7494b' -O - | pawk -p 'write_line(eval(l.replace("null","\"\"").replace("[[","[").replace("]]","]").rstrip(",")))' > raw/acs/inc_${yr}.csv;
      less raw/acs/edu_${yr}.csv | pcsv -c fips,edu_${yr} -p 'r["edu_'${yr}'"] = r["S1501_C02_015E"]; r["fips"] = r["state"] + r["county"]' > fips/edu_${yr}.csv;
      less raw/acs/inc_${yr}.csv | pcsv -c fips,inc_${yr} -p 'r["inc_'${yr}'"] = r["S1901_C01_012E"]; r["fips"] = r["state"] + r["county"]' > fips/inc_${yr}.csv;
    done


#religious census:
#downloaded xls version here: https://www.thearda.com/Archive/ChCounty.asp
#I think this is the dataset behind http://usreligioncensus.org/ but not sure
#NOTE: they have 2000 and 2010 data. The 2010 data seems to predict noticeably
#better than the 2000 data so using that only in the regressions
"raw/religion.csv" <-
    wget 'https://files.osf.io/v1/resources/b6n84/providers/osfstorage/5f2b43d85f705a0306619604?action=download&direct&version=1' -O - | any2csv | pcsv -g 'r["YEAR"] in ["2000","2010"]' > $OUTPUT0

"fips/religion.csv" <- "raw/religion.csv"
    less $INPUT0 | pcsv -p 'if r["ADHERENT"] == "": r["ADHERENT"] = "0"' | pcsv -g 'str_is_int(r["GRPCODE"])' | pagg -g FIPSMERG,YEAR,TOTPOP -c ADHERENT -a sum | pcsv -c fips,YEAR -p 'r["fips"] = f'\''{int(r["FIPSMERG"]):05d}'\''; r["religious_frac"] = float(r["ADHERENT_sum"])/float(r["TOTPOP"])' > $OUTPUT0


#manually pulled voting data from https://electionlab.mit.edu/data
#which points to https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/VOQCHQ
#and put dataverse_files/countypres_2000-2016.csv in the raw directory
"raw/countypres_2000-2016.csv" <-
    wget 'https://dataverse.harvard.edu/api/access/datafile/3641280?format=original&gbrecs=true' -O - > $OUTPUT0

"fips/county_voting.csv" <- "raw/countypres_2000-2016.csv"
    python3 process_voting_data.py -f $INPUT0 > $OUTPUT0

#preliminary 2020 data from NYT (pulled on 2020-11-15, not final)
"raw/nyt_president_2020.json" <-
    wget https://static01.nyt.com/elections-assets/2020/data/api/2020-11-03/national-map-page/national/president.json -O - > $OUTPUT0

"raw/counties_2020.csv" <- "raw/nyt_president_2020.json"
    less $INPUT0 | any2csv --path data,races | pcsv -c counties > $OUTPUT0

"fips/voting_2020.csv" <- "raw/counties_2020.csv"
    python3 process_nyt_2020.py -f $INPUT0 > $OUTPUT0

#process data for each presidential election
"election/election_2020.csv" <-"fips/voting_2020.csv", "fips/county_area.csv", "fips/county_pop_2010s.csv", "fips/edu_2018.csv", "fips/inc_2018.csv"
    pcsv -g 'r["year"] == "2010"' -f fips/county_area.csv > /tmp/area_2010.csv
    pcsv -g 'r["year"] == "2019"' -f fips/county_pop_2010s.csv > /tmp/pop_2019.csv
    pcsv -g 'r["YEAR"] == "2010"' -f fips/religion.csv > /tmp/religion_2010.csv
    less fips/voting_2020.csv | pjoin --left -k fips /tmp/religion_2010.csv | pjoin --left -k fips /tmp/area_2010.csv | pjoin --left -k fips /tmp/pop_2019.csv | pjoin --left -k fips fips/edu_2018.csv | pjoin --left -k fips fips/inc_2018.csv | pcsv -b 'import math' -p 'r["density"] = math.log(float(r["population"]) / float(r["area"])) if (r["population"] and r["area"]) else ""' | pcsv -b 'import math' -p 'r["log_inc"] = math.log(float(r["inc_2018"])) if r["inc_2018"] else ""' > $OUTPUT0

"election/election_2016.csv" <- "fips/county_voting.csv", "fips/county_area.csv", "fips/county_pop_2010s.csv", "fips/edu_2018.csv", "fips/inc_2018.csv"
    pcsv -g 'r["year"] == "2016"' -f fips/county_voting.csv > /tmp/voting_2016.csv
    pcsv -g 'r["year"] == "2010"' -f fips/county_area.csv > /tmp/area_2010.csv
    pcsv -g 'r["year"] == "2016"' -f fips/county_pop_2010s.csv > /tmp/pop_2016.csv
    pcsv -g 'r["YEAR"] == "2010"' -f fips/religion.csv > /tmp/religion_2010.csv
    less /tmp/voting_2016.csv | pjoin --left -k fips /tmp/religion_2010.csv | pjoin --left -k fips /tmp/area_2010.csv | pjoin --left -k fips /tmp/pop_2016.csv | pjoin --left -k fips fips/edu_2018.csv | pjoin --left -k fips fips/inc_2018.csv | pcsv -b 'import math' -p 'r["density"] = math.log(float(r["population"]) / float(r["area"])) if (r["population"] and r["area"]) else ""' | pcsv -b 'import math' -p 'r["log_inc"] = math.log(float(r["inc_2018"])) if r["inc_2018"] else ""' > $OUTPUT0

"election/election_2012.csv" <- "fips/county_voting.csv", "fips/county_area.csv", "fips/county_pop_2010s.csv", "fips/edu_2014.csv", "fips/inc_2014.csv"
    pcsv -g 'r["year"] == "2012"' -f fips/county_voting.csv > /tmp/voting_2012.csv
    pcsv -g 'r["year"] == "2010"' -f fips/county_area.csv > /tmp/area_2010.csv
    pcsv -g 'r["year"] == "2012"' -f fips/county_pop_2010s.csv > /tmp/pop_2012.csv
    pcsv -g 'r["YEAR"] == "2010"' -f fips/religion.csv > /tmp/religion_2010.csv
    less /tmp/voting_2012.csv | pjoin --left -k fips /tmp/religion_2010.csv | pjoin --left -k fips /tmp/area_2010.csv | pjoin --left -k fips /tmp/pop_2012.csv | pjoin --left -k fips fips/edu_2014.csv | pjoin --left -k fips fips/inc_2014.csv | pcsv -b 'import math' -p 'r["density"] = math.log(float(r["population"]) / float(r["area"])) if (r["population"] and r["area"]) else ""' | pcsv -b 'import math' -p 'r["log_inc"] = math.log(float(r["inc_2014"])) if r["inc_2014"] else ""' > $OUTPUT0

"election/election_2008.csv" <- "fips/county_voting.csv", "fips/county_area.csv", "fips/county_pop_2010s.csv", "fips/edu_2010.csv", "fips/inc_2010.csv"
    pcsv -g 'r["year"] == "2008"' -f fips/county_voting.csv > /tmp/voting_2008.csv
    pcsv -g 'r["year"] == "2000"' -f fips/county_area.csv > /tmp/area_2000.csv
    pcsv -g 'r["year"] == "2008"' -f fips/county_pop_2000s.csv > /tmp/pop_2008.csv
    pcsv -g 'r["YEAR"] == "2010"' -f fips/religion.csv > /tmp/religion_2010.csv
    #TODO: investigate 0 area
    less /tmp/voting_2008.csv | pjoin --left -k fips /tmp/religion_2010.csv | pjoin --left -k fips /tmp/area_2000.csv | pjoin --left -k fips /tmp/pop_2008.csv | pjoin --left -k fips fips/edu_2010.csv | pjoin --left -k fips fips/inc_2010.csv | pcsv -b 'import math' -p 'r["density"] = math.log(float(r["population"]) / float(r["area"])) if (r["population"] and r["area"] and float(r["area"]) > 0) else ""' | pcsv -b 'import math' -p 'r["log_inc"] = math.log(float(r["inc_2010"])) if r["inc_2010"] else ""' > $OUTPUT0

"election/election_2004.csv" <- "fips/county_voting.csv", "fips/county_area.csv", "fips/county_pop_2010s.csv", "fips/edu_2010.csv", "fips/inc_2010.csv"
    pcsv -g 'r["year"] == "2004"' -f fips/county_voting.csv > /tmp/voting_2004.csv
    pcsv -g 'r["year"] == "2000"' -f fips/county_area.csv > /tmp/area_2000.csv
    pcsv -g 'r["year"] == "2004"' -f fips/county_pop_2000s.csv > /tmp/pop_2004.csv
    pcsv -g 'r["YEAR"] == "2010"' -f fips/religion.csv > /tmp/religion_2010.csv
    #TODO: investigate counties with 0 area
    less /tmp/voting_2004.csv | pjoin --left -k fips /tmp/religion_2010.csv | pjoin --left -k fips /tmp/area_2000.csv | pjoin --left -k fips /tmp/pop_2004.csv | pjoin --left -k fips fips/edu_2010.csv | pjoin --left -k fips fips/inc_2010.csv | pcsv -b 'import math' -p 'r["density"] = math.log(float(r["population"]) / float(r["area"])) if (r["population"] and r["area"] and float(r["area"]) > 0) else ""' | pcsv -b 'import math' -p 'r["log_inc"] = math.log(float(r["inc_2010"])) if r["inc_2010"] else ""' > $OUTPUT0

"election/election_2000.csv" <- "fips/county_voting.csv", "fips/county_area.csv", "fips/county_pop_2010s.csv", "fips/edu_2010.csv", "fips/inc_2010.csv"
    pcsv -g 'r["year"] == "2000"' -f fips/county_voting.csv > /tmp/voting_2000.csv
    pcsv -g 'r["year"] == "2000"' -f fips/county_area.csv > /tmp/area_2000.csv
    pcsv -g 'r["year"] == "2000"' -f fips/county_pop_2000s.csv > /tmp/pop_2000.csv
    pcsv -g 'r["YEAR"] == "2010"' -f fips/religion.csv > /tmp/religion_2010.csv
    #TODO: investigate counties with 0 area
    less /tmp/voting_2000.csv | pjoin --left -k fips /tmp/religion_2010.csv | pjoin --left -k fips /tmp/area_2000.csv | pjoin --left -k fips /tmp/pop_2000.csv | pjoin --left -k fips fips/edu_2010.csv | pjoin --left -k fips fips/inc_2010.csv | pcsv -b 'import math' -p 'r["density"] = math.log(float(r["population"]) / float(r["area"])) if (r["population"] and r["area"] and float(r["area"]) > 0) else ""' | pcsv -b 'import math' -p 'r["log_inc"] = math.log(float(r["inc_2010"])) if r["inc_2010"] else ""' > $OUTPUT0


"%regress" <-
    less election/election_2000.csv | pcsv -g 'r["fips"] != "46113" and r["fips"][:2] != "02"' | linreg -w totalvotes -t rep_margin -c white_pct,edu_2010,log_inc,density,black_pct,hispanic_pct,religious_frac --alpha 0.001
    less election/election_2004.csv | pcsv -g 'r["fips"] != "46113" and r["fips"][:2] != "02"' | linreg -w totalvotes -t rep_margin -c white_pct,edu_2010,log_inc,density,black_pct,hispanic_pct,religious_frac --alpha 0.001
    less election/election_2008.csv | pcsv -g 'r["fips"] != "46113" and r["fips"][:2] != "02"' | linreg -w totalvotes -t rep_margin -c white_pct,edu_2010,log_inc,density,black_pct,hispanic_pct,religious_frac --alpha 0.001
    less election/election_2012.csv | pcsv -g 'r["fips"] != "46113" and r["fips"][:2] != "02"' | linreg -w totalvotes -t rep_margin -c white_pct,edu_2014,log_inc,density,black_pct,hispanic_pct,religious_frac --alpha 0.001
    less election/election_2016.csv | pcsv -g 'r["fips"] != "46113" and r["fips"][:2] != "02"' | linreg -w totalvotes -t rep_margin -c white_pct,edu_2018,log_inc,density,black_pct,hispanic_pct,religious_frac --alpha 0.001
    less election/election_2020.csv | pcsv -g 'r["fips"] != "46113" and r["fips"][:2] != "02"' | linreg -w totalvotes -t rep_margin -c white_pct,edu_2018,log_inc,density,black_pct,hispanic_pct,religious_frac --alpha 0.001
