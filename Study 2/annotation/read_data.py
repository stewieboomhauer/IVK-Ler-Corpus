import os
import re

from docx import Document
from typing import List


DATA_DIR = "data"


class Student:
    def __init__(self, name: str, idx: str):
        self.name = name
        self.id = idx
        self.texts = {}  # Dictionary: -> Woche: Text

    def __eq__(self, other):
        if not isinstance(other, Student):
            # don't attempt to compare against unrelated types
            return NotImplemented

        return self.name == other.name and self.id == other.id


class Text:
    def __init__(self, topic: str, date: str, sentences: List[str]):
        self.topic = topic
        self.date = date
        self.sentences = sentences  # List of Tuples: (Original, Target Hypothesis)


def read_single_text(doc_path: str):

    doc = Document(doc_path)

    sentences = []

    count = 0
    for line in doc.paragraphs:
        text = line.text
        if text.startswith("ORIG"):
            _, orig_content = re.split(':\s', text, maxsplit=1)
            count += 1
        if text.startswith("ZIELHYP"):
            _, target_content = re.split(':\s', text, maxsplit=1)
            count += 1

        if count == 2:
            sentences.append((orig_content.strip(), target_content.strip()))
            count = 0

    return sentences


def read_data():
    students = {}

    for week_dir in os.listdir(DATA_DIR):
        week_path = os.path.join("data", week_dir)
        date, _, week, topic, _ = re.split(' \(| |; |\)', week_dir)

        for student_file in os.listdir(week_path):
            student_path = os.path.join(week_path, student_file)

            if os.path.splitext(student_file)[-1] != ".docx":
                continue

            _, _, idx, _, name, _ = re.split('-|\(|\)', student_file)
            idx = int(idx)

            if idx not in students.keys():
                students[idx] = Student(name, idx)

            sentences = read_single_text(student_path)

            students[idx].texts[week] = Text(topic, date, sentences)

    return students
