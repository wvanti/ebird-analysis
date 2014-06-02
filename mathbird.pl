# Analyze the output files from analyze_summaries.pl

open TEST, "> test.txt";
open SAVE, "> math_output.txt";

$percentWindow = 0.1;
$window = $percentWindow * 100;

#####################################
print SAVE "\n\n";
print SAVE "==================================================\n";
open A, "total_per_year_reg.txt";
while (<A>) {
	# [0] species, [1] reg coeff, [2] n
	chomp;
	@dataTPYR = split (/\t/, $_);
	$regTotal{$dataTPYR[0]} = $dataTPYR[1]; # line 10
	$n = $dataTPYR[2];
}
close A;
print SAVE "Across the entire country, the species with the highest increase in observations over $n years are:\n";
foreach $aa (sort {$regTotal{$b} <=> $regTotal{$a}} keys %regTotal) {
	print SAVE "          $aa with $regTotal{$aa} observations per year\n";
	if ($k1++ > 3) { last; }
}
print SAVE "and the species with the lowest change are:\n";
foreach $aa (sort {$regTotal{$a} <=> $regTotal{$b}} keys %regTotal) {
	print SAVE "          $aa with $regTotal{$aa} observations per year\n"; # line 20
	if ($k2++ > 3) { last; }
}
print SAVE "\n";
print SAVE "=== Species with similar trends (Top 5)\n";
$loopCounter = 0;
# similar slopes
foreach $a3 (sort {$regTotal{$b} <=> $regTotal{$a}} keys %regTotal) {
	# %matches = {};
	if ($loopCounter++ > 4) { last; }
	$present = 0;
	$upperBound = $regTotal{$a3} + ($percentWindow * $regTotal{$a3});
	$lowerBound = $regTotal{$a3} - ($percentWindow * $regTotal{$a3});
	print SAVE "For $a3, the following species are within $window\% of the trend:";
	foreach $a4 (keys %regTotal) {
		if ($a4 eq $a3) { next; }
		if ($regTotal{$a4} > $lowerBound && $regTotal{$a4} < $upperBound) {
			print SAVE "\n          $a4           $regTotal{$a4}";
			$present = 1;
		}
	}
	if ($present == 0) {
		print SAVE "NONE\n"; 
	}
	print SAVE "\n";
}
# negative reciprocal of slope
$loopCounter = 0;
foreach $a3 (sort {$regTotal{$b} <=> $regTotal{$a}} keys %regTotal) {
	# %matches = {};
	if ($loopCounter++ > 4) { last; }
	$present = 0;
	$upperBoundR = (-1) * 1/($regTotal{$a3} + ($percentWindow * $regTotal{$a3}));
	$lowerBoundR = (-1) * 1/($regTotal{$a3} - ($percentWindow * $regTotal{$a3}));
	print SAVE "For $a3, the following species are within $window\% of the negative reciprocal of the trend:";
	foreach $a4 (keys %regTotal) {
		if ($a4 eq $a3) { next; }
		if ($regTotal{$a4} > $lowerBoundR && $regTotal{$a4} < $upperBoundR) {
			print SAVE "\n          $a4           $regTotal{$a4}";
			$present = 1;
		}
	}
	if ($present == 0) {
		print SAVE "NONE\n"; 
	}
	print SAVE "\n";
}

#####################################
print SAVE "\n\n";
print SAVE "==================================================\n";
open B, "total_per_state_reg.txt";
while (<B>) {
	# [0] species, [1] state, [2] reg coeff, [3] n
	chomp;
	@dataTPSR = split (/\t/, $_); # line 30
	$regState{$dataTPSR[1]} .= $dataTPSR[0] . "##" . $dataTPSR[2] . "__";	
	# NB: the key is the state name
}	
close B;

foreach $bb (sort keys %regState) {
	%rcState = {};
	$k3 = $k4 = 0;
	# $bb is state
	@stateTemp = split (/__/, $regState{$bb});
	foreach $bbb (@stateTemp) {
		($speciesS, $rcS) = split (/##/, $bbb); # line 40
		$rcState{$speciesS} = $rcS;
	}
	print SAVE "==== In $bb, the species with the highest increase in observations are:\n";
	for $bbbb (sort {$rcState{$b} <=> $rcState{$a}} keys %rcState) { 	
		print SAVE "               $bbbb with $rcState{$bbbb} observations per year\n";
		if ($k3++ > 3) { last; }
	}
	print SAVE "and the species with the lowest change are:\n";
	for $bbbb (sort {$rcState{$a} <=> $rcState{$b}} keys %rcState) {
		print SAVE "               $bbbb with $rcState{$bbbb} observations per year\n";
		if ($k4++ > 3) { last; } 
	}
	print SAVE "\n";
	print SAVE "=== Species with similar trends\n";
	# similar slopes
	$loopCounter = 0;
	foreach $a3 (sort {$rcState{$b} <=> $rcState{$a}} keys %rcState) {
		if ($loopCounter++ > 4) { last; }
		$present = 0;
		$upperBound = $rcState{$a3} + ($percentWindow * $rcState{$a3});
		$lowerBound = $rcState{$a3} - ($percentWindow * $rcState{$a3});
		print SAVE "For $a3, the following species are within $window\% of the trend:  ";
		foreach $a4 (keys %rcState) {
			if ($a4 eq $a3) { next; }
			if ($rcState{$a4} > $lowerBound && $rcState{$a4} < $upperBound) {
				print SAVE "\n          $a4           $rcState{$a4}";
				$present = 1;
			}
		}
		if ($present == 0) { print SAVE "NONE\n"; }
		print SAVE "\n";
	}
	# negative reciprocal of slope
	$loopCounter = 0;
	foreach $a3 (sort {$rcState{$b} <=> $rcState{$a}} keys %rcState) {
		if ($loopCounter++ > 4) { last; }
		$present = 0;
		$upperBoundR = (-1) * 1/($rcState{$a3} + ($percentWindow * $rcState{$a3}));
		$lowerBoundR = (-1) * 1/($rcState{$a3} - ($percentWindow * $rcState{$a3}));
		print SAVE "For $a3, the following species are within $window\% of the negative reciprocal of the trend:  ";
		foreach $a4 (keys %rcState) {
			if ($a4 eq $a3) { next; }
			if ($rcState{$a4} > $lowerBoundR && $rcState{$a4} < $upperBoundR) {
				print SAVE "\n          $a4           $rcState{$a4}";
				$present = 1;
			}
		}
		if ($present == 0) { print SAVE "NONE\n"; }
		print SAVE "\n";
	}
}
####################################
print SAVE "\n\n";
print SAVE "==================================================\n";
open C, "total_per_month_reg.txt";
while (<C>){
	# [0] species, [1] month num, [2] month text, [3] reg coeff, [4] n
	chomp;
	@dataTPMR = split (/\t/, $_); 
	$regMonth{$dataTPMR[1]} .= $dataTPMR[0] . "##" . $dataTPMR[3] . "__";	
	$monthTranslate{$dataTPMR[1]} = $dataTPMR[2];
	# key is month num
}
close C;
foreach $c (sort keys %regMonth) {
	%rcMonth = {};
	$k6 = $k5 = 0;
	# $c is month
	@monthTemp = split (/__/, $regMonth{$c});
	foreach $cc (@monthTemp) {
		($speciesM, $rcM) = split (/##/, $cc); 
		$rcMonth{$speciesM} = $rcM;
	}
	print SAVE "___________________________________________\n";
	print SAVE "In $monthTranslate{$c}, the species with the highest increase in observations (nationwide)  are:\n";
	for $ccc (sort {$rcMonth{$b} <=> $rcMonth{$a}} keys %rcMonth) { 	
		unless ($rcMonth{$ccc} eq "") {
			print SAVE "               $ccc with $rcMonth{$ccc} observations per year\n";
			if ($k5++ > 1) { last; }
		}
	}
	print SAVE "and the species with the lowest change are:\n";
	for $ccc (sort {$rcMonth{$a} <=> $rcMonth{$b}} keys %rcMonth) {
		unless ($rcMonth{$ccc} eq "") {
			print SAVE "               $ccc with $rcMonth{$ccc} observations per year\n";
			if ($k6++ > 1) { last; } 
		}
	}
	print SAVE "\n";
	print SAVE "=== Species with similar trends\n";
	$loopCounter = 0;
	# similar slopes
	foreach $a3 (sort {$rcMonth{$b} <=> $rcMonth{$a}} keys %rcMonth) {
		if ($loopCounter++ > 4) { last; }
		$present = 0;
		$upperBound = $rcMonth{$a3} + ($percentWindow * $rcMonth{$a3});
		$lowerBound = $rcMonth{$a3} - ($percentWindow * $rcMonth{$a3});
		print SAVE "For $a3, the following species are within $window\% of the trend:  ";
		foreach $a4 (keys %rcMonth) {
			if ($a4 eq $a3) { next; }
			if ($rcMonth{$a4} > $lowerBound && $rcMonth{$a4} < $upperBound) {
				print SAVE "\n          $a4";
				$present = 1;
			}
		}
		if ($present == 0) { print SAVE "NONE\n"; }
		print SAVE "\n";
	}
	# negative reciprocal of slopes	
	$loopCounter = 0;
	foreach $a3 (sort {$rcMonth{$b} <=> $rcMonth{$a}} keys %rcMonth) {
		if ($loopCounter++ > 4) { last; }
		$present = 0;
		$upperBoundR = (-1) * 1/($rcMonth{$a3} + ($percentWindow * $rcMonth{$a3}));
		$lowerBoundR = (-1) * 1/($rcMonth{$a3} - ($percentWindow * $rcMonth{$a3}));
		print SAVE "For $a3, the following species are within $window\% of the negative reciprocal of the trend:  ";
		foreach $a4 (keys %rcMonth) {
			if ($a4 eq $a3) { next; }
			if ($rcMonth{$a4} > $lowerBoundR && $rcMonth{$a4} < $upperBoundR) {
				print SAVE "\n          $a4";
				$present = 1;
			}
		}
		if ($present == 0) { print SAVE "NONE\n"; }
		print SAVE "\n";
	}	
}

###################################
print SAVE "\n\n";
open F, "total_per_state.txt";
while (<F>) {
	# [0] species, [1] state, [2] count
	chomp;
	@dataTPS = split (/\t/, $_);
	$countState{$dataTPS[1]} .= "$dataTPS[0]" . "##" . "$dataTPS[2]" . "__";	
}
close F;
foreach $f (sort keys %countState) {
	# $f is state
	%totalST = {};
	$k7 = $k8 = 0;
	@stYearTemp = split (/__/, $countState{$f});
	foreach $ff (sort @stYearTemp) {
		($speciesCS, $countCS) = split (/##/, $ff);
		$totalST{$speciesCS} += $countCS;
	}
	print SAVE "In $f, the three most common birds observed (across $n years) are:\n";
	for $f3 (sort {$totalST{$b} <=> $totalST{$a}} keys %totalST) {
		print SAVE "                     $f3 with count $totalST{$f3}\n";
		if ($k7++ > 1) { last; } 
	}
	print SAVE "     and three of the least common (but still seen) birds are:\n";
	for $f3 (sort {$totalST{$a} <=> $totalST{$b}} keys %totalST) {
		unless ($totalST{$f3} eq "") {
			print SAVE "                     $f3 with count $totalST{$f3}\n";
			if ($k8++ > 1) { last; }
		}
	}
}

close SAVE;

