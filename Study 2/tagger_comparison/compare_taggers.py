import csv
import json
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sn
from copy import deepcopy

from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report
from sklearn.metrics import cohen_kappa_score
from sklearn.metrics import confusion_matrix


def pos_results():
    with open("automatic_pos_tags.json") as unc_f:
        uncorrected = json.load(unc_f)

    with open("automatic_pos_tags - corrected (Jannis & Aleksandra).json") as c_f:
        corrected = json.load(c_f)

    orig_pos_comp = []
    target_pos_comp = []
    orig_file_end = "original-annotated.conll"
    target_file_end = "target-annotated.conll"

    for key, value in corrected.items():
        for week, sentences in value.items():
            current_f = "topo-field-data/topo_annotated/" + key + "-" + week + "-"
            current_f = current_f.replace(" ", "_")

            with open(current_f + orig_file_end) as orig_f:
                orig_pos_sticker = {}
                current_sent = []
                current_sent_num = 1
                reader = csv.reader(orig_f, delimiter="\t")
                for line in reader:
                    if not line:
                        orig_pos_sticker[current_sent_num] = current_sent
                        current_sent = []
                        current_sent_num += 1
                    else:
                        current_sent.append(line[3])
                orig_pos_sticker[current_sent_num] = current_sent

            with open(current_f + target_file_end) as target_f:
                target_pos_sticker = {}
                current_sent = []
                current_sent_num = 1
                reader = csv.reader(target_f, delimiter="\t")
                for line in reader:
                    if not line:
                        target_pos_sticker[current_sent_num] = current_sent
                        current_sent = []
                        current_sent_num += 1
                    else:
                        current_sent.append(line[3])
                target_pos_sticker[current_sent_num] = current_sent

            for sentence, orig_target in sentences.items():
                try:
                    sent_num = int(sentence[-2:])
                except ValueError:
                    sent_num = int(sentence[-1:])
                sticker_orig = orig_pos_sticker[sent_num]

                for dct, dct1, sticker_pos in zip(corrected[key][week][sentence]["original"], uncorrected[key][week][sentence]["original"], sticker_orig):
                    orig_pos_comp.append((list(dct.values())[0], list(dct1.values())[0], sticker_pos))
                    if sticker_pos == "ADP" and list(dct.values())[0] == "PUNCT":
                        print(key, week, sentence)

                sticker_target = target_pos_sticker[sent_num]
                for dct, dct1, sticker_pos in zip(corrected[key][week][sentence]["target"], uncorrected[key][week][sentence]["target"], sticker_target):
                    target_pos_comp.append((list(dct.values())[0], list(dct1.values())[0], sticker_pos))

    return orig_pos_comp, target_pos_comp


def store_pos_results(orig_pos_result_file, target_pos_result_file, orig_pos_comp, target_pos_comp):
    with open(orig_pos_result_file, "w") as rf:
        r_writer = csv.writer(rf, delimiter="\t")
        for tup in orig_pos_comp:
            r_writer.writerow(tup)

    with open(target_pos_result_file, "w") as rf:
        r_writer = csv.writer(rf, delimiter="\t")
        for tup in target_pos_comp:
            r_writer.writerow(tup)


def split_results(pos_comp):
    gold = []
    spcy = []
    stckr = []
    for g, sp, st in pos_comp:

        if isinstance(g, list):
            g = g[0]
        gold.append(g)

        if isinstance(sp, list):
            sp = sp[0]
        spcy.append(sp)

        if isinstance(st, list):
            st = st[0]
        stckr.append(st)

    return gold, spcy, stckr


def encoder_setup(all_values):
    encoder = LabelEncoder()
    encoder.fit(all_values)
    return encoder


def encode(pos_list, encoder):
    return encoder.transform(pos_list)


def get_metrics(gold, pred, labels=None):
    """
    Most important: F1 and Cohen's Kappa
    Also: F1 Values for all POS
    maybe: accuracy
    """
    metrics = classification_report(gold, pred, output_dict=True, target_names=labels, zero_division=1)
    ck = cohen_kappa_score(gold, pred)
    metrics["cohens_kappa"] = ck

    return metrics


def write_confusion_matrix(gold, pred):
    # TODO: Make it possible to see names in confusion matrx. Probably get from encoder.
    return confusion_matrix(gold, pred)


if __name__ == "__main__":

    TAGGER_DIR = "tagger_comparison/"

    orig_pos_comp, target_pos_comp = pos_results()
    # store_pos_results("pos-all-taggers-orig", "pos-all-taggers-target", orig_pos_comp, target_pos_comp)

    orig_gold, orig_spcy, orig_stckr = split_results(orig_pos_comp)
    target_gold, target_spcy, target_stckr = split_results(target_pos_comp)
    all_values = orig_gold + orig_spcy + orig_stckr + target_gold + target_spcy + target_stckr
    encoder = encoder_setup(all_values)

    labels = list(sorted(set(all_values)))

    # Encodings and confusion matrices ORIGINAL texts.
    orig_gold_enc = encode(orig_gold, encoder)
    
    orig_spcy_enc = encode(orig_spcy, encoder)
    gold_spcy_metrics = get_metrics(orig_gold_enc, orig_spcy_enc, labels=labels)

    orig_stckr_enc = encode(orig_stckr, encoder)
    gold_stckr_metrics = get_metrics(orig_gold_enc, orig_stckr_enc, labels=labels)

    with open(TAGGER_DIR + "gold_spacy_original_metrics.json", "w") as gspcy_metr_f, open(TAGGER_DIR + "gold_sticker_original_metrics.json", "w") as gstckr_metr_f:
        json.dump(gold_spcy_metrics, gspcy_metr_f, indent=4, ensure_ascii=False)
        json.dump(gold_stckr_metrics, gstckr_metr_f, indent=4, ensure_ascii=False)
    print(gold_spcy_metrics)

    spcy_cm = write_confusion_matrix(orig_gold_enc, orig_spcy_enc)
    stckr_cm = write_confusion_matrix(orig_gold_enc, orig_stckr_enc)

    df_cm = pd.DataFrame(spcy_cm, index=labels, columns=labels)
    plt.figure(figsize=(10, 7))
    sn.heatmap(df_cm, annot=True, vmax=50, fmt="g")
    plt.show()

    print(gold_stckr_metrics)

    df_cm = pd.DataFrame(stckr_cm, index=labels, columns=labels)
    plt.figure(figsize=(10, 7))
    sn.heatmap(df_cm, annot=True, vmax=50, fmt="g")
    plt.show()

    # Encodings and confusion matrices TARGET texts.

    # Spacy targets do not have X label.
    stckr_labels = deepcopy(labels)
    stckr_labels.remove("SPACE")

    target_gold_enc = encode(target_gold, encoder)
    target_spcy_enc = encode(target_spcy, encoder)
    target_gold_spcy_metrics = get_metrics(target_gold_enc, target_spcy_enc, labels=labels)

    target_stckr_enc = encode(target_stckr, encoder)
    target_gold_stckr_metrics = get_metrics(target_gold_enc, target_stckr_enc, labels=stckr_labels)

    with open(TAGGER_DIR + "gold_spacy_target_metrics.json", "w") as targ_gspcy_metr_f, open(TAGGER_DIR + "gold_sticker_target_metrics.json", "w") as targ_gstckr_metr_f:
        json.dump(target_gold_spcy_metrics, targ_gspcy_metr_f, indent=4, ensure_ascii=False)
        json.dump(target_gold_stckr_metrics, targ_gstckr_metr_f, indent=4, ensure_ascii=False)

    print(target_gold_spcy_metrics)

    target_spcy_cm = write_confusion_matrix(target_gold_enc, target_spcy_enc)
    target_stckr_cm = write_confusion_matrix(target_gold_enc, target_stckr_enc)

    df_cm = pd.DataFrame(target_spcy_cm, index=labels, columns=labels)
    plt.figure(figsize=(10, 7))
    sn.heatmap(df_cm, annot=True, vmax=50, fmt="g")
    plt.show()

    print(target_gold_stckr_metrics)

    df_cm = pd.DataFrame(target_stckr_cm, index=stckr_labels, columns=stckr_labels)
    plt.figure(figsize=(10, 7))
    sn.heatmap(df_cm, annot=True, vmax=50, fmt="g")
    plt.show()