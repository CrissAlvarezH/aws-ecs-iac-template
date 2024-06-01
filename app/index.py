import logging

from .utils import get_ditto_abilities

logging.basicConfig(format="%(asctime)s: %(levelname)s: %(message)s")
LOG = logging.getLogger("main")
LOG.setLevel(logging.INFO)


def main(event, context):
    LOG.info("init main: hello")
    LOG.debug("debug log")
    print("simple print")

    ditto_abilities = get_ditto_abilities()
    LOG.info("Ditto abilities: "+str(ditto_abilities))
