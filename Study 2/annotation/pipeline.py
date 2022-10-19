from read_data import read_data
from text_processing import pos_tags


if __name__ == "__main__":
    
    data = read_data()

    aisha = data[1]

    print(aisha.name, aisha.id)

    for text in aisha.texts.values():
        print(text.topic, text.date)
        for original, target in text.sentences:
            print(original)
            print(target)
            print(pos_tags(original))
            print(pos_tags(target))

