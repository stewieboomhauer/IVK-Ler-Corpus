import spacy
import de_core_news_sm
from spacy import displacy

def pos_tags(text_object):

    # python -m spacy download de_core_news_sm
    nlp = de_core_news_sm.load()
    doc = nlp(text_object)

    word = []
    pos_tags = []
    tags = []
    deps = []

    # Token and Tag
    for token in doc:
        word.append(token.text)
        pos_tags.append(token.pos_)
        tags.append(token.tag_)
        deps.append(token.dep_)

    return word, pos_tags, tags, deps
