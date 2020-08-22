# PlangPegDesigner
##PlantPegDesigner: experimentally-based software for designing efficient plant pegRNAs
 - - - - - - -
URL:http://www.plantgenomeediting.net

PlantPegDesigner is a user-friendly web application based on published design principles and the Tm-directed PBS length and dual-pegRNA data. 

Acknowlegement: The free and open source user interface, layui-v2.5.6 (https://www.layui.com/) was used in PlantPegDesigner.

PlantPegDesigner provides precise guidance on the details of each prime editing experiment, including the recommended optimal on-target spacer, PBS sequence, RT template sequence and primers for vector construction. 

For a PPE experiment, PlantPegDesigner only needs a single input sequence including the reference and edited sequence; the format of the input sequence is shown in Note 1. PlantPegDesigner provides a variety of choices of parameters to meet the different needs of users (see details in Note 2). 

PlantPegDesigner first screens the forward/reverse strand of the input sequence of the spacer sequence and PAM (spacer-PAM) to check if the desired edits are correctly positioned in the user-defined prime editing window. The dual-pegRNA model will then be recommended if the spacer-PAM sequences can be found in both the forward and reverse strands. PlantPegDesigner displays all possible candidate PBS and RT template sequences of varying length. It then recommends the PBS sequence with user-defined optimal PBS Tm (default to 30 °C, based on experimental data for Tm-directed PBS length) and an RT template sequence based on previously published design principles3 (see details in Note 2). For each pegRNA, PlantPegDesigner designs the primer sets for a one-step PCR strategy for vector construction, and also supports the design of pooled pegRNAs (see details in Notes 3-4).

## Note 1 The format of the input sequence
 - - - -
The input sequence of PlantPegDesigner contains both the reference sequence and the edited sequence. The designed edits are marked “(a/b)”. “a” is the original sequence and "b" is the desired mutant sequence; either “a” or “b” may be null values representing insertions "(/b)" or deletions "(a/)", respectively (see examples of base conversions, insertions and deletions below). PlantPegDesigner also supports introducing multiple edits in one pegRNA (see examples of multiple edits below). Both uppercase and lowercase are accepted. We recommend that the input sequence contain at least 50 bp of upstream sequence and at least 50 bp of downstream sequence.

Example of a base substitution sequence (OsALS-T1, +2 A to G):
CTCGAGACTCCAGGGCCATACTTGTTGGATATCATCGTCCCGCACCAGGAGCATGTGCTGCCTATGATCCCA(A/G)GTGGGGGCGCATTCAAGGACATGATCCTGGATGGTGATGGCAGGACTGTGTA

Example of a sequence containing an insertion (OsCDC48-T2, +2 AAA insertion):
CTTCGCCCAGACTCTGCAGCAGTCTCGTGGGTTCGGCACCGAGTTTAGGTTCGCTGACCAGCCAGCGTCTGGC(/AAA)GCCGGCGCCGCCGCTGACCCCTTCGCATCCGCTGCCGCCGCAGCTGACGATGATGATT

Example of a sequence containing a deletion (OsCDC48-T1, +1–6 CTCCGG deletion):
TAGAGCTGTTGCTAATGAAACAGGTGCTTTCTTCTTTCTGATTAATGGC(CCGGAG/)ATTATGTCAAAGCTAGCAGGAGAAAGTGAGAGTAATCTCAGGAAGGCATTTGAAGAAGCTGAGAAG

Example of a sequence containing multiple edits (OsCDC48-T1, CCGGAG to AGGCA):
TAGAGCTGTTGCTAATGAAACAGGTGCTTTCTTCTTTCTGATTAATGGC(CCGGAG/AGGCA)ATTATGTCAAAGCTAGCAGGAGAAAGTGAGAGTAATCTCAGGAAGGCATTTGAAGAAGCTGAGAAG

## Note 2 Parameters and an output example.
 - - - -
PlantPegDesigner provides a variety of choices of parameters to meet the different needs of users:

“PAM sequence” (default to NGG PAM), “Cut distance to PAM” (default to -3 position) and “Spacer length” (default to 20 nt): These three parameters depend on the type of Cas protein used, default to SpCas9. 

“Spacer GC content” (default to 0%-100%): It has been reported that on-target GC content can influence the on-target editing activity of Cas9, so users can change this parameter if needed1-3.

“Prime editing window” (default to +1 - +15): We define the nicked site as +1 and the NGG PAM as +4 to +6. Previous studies showed that prime editor can work efficiently in an editing window from +1 to +15 in plants4-11, but longer editing window have also been reported5-8,10. The user can change these parameters.

“PBS length” (default to 7-16 bp) and “PBS GC content” (default to 0%-100%): The default values are based on previous reports4-12.

“Recommended Tm of PBS sequence” (default to 30℃): We strongly recommend the PBS Tm is set to 30℃. If 30℃ is unavailable, 32℃ is recommended.

“Homologous RT template length” (default to 7-16 bp) and whether “Exclude first C in RT template” (default to true): The default values are based on previous results12. Caution: The Homologous RT template length is the length from the desired edits to the 3’ terminus, not the length of the whole RT template.

“Tm-directed PBS length model” and “Dual-pegRNA model”: These two models were based on the experimental results to design efficient PBS length and dual-pegRNAs (default to open). The Tm-directed PBS and dual-pegRNA would not be recommended if close these two models, respectively. And the reverse primer would not be recommended if close the Tm-directed PBS length model.

In the output page of PlantPegDesigner, all the available spacer-PAM sequences are ranked by the distance between the nCas9-induced nick site and the desired edits, and are marked as “No. X program”. For each program, all PBS and RT template sequences are reported. For the RT template, PlantPegDesigner recommends one sequence of median length that does not begin with “C”, which may not be the optimal RT template12. PlantPegDesigner reports all the RT template sequences of varying length, so users can test more pegRNAs with different RT template lengths if higher editing efficiencies are needed.

## Note 3. Primer design and vector construction
 - - - - -
PlantPegDesigner provides four types of vector for pegRNA construction, and users can also specify the vector backbone sequence. The pOsU3, pTaU3, and pTaU6 vectors are recommended for particle bombardment and protoplast transformation experiments. The pH-nCas9-PPE-V2 vector is recommended for particle bombardment or Agrobacterium-mediated monocotyledon transformation. We recommend using the one-step PCR strategy and Gibson assembly for vector construction4, in which sgRNAs are amplified using primer sets containing the spacer sequences in the forward primer and the PBS+RT template sequences in the reverse primer, and are cloned into the pOsU3, pTaU3, pTaU6 and pH-nCas9-PPE-V2 vectors.

## Note 4. Design of pooled pegRNAs 
 - - - -
PlantPegDesigner permits the design of up to 50 pooled pegRNAs with different input sequences. If more than 50 pegRNAs are needed, please contact us by E-mail. The output of the pooled design is shown in the output page, and all the recommended results can be directly downloaded. Both uppercase and lowercase are accepted. The format of the pooled input file is as below:

>Input sequence 1
CTCGAGACTCCAGGGCCATACTTGTTGGATATCATCGTCCCGCACCAGGAGCATGTGCTGCCTATGATCCCA(A/G)GTGGGGGCGCATTCAAGGACATGATCCTGGATGGTGATGGCAGGACTGTGTA

>Input sequence 2
CTTCGCCCAGACTCTGCAGCAGTCTCGTGGGTTCGGCACCGAGTTTAGGTTCGCTGACCAGCCAGCGTCTGGC(/AAA)GCCGGCGCCGCCGCTGACCCCTTCGCATCCGCTGCCGCCGCAGCTGACGATGATGATT

……

>Input sequence 50
TAGAGCTGTTGCTAATGAAACAGGTGCTTTCTTCTTTCTGATTAATGGC(CCGGAG/AGGCA)ATTATGTCAAAGCTAGCAGGAGAAAGTGAGAGTAATCTCAGGAAGGCATTTGAAGAAGCTGAGAAG


