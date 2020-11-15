import csv
import sys
import argparse
import json

def readCL():
    parser = argparse.ArgumentParser()
    parser.add_argument("-f","--infile")
    return parser.parse_args()

if __name__ == "__main__":
    csv.field_size_limit(sys.maxsize) #needed to process nyt's long fields
    args = readCL()
    with open(args.infile) as f_in:
        reader = csv.DictReader(f_in)
        fieldnames = ["fips","year","pct_two_party_rep","rep_margin","totalvotes"]
        writer = csv.DictWriter(sys.stdout, fieldnames=fieldnames)
        writer.writeheader()
        for row in reader:
            for county in json.loads(row['counties']):
                fips = county['fips']
                rep_votes = county['results']['trumpd']
                dem_votes = county['results']['bidenj']
                total_votes = county['votes']
                if fips == '17069': continue #hardin county IL has no data..
                if (rep_votes + dem_votes == 0):
                    print(county)
                    raise
                writer.writerow({
                    "fips": fips,
                    "year": 2020,
                    "pct_two_party_rep": rep_votes / (rep_votes + dem_votes),
                    "rep_margin": (rep_votes - dem_votes) / total_votes,
                    "totalvotes": total_votes
                })
