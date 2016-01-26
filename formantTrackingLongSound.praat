
debug = 1

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

## NOTES IMPORTANTES !!!!

## Régler la durée des fenêtres temporelles utilisées pour
## l'extraction temporaire des données sonores.  Problème de plantage
## du script au bout de quelques cycles. Lié à capacité mémoire mais
## pas seulement (interruption non expliquée au bout de quelques
## cycles). RESOLU ? L'interruption était liée au fait que certains objets 
## n'étaient pas effacés et que ça remplissait la mémoire en excés.

## Ajouter une option
grid$ = selected$("TextGrid")
sound$ = selected$("LongSound")
##sound$ = selected$("Sound")

form Extract formant & f0 tracks from a TextGrid segmented Sound
     comment You must select both a LongSound and a TextGrid before launching this script.
     ## comment You must select both a Sound and a TextGrid before launching this script.
     comment Request output for:
     boolean Formant_Tracks 1
     boolean Pitch_Track 1
     boolean Nasality_Track_(A1,_A2,_A3) 1
     comment Duration of each processed sub-signal (in second, higher needs more memory)
     natural maxtime 30
     comment Formant extraction
     comment Select speaker (will control maximum formant frequency m = 5000 Hz, f = 5500 Hz, c = 8000 Hz)
     optionmenu gender: 1
     		button m
		button f
		button c
     comment Pitch extraction 
     comment Pitch parameters (min pitch in Hz, voicing threshold)
     		natural pitchfloor 75
     		real voicingthr 0.45
     comment Miscellaneous options
     comment Number of the TextGrid tier containing the PRIMARY transcription
     natural tier 2
     comment Number of the TextGrid tier containing the SECONDARY transcription (if none use the same number as for the PRIMARY one)
     natural wtier 1
     comment Specify output file name (data will be appended if it exists)
     word resultfile ./tracks.res
endform

echo "Processing..."

#maxtime=120
stepsize=1

#printline "Formants : 'Formant_Tracks$'"
#if formant_Tracks$ = 1
#   printline "Formants : 'Formant_Tracks$'"
#endif

## General acoustic analysis parameters
timestep = 0.0025
windowlength = 0.025


## Formant analysis parameters	
# Defaults: 5 50 1.5 5 0.000001
maxnformants = 5
preemph_cutoff = 50
formantsdlim = 1.5
maxiter = 5
tolerance = 0.000001
	
## Formant frequency analysis depending on speaker sex (max formant
##   frequency = 5500 Hz for women, = 5000 Hz for men)
if gender$ = "c"
	maxformantfreq = 8000
elif gender$ = "f"
	maxformantfreq = 5500
else
	maxformantfreq = 5000
endif
	

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

startofsubset = 0
endofsubset = maxtime
onset = startofsubset
step=0


## printline "'startofsubset' : 'endofsubset'"

## Main loop (calls specific procedures)
## Tant qu'on n'est pas à la fin du fichier son
while endofsubset < duration+maxtime
	if endofsubset > duration
		endofsubset = duration
	endif	
	move=1
	## Tant que le paramètre booléen 'move' n'est pas fixé à 0
 	while 'move' <> 0
		select TextGrid 'grid$'
		wpos = Get interval at time... 'wtier' 'endofsubset'
		select TextGrid 'grid$'
		label$ = Get label of interval... 'wtier' 'wpos'
		##printline "Numéro Intervalle : 'wpos' / Contenu : 'intlabel'"
		## label <> "" when within an interval
		## Can't compare strings with <> ?? need to test for string equality ???
		if label$ <> ""
		    move=1
		    endofsubset = endofsubset + stepsize
		else
		    move=0
		endif
	endwhile
	printline "Currently processing data in the interval 'startofsubset':'endofsubset' seconds"
	printline "Please wait..."
	step = step + 1

	## Data Processing
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
	## select Sound 'sound$'
	Extract part... 'startofsubset' 'endofsubset' rectangular 1.0 1
	select Sound 'sound$'
	soundextract$ = "'sound$'_part"
	Rename... 'soundextract$'
	## printline 'soundextract$'

	## Extraction of the temporary TextGrid object
	select TextGrid 'grid$'
	Extract part... 'startofsubset' 'endofsubset' 1
	gridextract$ = "'grid$'_part"
	select TextGrid 'gridextract$'
	## We get the number of intervals available within this TextGrid for
	## the relevant Tier number, should be setup at launching time
	numberofintervals = Get number of intervals... 'tier'
	
	headerline$ = "filename;wlabel;label;time_onset;time_offset;frametime;F1;B1;F2;B2;F3;B3;f0'newline$'"
	if 'startofsubset' == 0
		fileappend "'resultfile$'" 'headerline$'
	endif
	

#### Intensity Normalization (85dB, no effect on formant frequency analysis)
###################################

	select Sound 'soundextract$'
    	
	# Intensity computation
	To Intensity... 'pitchfloor' 0
	# Formula expression (original + 85 - original => normalized to maximum amplitude = 85 dB)
	Formula... self+(85-self)
	# Convert the current object (Intensity) to an IntensityTier (time /
	# intensity pairs)... using the Formula???
	Down to IntensityTier
	# Selection of both the IntensityTier and the Sound
	select IntensityTier 'soundextract$'
	plus Sound 'soundextract$'
	# Multiplication of the selected objects (the sound samples by the
	# intensity modificator). Will generate an object with "_int" added to
	# the Sound object name.
	Multiply

	# Cleaning
	select Intensity 'soundextract$'
	Remove
	select IntensityTier 'soundextract$'
	Remove
	#select Sound 'soundextract$'
	#Remove
	select Sound 'soundextract$'_int
	Rename... 'soundextract$'_norm

if debug <> 1
	# In order to perform LPC analysis correctly, we need to resample the
	# sound in order to limit its component frequencies to the maximum
	# formant frequency we want to extract. This is done on the energy
	# normalized sound.
	targetSamplingFreq = 'maxformantfreq'*2
	select Sound 'soundextract$'_norm
	Resample... 'targetSamplingFreq' 50
	select Sound 'soundextract$'_norm
	Remove
	select Sound 'soundextract$'_norm_'targetSamplingFreq'
	Rename... 'soundextract$'_norm
endif

#### Formant extraction process -- Assez rapide... Insérer un test pour savoir si on le veut ?
#### Comment peut-on revisualiser par la suite les résultats dans Praat ? Sauvegarder tracé dans un fichier ? Et le charger ensuite ?

	select Sound 'soundextract$'
	To Formant (burg)... 'timestep' 'maxnformants' 'maxformantfreq' 'windowlength' 'preemph_cutoff'
	# Time step; Max number of formants; maximum freq; window length (s); pre-emphasis cutoff; number of std-dev; max number of iterations; tolerance
	#To Formant (robust)... 'timestep' 'maxnformants' 'maxformantfreq' 'windowlength' 'preemph_cutoff' 'formantsdlim' 'maxiter' 'tolerance'
	
	
#### Pitch extraction process -- Assez lent... Insérer un test pour savoir si on le veut ?
	select Sound 'soundextract$'
	
	## Sound selected, Periodicity, To Pitch : options = Time step, Pitch floor, Pitch ceiling
	#To Pitch... 'pitchtimestep' 'pitchfloor' 'pitchceiling'
	## Periodicity, To Pitch (ac) = autocorrelation : options = Time step, Pitch floor, max number of candidates, very accurate (boolean), silence threshold, voicing threshold, octave cost, octave-jump cost, voiced-unvoiced cost, pitch ceiling
	To Pitch (ac)... 'pitchtimestep' 'pitchfloor' 'maxcandidates' 'accurate' 'silencethr' 'voicingthr' 'octavecost' 'octavejumpcost' 'voicingcost' 'pitchceiling'

	#Down to PitchTier
	#select PitchTier 'soundextract$'

##### Preprocessing for a1, a2, a3 computation (cf. nasality, Marilyn Chen) -- Très rapide...

	# LPC (autocorrelation) = analyse Vocal Tract (source-)filter coefficients
    	#########################
	select Sound 'soundextract$'_norm
	lpcOrder = 11
	To LPC (autocorrelation)... 'lpcOrder' 'windowlength' 'timestep' 'preemph_cutoff'
	Rename... 'soundextract$'

	# Inverse Filtering (taking the Sound and the LPC coefficients as
	# inputs, the Source is reconstructed)
	####################

	select Sound 'soundextract$'_norm
	plus LPC 'soundextract$'
	Filter (inverse)

	Rename... 'soundextract$'_source
	
	
	
#### Processing formant frequencies and bandwidths from Formant object

	for n to numberofintervals
		## Get the position of intervals and their associated labels
		select TextGrid 'gridextract$'
		## Get (string) label of interval number 'n' within tier number 'tier'
		label$ = Get label of interval... 'tier' 'n'
		if label$ <> "" 
			select TextGrid 'gridextract$'
			## Get onset and offset time values for each transcribed interval + middle position
			time_onset = Get starting point... 'tier' 'n'
			time_offset = Get end point... 'tier' 'n'
			time_mid = (time_offset + time_onset)/2
		   
			## Locate the interval mid-point and associate it with the
 			## label in another tier (numbered 'wtier')
			wpos = Get interval at time... 'wtier' 'time_mid'
			wlabel$ = Get label of interval... 'wtier' 'wpos'
			
			## Rounding of time values up to a thousandth of a second
			time_onset = round(time_onset *  1000)/1000
			time_offset = round(time_offset *  1000)/1000
			
			## Convert these time values to sample index
			select Sound 'soundextract$'
			sample_onset = Get sample number from time... 'time_onset'
			sample_offset = Get sample number from time... 'time_offset'
			sample_onset = round(sample_onset)
			sample_offset = round(sample_offset)
			
			## But what we actually need is the corresponding frame number
			## So the time values serve to get onset and offset frame numbers
			## used for going from the initial interval frame to the final interval frame
			## (for each frame)
			select Formant 'soundextract$'
			frame_onset = Get frame number from time... 'time_onset'
			frame_offset = Get frame number from time... 'time_offset'
			## frame numbers are rounded as they are necessarily integers
			## (index into an array)
			frame_onset = round(frame_onset)
			frame_offset = round(frame_offset)
			printline "'frame_onset' / 'frame_offset'"

			## Now we loop through each frame within the interval and extract
			## the required acoustic information		
			for j from frame_onset to frame_offset
				## Formant analysis: requires a Formant object named whose name
				## is contained within the 'soundextract$' variable
				select Formant 'soundextract$'
				## Extraction of frame numbers based on the temporal positions
				frametime = Get time from frame number... 'j'
				## Rounding time to 1/1000000
				timeofmeasurement = round(frametime*1000000)/1000000
				
				## Extraction of formant frequencies and bandwidths (as integers)
				f1 = Get value at time... 1 'frametime' Hertz Linear
				b1 = Get bandwidth at time... 1 'frametime' Hertz Linear
				f2 = Get value at time... 2 'frametime' Hertz Linear
				b2 = Get bandwidth at time... 2 'frametime' Hertz Linear
				f3 = Get value at time... 3 'frametime' Hertz Linear
				b3 = Get bandwidth at time... 3 'frametime' Hertz Linear
				#f1m = Get mean... 1 'frameno' 0.05 Hertz
				#printline 'f1'
				
				## Extraction of pitch (f0 frequency): requires a Pitch object whose name
				## is contained within the 'soundextract$' variable
				select Pitch 'soundextract$'
				## printline 'soundextract$'
				f0 = Get value at time... 'frametime' Hertz Linear
				#fnote$ = string$('fnote$')
				#if f0 > "--undefined--"
				#	f0 = 'f0'
				#	printline 'f0'
				#else
				#	f0 = 0
				#endif
				## printline 'f0'
				#if 'f0' <> 0 (not --undefined--)		

				## Just a trick waiting for an implementation
                        ## of finding --undefined-- f0 values because
                        ## we need to determine how to compute t0 only
                        ## when f0 is reasonable. ISSUE: Some measures
                        ## are -undefined-. How may I determine
                        ## whether a value is undefined BEFORE I
                        ## perform any computation on this measure?
				## if f1 > 10000

				debug = 1
				if debug <> 1
				## So let's try this solution. It seems to work.
				##if f0 <> undefined
					## Fundamental period and spectral analysis window computation
					t0 = 1/'f0'
					# The analysis will cover approximately '7' f0 periods
					nperiods_expected = 3.5
					# The frequency window is determined by the
					# temporal window for the FFT, so the frequency
					# window should be obtained from a temporal
					# parameter.
					frequency_window = 60
					start = 'frametime' - ( 't0' * ('nperiods_expected' / 2))
					end = 'frametime' + ('t0' * ('nperiods_expected' / 2))
					## printline 'start'
					## printline 'end'
					### Formant amplitude computation
					select Sound 'soundextract$'
       					Extract part... 'start' 'end' Hanning 1 yes
       					To Spectrum (fft)
       					To Ltas (1-to-1)
	
					lower_limit_a1 = f1 - frequency_window/2
	       				upper_limit_a1 = f1 + frequency_window/2
					
					a1 = Get maximum... lower_limit_a1 upper_limit_a1 None
					a1hz = Get frequency of maximum... lower_limit_a1 upper_limit_a1 None
					
					lower_limit_a2 = f2 - frequency_window/2
					upper_limit_a2 = f2 + frequency_window/2
					
					a2 = Get maximum... lower_limit_a2 upper_limit_a2 None
					a2hz = Get frequency of maximum... lower_limit_a2 upper_limit_a2 None
					
					lower_limit_a3 = f3 - frequency_window/2
					upper_limit_a3 = f3 + frequency_window/2
					
					a3 = Get maximum... lower_limit_a3 upper_limit_a3 None
					a3hz = Get frequency of maximum... lower_limit_a3 upper_limit_a3 None
	
				endif

				## Frequency values are rounded for writing into the results file 
				printline "'f1' / 'round(f1)'"
				f1 = round(f1)
				f2 = round(f2)
				f3 = round(f3)
				b1 = round(b1)
				b2 = round(b2)
				b3 = round(b3)

			  	f0 = round(f0)

				## Saving the results into the results text file
				## print 'label$';'time_onset';'sample_onset';'time_offset';'sample_offset';'newline$'
				##resultline$ = "'sound$';'wlabel$';'label$';'time_onset';'frame_onset';'time_offset';'frame_offset';'j';'timeofmeasurement';'f1';'b1';'f2';'b2';'f3';'b3';'f0''newline$'"
				resultline$ = "'sound$';'wlabel$';'label$';'time_onset';'time_offset';'timeofmeasurement';'f1';'b1';'f2';'b2';'f3';'b3';'f0''newline$'"
				fileappend "'resultfile$'" 'resultline$'
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
	select Sound 'soundextract$'_norm
	Remove
	select Sound 'soundextract$'_source
	Remove
	select LPC 'soundextract$'
	Remove
endproc



