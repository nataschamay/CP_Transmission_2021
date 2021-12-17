# find_epiOverlap_Procedure.pl
# By Natascha May Thevasagayam, NCID, Singapore

# For determining procedure contact
# Usage: perl find_epiOverlap_Procedure.pl

use List::MoreUtils qw(uniq);

####################
# INPUT FILES
####################
open (PROCEDURE, "list_procedure"); 	# Procedure data; NOTE:removed duplicates and n.a
open (DOC, "list_dateOfCulture");		# Isolate date of culture
open (PATIENTID, "list_patientID");		# Patient IDs
open (LINKEDPAIRS, "list_linkedPairs");	# Transmission pairs

####################
# OUTPUT FILES
####################
open (OUTFULL, ">EpiOverlap_Procedure_full");
open (OUTSTATUS, ">EpiOverlap_Procedure_status");

####################
# Input files are assumed to have headers
####################
$skip_header = <PROCEDURE>;
$skip_header = <PATIENTID>;
$skip_header = <LINKEDPAIRS>;


#######################
#Store Procedure data
#######################
# Multiple dates are comma delimited
=head
Patient ID	Procedure Hospital	ERCP	Cystoscope	Colonoscope	OGD
Patient_14	Hospital_A			2015.780822	2015.780822
Patient_14	Hospital_A			2019.315069	2019.315069
Patient_14	Hospital_A				2019.449315
Patient_36	Hospital_A	2015.402740			
Patient_48	Hospital_A			2017.199461,2017.281429,2017.286893	2017.199461,2017.245909,2017.281429
=cut

while (<PROCEDURE>){
	chomp($_);
	$infile = $_;
	$infile =~ s/\n|\r//; #**sometimes chomp is not enough**#	
	@infile_split = split(/\t/,$infile);

	$patient = $infile_split[0];
	$phospital = $infile_split[1];
	@ercp_split = split(/,/,$infile_split[2]);
	@cyto_split = split(/,/,$infile_split[3]);
	@colon_split = split(/,/,$infile_split[4]);
	@ogd_split = split(/,/,$infile_split[5]);

	# Store hospital and procedure dates
	foreach $ercp_date (@ercp_split) {
		push @{ $HoERCP{$patient} }, "$phospital#$ercp_date";
	}

	foreach $cyto_date (@cyto_split) {
		push @{ $HoCYTO{$patient} }, "$phospital#$cyto_date";
	}

	foreach $colon_date (@colon_split) {
		push @{ $HoCOLON{$patient} }, "$phospital#$colon_date";
	}

	foreach $ogd_date (@ogd_split) {
		push @{ $HoOGD{$patient} }, "$phospital#$ogd_date";
	}

}
close(PROCEDURE);

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

####################
#Store Date of Culture
####################
while (<DOC>){
	chomp($_);
	$infile = $_;
	$infile =~ s/\n|\r//; #**sometimes chomp is not enough**#	
	@infile_split = split(/\t/,$infile);

	$HoDOC{$infile_split[0]} = $infile_split[1];
}
close(DOC);

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
	(@recip_ERCP, @donor_ERCP) = ();		
	for $keyERCP ( keys %HoERCP ) {
		if ($keyERCP eq $recip_patient){
			@recip_ERCP = @{ $HoERCP{$keyERCP} };
		}
		if ($keyERCP eq $donor_patient){
			@donor_ERCP = @{ $HoERCP{$keyERCP} };
		}
	}
	
	(@recip_CYTO, @donor_CYTO) = ();
	for $keyCYTO ( keys %HoCYTO ) {
		if ($keyCYTO eq $recip_patient){
			@recip_CYTO = @{ $HoCYTO{$keyCYTO} };
		}
		if ($keyCYTO eq $donor_patient){
			@donor_CYTO = @{ $HoCYTO{$keyCYTO} };
		}
	}
	
	(@recip_COLON, @donor_COLON) = ();
	for $keyCOLON ( keys %HoCOLON ) {
		if ($keyCOLON eq $recip_patient){
			@recip_COLON = @{ $HoCOLON{$keyCOLON} };
		}
		if ($keyCOLON eq $donor_patient){
			@donor_COLON = @{ $HoCOLON{$keyCOLON} };
		}
	}
	
	(@recip_OGD, @donor_OGD) = ();
	for $keyOGD ( keys %HoOGD ) {
		if ($keyOGD eq $recip_patient){
			@recip_OGD = @{ $HoOGD{$keyOGD} };
		}
		if ($keyOGD eq $donor_patient){
			@donor_OGD = @{ $HoOGD{$keyOGD} };
		}
	}

	for($r=0;$r<=$#recip_ERCP;$r++){
		for($d=0;$d<=$#donor_ERCP;$d++){

			# Get [0]hospital and [1]date
			@recip_split = split(/#/,$recip_ERCP[$r]);
			@donor_split = split(/#/,$donor_ERCP[$d]);

			if ($recip_split[0] eq $donor_split[0]){
			
				if ($recip_split[1] eq $donor_split[1] && $donor_split[1] >= $HoDOC{$donor} && $recip_split[1] >= $HoDOC{$donor} && $donor_split[1] <= $HoDOC{$recip} && $recip_split[1] <= $HoDOC{$recip}){
					print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tProcedure Contact(ERCP)\tProcedure Direct\t$recip_ERCP[$r]\t$donor_ERCP[$d]\n";
					$statusERCP1 = "Procedure Direct";
					$status1 = "Procedure Direct";	
					$HoENT{$recip}[0] = "Procedure Direct";
				}elsif($recip_split[1] > $donor_split[1] && $donor_split[1] >= $HoDOC{$donor} && $recip_split[1] >= $HoDOC{$donor} && $donor_split[1] <= $HoDOC{$recip} && $recip_split[1] <= $HoDOC{$recip}){ #donor did procedure before recip
					print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tProcedure Contact(ERCP)\tProcedure Indirect\t$recip_ERCP[$r]\t$donor_ERCP[$d]\n";
					$statusERCP2 = "Procedure Indirect";
					$status2 = "Procedure Indirect";
					$HoENT{$recip}[1] = "Procedure Indirect";	
					
				}else{ #donor not before recip
					print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tNo Procedure Contact(d>r)\t\t$recip_ERCP[$r]\t$donor_ERCP[$d]\n";
					$statusERCP3 = "No Procedure Contact(d>r)";
					$status3 = "No Procedure Contact(d>r)";
					$HoENT{$recip}[2] = "No Procedure Contact";
				}
			}else{ #different hospital
				print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tNo Procedure Contact(diffHosp)\t\t$recip_ERCP[$r]\t$donor_ERCP[$d]\n";
				$statusERCP3 = "No Procedure Contact(diffHosp)";
				$status3 = "No Procedure Contact(diffHosp)";
				$HoENT{$recip}[2] = "No Procedure Contact";
			}

		}
	}
	
	for($r=0;$r<=$#recip_CYTO;$r++){
		for($d=0;$d<=$#donor_CYTO;$d++){

			# Get [0]hospital and [1]date
			@recip_split = split(/#/,$recip_CYTO[$r]);
			@donor_split = split(/#/,$donor_CYTO[$d]);

			if ($recip_split[0] eq $donor_split[0]){

				if ($recip_split[1] eq $donor_split[1] && $donor_split[1] >= $HoDOC{$donor} && $recip_split[1] >= $HoDOC{$donor} && $donor_split[1] <= $HoDOC{$recip} && $recip_split[1] <= $HoDOC{$recip}){
					print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tProcedure Contact(CYTO)\tProcedure Direct\t$recip_CYTO[$r]\t$donor_CYTO[$d]\n";
					$statusCYTO1 = "Procedure Direct";
					$status1 = "Procedure Direct";
					$HoENT{$recip}[0] = "Procedure Direct";	
					
				}elsif($recip_split[1] > $donor_split[1] && $donor_split[1] >= $HoDOC{$donor} && $recip_split[1] >= $HoDOC{$donor} && $donor_split[1] <= $HoDOC{$recip} && $recip_split[1] <= $HoDOC{$recip}){ #donor did procedure before recip
					print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tProcedure Contact(CYTO)\tProcedure Indirect\t$recip_CYTO[$r]\t$donor_CYTO[$d]\n";
					$statusCYTO2 = "Procedure Indirect";
					$status2 = "Procedure Indirect";
					$HoENT{$recip}[1] = "Procedure Indirect";
					
				}else{ #donor not before recip
					print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tNo Procedure Contact(d>r)\t\t$recip_CYTO[$r]\t$donor_CYTO[$d]\n";
					$statusCYTO3 = "No Procedure Contact(d>r)";
					$status3 = "No Procedure Contact(d>r)";
					$HoENT{$recip}[2] = "No Procedure Contact";
				}
			}else{ #different hospital
				print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tNo Procedure Contact(diffHosp)\t\t$recip_CYTO[$r]\t$donor_CYTO[$d]\n";
				$statusCYTO3 = "No Procedure Contact(diffHosp)";
				$status3 = "No Procedure Contact(diffHosp)";
				$HoENT{$recip}[2] = "No Procedure Contact";
			}

		}
	}

	for($r=0;$r<=$#recip_COLON;$r++){
		for($d=0;$d<=$#donor_COLON;$d++){

			# Get [0]hospital and [1]date
			@recip_split = split(/#/,$recip_COLON[$r]);
			@donor_split = split(/#/,$donor_COLON[$d]);

			if ($recip_split[0] eq $donor_split[0]){

				if ($recip_split[1] eq $donor_split[1] && $donor_split[1] >= $HoDOC{$donor} && $recip_split[1] >= $HoDOC{$donor} && $donor_split[1] <= $HoDOC{$recip} && $recip_split[1] <= $HoDOC{$recip}){
					print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tProcedure Contact(COLON)\tProcedure Direct\t$recip_COLON[$r]\t$donor_COLON[$d]\n";
					$statusCOLON1 = "Procedure Direct";
					$status1 = "Procedure Direct";	
					$HoENT{$recip}[0] = "Procedure Direct";	
					
				}elsif($recip_split[1] > $donor_split[1] && $donor_split[1] >= $HoDOC{$donor} && $recip_split[1] >= $HoDOC{$donor} && $donor_split[1] <= $HoDOC{$recip} && $recip_split[1] <= $HoDOC{$recip}){ #donor did procedure before recip
					print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tProcedure Contact(COLON)\tProcedure Indirect\t$recip_COLON[$r]\t$donor_COLON[$d]\n";
					$statusCOLON2 = "Procedure Indirect";
					$status2 = "Procedure Indirect";
					$HoENT{$recip}[1] = "Procedure Indirect";
					
				}else{ #donor not before recip
					print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tNo Procedure Contact(d>r)\t\t$recip_COLON[$r]\t$donor_COLON[$d]\n";
					$statusCOLON3 = "No Procedure Contact(d>r)";
					$status3 = "No Procedure Contact(d>r)";
					$HoENT{$recip}[2] = "No Procedure Contact";
				}
			}else{ #different hospital
				print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tNo Procedure Contact(diffHosp)\t\t$recip_COLON[$r]\t$donor_COLON[$d]\n";
				$statusCOLON3 = "No Procedure Contact(diffHosp)";
				$status3 = "No Procedure Contact(diffHosp)";
				$HoENT{$recip}[2] = "No Procedure Contact";
			}

		}
	}

	for($r=0;$r<=$#recip_OGD;$r++){
		for($d=0;$d<=$#donor_OGD;$d++){

			# Get [0]hospital and [1]date
			@recip_split = split(/#/,$recip_OGD[$r]);
			@donor_split = split(/#/,$donor_OGD[$d]);

			if ($recip_split[0] eq $donor_split[0]){

				if ($recip_split[1] eq $donor_split[1] && $donor_split[1] >= $HoDOC{$donor} && $recip_split[1] >= $HoDOC{$donor} && $donor_split[1] <= $HoDOC{$recip} && $recip_split[1] <= $HoDOC{$recip}){
					print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tProcedure Contact(OGD)\tProcedure Direct\t$recip_OGD[$r]\t$donor_OGD[$d]\n";
					$statusOGD1 = "Procedure Direct";
					$status1 = "Procedure Direct";
					$HoENT{$recip}[0] = "Procedure Direct";	
					
				}elsif($recip_split[1] > $donor_split[1] && $donor_split[1] >= $HoDOC{$donor} && $recip_split[1] >= $HoDOC{$donor} && $donor_split[1] <= $HoDOC{$recip} && $recip_split[1] <= $HoDOC{$recip}){ #donor did procedure before recip
					print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tProcedure Contact(OGD)\tProcedure Indirect\t$recip_OGD[$r]\t$donor_OGD[$d]\n";
					$statusOGD2 = "Procedure Indirect";
					$status2 = "Procedure Indirect";
					$HoENT{$recip}[1] = "Procedure Indirect";
					
				}else{ #donor not before recip
					print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tNo Procedure Contact(d>r)\t\t$recip_OGD[$r]\t$donor_OGD[$d]\n";
					$statusOGD3 = "No Procedure Contact(d>r)";
					$status3 = "No Procedure Contact(d>r)";
					$HoENT{$recip}[2] = "No Procedure Contact";
				}
			}else{ #different hospital
				print OUTFULL "$recip\t$donor\t$recip_patient\t$donor_patient\tNo Procedure Contact(diffHosp)\t\t$recip_OGD[$r]\t$donor_OGD[$d]\n";
				$statusOGD3 = "No Procedure Contact(diffHosp)";
				$status3 = "No Procedure Contact(diffHosp)";
				$HoENT{$recip}[2] = "No Procedure Contact";
			}

		}
	}	
	
	if(length($status1)==0 && $status1 eq $status2 && $status1 eq $status3){
		$status3 = "No Procedure Contact(notInProc)";
		$HoENT{$recip}[2] = "No Procedure Contact";
	}

	print OUTSTATUS "$recip\t$donor\t$recip_patient\t$donor_patient\t$status1\t$status2\t$status3\n";
	($status1,$status2,$status3) = ();

}
close(LINKEDPAIRS);


