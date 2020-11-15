import csv
import argparse
import sys

def readCL():
    parser = argparse.ArgumentParser()
    parser.add_argument("-f","--infile")
    return parser.parse_args()

def process_row(row):
    #United States link under:
    #Annual County Resident Population Estimates by Age, Sex, Race, and Hispanic Origin: April 1, 2010 to July 1, 2019 (CC-EST2019-ALLDATA)
    #https://www.census.gov/data/tables/time-series/demo/popest/2010s-counties-detail.html
    fips = f'{int(row["STATE"]):02}{int(row["COUNTY"]):03}'
    #population = row[f"POPESTIMATE{yr}"]
    population = int(row["TOT_POP"])
    white_pop = int(row["NHWA_MALE"]) + int(row["NHWA_FEMALE"])
    black_pop = int(row["BA_MALE"]) + int(row["BA_FEMALE"])
    hispanic_pop = int(row["H_MALE"]) + int(row["H_FEMALE"])
    yr = 2007 + int(row["YEAR"])
    return {"fips": fips, "year": yr, "population": row["TOT_POP"], "white_pct": white_pop/population, "hispanic_pct": hispanic_pop/population, "black_pct": black_pop/population}

if __name__ == "__main__":
    args = readCL()
    with open(args.infile) as f_in:
        reader = csv.DictReader(f_in)
        fieldnames = ["fips","year","population","white_pct","hispanic_pct","black_pct"]
        writer = csv.DictWriter(sys.stdout, fieldnames=fieldnames)
        writer.writeheader()
        for row in reader:
            if row["AGEGRP"] != "0": continue #only consider total age for now
            if row["YEAR"] in ["1","2"]: continue #these are the april 1 estimates, 3-12 are the july 1 estimates
            writer.writerow(process_row(row))
