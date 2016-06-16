## This script will open a group of files inside a directory and will
## extract various acoustic analyses from each of them at a specific
## time point, and then save this information to a text
## file. Obviously, this script should only be used for single segment
## soundfiles (or similar situations).

## Original Praat script by Kevin Ryan 9/05. Base script to open
## multiple files in a directory

## Modifications by Olivier Crouzet (Copyright 2016-2020)
## - 2016/05/27 - Open a directory with a graphical interface
## - 2016/05/27 - Apply formant extraction from the mid-time position in each file
## - 2016/05/27 - Save resulting (fixed 2-digits rounded) data to a CSV file



## TODO
## - Add pitch extraction, formant bandwidths, nasality parameters?, anything else?
## - Control acoustic analysis parameters in the form (male / female / child, ...)


## USAGE:
## FORM: ask for initial substring (optional) and file extension
## (default: .wav)
## Leaving the initial substring blank will get all the files (with
## corresponding extension) inside the directory
##
## A graphical interface easing the selection of the directory is
## launched at start


form Read all files of the given extension inside a directory
   sentence Initial_substring_or_nothing 
   sentence File_extension .wav
   comment Formant analysis parameters
   positive Time_step 0.01
   integer Maximum_number_of_formants 5
   positive Maximum_formant_(Hz) 5500_(=adult female)
   positive Window_length_(s) 0.025
   real Preemphasis_from_(Hz) 50
endform

##source_file$ = chooseReadFile$: "Open a sound file"
source_directory$ = chooseDirectory$: "Select a directory"


## Create a string from all the corresponding files ??? Old syntax?
Create Strings as file list... list 'source_directory$'/'initial_substring_or_nothing$'*'file_extension$'
head_words = selected("Strings")
file_count = Get number of strings


# Choose the output data file
resultsfile$ = chooseWriteFile$: "Save as...", "results.csv"
titleline$ = "Filename,F1,F2,F3,F4,B1,B2,B3,B4'newline$'"
## How to write / wipe?
fileappend "'resultsfile$'" 'titleline$'


## Loop through the list of files, extracting each name and reading it
## into the Objects list
## TODO acoustic analysis

for current_file from 1 to file_count
   select Strings list
   filename$ = Get string... current_file
   Read from file... 'source_directory$'/'filename$'

   ## Select current sound object
   soundname$ = selected$ ("Sound", 1)
   length = Get total duration
   midpoint = length / 2
   quarter25 = 1 * length / 4
   quarter75 = 3 * length / 4
   appendInfoLine: "Filename: ", soundname$, " / Length: ", length, " / Midpoint: ", midpoint
   
   ## OPERATIONS TO EXTRACT FORMANTS MEASURED IN THE MIDDLE OF THE SOUND
   ## ADD pitch, formant bandwidth, nasal parameters?, anything else?

   ## FORMANTS
   To Formant (burg)... time_step maximum_number_of_formants maximum_formant window_length preemphasis_from

   select Formant 'soundname$'
   f1 = Get value at time... 1 midpoint Hertz Linear
   # round with fixed precision; result: string
   f1$ = fixed$ (f1, 2)
   # convert string to number
   f1 = number (f1$)

   f2 = Get value at time... 2 midpoint Hertz Linear
   # round with fixed precision; result: string
   f2$ = fixed$ (f2, 2)
   # convert string to number
   f2 = number (f2$)


   f3 = Get value at time... 3 midpoint Hertz Linear
   # round with fixed precision; result: string
   f3$ = fixed$ (f3, 2)
   # convert string to number
   f3 = number (f3$)


   f4 = Get value at time... 4 midpoint Hertz Linear
   # round with fixed precision; result: string
   f4$ = fixed$ (f4, 2)
   # convert string to number
   f4 = number (f4$)


   # Save result to text file:
   resultsline$ = "'soundname$','f1','f2','f3','f4','newline$'"
   fileappend "'resultsfile$'" 'resultsline$'


   ## SAVE MEASUREMENTS TO A TXT FILE

## Cleanup the temporary object from the objects list
select Sound 'soundname$'
plus Formant 'soundname$'
Remove



endfor


## Finally, remove the temporary file list object (head_words) and report the number of files read

select 'head_words'
Remove
##select Strings list
##Remove
##clearinfo
appendInfoLine: "Done! 'file_count' files read.'newline$'."

