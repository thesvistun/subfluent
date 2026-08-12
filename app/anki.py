'''
Module to work with Anki structures.
'''

import random
import genanki


def create_deck(
    deck_name: str, fields: list, model: genanki.Model, deck_id: int = None):
    '''
    Create Anki deck.
    '''

    if not deck_id:
        deck_id = random.randrange(1 << 30, 1 << 31)

    deck = genanki.Deck(deck_id, deck_name)

    for field in fields:
        note = genanki.Note(model=model, fields=field)
        deck.add_note(note)
    return deck


def get_builtin_models() -> list:
    '''
    Gather builtin Anki models.

    :return: Builtin Anki models
    :rtype: list
    '''

    models = []
    models.append(genanki.builtin_models.BASIC_MODEL)
    models.append(genanki.builtin_models.BASIC_AND_REVERSED_CARD_MODEL)
    models.append(genanki.builtin_models.BASIC_OPTIONAL_REVERSED_CARD_MODEL)
    models.append(genanki.builtin_models.BASIC_TYPE_IN_THE_ANSWER_MODEL)
    models.append(genanki.builtin_models.CLOZE_MODEL)
    return models


def get_builtin_model(models: list, name: str):
    '''
    Get selected builtin Anki model out of provided list of them.

    :param models: Provided list of builtlin Anki models
    :type models: list
    :param name: Name of the builtin Anki model to be returned
    :type name: str
    '''

    for model in models:
        if model.name == name:
            return model
    return None


def get_builtin_models_names(models: list) -> list:
    '''
    Gather builtin Anki models' names.

    :param models: Provided list of builtlin Anki models
    :type models: list
    :return: Builtin Anki models' names
    :rtype: list
    '''

    names = []
    for model in models:
        names.append(model.name)
    return names
