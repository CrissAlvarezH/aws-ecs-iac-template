import os
import logging

from .utils import get_pokemon_abilities, get_specie_happiness

logging.basicConfig(format="%(asctime)s: %(levelname)s: %(message)s")
LOG = logging.getLogger("main")
LOG.setLevel(logging.INFO)


def main():
    LOG.info("init main: hello")
    LOG.debug("debug log")
    print("simple print")

    pokemon = os.environ.get("POKEMON_NAME", None)
    if not pokemon:
        raise ValueError("'POKEMON_NAME' env var is null")

    LOG.info(f"pokemon: {pokemon}")

    ditto_abilities = get_pokemon_abilities(pokemon)
    LOG.info("Ditto abilities: "+str(ditto_abilities))

    specie = os.environ.get("POKEMON_SPECIE", None)
    if not specie:
        raise ValueError("'POKEMON_SPECIE' env var is null")
    specie_happiness = get_specie_happiness(specie)

    LOG.info(f"specie: {specie}, has {specie_happiness} of happiness")
