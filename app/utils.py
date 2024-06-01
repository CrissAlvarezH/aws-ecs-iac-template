import requests

def get_ditto_abilities():
    res = requests.get("https://pokeapi.co/api/v2/pokemon/ditto")

    return [a.get("ability").get("name") for a in res.json().get("abilities", [])]
