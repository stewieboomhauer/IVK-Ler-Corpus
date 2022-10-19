from spacy_conll import init_parser
import stanza
from read_data import read_data
import os

stanza.download('de')
stanza_nlp = stanza.Pipeline('de')


if __name__ == "__main__":

    data = read_data()

    aisha = data[1]

    print(aisha.name, aisha.id)

    for text in aisha.texts.values():
        print(text.topic, text.date)
        for original, target in text.sentences:
            nlp = init_parser("stanza",
                              "de",
                              parser_opts={"use_gpu": True, "verbose": False},
                              include_headers=True)
            # Parse a given string
            doc_orig = nlp(original)
            doc_target = nlp(target)

            # Get the CoNLL representation of the whole document, including headers
            conll_orig = doc_orig._.conll_str
            conll_target = doc_target._.conll_str

            #print(conll_orig, conll_target)
            with open('aisha.conll', 'a', encoding="utf-8") as f:
                f.write(conll_orig + os.linesep)


