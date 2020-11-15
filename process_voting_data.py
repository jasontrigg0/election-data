import argparse
import csv
import sys

def readCL():
    parser = argparse.ArgumentParser()
    parser.add_argument("-f","--infile")
    return parser.parse_args()


def group_csv(reader, get_row_group, get_row_key, filter_fn = None):
    output = {}
    group_val = None
    for row in reader:
        if filter_fn and not filter_fn(row): continue
        new_group_val = get_row_group(row)
        if new_group_val != group_val:
            if group_val:
                yield (group_val, output)
            group_val = new_group_val
            output = {}
        output[get_row_key(row)] = row
    yield (group_val, output)

if __name__ == "__main__":
    args = readCL()
    with open(args.infile) as f_in:
        reader = csv.DictReader(f_in)
        fieldnames = ["fips","year","pct_two_party_rep","rep_margin","totalvotes"]
        writer = csv.DictWriter(sys.stdout, fieldnames=fieldnames)
        writer.writeheader()
        for key, info in group_csv(reader, lambda x: (f'{int(x["FIPS"]):05}',x["year"]), lambda x: x["party"], lambda x: x["FIPS"] != "NA"):
            fips, year = key
            if fips == "51515" and int(year) >= 2016: continue #51515 was merged into 51519 in 2013
            if fips == "02099": continue #skip Alaska "District 99". Doesn't have vote counts
            #one quirk: dataset shows Kansas City MO split in two, instead of all being
            #reported in Jackson County [fips: 29095] there's also Kansas City [fips: 36000]
            #manually combined this for the 2000-2016 data
            if fips == "36000": continue #manually merged in with 29095 below
            if fips == "29095":
                if year == "2000":
                    pass
                elif year == "2004":
                    info["republican"]["candidatevotes"] = "130500"
                    info["republican"]["totalvotes"] = "315993"
                    info["democrat"]["candidatevotes"] = "183654"
                    info["democrat"]["totalvotes"] = "315993"
                elif year == "2008":
                    info["republican"]["candidatevotes"] = "124687"
                    info["republican"]["totalvotes"] = "339266"
                    info["democrat"]["candidatevotes"] = "210824"
                    info["democrat"]["totalvotes"] = "339266"
                elif year == "2012":
                    info["republican"]["candidatevotes"] = "122708"
                    info["republican"]["totalvotes"] = "311566"
                    info["democrat"]["candidatevotes"] = "183953"
                    info["democrat"]["totalvotes"] = "311566"
                elif year == "2016":
                    info["republican"]["candidatevotes"] = "116211"
                    info["republican"]["totalvotes"] = "301876"
                    info["democrat"]["candidatevotes"] = "168972"
                    info["democrat"]["totalvotes"] = "301876"
                else:
                    raise Exception("Need to figure out Kansas City MO before using post 2016 data -- prior years were handled manually, see code")

            rep_votes = int(info["republican"]["candidatevotes"])
            dem_votes = int(info["democrat"]["candidatevotes"])
            total_votes = int(info["republican"]["totalvotes"])
            writer.writerow({
                "fips": fips,
                "year": year,
                "pct_two_party_rep": rep_votes / (rep_votes + dem_votes),
                "rep_margin": (rep_votes - dem_votes) / total_votes,
                "totalvotes": total_votes
            })
