# PlangPegDesigner
PlantPegDesigner: experimentally-based software for designing efficient plant pegRNAs
URL:http://www.plantgenomeediting.net/CRISPR_web/index.CRISPR.html
PlantPegDesigner is a user-friendly web application based on published design principles and the Tm-directed PBS length and dual-pegRNA data. 
PlantPegDesigner provides precise guidance on the details of each prime editing experiment, including the recommended optimal on-target spacer, PBS sequence, RT template sequence and primers for vector construction. 

For a PPE experiment, PlantPegDesigner only needs a single input sequence including the reference and edited sequence; the format of the input sequence is shown in Note 1. PlantPegDesigner provides a variety of choices of parameters to meet the different needs of users (see details in Note 2). 

PlantPegDesigner first screens the forward/reverse strand of the input sequence of the spacer sequence and PAM (spacer-PAM) to check if the desired edits are correctly positioned in the user-defined prime editing window. The dual-pegRNA model will then be recommended if the spacer-PAM sequences can be found in both the forward and reverse strands. PlantPegDesigner displays all possible candidate PBS and RT template sequences of varying length. It then recommends the PBS sequence with user-defined optimal PBS Tm (default to 30 °C, based on experimental data for Tm-directed PBS length) and an RT template sequence based on previously published design principles3 (see details in Note 2). For each pegRNA, PlantPegDesigner designs the primer sets for a one-step PCR strategy for vector construction, and also supports the design of pooled pegRNAs (see details in Notes 3-4).
