# find_controls_part1.pl
# By Natascha May Thevasagayam, NCID, Singapore

# For selecting controls based on specified criteria (part 1)
# Usage: perl find_controls_part1.pl

use List::MoreUtils qw(uniq);

open (linkedpairings, "lookup_linkedpairings");
open (linkedpairsRecip, "lookup_linked"); # linked = genomic-linked bacterial transmission
open (NOTlinkedpairsRecip, "lookup_NOT_linked_removedMultiCP_randomized");

open (OUT1, ">find_controls_out");

####################
# IMPT: Input files are assumed to have headers
####################
$skip_header = <linkedpairings>;
$skip_header = <linkedpairsRecip>;
$skip_header = <NOTlinkedpairsRecip>;

####################
# Store linked pairings
####################
=head
Acquisition patient	Acquisition isolate	Source patient	Source isolate
Patient_40	CF27	Patient_48	CF25
Patient_14	CF31	Patient_40	CF27
Patient_14	CF31	Patient_59	CF28
=cut

while (<linkedpairings>){
	chomp($_);
	$infile = $_;
	$infile =~ s/\n|\r//; #**sometimes chomp is not enough**#
	@infile_split = split(/\t/,$infile);

	push @{$HoDonorPatient{$infile_split[1]}}, $infile_split[2]; # Acquisition isolate ID --> Array of ALL Source patient IDs
}

####################
# Store data for linked isolates
####################
=head
Patient ID	Isolate ID	Date of Culture	Date of Culture (decimal)	CC group	Genomic species	ST	Genomic CP gene(s)
Patient_14	CF31	6/11/2018	2018.849315	cfreundii_CCgroup22_40samples	Citrobacter freundii	22	blaNDM-1
Patient_18	CF15	1/10/2019	2019.750685	cfreundii_CCgroup22_40samples	Citrobacter freundii	107	blaNDM-1
Patient_21	CF30	5/11/2018	2018.846576	cfreundii_CCgroup22_40samples	Citrobacter freundii	22	blaNDM-1
=cut

while (<linkedpairsRecip>){
	chomp($_);
	$infile = $_;
	$infile =~ s/\n|\r//; #**sometimes chomp is not enough**#
	@infile_split = split(/\t/,$infile);

	# Store whole line; Isolate ID is the unique ID
	$HoLINKED{$infile_split[1]} = [ @infile_split ];
}
close(linkedpairsRecip);


while (<NOTlinkedpairsRecip>){
	chomp($_);
	$infile = $_;
	$infile =~ s/\n|\r//; #**sometimes chomp is not enough**#
	@infile_split = split(/\t/,$infile);

	# Store whole line; Isolate ID is the unique ID
	$HoXLINKED{$infile_split[1]} = [ @infile_split ];
}
close(NOTlinkedpairsRecip);


for $hoaG ( keys %HoLINKED ) {

	for $hoaX ( keys %HoXLINKED ) {

		$CPstatus = "";
		$donorPatientIDstatus = "";
		if ($HoLINKED{$hoaG}[1] ne $HoXLINKED{$hoaX}[1]){ # Only consider different Isolate ID

			# Check for CP gene substring
			if (index($HoLINKED{$hoaG}[7], $HoXLINKED{$hoaX}[7]) != -1) {
				$CPstatus = "match"; # if match CP gene, disqualified.
			} 

			# Check for different source patient ID
			foreach $donorPatient (@{$HoDonorPatient{$HoLINKED{$hoaG}[1]}}){  
				if ($donorPatient eq $HoXLINKED{$hoaX}[0]) {
					$donorPatientIDstatus = "match"; # if match ANY of the donor patient ID, disqualified.
				} 
			}

			# Criteria:
			#		Control date of culture same or after Acquisition DOC (hence will also be after the Source DOC)
			#		Different Acquisition patient ID
			#		Different Source patient ID

			if ($HoLINKED{$hoaG}[3] <= $HoXLINKED{$hoaX}[3] && $HoLINKED{$hoaG}[0] ne $HoXLINKED{$hoaX}[0] && $donorPatientIDstatus ne "match"){
					print OUT1 join( "\t", @{$HoLINKED{$hoaG}} );
					print OUT1 "\t#\t";
					print OUT1 join( "\t", @{$HoXLINKED{$hoaX}} );
					print OUT1 "\n";
			}

		}else{
			print "ERROR: there should not be any matching Isolate IDs between the two input files";

		}
	}
}

close(OUT1);
close (linkedpairings);

