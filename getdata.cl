# ------------------------------------------------------------------------------------ 
# Get mean FWHM, SKY MEAN and SKY STANDARD DEVIATION value from several stars
# ------------------------------------------------------------------------------------


procedure getdata (image, datamax)

file image {prompt = "Input image name (include extension) or \'*.fit\'"}
real datamax {prompt = "Maximum good data value?"}
#real gain1 {prompt = "Gain?"}
#real rdnoise1 {prompt = "Rdnoise?"}
struct *file_var {mode="h", prompt = "Internal file name variable"}
struct *file_var2 {mode="h", prompt = "Internal file name variable"}
struct *file_var3 {mode="h", prompt = "Internal file name variable"}


begin
      string imname, section, old_imname
      bool check, data_daofind, datapar_search, section_bool, trimming, fitrad_error
      real dmax, fitrad, sigma, gain, rdnoise, sstd, smean, thresh
      real fannulus, fdannulu, sig, smean2, sstd2
      real diff, diff2, diff3, oldfitrad, oldsmean, oldsstd, oldthresh
      real var[500], var6[500], var3[500], var4[500], var5[500]
      real fitradvar[11], smeanvar[11], sstdvar[11]
      real xcen1, ycen1, xcen2, ycen2, fwh2, test, test2, msky, stdev, msky_aver, stdev_aver
      int k, i, m
      struct line, line2

      imname = image
      dmax = datamax  

#      gain = gain1
#      rdnoise = rdnoise1

	    if (! defpac ("daophot")) {
	        print ('')
	        print (' This script must be loaded inside the package noao/digiphot/daophot')
	        bye()
	    }
	    else { # Do nothing
	    }      

      trimming = no
      section_bool = no
      check = no
      print ('\n Search only a SECTION of the frame(s)? (y/n)')
      scan (check)
      if (check) {
          section_bool = yes
          print ('\n Input section where stars will be searched for')
          print (' with the format: [x1:x2,y1:y2]')
          scan (section)
      }
      
      if (imname == '*.fit') {
          delete ('getdatalist',verify=no,>>&"/dev/null")
          files ('*.fit', >> 'getdatalist')
      }
      else {
          delete ('getdatalist',verify=no,>>&"/dev/null")      
          print (imname, >> 'getdatalist')
      }
      
      fitrad_error = no # This bool variable will indicate later on if the FWHM value
                        # was set manually to 3 because no FWHM could be calculated
      file_var3 = ('getdatalist')
      while (fscan (file_var3,line2) != EOF) {   # ************ 'getdata file while' *******************

	      k = strlen(line2)
	      if (substr (line2, k-3, k) == ".fit") {
	      imname = substr (line2, 1, k-4)
	      }
	      else {
	          print ('\n Did you input the name of the frame WITHOUT the')
	          print (' \'fit\' extension? (y/n)')
	          scan (check)
	          if (check) {
	              imname = substr (line2, 1, k)
	          }
	          else {
			          print (' FILENAME ERROR')
			          bye()
	          }
	      }  
	      
	      print ('')
	      print (' Image: '//imname)  

	      hselect.mode = "hl"
	      hselect.images = imname
	      hselect.fields = "GAIN"
	      hselect.expr = yes
	      hselect > "tempget"
		    file_var = 'tempget'
		    while (fscan (file_var,gain) != EOF)
		    del ("tempget")
		    print ('\n GAIN = '//gain)

	      hselect.mode = "hl"
	      hselect.images = imname
	      hselect.fields = "RDNOISE"
	      hselect.expr = yes
	      hselect > "tempget"
		    file_var = 'tempget'
		    while (fscan (file_var,rdnoise) != EOF)
		    del ("tempget")
		    print (' RDNOISE = '//rdnoise)

	      fitrad = 3 # Initial FWHM value
	      smean = 1. # Initial SKY MEAN value
	      sstd = 1.  # Initial SKY STANDARD DEVIATION value

	      oldfitrad = 3.
	      oldsmean = 1.
	      oldsstd = 1.
	      datapar_search = yes
	      
        old_imname = imname
	      if (section_bool) {
	          print (' Trimming...')
	          imcopy.input = imname//section
	          imcopy.output = imname//'_trim.fit'
	          imcopy.verbose = yes
	          imcopy.mode = "hl"
	          imcopy
            imname = imname//'_trim'
            trimming = yes
        }
	      
	      k=1
        sig=1
	      while (datapar_search==yes) {    # ************ 'Datapar search while' *******************
	
	          if ((smean*gain + rdnoise*rdnoise) <= 0. || (smean <= 0.)) {
	             print ('\n ******************************************')
	             print ('\n POSSIBLY A \'LAS CAMPANAS\' OBSERVATORY FRAME')
	             print ('       (if not, check results carefully)')
	             print ('\n ******************************************')
               if (sig==1) {
                   sigma = sqrt(1*gain + rdnoise*rdnoise)/gain
                   sigma = sigma*5 # This structure is meant for 'Las Campanas' observatory frames
                   sig = 2
               }
	          }    
	          else {
			          sigma = sqrt(smean*gain + rdnoise*rdnoise)/gain
			      }    
			      datapars.fwhmpsf = fitrad
			      datapars.sigma = sstd
            datapars.datamin = smean-3*sigma
			      datapars.datamax = dmax

			      i = 5
			      data_daofind=no
			      while (data_daofind==no && i >= 1) {   # ************ 'Daofind while' *******************
			      
	              findpars.threshold = i*3.5*sigma # Use a high threshold so only the brighter stars will be found		
					      print ('                                                       ')
					      print (' ----------------------------------------------------- ')
					      print (' Daofind task :                                        ')
					      print (' We use a high threshold so only the brighter stars will be found')
					      print ('')
					      print (' Threshold value: ' // i*3.5*sigma //' ('//i//'*3.5*sigma)   ')
					      print (' ----------------------------------------------------- ')
					      print ('')

					      print (' Searching...')
					      daofind.verif = no
					      daofind.verb = yes
					      daofind.interactive = no
					      daofind.verbose = no
					      daofind.mode = 'hl'
					      
					      daofind ((imname), (imname//'.coo.psf.1'))
#					      display ((imname), 1)
					      
#	              tvmark.interactive = no
#	              tvmark.outimage = ""
#	              tvmark.mark = 'circle'
#	              tvmark.font = "raster"
#	              tvmark.txsize = 2
#	              tvmark.radii = 10
#	              tvmark.color = 204
#	              tvmark.number = yes
#	              tvmark.label = no
#	              tvmark (1, (imname//'.coo.psf.1'))				      

					      file_var = (imname//'.coo.psf.1')
					      m=0
					      while (fscan (file_var,line) != EOF) {
					          m = m + 1
					      }
					      
					      m = m - 41 # This is the number of stars found by 'Daofind', the first 41 lines are format text.
					      print ('')
					      print (' Number of stars found by \'Daofind\': '//m)

								i = i-1            # If number of stars found is 1 or 0 run 'Daofind' again
					      if (m <= 5) {      # with a lower threshold
	                  if (i <=0) {
	                      print ('\n Not enough stars found using minimum threshold value (<5).')
	                      print (' Halting')
	                      print ('Not enough stars found using minimum threshold value (<5)', >> imname//'_iter')
    					          delete ((imname//'.coo.psf.1'))
	                      bye()
	                  }
					          delete ((imname//'.coo.psf.1'))
					      }
					      else {
					          data_daofind = yes
					      }
			      
			      		if (data_daofind == yes) {
							      print ('                                                       ')
							      print (' ----------------------------------------------------- ')
							      print (' Phot task (calculation of FWHM)                       ')
							      print ('                                                       ')
							      print (' ----------------------------------------------------- ')
							      unlearn centerpars
							      unlearn fitskypars
							      unlearn photpars
							      unlearn psf
							      fitskypars.salgorithm = "mode" # From Massey-Davis guide to stellar CCD photometry
							      centerpars.calgorithm = "none" 
							      
							      # According to 'A Reference Guide to the IRAF-DAOPHOT Package'
							      # by L. Davis (page 31): cbox = 2xFWHM (or 5, wichever is greater)
							      #                        annulus = 4xFWHM
							      #                        dannulu = 2.5-4.0xFWHM
							     
							      # According to IRAF help: a reasonable value for 'cbox' is 2.5-4.0 * FWHM
							      
							      # According to 'A User's Guide to Stellar CCD Photometry with IRAF'
							      # by Massey-Davis (page 47): cbox = 5 (approx 2.0-3.0xFWHM)
							      #                            annulus = 10 (approx 3.0-4.0xFWHM)
							      #                            dannulu = 10 (approx 3.0-4.0xFWHM)
							       
							      centerpars.cbox = 2.5*fitrad
							      fannulus = 4*fitrad
							      fdannulu = 3.25*fitrad      
							      fitskypars.annulus = fannulus
							      fitskypars.annulus = fdannulu		      
							      
							      phot.interactive = no
							      phot.radplots = no
							      phot.update = yes
							      phot.verbose = yes
							      phot.verify = no
							      phot.verbose = no
							      phot.mode = 'hl'
							      photpars.apertures = fitrad
							      phot ((imname), (imname//'.coo.psf.1'), (imname//'.mag.psf.1'))
							      
							      txdump.mode = 'hl' 
							      txdump.textfile = (imname//'.mag.psf.1')
							      txdump.headers = no
							      txdump.fields = 'MSKY,STDEV'
							      txdump.expr = 'MAG[1]!=INDEF'
							      txdump > auxiliar

							      file_var = ('auxiliar')
							      m=0
							      while (fscan (file_var,line) != EOF) {
							          m = m + 1
							      }

							      print ('')
							      print (' Number of stars found (with MAG != INDEF) = '//m)	
					          print ('Number of stars found (with MAG != INDEF) = '//m, >> imname//'_iter')		      	

							      if (m<=5) {
							          if (i <=0) {
			                      print ('\n Not enough stars found using minimum threshold value (<5).')
			                      print (' Halting')
			                      print ('Not enough stars found using minimum threshold value (<5)', >> imname//'_iter')	
			                      delete ((imname//'.coo.psf.1'))
			                      delete ((imname//'.mag.psf.1'))
			                      delete ('auxiliar')
			                      delete ('getdatalist')
			                      bye()
							          }
							          else {
									          print ('\n Not enough stars found with MAG != INDEF (<5)')
									          print (' The threshold value must be too big (check code)')
									          print (' or the image too saturated (or there\'s something')
									          print (' wrong with the frame)')
									          print ('\n Reducing threshold and peforming new \'daofind\'.')
									          data_daofind = no
									          delete ('auxiliar')
									          delete ((imname//'.coo.psf.1'))
									          delete ((imname//'.mag.psf.1'))
							          }
							      }
					      }
			      		  
            } # This bracket closes the 'data_daofind' 'while

	#--------------------------------------------------------------------------------------------
	# Obtaining SKY MEAN value and SKY STANDARD DEVIATION value
	#

			      file_var = "auxiliar"
			      msky_aver = 0
			      stdev_aver = 0
			      m=0
			      while (fscan (file_var,msky,stdev) != EOF) {
			          msky_aver = msky_aver + msky
			          stdev_aver = stdev_aver + stdev
			          m = m + 1
			      }
			      
			      smean = msky_aver/m # Final SMEAN value
			      sstd = stdev_aver/m # Final SSTD value
			      smeanvar[k] = smean
			      sstdvar[k] = sstd
			      
			      print ('')
			      print (' SMEAN = '//smean)
			      print (' STDEV = '//sstd)
			      
			      diff2 = smean -oldsmean
			      diff3 = sstd - oldsstd
			      
			      delete ('auxiliar')
			      
	#--------------------------------------------------------------------------------------------

	#--------------------------------------------------------------------------------------------
	# Obtaining FWHM value
	#		      
	          print ('')
	          print (' Obtaining average FWHM value')
	          print ('')
	          print ('     Maximum number of iterations left: '//(10-k))
	          
			      txdump.mode = 'hl' 
			      txdump.textfile = (imname//'.mag.psf.1')
			      txdump.headers = yes
			      txdump.fields = 'xcenter, ycenter, mag'
			      txdump.expr = 'MAG[1]!=INDEF'    # Cleans the stars with INDEF MAG values
			      txdump > auxiliar
			      
	          txsort.ascend = yes              # Sorts stars in descending MAG order
	          txsort ('auxiliar', 'MAG')

			      txdump.mode = 'hl'           
	          txdump.textfile = ('auxiliar')
	          txdump.headers = no
	          txdump.fields = 'xcenter, ycenter'
	          txdump.expr = 'yes'              # Removes the 'MAG' column
	          txdump > ('auxiliar2')

			      file_var = "auxiliar2"          
			      m=0
			      while (fscan (file_var,line) != EOF) {
			          m = m + 1                    # Counts number of stars in last file
			      }
			      
			      if (m >= 100.) {                 # If number of stars is >= 100 then keep the first 100
			          fields.mode = 'hl' 
			          fields.files = ('auxiliar2')
			          fields.fields = "1-2"
			          fields.lines = "1-100"
			          fields > ('auxiliar3')
			      }
			      else {
	              cp ('auxiliar2', 'auxiliar3')
			      }
			      
						noao
						obsutil
						
						print ('q', >> 'cursor.txt')
	          print ('')
	          print ('     Running \'psfmeasure\' task...')

						psfmeasure(coords="markall", wcs="logical", display=no, frame=1,
						level=0.5, size="FWHM", beta=INDEF, scale=1., radius=15, sbuffer=5,
						swidth=5, saturation=62000, ignore_sat=yes, iterations=5, xcenter=INDEF,
						ycenter=INDEF, logfile="", graphcur="cursor.txt", images=(imname//'.fit'),
						imagecur="auxiliar3", > "outputpsf") # This task performs the calculation of FWHM values for 
	                                               # multiple stars.
			      file_var = "outputpsf"
			      m=0
			      while (fscan (file_var,line) != EOF) {
			          m = m + 1
			      }
			      
			      fields.mode = 'hl' 
			      fields.files = "auxiliar3"
			      fields.fields = "1,2"
			      fields.lines = '2-'
			      fields >> "output3"

			      fields.mode = 'hl' 
			      fields.files = "outputpsf"
			      fields.fields = "1,2,4"
			      fields.lines = '5-'//(m-2)
			      fields >> "output2"
			      
			      file_var = "output3"
			      m=1
			      while (fscan (file_var, xcen1, ycen1) != EOF) {
			          var[m] = xcen1  # XCENTER found by 'phot'
			          var6[m] = ycen1 # YCENTER found by 'phot'
			          m = m + 1
			      }     
			      
			      file_var = "output2"
			      m=1
			      while (fscan (file_var, xcen2, ycen2, fwh2) != EOF) {
			          var3[m] = xcen2 # XCENTER found by 'psfmeasure'
			          var4[m] = ycen2 # YCENTER found by 'psfmeasure'
			          var5[m] = fwh2  # FWHM
			          m = m + 1
			      }  
					  
					  print ('')
					  print ('     Rejecting badly centered stars...')
					  test = 0.
					  test2 = 0.
					  j = 0
			      i = 0  
			      for (i=1; i<=(m-1); i=i+1) {
			          test = (var[i] - var3[i])
			          if ((test >= 3.) || (test <= -3.)) { # Condition to keep star's FWHM value (found by 'psfmeasure'):
			          }                                    # must be centered within 3 pixels of the center found by 'phot'
			          else {
			              test2 = test2 + var5[i]
			              j = j+1
			          }
			      }
			      
			      if (j == 0) {
			          fitrad = 3
			          fitradvar[k] = fitrad
			          print ('\n No FWHM could be calculated douring this iteration')
			          print (' FWHM value set to 3 to avoid floating point error (division by zero)')
			          fitrad_error = yes
			      }
			      else {
					      fitrad = test2/j # Final FWHM value
					      fitradvar[k] = fitrad
					      fitrad_error = no
			      }
			      
			      print ('')
			      print (' FWHM = '//fitrad)

	          diff = fitrad - oldfitrad
	#--------------------------------------------------------------------------------------------

	#--------------------------------------------------------------------------------------------
	# End of iteration condition
	#	
	
						if (smean<0) {
						    smean2=-smean
						}
						else {
						    smean2=smean
						}                       # This structures account for the fact that this values may be negative
						if (sstd<0) {           # and so the 'End of iteration condition' below will fail unless they are
						    sstd2=-ssstd        # transformed into positive
						}
						else {
						    sstd2=sstd
						}
	          if ((diff >= -fitrad/10) && (diff <= fitrad/10) && (diff2 >= -smean2/10) && (diff2 <= smean2/10) && (diff3 >= -sstd2/10) && (diff3 <= sstd2/10) || (k >= 10)) {
	          # End of iteration condition: FWHM, SKY MEAN and STDEV values must ALL have a difference of less than abs(10%) with
	          # the previous calculated value; OR after 10 or more iterations have been executed.
	              datapar_search = no
	              if (k>=10) {           # If the script reached the maximum number of iterations, then average ALL the values
	                  fitrad = 0.        # and present this average as the final value.
	                  smean = 0
	                  sstd = 0
	                  m = 1
	                  while (m <=10) {
					              fitrad = fitradvar[m] + fitrad
					              smean = smeanvar[m] + smean
					              sstd = sstdvar[m] + sstd
					              m = m + 1
			              }
			              fitrad = fitrad/10
			              smean = smean/10
			              sstd = sstd/10
			              print ('')
			              print (' Maximum number of iterations achieved, using average values')
			              print ('Maximum number of iterations achieved, using average values', >> imname//'_iter')
			              print ('') 
			              if (fitrad_error==yes) {
			                  print (' FWHM (manually set to 3 due to error)  = '//fitrad)
					          }    
					          else {
					              print (' FWHM = '//fitrad)
			              }
			              print (' Sky Mean = '//smean)
			              print (' STDDEV = '//sstd)
			              print ('')		              
	              }
	              else {
			              print ('')
			              if (fitrad_error==yes) {
			                  print (' FWHM (manually set to 3 due to error)  = '//fitrad)
					          }    
					          else {
					              print (' FWHM = '//fitrad)
			              }
			              print (' Sky Mean = '//smean)
			              print (' STDDEV = '//sstd)
			              print ('')
	              }
	          }    
	          else { # Do nothing (perform new iteration)
	          }
	#--------------------------------------------------------------------------------------------          
	          
	          delete ('auxiliar')
	          delete ('auxiliar2')
	          delete ('auxiliar3')
	          delete ((imname//'.coo.psf.1'))
	          delete ((imname//'.mag.psf.1'))
	          delete ('cursor.txt')
	          delete ('outputpsf')
	          delete ('output2') 
	          delete ('output3')
	          
            if (fitrad_error==yes) {
                print ('FWHM (manually set to 3 due to error) = '//fitrad, >> imname//'_iter')
			      }    
			      else {
			          print ('FWHM = '//fitrad, >> imname//'_iter')
            }		          
			      print ('STDDEV = '//sstd, >> imname//'_iter')  
			      print ('Sky Mean = '//smean, >> imname//'_iter')          
	          
	          oldfitrad = fitrad
	          oldsmean = smean
	          oldsstd = sstd
	          k = k+1
	          
            fitrad_error=no # This is to reset this error warning

	      } # This bracket closes the 'datapar_search' 'while'
	      
        print (fitrad//'  FWHM', >> old_imname//'_data')
	      print (sstd//'  STDDEV' , >> old_imname//'_data')  
	      print (smean//'  Sky Mean', >> old_imname//'_data')
	      
        if (trimming == yes) {
            delete (imname//'.fit')
        }		      

      } # This bracket closes the 'while' that goes through the 'getdatalist' file
      
      delete ('getdatalist')

      print ('\n SCRIPT FINISHED SUCCESFULLY') 

end

