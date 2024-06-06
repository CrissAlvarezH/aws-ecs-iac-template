import logging

import requests


LOG = logging.getLogger("main")
LOG.setLevel(logging.INFO)


def get_pokemon_abilities(name: str):
    url = f"https://pokeapi.co/api/v2/pokemon/{name}"
    res = requests.get(url)
    LOG.info(f"'{url}' status_code: {res.status_code}")
    return [a.get("ability").get("name") for a in res.json().get("abilities", [])]


def get_specie_happiness(specie: str):
    url = f"https://pokeapi.co/api/v2/pokemon-species/{specie}"
    res = requests.get(url)
    LOG.info(f"'{url}' status_code: {res.status_code}")
    return res.json().get("base_happiness")
