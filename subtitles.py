'''
Module to work with subtitles.
'''

import re
import spacy
import srt

def read_subs(file_content: str) -> list:
    '''
    Subtitles parser

    :param file_content: File of subtitles
    :type file_content: str
    :return: Parsed subtitles
    :rtype: list
    '''

    subs_generator = srt.parse(file_content)
    return list(subs_generator)

def _get_word_rating(word: str, rated_ordered_words: list) -> int:
    try:
        rating = rated_ordered_words.index(word) + 1
    except ValueError:
        rating = -1
    return rating

def _add_to_dict(dictionary: dict, word: str, lemma: str, basic_rated_ordered_words: list):
    word_found = False
    lemma_found = False
    for item in dictionary:
        if item['word'] == word:
            item['word_counter'] += 1
            word_found = True
        if item['lemma'] == lemma:
            item['lemma_counter'] += 1
            lemma_found = True
        if word_found and lemma_found:
            break
    if not word_found:
        lemma_rating = _get_word_rating(lemma, basic_rated_ordered_words)
        dictionary.append({'word': word, 'word_counter': 1, 'lemma': lemma, 'lemma_counter':1,
            'lemma_rating': lemma_rating, 'learned': False})


def collect_subs_dict(subs: list, basic_rated_ordered_words: list):
    '''
    Not in use. Collect words out of the subtitles without NLP
    '''

    subs_dictionary = []
    # collecting words out of the subs
    for sub in subs:
        # spliting text
        split_regex = r'\s*[\(\)\[\],.!?;\s]+\s*'
        for sub_word in re.split(split_regex, sub.content):
            # stripping words
            sub_word = sub_word.strip('\'"=- ').lower()
            # Remove words that contain digits
            if not sub_word or re.match(r'.*\d+.*', sub_word):
                continue
            _add_to_dict(subs_dictionary, sub_word, sub_word, basic_rated_ordered_words)
    return subs_dictionary


def collect_subs_dict_nlp(subs: list, basic_rated_ordered_words: list):
    '''
    Collect words out of the subtitles using NLP
    '''

    subs_dictionary = []
    nlp = spacy.load('en_core_web_sm')
    doc = nlp('\n'.join(sub.content for sub in subs))
    for item in [{'norm': token.norm_, 'lemma': token.lemma_} for token in doc if token.is_alpha]:
        _add_to_dict(subs_dictionary, item['norm'], item['lemma'], basic_rated_ordered_words)
    return subs_dictionary
