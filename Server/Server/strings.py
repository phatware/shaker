import json
from api_setup import _config

##
## Setup global resources
##

_strings = {
    "en" : {
        "key" : "string"
    }
}

def str_loc(str_key):
    loc_string = ""
    try:
        loc_string = _strings[_config["language"]][str_key]
    except:
        print("No string for " + str_key + ", language: " + _config["language"])
    return loc_string

try:
    with open('strings.json') as strings_file:
        _strings = json.load(strings_file)
    # print(str_loc("success"))
except Exception:
    print("Can't import strings from strings.json")

