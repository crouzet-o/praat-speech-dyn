# praat-speech-dyn
Praat Scripts for the extraction of dynamic data in speech signals


## formantTrackingLongSound.praat

### Description

This script will extract formant frequency (4 formants) and bandwidth
trajectories along with the corresponding pitch tracks and temporal positions
from a segmented and transcribed sound. It will save the results along with
various available information into a CSV file for later analysis.

The format of the output file is a "long table": 1 line for each observation,
each observation being a time point within an utterance.

### Usage

This script applies on a combined selection of a LongSound and a corresponding
TextGrid. It is designed to be applied on LongSounds only. It can easily be
applied on short recordings, provided these recordings are opened as
LongSounds.

It guarantees that your computer's memory won't be exhausted by chunking the
corresponding sound into reasonable portions (default: 30s), while verifying
that these chunks don't overlap transcribed segments. It should therefore run
on low resources computers (even though it may take a longer time to accomplish
its task).

## getFormantsFromFiles.praat

### Description

This script will load all files in a directory and will extract formant frequencies in the middle of the file.
 

