import pandas as pd
df = pd.read_json("committee.json")
df.to_csv("committee_info.csv")

#def addcolumns(r):
  #SubcommitteeColumn = r["subcommittees"]
  #r["subcommittee_name"] = SubcommitteeColumn["name"]
  #r["subcommittee_thomas_id"] = SubcommitteeColumn["thomas_id"]
  #r["subcommittee_address"] = SubcommitteeColumn["address"]
  #r["subcommittee_phone"] = SubcommitteeColumn["phone"]
  #return r

def addcolumns(r):
    subcommittee_columns = r["subcommittees"]
    new_rows = []
    if isinstance(subcommittee_columns, list):
        for subcommittee in subcommittee_columns:
            new_r = r.copy()
            new_r["subcommittee_name"] = subcommittee.get("name")
            new_r["subcommittee_thomas_id"] = subcommittee.get("thomas_id")
            new_rows.append(new_r)
    return new_rows if new_rows else [r]

ndf = df.apply(addcolumns,axis=1)

ndf.to_csv("committee_subcommittee_info.csv")