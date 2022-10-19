# Study 2. 

Since the underlying Natural Language Processing (NLP) models are generally trained on native language data, the validity of the analysis cannot be taken for granted for learner language and can involve substantial conceptual challenges (Meurers & Dickinson 2017). It is thus important to determine: How much does learners’ language affect automated analyses like POS-tag?

## Data

The texts were written by international children with the help of short picture stories.  
The pupils had to describe what they saw in the pictures.  
They were provided with a vocabulary list containing words connected to the story plot.

### Story 1

### Story 2

### Story 3

...

## Annotation

### Part-of-Speech Tagging

The annotation of the corpus followed a computer-assisted error analysis approach similar to the one described in Zinsmeister & Breckle (2010). Hence, it was done in two steps. The first step was an automatic annotation carried out with the help of the SpaCy29 framework and a less known sequence labeling framework called sticker30 (de Kok & Pütz, 2020). Both frameworks were used for parts-of-speech tagging for comparison purposes. Both tagging systems adhere to the universal dependency annotation scheme, which makes it easy to compare them. The annotation layer was added for both the original texts and the target hypotheses. The original sentences posed a particular challenge for the sequence labels because they contain a multitude of orthographic and grammatical errors. Even while many sequence labeling tasks can now be completed automatically and with great accuracy for correct texts, it is unclear if this also holds true for texts that contain errors. For this reason, as a second step, human annotation was performed on top of the automatic labeling. To accelerate the time-consuming manual annotation, this step was framed as a correction of the automatic results. It was necessary for all labeling tasks, because neural sequence labels are not perfect yet. Even for part-of-speech tagging, where most of the modern labeling systems constantly reach F1 scores of over 96%, the additional human correction phase had to be done.


