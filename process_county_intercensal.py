import csv
import argparse
import sys

def readCL():
    parser = argparse.ArgumentParser()
    parser.add_argument("-f","--infile")
    return parser.parse_args()

def info_by_fips(reader):
    output = {}
    fips = None
    for row in reader:
        row_fips = f'{int(row["STATE"]):02}{int(row["COUNTY"]):03}'
        if row_fips != fips:
            if fips:
                yield (fips,output)
            fips = row_fips
            output = {}
        output[(row["SEX"],row["ORIGIN"],row["RACE"])] = row
    yield (fips, output)

if __name__ == "__main__":
    args = readCL()
    with open(args.infile) as f_in:
        reader = csv.DictReader(f_in)
        fieldnames = ["fips","year","population","white_pct","hispanic_pct","black_pct"]
        writer = csv.DictWriter(sys.stdout, fieldnames=fieldnames)
        writer.writeheader()
        for fips, info in info_by_fips(reader):
            for yr in range(2000,2011):
                population = int(info[("0","0","0")][f"POPESTIMATE{yr}"])
                white_pop = int(info[("0","0","1")][f"POPESTIMATE{yr}"])
                black_pop = int(info[("0","0","2")][f"POPESTIMATE{yr}"])
                hispanic_pop = int(info[("0","2","0")][f"POPESTIMATE{yr}"])
                writer.writerow({
                    "fips": fips,
                    "year": yr,
                    "population": population,
                    "white_pct": white_pop / population,
                    "hispanic_pct": hispanic_pop / population,
                    "black_pct": black_pop / population
                })
