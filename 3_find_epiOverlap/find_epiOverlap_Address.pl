# find_epiOverlap_Address.pl
# By Natascha May Thevasagayam, NCID, Singapore

# For determining address contact
# Usage: perl find_epiOverlap_Address.pl

use List::MoreUtils qw(uniq);

open (ADDRESS, "list_address"); 		#NOTE:removed duplicates and n.a
open (PATIENTID, "list_patientID");		# Patient IDs
open (LINKEDPAIRS, "list_linkedPairs");	# Transmission pairs

open (OUTFULL, ">EpiOverlap_Address_full");
open (OUTSTATUS, ">EpiOverlap_Address_status");

####################
# Input files are assumed to have headers
####################
$skip_header = <ADDRESS>;
$skip_header = <PATIENTID>;
$skip_header = <LINKEDPAIRS>;

####################
#Store Address data
####################
=head
Patient ID	Postal code	Unit number	Serial number
Patient_14	xyz123	A-07	1
Patient_18	xyz124	A-08	2
Patient_40	xyz987	A-13	7
Patient_48	xyz987	A-14	8
=cut

while (<ADDRESS>){
	chomp($_);
	$infile = $_;
	$infile =~ s/\n|\r//; #**sometimes chomp is not enough**#	
	@infile_split = split(/\t/,$infile);

	# Store whole line; Row number is the unique ID
	$HoAdm{$infile_split[3]} = [ @infile_split ];
}
close(ADDRESS);

####################
#Store Patient IDs
####################
while (<PATIENTID>){
	chomp($_);
	$infile = $_;
	$infile =~ s/\n|\r//; #**sometimes chomp is not enough**#	
	@infile_split = split(/\t/,$infile);

	$HoPatientID{$infile_split[0]} = $infile_split[1];
}
close(PATIENTID);


while (<LINKEDPAIRS>){
	chomp($_);
	$linkedpair = $_;
	$linkedpair =~ s/\n|\r//; #**sometimes chomp is not enough**#

	@linkedpair_split = split(/\t/,$linkedpair);

	$recip = $linkedpair_split[0];
	$donor = $linkedpair_split[1];

	$recip_patient = $HoPatientID{$recip};
	$donor_patient = $HoPatientID{$donor};

	################################################
	# Loop thru hash and store data for comparison
	################################################
	(@recip_postcode, @recip_unit, @recip_rowNum) = ();
	(@donor_postcode, @donor_unit, @donor_rowNum) = ();
		
	for $hoa ( keys %HoAdm ) {
		
		if ($HoAdm{$hoa}[0] eq $recip_patient){

			push @recip_postcode, $HoAdm{$hoa}[1];
			push @recip_unit, $HoAdm{$hoa}[1]."#".$HoAdm{$hoa}[2];

			push @recip_rowNum, $HoAdm{$hoa}[3];
		}

		if ($HoAdm{$hoa}[0] eq $donor_patient){

			push @donor_postcode, $HoAdm{$hoa}[1];
			push @donor_unit, $HoAdm{$hoa}[1]."#".$HoAdm{$hoa}[2];

			push @donor_rowNum, $HoAdm{$hoa}[3];
		}
	}

	for($r=0;$r<=$#recip_postcode;$r++){
		for($d=0;$d<=$#donor_postcode;$d++){

			if ($recip_postcode[$r] eq $donor_postcode[$d]){
				
				print OUTFULL "POSTCODE\t$recip_patient\t$donor_patient\t@{$HoAdm{$recip_rowNum[$r]}}\t@{$HoAdm{$donor_rowNum[$d]}}\n";
				$status1 = "POSTCODE";

			}

			if ($recip_unit[$r] eq $donor_unit[$d] && $recip_unit[$r] !~ m/\Qn.a/ && $donor_unit[$r] !~ m/\Qn.a/){

				print OUTFULL "UNIT\t$recip_patient\t$donor_patient\t@{$HoAdm{$recip_rowNum[$r]}}\t@{$HoAdm{$donor_rowNum[$d]}}\n";
				$status2 = "UNIT";

			}

		}
	}

	print OUTSTATUS "$recip\t$donor\t$recip_patient\t$donor_patient\t$status1\t$status2\n";
	($status1,$status2) = ();

}
close(LINKEDPAIRS);
