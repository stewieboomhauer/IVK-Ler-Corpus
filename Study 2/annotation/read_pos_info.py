from text_processing import text_features
from io import open
import json


f = open('automatic_pos_tags.json', encoding="utf8")

# returns JSON object as
# a dictionary
data = json.load(f)

# creating dicts for deps and lemmas
def all_lemmas_and_deps(data):
    all_orig_deps = []
    all_target_deps = []
    all_orig_lemmas = []
    all_target_lemmas = []

    for student, student_dict in data.items():
        for week, week_dict in student_dict.items():
             for sentence, (original, target) in week_dict.items():
                    orig_words, orig_lemma_tags, _, _,orig_dep_tags = text_features(original)
                    all_orig_lemmas.append(orig_lemma_tags)
                    all_orig_deps.append(orig_dep_tags)

                    target_words, target_lemma_tags, _ , _, target_dep_tags = text_features(target)
                    all_target_lemmas.append(target_lemma_tags)
                    all_target_deps.append(target_dep_tags)

    return all_orig_lemmas, all_orig_deps, all_target_lemmas, all_target_deps

# Word + POS tag extraction
def read_pos_info():

    # Iterating through the json
    for student, student_dict in data.items():
        for week, week_dict in student_dict.items():
             for sentence, sentence_dict in week_dict.items():
                   for original, target in sentence_dict.items():
                       for tup in sentence_dict["original"]:
                        current_word_orig = list(tup.keys())[0]
                        current_pos_orig = list(tup.values())[0]
                        for tup in sentence_dict["target"]:
                            current_word_target = list(tup.keys())[0]
                            current_pos_target = list(tup.values())[0]

    return current_word_orig, current_pos_orig, current_word_target, current_pos_target




