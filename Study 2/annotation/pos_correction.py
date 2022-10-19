import json

from read_data import read_data
from text_processing import pos_tags


def pos_correction(data):
    correction_dict = {}
    for idx, student in data.items():
        correction_dict[student.name] = {}
        for week, text in student.texts.items():
            week = "week" + str(week)
            correction_dict[student.name][week] = {}
            for sent_num, (original, target) in enumerate(text.sentences, start=1):
                sentence = "sentence" + str(sent_num)

                orig_words, orig_pos_tags, _, _ = pos_tags(original)
                target_words, target_pos_tags, _, _ = pos_tags(target)

                correction_dict[student.name][week][sentence] = {
                    "original": [
                        {word: pos} for word, pos in zip(orig_words, orig_pos_tags)
                    ],
                    "target": [
                        {word: pos} for word, pos in zip(target_words, target_pos_tags)
                    ],
                }

    with open("automatic_pos_tags-2.json", "w") as pos_file:
        json.dump(correction_dict, pos_file, indent=4, ensure_ascii=False)


if __name__ == "__main__":
    data = read_data()

    pos_correction(data)
