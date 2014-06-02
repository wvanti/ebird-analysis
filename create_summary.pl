# header array positions
#   6: scientific name
# 113: common name
#  36: year collected
#  37: month collected
#  38: day collected
#  24: country
#  25: state/province
#  32: decimal latitude
#  33: decimal longitude

# open F, "testfile4";
# the following is the original location of the data file in the school server
open F, "cld/ebird/AKN.2011-4-22.txt1";

while (<F>) {
	chomp;
	if ($k++ == 0) { next; }
	@headers = split (/\t/, $_);

	unless ($headers[6] eq "") {
		$commonNames{$headers[6]} = $headers[113];
		unless ($headers[25] eq "") {
			$states{$headers[6]} .= "$headers[25]" . "__";
			unless ($headers[36] eq "" && $headers[37] eq "") {
				$yearMonthByCountryState{$headers[6]} .= "$headers[24]" . "##" . "$headers[25]". "##" . "$headers[36]" . "##" . "$headers[37]" . "__";
				# 24 is country, 25 is state, 36 is year, 37 is month
				# for US states, the country might be blank
				# this 'unless' makes sure there's a year and a month for the observation, but
				# there's the possibility of blank locations.  maybe include those in the exclusion.
			}
		}
	}
}

close F;

open G, "> sp_summaries.txt";

print "\n";

##################################################
# This block counts obs per state by year by month
foreach $a (sort keys %commonNames) {
	%countStateYear = {};
	@tempYearMoByState = split (/__/, $yearMonthByCountryState{$a});
	foreach $b (@tempYearMoByState) {
		# $b will be country##State##Year##Month for each observation
		$countStateYear{$b}++;
		# keeping the country##state##year##month string together is an easier approach
	}
	foreach $c (sort keys %countStateYear) {
		($country, $st, $yr, $mo) = split (/##/, $c);
		unless ($countStateYear{$c} eq "") {
			print G "$a" . "\t" . "$yr" . "\t" . "$mo" . "\t" . "$country" . "\t" . "$st" . "\t" . "$countStateYear{$c}" . "\n";
			# Output file structure (tab delimited):
			# species, year, month, country, state, count
		}
	}
}
#
##################################################

close G;
