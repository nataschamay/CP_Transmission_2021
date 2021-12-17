# dnaDist_Poisson.R
# By Prakki Sai Rama Sridatta (NCID, Singapore); with contribution from David Eyre (University of Oxford, United Kingdom)

# Calculate pairwise SNP difference based on output of Gubbins, and run Poisson function (contributed by David Eyre) to compare the pairwise SNP to the BEAST-derived mutation rate threshold, assuming a Poisson distribution for the accumulation of mutations.

# Before running script: Edit lines with ###
# Usage: Rscript dnaDist_Poisson.R

# output format:
	# snps = pairwise SNP count between Isolate1 and Isolate2, based on the recombination-filtered core genome alignment
	# mu = the mutation rate (substitutions/genome/year) for the respective species determined using BEAST
	# time.diff = difference between Isolate1_Date and Isolate2_Date
	# expected.snp = time.diff * mu
	# original.cutoff = TRUE if snps < expected.snp, FALSE otherwise (this is just a gauge, not used to indicate transmission)
	# max.snp = output of R function qpois(0.95, time.diff * mu)
	# transmission.plausible = 1 if snps <= max.snp, 0 if otherwise (used to indicate transmission)

library(ape)
library(dplyr)
library(reshape2)

setwd("/user/data1/CP/find_pairs")												### Set the path

STGroup <- "postGubbins_cfreundii_CCgroup22_40samples"							### Set the group name
beast_mu <- 2.72																### Set the mu (output of BEAST, specific to each species)

# Read input multiple fasta file - this is the output of Gubbins, i.e. recombination-filtered core genome
data <- read.FASTA(file = "postGubbins.filtered_polymorphic_sites.fasta") 		### Set the input filename 

# Calculate the pair-wise distance
out <-  dist.dna(data,model="N",pairwise.deletion=TRUE,as.matrix=T) # Full matrix
out[lower.tri(out,diag=T)] <- NA # Take upper triangular matrix, when needed

D_out_melt = melt(as.matrix(out), varnames = c("row", "col"))
D_out_melt_sorted = arrange(D_out_melt, value)

# Ignore the NA records
fullrecords <- D_out_melt_sorted[complete.cases(D_out_melt_sorted),] 

# Replacing unwanted strings in the filebasenames
fullrecords_NameStripped <- as.data.frame(sapply(fullrecords,function(x) {x <- gsub("_Ns_converted_to_RefBase","",x)}))

# Ignore rows with Reference Sequence. The reference header contains pattern called "length"
fullrecords_NameStripped <- fullrecords_NameStripped[grep("length", fullrecords_NameStripped$row, invert = TRUE), ]
fullrecords_NameStripped <- fullrecords_NameStripped[grep("length", fullrecords_NameStripped$col, invert = TRUE), ]

# Adding pair.id column
fullrecords_NameStripped$PairID <- paste0(fullrecords_NameStripped$row,"#",fullrecords_NameStripped$col )

# Add a column to dataframe with BEAST SNP rate with header name "beast_mu"
fullrecords_NameStripped$beast_mu <- beast_mu
fullrecords_NameStripped$STGroup <- STGroup

#########################################
## David Eyre's Poisson script portion ##
#########################################

# Importing the date of cultures
cultureDate <- read.table("/user/data1/CP/find_pairs/IsolateDOC.txt",header = TRUE);	### Set the DOC file location

# Using match function, retrieve the date of cultures for Sample1 and Sample2
fullrecords_NameStripped$Sample1_Date <-cultureDate$cultureDate[match(fullrecords_NameStripped$row,cultureDate$Isolate)]
fullrecords_NameStripped$Sample2_Date <-cultureDate$cultureDate[match(fullrecords_NameStripped$col,cultureDate$Isolate)]

# Calculate absolute time difference between samples
fullrecords_NameStripped$timeDiff <- abs(as.numeric(as.character(fullrecords_NameStripped$Sample1_Date)) - as.numeric(as.character(fullrecords_NameStripped$Sample2_Date)))

# Calculate Expected SNP
fullrecords_NameStripped$expected_snp <- fullrecords_NameStripped$timeDiff*fullrecords_NameStripped$beast_mu

# Determine if there is tranmission with original cutoff
fullrecords_NameStripped$TranmissionByBEASTcutoff <- as.numeric(as.character(fullrecords_NameStripped$value)) < as.numeric(as.character(fullrecords_NameStripped$expected_snp))

# Rearranging and renaming columns 
fullrecords_NameStripped <- fullrecords_NameStripped[,c("STGroup","row","col","PairID","value","beast_mu","Sample1_Date","Sample2_Date","timeDiff","expected_snp","TranmissionByBEASTcutoff")]
colnames(fullrecords_NameStripped)
colnames(fullrecords_NameStripped) = c("st_cp_grouping", "id1", "id2", "pair.id", "snps","mu","Sample1_Date","Sample2_Date","time.diff", "expected.snp", "original.cutoff")

# qpois function
fullrecords_NameStripped$max.snp = qpois(0.95, fullrecords_NameStripped$time.diff*fullrecords_NameStripped$mu)
fullrecords_NameStripped$max.snp 

# Determine if there is tranmission with max.snp cutoff
fullrecords_NameStripped$transmission.plausible = ifelse(as.numeric(as.character(fullrecords_NameStripped$snps)) <= as.numeric(as.character(fullrecords_NameStripped$max.snp)), 1, 0)

# Write output
write.csv(fullrecords_NameStripped, "dnaDist_poisson_out")					### Set output filename


