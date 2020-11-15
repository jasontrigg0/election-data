import csv
import argparse
import sys

def readCL():
    parser = argparse.ArgumentParser()
    parser.add_argument("-f","--infile")
    return parser.parse_args()


if __name__ == "__main__":
    args = readCL()
    with open(args.infile) as f_in:
        reader = csv.DictReader(f_in)
        fieldnames = ["fips","year","area"]
        writer = csv.DictWriter(sys.stdout,fieldnames=fieldnames)
        writer.writeheader()
        #pulling land area from LND01.xls
        #https://www.census.gov/library/publications/2011/compendia/usa-counties-2011.html#LND
        for row in reader:
            #Mastdata.xls has column information:
            writer.writerow({
                "fips": row["STCOU"],
                "year": 2000,
                "area": row["LND110200D"] #land area in 2000
            })
            writer.writerow({
                "fips": row["STCOU"],
                "year": 2010,
                "area": row["LND110210D"] #land area in 2010
            })
