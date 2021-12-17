System requirements
===================
A Linux/Unix workstation with Perl and R installed. 
The tools were developed and tested on Ubuntu 18.04 and 20.04.

Installation guide
==================
No installation required as all codes are in the form of Perl scripts or R scripts, to be run directly on the command line or RStudio.

Custom code for performing transmission analysis
================================================
1) dnaDist_Poisson.R - for calculating pairwise SNP difference based on output of Gubbins, and compares the pairwise SNP to the BEAST-derived mutation rate threshold, assuming a Poisson distribution for the accumulation of mutations.
2) find_pairs.pl - for determining transmission pairs based on specified criteria
3) find_epiOverlap_Adm.pl - for determining hospital/ward contact
4) find_epiOverlap_Discipline.pl - for determining discipline contact
5) find_epiOverlap_Procedure.pl - for determining procedure contact
6) find_epiOverlap_Address.pl - for determining address contact
7) find_controls_part1.pl and find_controls_part2.pl - for selecting controls based on specified criteria