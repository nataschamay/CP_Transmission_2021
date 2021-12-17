# find_controls_part2.pl
# By Natascha May Thevasagayam, NCID, Singapore

# For selecting controls based on specified criteria (part 2)
# Usage: perl find_controls_part2.pl

#############################################################################################################################
# find_controls_out (output of find_controls_part1.pl) will need to be manually processed first, 
# before being used as input here. The manual processing using Microsoft Excel involves:
#	(1) Sort by Recip_SubjectID and Control_PatientID (Note: "Acquisition" and "Recipient"/"Recip" are used interchangeably)
#	(2) Remove duplicate control isolates from the same patient (Excel formula: IF(AND(C2=C1,K2=K1),"Repeated Control Patient ID","OK")
#	(3) Remove control isolates of patients that lack admission data
# resulting in find_controls_out_filtered
#############################################################################################################################

open (CandidateControls, "find_controls_out_filtered"); 
open (linkedpairings, "lookup_linkedpairings");
open (poissonSNP, "dnaDist_poisson_out");

open (OUT3, ">find_controls_out_notLinkedtoDonor_Assigned");
open (OUT4, ">find_controls_out_notLinkedtoDonor_AllValidControls_forReference");

print OUT3 "Recip\tDonor\tControl\tRecip_PatientID\tRecip_SubjectID\tRecip_DOC\tRecip_DOC\tRecip_STcluster\tRecip_Species\tRecip_ST\tRecip_CPgene\t#\tControl_PatientID\tControl_SubjectID\tControl_DOC\tControl_DOC\tControl_STcluster\tControl_Species\tControl_ST\tControl_CPgene\n";

print OUT4 "Recip\tDonor\tControl(s)\n";
####################
# IMPT: Input files are assumed to have headers
####################
$skip_header = <CandidateControls>;
$skip_header = <linkedpairings>;
$skip_header = <poissonSNP>;

while (<CandidateControls>){
	chomp($_);
	$infile = $_;
	$infile =~ s/\n|\r//; #**sometimes chomp is not enough**#
	@infile_split = split(/\t/,$infile);

	# for each pair of acquisition->control, store the whole line
	$HoCandidateControls{$infile_split[1]}{$infile_split[10]} = [ @infile_split ];
	
}

while (<poissonSNP>){
	chomp($_);
	$infile = $_;
	$infile =~ s/\n|\r//; #**sometimes chomp is not enough**#
	@infile_split = split(/,/,$infile);

	# Store whether transmission is plausible between each pair
	$HoPoissonSNP{$infile_split[2]}{$infile_split[3]} = $infile_split[13]; 
}


####################
# Store linked pairings
####################
=head
Acquisition patient	Acquisition isolate	Source patient	Source isolate
Patient_40	CF27	Patient_48	CF25
Patient_14	CF31	Patient_40	CF27
Patient_14	CF31	Patient_59	CF28
=cut

while (<linkedpairings>){ #recip-donor
	chomp($_);
	$infile = $_;
	$infile =~ s/\n|\r//; #**sometimes chomp is not enough**#
	@infile_split = split(/\t/,$infile);

	# Loop thru WHOLE CandidateControls; choose a RANDOM control among all those that are valid for this recip-donor pair
	@validControls = (); #ensure array is cleared
	for $key1 ( keys %HoCandidateControls ) {					# $key1 = recip
		for $key2 ( keys %{ $HoCandidateControls{$key1} } ){ 	# $key2 = control
			
			$plausible = 0;

			if ($key1 eq $infile_split[1]){ #for each recip (i.e. recip matches between the two files)

				# Check if Donor and Control transmission plausible (check both ways as the pairing could be A-B or B-A)
				if ($HoPoissonSNP{$infile_split[3]}{$key2} == 1 || $HoPoissonSNP{$key2}{$infile_split[3]} == 1){
					$plausible = 1;

				}# else AB == 0 OR BA == 0 OR pair not found in the file (i.e. different species/STcluster)
				
				# store all valid controls for this recip-donor
				if($plausible == 0){

					push(@validControls, $key2);

				}
			}
		}
	}
	
	$randomControl = $validControls[int rand (@validControls)];	#store random control from array
	
	print OUT3 "$infile_split[1]\t$infile_split[3]\t$randomControl\t";
	print OUT3 join( "\t", @{$HoCandidateControls{$infile_split[1]}{$randomControl}} );
	print OUT3 "\n";

	print OUT4 "$infile_split[1]\t$infile_split[3]\t";
	print OUT4 join( "\t", @validControls );
	print OUT4 "\n";

}
