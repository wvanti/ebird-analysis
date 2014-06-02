# summary file positions
#  0: Species
#  1: Year
#  2: Month
#  3: Country
#  4: State
#  5: Number of observations

print "\n";

open F, "sp_summaries.txt";

%monthTranslate = 	("01", "January",
					 "02", "February",
					 "03", "March",
					 "04", "April",
					 "05", "May",
					 "06", "June",
					 "07", "July",
					 "08", "August",
					 "09", "September",
					 "10", "October",
					 "11", "November",
					 "12", "December");

while (<F>) {
	chomp;
	@headers = split (/\t/, $_);
	unless ($headers[0] eq "") {
		if ($headers[3] eq "United States") { # let's do US only first
		# should consider including (if $headers[1] > 1989) or similar as well
		# should also consider excluding 2011 since it's only a partial year
		# this is the place to change the year range
		# previous versions - no year restriction, then 1979/2011 (1980 to 2010)
			if ($headers[1] > "1999" && $headers[1] < "2011") {
				$speciesNames{$headers[0]}++;
				$yearsObsTemp{$headers[1]} += $headers[5];
				$yearMonthStateCount{$headers[0]} .= "$headers[1]" . "##" . "$headers[2]" . "##" . "$headers[4]" . "##" . "$headers[5]" . "__";
			}
		}
	}
}

close F;

# LINEAR REGRESSION - COEFFICIENT CALCULATION
# X is the year of observation (i.e. x is time)
# in this revision of the program, X will always represent the years 
# between 1980 and 2010 (n = 30)
# Y is the number of observations
# n is the number of years of observation (in most cases)
# then
# Sum of X, Sum of Y, Sum of (X squared), Sum of (XY)
# then
# Sum of Crossproducts = Sum of (XY) - ((Sum of X * Sum of Y)/n)
# Sum of Squares = Sum of (X squared) - ((Sum of X * Sum of X)/n)
# and then
# Regression Coefficient = Sum of Crossproducts / Sum of Squares
# Reference: Zar, J.H. (1996). Biostatistical Analysis. Upper Saddle River, NJ: Prentice Hall. 

 open TPY, "> total_per_year.txt";
open TPYR, "> total_per_year_reg.txt";
 open TPM, "> total_per_month.txt";
open TPMR, "> total_per_month_reg.txt";
 open TPS, "> total_per_state.txt";
open TPSY, "> total_per_state_year.txt";
open TPSR, "> total_per_state_reg.txt";
open PMPS, "> per_state_per_month.txt";
open PMSR, "> per_state_per_month_reg.txt";
open HIST, "> total_obs_hist.txt";
open TESTT, "> test.txt";

# each of these files groups the data in a certain way, to varying degrees of specificity
# one step above this is the original sp_summaries.txt or sp_US_summaries.txt, which contains
# detailed counts per year per month per state

################################################################
# This block produces data for a histogram of total observations
# filename: total_obs_hist.txt
$ycc = 0;
foreach $yot (sort keys %yearsObsTemp) {
	if ($ycc == 0) { $firstYear = $yot; }
	$ycc ++;
	print HIST "$yot" . "\t" . "$yearsObsTemp{$yot}\n";
	# tab-delimited: year, number of observations (all species)
}
$ycc = 0;
foreach $yot (sort {$b <=> $a} keys %yearsObsTemp) {
	if ($ycc == 0) { $lastYear = $yot; }
	$ycc++;
	last;
}
# print "first year is $firstYear, last year is $lastYear\n";
#
################################################################

foreach $a (sort keys %speciesNames) {
	 %countPerYear = {};
	%countPerMonth = {};
	%countPerState = {};
		
	@ymsc = split (/__/, $yearMonthStateCount{$a});
	foreach $b (@ymsc) {
		($year, $month, $state, $count) = split (/##/, $b);
		  $countPerYear{$year} += $count;
		$countPerMonth{$month} .= "$year" . "##" . "$count" . "__";
		$countPerState{$state} .= "$year" . "##" . "$month" . "##" . "$count" . "__";
	}
	
	################################################################
	# This block populates (1) total_per_year.txt and (2) total_per_year_reg.txt
	# (1) each species with total number of observations per year
	# (2) linear regression coefficient for these values across the years
	$sumYear_X = $sumCount_Y = $sumYearTimesCount = $sumSquares_X = $nY = 0;
	# foreach $y (sort keys %countPerYear) { # for each year
	foreach $y (sort keys %yearsObsTemp) {
		unless ($countPerYear{$y} eq "") {
			print TPY "$a" . "\t" . "$y" . "\t" . "$countPerYear{$y}\n";
			# tab-delimited: species, year, number of observations
		}
			$sumYear_X += $y;
			$sumCount_Y += $countPerYear{$y};
			$sumYearTimesCount += $y * $countPerYear{$y};
			$sumSquares_X += $y * $y;
			$nY++;
		#}
	}
	$sumCrossProducts = $sumYearTimesCount - (($sumYear_X * $sumCount_Y) / $nY);
	      $sumSquares = $sumSquares_X - (($sumYear_X * $sumYear_X)/ $nY);
	unless ($sumSquares == "") {
		$slopeYearlyReg = $sumCrossProducts / $sumSquares;
	}
	print TPYR "$a" . "\t" . "$slopeYearlyReg" . "\t" . "$nY\n";
	# tab-delimited: species, regression coefficient (total, across years), number of years
	#
	################################################################

	################################################################
	# This block populates (1) total_per_month.txt and (2) total_per_month_reg.txt
	# (1) each species with total number of observations in each month of the year (across all years)
	# (2) linear regression coefficient for these values across the years (e.g. every January over many years)
	foreach $m (sort keys %countPerMonth) {  # for each month
		%yearlyMonthCount = {};
		
		unless ($countPerMonth{$m} eq "") {
			@ym = split (/__/, $countPerMonth{$m});
			foreach $mm (@ym) {
				($yearm1, $countm1) = split (/##/, $mm);
				$yearlyMonthCount{$yearm1} += $countm1;
			}
			$sumMonth_X = $sumCount_M = $sumSquares_M = $sumYearTimesCountM = $nM = 0;
			$sumCrossProdsM = $sumSquaresMM = $slopeSpeciesMonth = 0;
			# foreach $yearm (keys %yearlyMonthCount) {
			foreach $yearm (keys %yearsObsTemp) {
				#unless ($yearlyMonthCount{$yearm} eq "") {
					$sumMonth_X += $yearm;
					$sumCount_M += $yearlyMonthCount{$yearm};
					$sumSquares_M += $yearm * $yearm;
					$sumYearTimesCountM += $yearm * $yearlyMonthCount{$yearm};
					$nM++;
				#}
			}
			print TPM "$a" . "\t" . "$m" . "\t" . "$monthTranslate{$m}" . "\t" . "$sumCount_M\n";
			# tab-delimited: species, month number, month text, total number of observations in that month (across all years)
			$sumCrossProdsM = $sumYearTimesCountM - (($sumMonth_X * $sumCount_M) / $nM);
			$sumSquaresMM = $sumSquares_M - (($sumMonth_X * $sumMonth_X) / $nM);
			unless ($sumSquaresMM == "") {
				$slopeSpeciesMonth = $sumCrossProdsM / $sumSquaresMM;
			}
			print TPMR "$a" . "\t" . "$m". "\t" . "$monthTranslate{$m}" . "\t" . "$slopeSpeciesMonth" . "\t" . "$nM\n";
			# tab-delimited: species, month(number), month(text), regression coefficient (total, across months e.g. every January), number of years
		}
	}
	#
	################################################################
	
	################################################################
	# This block populates (1) total_per_state.txt, (2) total_per_state_year.txt, (3) total_per_state_reg.txt
	# (1) each species with total number of observations in each state (across all years)
	# (2) each species with total number of observations in each state (PER year)
	# (3) linear regression coefficient for each state across the years
	foreach $s (sort keys %countPerState) {
		# $s is the state name
		%aggMonthCount = {};
		%perState = {};
				
		unless ($countPerState{$s} eq "") {
			@ys = split (/__/, $countPerState{$s});
			# contains year##month##count
			%monthCount = {}; 
			%perState = {};
			foreach $ymc (@ys) {
				($years1, $months1, $counts1) = split (/##/, $ymc);
				$calendar{$months1}++;
				$perState{$years1} += $counts1;
				$monthCount{$months1} .= "$years1" . "##" . "$counts1" . "__";
			}

			$smM_X = $smM_Y = $smSq_X = $smMXY = $nM1 = $smXPM = $smSQM = $slopePerState = 0;
			# foreach $bys (sort keys %perState) { # bys is years
			foreach $bys (sort keys%yearsObsTemp) {
				unless ($perState{$bys} eq "") {
					print TPSY "$a" . "\t" . "$s" . "\t" . "$bys" . "\t" . "$perState{$bys}\n"; 
					# tab-delimited: species, state, year, number of observations
				}
					$smM_X += $bys;
					$smM_Y += $perState{$bys};
					$smSq_X += $bys * $bys;
					$smMXY += $bys * $perState{$bys};
					$nM1++;
				#}
			}
			#	if ($s eq "California") {
			#		print TESTT "$a in $s smmx $smM_X smmy $smM_Y smsq $smSq_X smmxy $smMXY n $nM1\n"; 
			#	}

			print TPS "$a" . "\t" . "$s" . "\t" . "$smM_Y\n";
			# tab-delimited: species, state, total number of observations
			$smXPM = $smMXY - (($smM_X * $smM_Y) / $nM1);
			$smSQM = $smSq_X - (($smM_X * $smM_X) / $nM1);
			unless ($smXPM == "") {
				$slopePerState = $smXPM / $smSQM;
			}	
			print TPSR "$a" . "\t" . "$s" . "\t" . "$slopePerState" . "\t" . "$nM1\n";	
			# tab-delimited: species, state, regression coefficient (total, each state across the years), number of years
						
			#######
			# this subblock populates (1) per_month_per_state_reg.txt
			# (1) for each state, the linear regression coefficient for a given month across the years
			foreach $mo (sort keys %monthCount) { 
				# $mo is the month number
				unless ($monthCount{$mo} eq "") { 
					@ys2 = split (/__/, $monthCount{$mo});
					%aggMonthCount = {}; 
					foreach $ymc2 (@ys2) {
						($years2, $counts2) = split(/##/, $ymc2);
						$aggMonthCount{$years2} += $counts2; 
					}
					$sumMSC_X = $sumMSC_Y = $sumSqMSC_X = $sumMSC_XY = $nS1 = 0;
					$sumCrossProdsMS = $sumSquaresMS = $slopeMbS = 0;
					# foreach $ymc3 (sort keys %aggMonthCount) {
					foreach $ymc3 (sort keys %yearsObsTemp) {
						#unless ($aggMonthCount{$ymc3} eq "") {
							$sumMSC_X += $ymc3;                 		# sum of years
							$sumMSC_Y += $aggMonthCount{$ymc3}; 		# sum of yearly counts (inside the $mo month)
							$sumSqMSC_X += $ymc3 * $ymc3;       		# sum of squares of X (x = years)
							$sumMSC_XY += $ymc3 * $aggMonthCount{$ymc3};# sum of x * y (years * counts)
							$nS1++;										# n
						#}
					}
					print PMPS "$a" . "\t" . "$s" . "\t". "$mo" . "\t" . "$monthTranslate{$mo}" . "\t" . "$sumMSC_Y\n";
					# tab-delimited: species, state, month number, month txt, number of observations 
					$sumCrossProdsMS = $sumMSC_XY - (($sumMSC_X * $sumMSC_Y) / $nS1); # why is this zero
					$sumSquaresMS = $sumSqMSC_X - (($sumMSC_X * $sumMSC_X) / $nS1);
					unless ($sumSquaresMS == "") {
						$slopeMbS = $sumCrossProdsMS / $sumSquaresMS;
					}
					print PMSR "$a" . "\t" . "$mo" . "\t" . "$monthTranslate{$mo}" . "\t" . "$s" . "\t" . "$slopeMbS" . "\t" . "$nS1\n";
					# tab-delimited: species, month number, month text, state, regression coefficient (per state, on a given month, across the years), number of years
				}
			}
			#
			#######
		}
	}
	#
	################################################################
}

close TPY;
close TPYR;
close TPM;
close TPMR;
close TPS;
close TPSY;
close TPSR;
close PMSR;
close PMPS;
close HIST;
close TESTT;
