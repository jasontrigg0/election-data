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
    
    fieldnames = ["fips","year","pct_two_party_rep","rep_margin","totalvotes"]
    writer = csv.DictWriter(sys.stdout, fieldnames=fieldnames)
    writer.writeheader()
    
    with open(args.infile) as f_in:
        results = json.loads(f_in.read())
        for row in results["data"]:
            for unit in row["reporting_units"]:
                if not unit["fips_county"]: continue
                rep_votes = [x["votes"]["total"] for x in unit["candidates"] if x["nyt_id"] == "trump-d"][0]
                dem_votes = [x["votes"]["total"] for x in unit["candidates"] if x["nyt_id"] == "harris-k"][0]
                total_votes = unit["total_votes"]
                if (rep_votes + dem_votes == 0):
                    print(county)
                    raise
                writer.writerow({
                    "fips": unit["fips_state"]+unit["fips_county"],
                    "year": 2024,
                    "pct_two_party_rep": rep_votes / (rep_votes + dem_votes),
                    "rep_margin": (rep_votes - dem_votes) / total_votes,
                    "totalvotes": total_votes
                })
