# find_pairs.pl
# By Natascha May Thevasagayam, NCID, Singapore

# For determining clonal transmission pairs based on specified criteria
# Usage: perl find_pairs.pl


use List::MoreUtils qw(uniq);

####################
# INPUT FILES
####################
open (INFILE, "lookup_isolates");
open (PAIRWISESNP, "dnaDist_poisson_out");

# INFILE format:
# (Isolates with multiple CPgenes:
#		- Split into two rows and append at the bottom of the find_pairs_lookup input file
#		- Add CPgene suffix to IsolateID; removed before comparison in script)
=head
Patient ID	Isolate ID	Date of culture	Date of culture (decimal)	ST cluster	Species	ST	CP gene
Patient_4	CF1	30/5/2019	2019.410959	cfreundii_CCgroup22_40samples	Citrobacter freundii	107	blaNDM-1
Patient_4	CF2	8/6/2019	2019.435617	cfreundii_CCgroup22_40samples	Citrobacter freundii	107	blaNDM-1
Patient_6	CF3	13/6/2019	2019.449315	cfreundii_CCgroup22_40samples	Citrobacter freundii	22	blaNDM-1
Patient_9	CF39_NDM1	8/10/2019	2019.769863	cfreundii_CCgroup22_40samples	Citrobacter freundii	22	blaNDM-1
Patient_24	CF40_NDM1	20/5/2019	2019.383562	cfreundii_CCgroup22_40samples	Citrobacter freundii	22	blaNDM-1
Patient_9	CF39_OXA48	8/10/2019	2019.769863	cfreundii_CCgroup22_40samples	Citrobacter freundii	22	blaOXA-48
Patient_24	CF40_OXA48	20/5/2019	2019.383562	cfreundii_CCgroup22_40samples	Citrobacter freundii	22	blaOXA-48
=cut

# PAIRWISESNP format:
# This is an output file from dnaDist_Poisson.R (an R script which calculates pairwise SNP difference based on output of Gubbins, 
# and compares it to the BEAST-derived mutation rate threshold, assuming a Poisson distribution for the accumulation of mutations)
	# snps = pairwise SNP count between Isolate1 and Isolate2, based on the recombination-filtered core genome alignment
	# mu = the mutation rate (substitutions/genome/year) for the respective species determined using BEAST
	# time.diff = difference between Isolate1_Date and Isolate2_Date
	# expected.snp = time.diff * mu
	# original.cutoff = TRUE if snps < expected.snp, FALSE otherwise (this is just a gauge, not used to indicate transmission)
	# max.snp = output of R function qpois(0.95, time.diff * mu)
	# transmission.plausible = 1 if snps <= max.snp, 0 if otherwise (used to indicate transmission)
=head
SN,st_cp_grouping,Isolate1,Isolate2,pair.id,snps,mu,Isolate1_Date,Isolate2_Date,time.diff,expected.snp,original.cutoff,max.snp,transmission.plausible
1,postGubbins_cfreundii_CCgroup22_40samples,CF39,CF16,NA,0,2.72,2019.769863,2019.797261,0.027398,0.07452256,TRUE,1,1
2,postGubbins_cfreundii_CCgroup22_40samples,CF39,CF17,NA,0,2.72,2019.769863,2019.816439,0.046576,0.12668672,TRUE,1,1
3,postGubbins_cfreundii_CCgroup22_40samples,CF16,CF17,NA,0,2.72,2019.797261,2019.816439,0.019178,0.05216416,TRUE,1,1
=cut


####################
# OUTPUT FILE
####################
open (OUTPAIRWISESNP, ">find_pairs_lookup_out_pairwiseSNP");
print OUTPAIRWISESNP "STcluster_CPgene\tPatientID|earliestIsolate|earliestdate\tDonor\tHashPair\tSNPcount\tTransmission\n";


$skip_header = <INFILE>;
@for_uniquelist = ();

while (<INFILE>){
	chomp($_);
	$infile = $_;
	$infile =~ s/\n|\r//; #**sometimes chomp is not enough**#
	
	# Store uniqlist of STcluster-CPgene
	@infile_split = split(/\t/,$infile);
	$infile_vars = $infile_split[4].":".$infile_split[7];
	push @for_uniquelist, $infile_vars; 
	@uniquelist = uniq @for_uniquelist; 
	
	#Content of @uniquelist:
	#kpneumo_CCgroup3_460samples:blaKPC-2
	#ecoli_CCgroup1_204samples:blaKPC-2
	#ecoli_CCgroup1_204samples:blaNDM-1

	# Also store whole line; Isolate ID is the unique ID
	$HoA{$infile_split[1]} = [ @infile_split ];
}
close(INFILE);



while (<PAIRWISESNP>){
	chomp($_);
	$pairwisesnp = $_;
	$pairwisesnp =~ s/\n|\r//; #**sometimes chomp is not enough**#

	# Store pairwise SNPs
	@pairwisesnp_split = split(/,/,$pairwisesnp);
	$pairwisesnp_vars = $pairwisesnp_split[2].":".$pairwisesnp_split[3]; # pair
	$pairwisesnp_value = $pairwisesnp_split[5].":".$pairwisesnp_split[13]; # snpcount and transmission(0/1)
	
	$HoPWS{$pairwisesnp_vars} = $pairwisesnp_value;

}
close(PAIRWISESNP);


# Foreach STcluster-CPgene type
foreach my $d (@uniquelist) {
	
	@d_split = split(/:/,$d);

	# Gather all the Patient IDs
	@group_patient = ();
	for $hoa ( keys %HoA ) {
		if($HoA{$hoa}[4] eq $d_split[0] && $HoA{$hoa}[7] eq $d_split[1]){
			push @group_patient, $HoA{$hoa}[0];
		}
	}

	@group_patient = uniq @group_patient;
	
	# Loop thru list of Patient ID for this STcluster-CPgene type
	foreach $i(@group_patient) {
		
		# Search thru the whole hash again, to find earliest date for each Patient ID (maintain same STcluster and CPgene)
		@dates = ();
		for $hoa ( keys %HoA ) {
			if($HoA{$hoa}[4] eq $d_split[0] && $HoA{$hoa}[7] eq $d_split[1] && $HoA{$hoa}[0] eq $i){
				push @dates, $HoA{$hoa}[3];
			}
		}

		@dates_sorted = sort { $a <=> $b } @dates; # numerical sort
		$earliestdate =  $dates_sorted[0];

		# Search thru the whole hash again...
		$earliestIsolate = "";
		@otherIsolate = ();
		for $hoa ( keys %HoA ) {

			# Find Isolate ID for earliest date (maintain same STcluster and CPgene)
			if($HoA{$hoa}[4] eq $d_split[0] && $HoA{$hoa}[7] eq $d_split[1] && $HoA{$hoa}[0] eq $i && $HoA{$hoa}[3] eq $earliestdate){
				
				# Ensure that same Isolate ID is picked as earliestIsolate between runs --> avoid confusion across datasets in the future:
				# if earliestIsolate already define for given Patient ID and incoming earliestIsolate is alphabetically later, don't overwrite
				if($earliestIsolate eq ""){
					$earliestIsolate = $HoA{$hoa}[1];
	
				}else{				
					if($HoA{$hoa}[1] lt $earliestIsolate){
						$earliestIsolate = $HoA{$hoa}[1];
						
					}else{
						# Don't overwrite the earliestIsolate
					}
				}

			}elsif($HoA{$hoa}[4] eq $d_split[0] && $HoA{$hoa}[7] eq $d_split[1] && $HoA{$hoa}[0] eq $i && $HoA{$hoa}[3] ne $earliestdate){
				# SamePatient_SameSTcluster_SameCP_NotEarliestIsolate
			}
			
			# Find *OTHER PATIENT* with *earlier date* than earliestIsolate (maintain same STcluster and CPgene); i.e. potential source
			if($HoA{$hoa}[4] eq $d_split[0] && $HoA{$hoa}[7] eq $d_split[1] && $HoA{$hoa}[0] ne $i && $HoA{$hoa}[3] <= $earliestdate){

					push @otherIsolate, $HoA{$hoa}[0]."|".$HoA{$hoa}[1]."|".$HoA{$hoa}[3]; #Patient|Isolate|Date

			}
		}

		# Combine with PairwiseSNP info
		foreach $j(@otherIsolate) {

			@j_split = split(/\|/,$j); #split Paient|Isolate|Date
			@j_split_CP = split(/_/,$j_split[1]); #split to remove CPgene suffix for some

			@earliestIsolate_split_CP = split(/_/,$earliestIsolate);

			$var_forlookupinHoPWS1 = $earliestIsolate_split_CP[0].":".$j_split_CP[0];
			$var_forlookupinHoPWS2 = $j_split_CP[0].":".$earliestIsolate_split_CP[0];
			
			if(defined($HoPWS{$var_forlookupinHoPWS1})){
			
				$pair = $var_forlookupinHoPWS1; # Note: this pair is not ordered as Acquisition-Donor; order is as appears in dnaDist_poisson_out
				
				@lookupinHoPWS = split(/:/,$HoPWS{$var_forlookupinHoPWS1});
				$snpcount = $lookupinHoPWS[0];
				$transmission = $lookupinHoPWS[1];

			}elsif(defined($HoPWS{$var_forlookupinHoPWS2})){

				$pair = $var_forlookupinHoPWS2; # Note: this pair is not ordered as Acquisition-Donor; order is as appears in dnaDist_poisson_out

				@lookupinHoPWS = split(/:/,$HoPWS{$var_forlookupinHoPWS2});
				$snpcount = $lookupinHoPWS[0];
				$transmission = $lookupinHoPWS[1];


			}else{ # for error checking
				$pair = "NotFound";
				$snpcount = "NotFound";
				$transmission = "NotFound";
			}

			print OUTPAIRWISESNP "$d\t$i|$earliestIsolate|$earliestdate\t$j\t$pair\t$snpcount\t$transmission\n";
		}
	}
}


