## formantTrackingLongSound.praat
## 
## This script performs formant and f0 tracking on a recording that
## has been transcribed within a TextGrid. Acoustic tracks are limited to the
## annotated intervals and values are saved along with up to 2 simultaneous 
## tier annotations and the sound filename into a .csv file, each line being 
## associated with a single time slice, therefore allowing to investigate formant 
## & f0 movements / temporal changes in speech production.
## 
## The csv file is a "long format" text file (1 line for 1 observation, 1 observation 
## being a single time slice) compatible with any analysis tool among 
## which the R statistical programming language. If one wants to investigate 
## acoustic changes through time, one will have to manipulate the csv file
## accordingly in order to process these formant / f0 tracks as single objects 
## associated with investigated segments or sequences (vowels, consonants,
## CV(C) sequences, VV sequences...). Be aware that the output file contains 
## 1 observation per time slice whereas you will probably want to represent your
## data as 1 observation per segment or sequence, which implies that the
## csv data are processed adequately. As a matter of fact, it is not trivial as
## each segment will contain a variable number of observations depending on
## its duration. 
##
## The relevant Sound and TextGrid objects must be selected prior to execution.
##
## Options:
##
## Acoustic analysis parameters:
## 
## 	Formant extraction parameters:
## 		Speaker gender:  m / f / c (determines the maximum formant frequency)
##		These have been replace with more precise parameters:
##		maxNumFormants: Maximum number of formants (default: 5)
##		maxFormantFreq: Maximum formant frequency (default: 5000)
##
## 	Pitch extraction parameters: (TODO)
## 		Minimum valid pitch value (in Hz): (default=75) Change to prevent 
## 			extreme measurements due to specific voice patterns, 
## 			e.g. 65 for creaky / low voices, 100 for breathy / high voices.
##
## 		Voicing threshold: (default=0.45, increase to account for creaky or 
##			breathy voice, e.g. 0.55)
##
## Transcription parameters:
## 	Digit identification of the primary tier
## 	Digit identification of the secondary tier (if any, else use the primary tier number)
## 
## Output parameters:
## 	Results filename
##

debug = 1

## Add an option?
grid$ = selected$("TextGrid")
sound$ = selected$("LongSound")
##sound$ = selected$("Sound")

form Extract formant & f0 tracks from a TextGrid segmented Sound
     comment You must select both a LongSound
     comment and a TextGrid before launching this script.
     comment Request output for:
     boolean Formant_Tracks 1
     boolean Pitch_Track 1
     boolean Nasality_Track_(A1,_A2,_A3) 0
     comment Duration of each processed sub-signal (in seconds,
     comment the higher the more memory is needed).
     natural maxtime 30
     comment Time interval between measurements (in seconds)
     positive timestep 0.01
     comment Formant extraction parameters
##     comment Select speaker (will control maximum formant frequency m = 5000 Hz, f = 5500 Hz, c = 8000 Hz)
##     optionmenu gender: 1
##     		button m
##		button f
##		button c
     comment Maximum number of Formants
     natural maxNumFormants 5
     comment Maximal frequency
     comment (in Hz, base: m = 5000, w = 5500, c = 8000)
     natural maxFreqFormants 5000
     comment Pitch extraction parameters
     comment Pitch parameters (min pitch in Hz, voicing threshold)
     		natural pitchfloor 75
     		real voicingthr 0.45
     comment Miscellaneous options
     comment Number of the TextGrid tier containing the PRIMARY transcription
     natural ptier 1
     comment Number of the TextGrid tier containing the SECONDARY transcription (if none use the same number as for the PRIMARY one)
     natural stier 2
     comment Specify output file name (data will be appended if it exists)
     word resultfile ./tracks.res
endform

echo "Processing..."

stepsize=1

windowlength = 0.025

## Formant analysis parameters	
# Defaults: 5 50 1.5 5 0.000001
#maxNumFormants = 5
preemph_cutoff = 50
formantsdlim = 1.5
maxiter = 5
tolerance = 0.000001
	
## Formant frequency analysis depending on speaker sex (max formant
##   frequency = 5500 Hz for women, = 5000 Hz for men)
##if gender$ == "c"
##	maxFreqFormants = 8000
##elif gender$ = "f"
##	maxFreqFormants = 5500
##else
##	maxFreqFormants = 5000
##endif
	

## Pitch analysis parameters
## pitchfloor=75
pitchtimestep = 0.75/pitchfloor
maxcandidates=15
accurate=1
silencethr=0.03
##voicingthr=0.45
octavecost=0.01
octavejumpcost=0.35
voicingcost=0.14
pitchceiling=600

select LongSound 'sound$'
##select Sound 'sound$'
duration = Get total duration
printline "Total duration: 'duration'"

iterations = 'duration'/'maxtime'
printline "Iterations: 'iterations'"

# Due to what looks like a bug in Praat (which seems to round the
# total duration of the file), we remove a small amount (1ms) of the
# rounded duration in order to not get outside the file.
duration = duration - 0.001

startofsubset = 0
endofsubset = maxtime
onset = startofsubset
step=0

#printline "'startofsubset' : 'endofsubset'"

## Main loop (calls specific procedures)
## While the end has not been reached
while endofsubset < duration+maxtime
	##printline "Currently processing data in the interval 'startofsubset':'endofsubset' seconds"
	appendInfoLine: "Currently processing data in the interval 'startofsubset':'endofsubset' seconds"
	if endofsubset > duration
		endofsubset = duration
	endif	
	move=1
	## While we do not fall over a transcripted segment
 	while 'move' <> 0
		select TextGrid 'grid$'
		ppos = Get interval at time... 'ptier' 'endofsubset'
		# printline "Interval number: 'ppos'"
		select TextGrid 'grid$'
		label$ = Get label of interval... 'ptier' 'ppos'
		#printline "Tier number: 'ptier' / Interval number: 'ppos' / Content: 'label$'"
		## If we are inside an interval we move a little further
		## (label$ <> "" when within an interval)
## We should also add a test for the secondary tier
## Therefore we should extract the stier information here
		if label$ <> ""
		    move=1
		    endofsubset = endofsubset + stepsize
		else
		    move=0
		endif
	endwhile
	step = step + 1
	##printline "newstep: 'step' / 'startofsubset' / 'endofsubset'"

	## Process data
	call formantTracking
	##call testTrack
	## update time positions
	startofsubset = endofsubset
	endofsubset = startofsubset + maxtime
endwhile
nsteps = step

printline "Process terminated."
printline "Total number of steps: 'nsteps'"






procedure formantTracking
	
	## Extraction of the temporary Sound object
	## printline "'startofsubset' 'endofsubset'"
	select LongSound 'sound$'

	## This part is quite different between a Sound and a LongSound
      ## object. For Sounds, when one extracts a part, Praat adds a
      ## _part at the end whereas for a LongSound, it just creates a
      ## Sound object with the name of the LongSound one.

	Extract part... 'startofsubset' 'endofsubset' 1
	Rename... 'sound$'_part
	soundextract$ = "'sound$'_part"

	## This is what we need to do if we simply work with a Sound object
	##select Sound 'sound$'
	##Extract part... 'startofsubset' 'endofsubset' rectangular 1.0 1

	## Extraction of the temporary TextGrid object
	select TextGrid 'grid$'
	Extract part... 'startofsubset' 'endofsubset' 1
	gridextract$ = "'grid$'_part"
	select TextGrid 'gridextract$'
	## Get the number of intervals available within this TextGrid for
	## the relevant Tier number
	numberofintervals = Get number of intervals... 'ptier'
	
	headerline$ = "filename;slabel;label;time_onset;time_offset;frametime;F1;B1;F2;B2;F3;B3;f0'newline$'"
	if 'startofsubset' == 0
		fileappend "'resultfile$'" 'headerline$'
	endif
	

#### Formant extraction process

#### How can one verify the results within Praat? Save it into a file
#### and reload it? Hand-modifications?

	select Sound 'soundextract$'
	To Formant (burg)... 'timestep' 'maxNumFormants' 'maxFreqFormants' 'windowlength' 'preemph_cutoff'
	# Time step; Max number of formants; maximum freq; window length (s); pre-emphasis cutoff; number of std-dev; max number of iterations; tolerance
	#To Formant (robust)... 'timestep' 'maxNumFormants' 'maxFreqFormants' 'windowlength' 'preemph_cutoff' 'formantsdlim' 'maxiter' 'tolerance'
	
	
#### Pitch extraction process
	select Sound 'soundextract$'
	
	## Sound selected, Periodicity, To Pitch : options = Time step, Pitch floor, Pitch ceiling
	#To Pitch... 'pitchtimestep' 'pitchfloor' 'pitchceiling'
	## Periodicity, To Pitch (ac) = autocorrelation : options = Time step, Pitch floor, max number of candidates, very accurate (boolean), silence threshold, voicing threshold, octave cost, octave-jump cost, voiced-unvoiced cost, pitch ceiling
	To Pitch (ac)... 'pitchtimestep' 'pitchfloor' 'maxcandidates' 'accurate' 'silencethr' 'voicingthr' 'octavecost' 'octavejumpcost' 'voicingcost' 'pitchceiling'

	#Down to PitchTier
	#select PitchTier 'soundextract$'


	
#### Processing formant frequencies and bandwidths from Formant object step by step

	for n to numberofintervals
		## Get the position of intervals and their associated labels
		select TextGrid 'gridextract$'
		## Get (string) label of interval number 'n' within tier number 'ptier'
		label$ = Get label of interval... 'ptier' 'n'
		if label$ <> ""
			select TextGrid 'gridextract$'
			## Get onset and offset time values for each transcribed interval + middle position
			time_onset = Get starting point... 'ptier' 'n'
			time_offset = Get end point... 'ptier' 'n'
			time_mid = (time_offset + time_onset)/2
			## printline "'startofsubset'"
		   
## This one is badly conceived... we get the stier
## label at ptier mid-point, whereas we should read
## it at each specific time to be sufficiently general.
			
## Locate the interval mid-point and associate it
## with the label in the secondary tier (numbered
## 'stier') 
##spos = Get interval at time... 'stier' 'time_mid' 
##slabel$ = Get label of interval... 'stier' 'spos'
			
			## Convert these time values to sample index (UNUSED)
			select Sound 'soundextract$'
			#sample_onset = Get sample number from time... 'time_onset'
			#sample_offset = Get sample number from time... 'time_offset'
			#sample_onset = round(sample_onset)
			#sample_offset = round(sample_offset)
			
			## But what we actually need is the corresponding frame number
			## So the time values serve to get onset and offset frame numbers
			## used for going from the initial interval frame to the final interval frame
			## (for each frame)
			select Formant 'soundextract$'
			frameindex_onset = Get frame number from time... 'time_onset'
			frameindex_offset = Get frame number from time... 'time_offset'
			##printline "'time_onset' 'time_offset' 'frameindex_onset' 'frameindex_offset'"
	
			## frame numbers are rounded as they are necessarily integers
			## (index into an array)
			frameindex_onset = round(frameindex_onset)
			frameindex_offset = round(frameindex_offset)
			
			##printline "'frameindex_onset' / 'frameindex_offset' - 'time_onset' / 'time_offset'"

			## Now we loop through each frame within the interval and extract
			## the required acoustic information		
			for j from frameindex_onset to frameindex_offset
			    ## It there's no interval in the file,
			    ## Get frame number from time returns -1.
			    ## Only existing interval data are analysed
			    if j > 0
				      ## printline "Label / Frame onset / offset / number: 'label$' - 'frameindex_onset' / 'frameindex_offset' / 'j'"
					select Formant 'soundextract$'
					## Extraction of frame numbers based on the temporal positions
					##printline "Frame number: 'j'"
					frametime = Get time from frame number... 'j'
					## Rounding time to 1/1000000
					timeofmeasurement = round(frametime*1000000)/1000000
					
					## Locate the measurement time-point and associate it
					## with the label in the secondary tier (numbered
					## 'stier')
					
					select TextGrid 'gridextract$'
			    		spos = Get interval at time... 'stier' 'frametime'
					## printline "'j' / 'frametime' / 'spos'"
			    		slabel$ = Get label of interval... 'stier' 'spos'
					
					
					
					
					select Formant 'soundextract$'
					## Extraction of formant frequencies and bandwidths (as integers)
					f1 = Get value at time... 1 'frametime' Hertz Linear
					b1 = Get bandwidth at time... 1 'frametime' Hertz Linear
					f2 = Get value at time... 2 'frametime' Hertz Linear
					b2 = Get bandwidth at time... 2 'frametime' Hertz Linear
					f3 = Get value at time... 3 'frametime' Hertz Linear
					b3 = Get bandwidth at time... 3 'frametime' Hertz Linear
					#f1m = Get mean... 1 'frameno' 0.05 Hertz
					
					## Extraction of pitch (f0 frequency): requires a Pitch object whose name
					## is contained within the 'soundextract$' variable
					select Pitch 'soundextract$'
					## printline 'soundextract$'
					f0 = Get value at time... 'frametime' Hertz Linear
					
					## Frequency values are rounded for writing into the results file 
					f1 = round(f1)
					f2 = round(f2)
					f3 = round(f3)
					b1 = round(b1)
					b2 = round(b2)
					b3 = round(b3)
					
			  		f0 = round(f0)
					
					## Rounding of time values up to a 10 thousandths of a second
					time_onset = round(time_onset *  10000)/10000
					time_offset = round(time_offset *  10000)/10000
					
					## Adapt this part to select which outputs we want
					
					## Saving the results into the results text file
					## print 'label$';'time_onset';'sample_onset';'time_offset';'sample_offset';'newline$'
					##resultline$ = "'sound$';'slabel$';'label$';'time_onset';'frameindex_onset';'time_offset';'frameindex_offset';'j';'timeofmeasurement';'f1';'b1';'f2';'b2';'f3';'b3';'f0''newline$'"
					resultline$ = "'sound$';'slabel$';'label$';'time_onset';'time_offset';'timeofmeasurement';'f1';'b1';'f2';'b2';'f3';'b3';'f0''newline$'"
					fileappend "'resultfile$'" 'resultline$'
				endif
			endfor
		endif
	endfor
	## We should clear the formant and pitch objects?    
	select Formant 'soundextract$'
	Remove
	select Pitch 'soundextract$'
	Remove
	select Sound 'soundextract$'
	Remove
	select TextGrid 'gridextract$'
	Remove
endproc



