Computes time-frequency and inter-trial phase consistency analysis using newtimef of EEGLAB. 
The analysis was performed using Morlet wavelet convolution.

ITPC was also computed on a time-shuffled version of the EEG 
data to assess phase alignment relative to chance. For each participant, trial-wise time-series 
was shifted circularly in time by a random offset prior to TF decomposition. This preserved the 
spectral and autocorrelation structures of the data while disrupting the temporal alignment to 
stimulus onset. ITPC was then computed using the same wavelet parameters described above 
and averaged across shuffles to obtain a null estimate. Observed ITPC values were compared 
to these time-shuffled null values to assess if phase consistency exceeds levels expected by 
chance. 
