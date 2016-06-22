# praat-speech-dyn
Praat Scripts for the analysis and synthesis of dynamic properties in speech
signals.


# formantTrackingLongSound.praat

## Description

This script will extract formant frequencies (4 formants) and bandwidth
trajectories along with the corresponding pitch track and temporal positions
from a segmented and transcribed sound. It will save the results along with
various available information into a CSV file for later analysis.

The format of the output file is a "long table": 1 line for each observation,
each observation being a time point within an utterance.

It is designed to be used on a combination of sound and transcription from
which one may wish to extract temporal phonetic properties occurring at
specific intervals that correspond to the segmented transcripts. 

Further data analysis may then be performed with dedicated tools (like R).

## Usage

This script applies on a combined selection of a LongSound and a corresponding
TextGrid. It is designed to be applied on LongSounds only. It can easily be
applied on "short" recordings, provided these recordings are opened as
LongSounds.

As it can apply on long recordings, it guarantees that your computer's memory
won't be exhausted by chunking the corresponding (long)sound object into
successive reasonable portions (default: 30s), while verifying that these
chunks don't overlap transcribed segments. It should therefore run on low
resources computers (even though it will take a longer time to accomplish its
task).

### Options

- Formant extraction parameters
- Pitch extraction parameters
- Reference tiers
- Output filename (it is saved in the scripts' directory)


### Output


# getFormantsFromFiles.praat

## Description

This script will load all files in a directory and will extract formant frequencies in the middle of the file.
 
## Usage

### Options

### Output

