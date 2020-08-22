#perl -w
use strict;
use warnings;

my $left_cutoff = 20;
my $right_cutoff = 10;

my $input_file = "Input.txt";
my $output_file = "Output.html";
if(@ARGV != 0){
	($input_file, $output_file) = @ARGV;
}

my $step1;
open (IN,"$input_file");
#Input_Sequence	123456789AAAAAAAAAA(TGC/GTA)AGGTTTTTTTTTTTTTTTT123456789
#PAM	NGG
#CutToPAM	-3
#OnTargetLength	20
#OnTarget_CG_Conetent	0-100
#PE_Window	1-15
#PBS_Length	7-16
#PBS_CG_Content	40-60
#Tm_model	True
#TM_Best	30
#RT_Length	7-16
#Exclude_LastG_in_RT	True
#CCNNGG_model	True
#UpstreamPrimer5	TTGTGCAGATGATCCGTGGCG
#UpstreamPrimer3	GTTTTAGAGCTAGAAATA
#DownstreamPrimer5	CTATGACCATGATTACGCCAAGCTTAAAAAAA 
#DownstreamPrimer3	GCACCGACTCGGTGCCAC

open (OUT,">$output_file");
my %input;
while(<IN>){#Read input file
	chomp;
	my ($temp) = split(/\r/, $_);
	my ($key, $value) = split(/\t/, $temp);
	$input{$key} = $value;
#	print "Input:\t$key\t$value\n";#Testing
}

my $testsequence = Test_Sequence($input{"Input_Sequence"});
my $testPAM = Test_PAM($input{"PAM"});

my %Final_result;
my $CCGG_model = 0;
my %CCGG_PAM_count;
for(my $FR = 0; $FR < 2; $FR ++){
	my ($RefSeq, $AltSeq, $length_left, $length_right, $length_ref, $length_alt);
	my $Forward_or_Reverse = "";
	if($FR == 0){
		$Forward_or_Reverse = "Forward Strand";#Forward Strand
		($RefSeq, $AltSeq, $length_left, $length_right, $length_ref, $length_alt) = Ref_Alt($input{"Input_Sequence"});	#Read input sequence
	}
	if($FR == 1){
		$Forward_or_Reverse = "Reverse Strand";#Reverse Strand
		($AltSeq, $RefSeq, $length_left, $length_right, $length_alt, $length_ref) = Ref_Alt(Rev_com($input{"Input_Sequence"}));	#Read input sequence, !!!!!Ref and alt
	}	
	#my $RefRCSeq = Rev_com($RefSeq);
	#my $AltRCSeq = Rev_com($AltSeq);
	#print "Ref:$RefSeq\nAlt:$AltSeq\n";
	#print "RefRC:$RefRCSeq\nAltRC:$AltRCSeq\n";
	
	my @PamOutput = FindAllPam($RefSeq, $input{"PAM"}, $input{"OnTargetLength"}, $input{"CutToPAM"});	#Find All Pams of Forward strand
	#for (my $i = 0; $i < @PamOutput; $i ++){print "$PamOutput[$i]\n";} #Testing
	
	my @PamOutput_GC = Filter_GC_PAM($input{"OnTarget_CG_Content"}, @PamOutput); #Filter GC content of OnTargetSeq
	
	my @PamOutput1 = Filter_PE_Window($input{"PE_Window"}, $length_left, @PamOutput_GC); #Filter PE Window
	#for (my $i = 0; $i < @PamOutput1; $i ++){print "$PamOutput1[$i]\n";} #Testing

	if(@PamOutput1 > 0){#CCGG model
		$CCGG_model ++;		
	}
	$CCGG_PAM_count{$FR} = @PamOutput1;
	
	for (my $i = 0; $i < @PamOutput1; $i ++){ 
		my ($OnTargetSeq, $PAMSeq, $Cut_Position, $left_distance_to_cut) = split(/\;/, $PamOutput1[$i]);
		my $OnTargetSeqGC = GC($OnTargetSeq) * 100;
		$Final_result{$left_distance_to_cut}{$Forward_or_Reverse} .= "PAM:\t$OnTargetSeq,$PAMSeq,$OnTargetSeqGC,$Cut_Position,$left_distance_to_cut\n"; #Output PAM
		my @best_PBS;
		my @best_RT;
		{#Get PBS for each PAM
			my ($PBS_min, $PBS_max) = split(/\-/, $input{"PBS_Length"});
			my ($PBS_CG_Content_min, $PBS_CG_Content_max) = split(/\-/, $input{"PBS_CG_Content"});			
			my $best_TM = 0;
			my @PBS_Results;
			for(my $j = $PBS_min; $j <= $PBS_max; $j ++){
				my $PBS_Seq = substr($RefSeq, $Cut_Position - $j, $j);
				my $PBS_Tm = TM($PBS_Seq);
				my $PBS_GC = GC($PBS_Seq) * 100; #Percentage
				if($PBS_GC > $PBS_CG_Content_max || $PBS_GC < $PBS_CG_Content_min){	#Filter GC Content
					next;
				}
				if(abs($PBS_Tm - $input{"TM_Best"}) <= abs($best_TM - $input{"TM_Best"})){
					$best_TM = $PBS_Tm;
				}
				my $PBS_length = length($PBS_Seq);
				$PBS_Results[@PBS_Results] = "$PBS_Seq;$PBS_length;$PBS_Tm;$PBS_GC";
			}
			for(my $j = 0; $j < @PBS_Results; $j ++){
				my ($PBS_Seq, $PBS_length, $PBS_Tm, $PBS_GC) = split(/\;/, $PBS_Results[$j]);
				my $best = "";
				if($input{"Tm_model"} eq "True"){
#					if(abs($PBS_Tm - $input{"TM_Best"}) == abs($best_TM - $input{"TM_Best"})){#Recommend_TM
					if($PBS_Tm == $best_TM){#Recommend_TM
						$best = "Best TM!";						
						$best_PBS[@best_PBS] = $PBS_Seq;
					}					
				}	
				my $RC_PBS_Seq = Rev_com($PBS_Seq);
				$Final_result{$left_distance_to_cut}{$Forward_or_Reverse} .= "PBS:\t$RC_PBS_Seq,$PBS_length,$PBS_Tm,$PBS_GC,$best\n";#Output PBS
			}
		}
		{#Get RT
			my @RT_Results;
			my ($RT_min, $RT_max) = split(/\-/, $input{"RT_Length"});
	#		print "$RT_min, $RT_max\n";die;#testing;
			my $RT_left_seq = substr($AltSeq, $Cut_Position, $length_left - $Cut_Position);
			my $min_to_middle = 100;
			for(my $j = $RT_min; $j <= $RT_max; $j ++){
				my $RT_right_seq = substr($AltSeq, $length_left, $length_alt + $j);
				my $RT_seq = $RT_left_seq.$RT_right_seq;
				my $lastSeq = substr($RT_seq, length($RT_seq) - 1, 1);
				if($input{"Exclude_LastG_in_RT"} eq "True"){
					if($lastSeq eq "g" || $lastSeq eq "G"){		#Filter LastG in RT
						next;
					}
				}
				$RT_Results[@RT_Results] = "$RT_seq;$j";
				if(abs($j - int(($RT_min + $RT_max)/2)) < abs($min_to_middle - int(($RT_min + $RT_max)/2))){#Nearest to the middle
					$min_to_middle = $j;
				}
			}
			my $best_nearest = 1;# only save the smallest best one
			for(my $j = 0; $j < @RT_Results; $j ++){
				my ($RT_seq, $RT_length) = split(/\;/, $RT_Results[$j]);
				my $best = "";
#				if(abs($RT_length - int(($RT_min + $RT_max)/2)) == abs($min_to_middle - int(($RT_min + $RT_max)/2))){
#					$best = "Best for RT!";
#					$best_nearest ++;
#				}
#				if($best_nearest > 2){
#					$best = "";
#				}
				if(($j + 1)  == int((@RT_Results+1)/2)){					
					$best = "Best for RT!";
					$best_RT[@best_RT] = $RT_seq;
				}
				my $RC_RT_seq = Rev_com($RT_seq);
				my $RT_seq_length = length($RT_seq);
				$Final_result{$left_distance_to_cut}{$Forward_or_Reverse} .= "RT:\t$RC_RT_seq,$RT_seq_length,$best\n";#Output RT
			}
		}
		my $OnTargetSeq1 = $OnTargetSeq;
		$OnTargetSeq1 =~s/^g//;
		my $upstreamprimer = $input{"UpstreamPrimer5"}.$OnTargetSeq1.$input{"UpstreamPrimer3"};#Up and down stream primers
		$Final_result{$left_distance_to_cut}{$Forward_or_Reverse} .= "UpstreamPrimer:\t$upstreamprimer\n";
		for(my $j = 0; $j < @best_PBS; $j ++){
			for(my $k = 0; $k < @best_RT; $k ++){
				my $downstreamprimer = $input{"DownstreamPrimer5"}.$best_PBS[$j].$best_RT[$k].$input{"DownstreamPrimer3"};
				$Final_result{$left_distance_to_cut}{$Forward_or_Reverse} .= "DownstreamPrimer:\t$downstreamprimer\n";
			}
		}
	}
}

my $CCNNGG_Success = 0;
if($input{"CCNNGG_model"} eq "True"){
	if($CCGG_model == 2){
		my $forward_PAM =  $CCGG_PAM_count{"0"};
		my $reverse_PAM =  $CCGG_PAM_count{"1"};
		$step1 .= "CCGG:\tThere are $forward_PAM PAM(s) on the forward strand and $reverse_PAM PAM(s) on the reverse strand, the dual-pegRNA model could be used!\n";
		$CCNNGG_Success = 1;
	}
	else{
		$step1 .= "CCGG:\tThe dual-pegRNA model could not be used!\n";
	}
}

my $best_pam1 = "recommended program, also could be used for NGG-pegRNA in dual-pegRNA model!";
my $best_pam2 = "recommended program, also could be used for CCN-pegRNA in dual-pegRNA model!";
my $best_pam0 = "recommended program";
my $count = 0;
foreach my $left_distance_to_cut (sort {$a <=> $b} keys %Final_result){
	foreach my $Forward_or_Reverse (sort keys %{$Final_result{$left_distance_to_cut}}){
		$count ++;
		if($Forward_or_Reverse eq "Forward Strand"){
			if($CCNNGG_Success == 1){
				$step1 .= "No:\tNo. $count $best_pam1\nStrand:\t$Forward_or_Reverse\n";
				$best_pam1 = "program";				
			}
			else{
				$step1 .= "No:\tNo. $count $best_pam0\nStrand:\t$Forward_or_Reverse\n";
				$best_pam0 = "program";	
			}
		}
		else{
			if($CCNNGG_Success == 1){
				$step1 .= "No:\tNo. $count $best_pam2\nStrand:\t$Forward_or_Reverse\n";
				$best_pam2 = "program";				
			}
			else{
				$step1 .= "No:\tNo. $count $best_pam0\nStrand:\t$Forward_or_Reverse\n";
				$best_pam0 = "program";	
			}
		}
		$step1 .= "$Final_result{$left_distance_to_cut}{$Forward_or_Reverse}End\n";
	}	
}
if($count == 0){
	$step1 .= "CCGG:\tNo PAM available.";
}



print OUT <<EndR;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Search</title>
<style>
#header {
    background-color:green;
    color:white;
    text-align:center;
    padding:5px;
}
#nav {
    line-height:30px;
    background-color:transparent;
    height:300px;
    width:600px;
    float:left;
    padding:5px;	      
}
#section {
	margin: 0 auto;
    width:400px;
    display: table;
    padding:10px;	 
	
}
#section input
{
	background-color:rgba(0,100,0,0.1);
	color: blue;
	font-size: 15px;
	display: table-cell;
	 width: 20%;
	text-align: center;
}
#section input.larger {
        transform: scale(2);
        margin: 10px;
      }	
#footer {
    background-color:rgba(0,100,0,0.1);
    color:blue;
    clear:both;
    text-align:center;
   padding:5px;	 	 
}
</style>
</head>

<body>
<div id="header">
<h1>PlantPegDesigner</h1>

</div>

<!-- <div id="nav">

</div>
-->
<div id="section">
EndR


my $new = 1;
my $last = "";
my $best_pam = 0;
my $first_PBS = 1;
my $first_RT = 1;
my @step2 = split(/\n/, $step1);
for (my $i = 0; $i < @step2; $i ++){
	my $temp = $step2[$i];
	my ($key, $value) = split(/\t/, $temp);
	if($key eq "Wrong:"){
		print OUT "$temp\n";
		last;
	}
	if($key eq "CCGG:"){
		print OUT <<EndR;
<p><span style="color:#c51b8a">$value</p>
EndR
	}
	if($new == 1){		
		$new = 0;
		print OUT <<EndR;
<p></p>
<table frame="hsides" width="1000">
EndR
	}
	if($temp eq "End"){
		print OUT "</table>\n";
		$new = 1;
		$first_PBS = 1;
		$first_RT = 1;
		next;
	}	
#	print "$key\t$value\n";
	my @values = split(/\,/, $value);
	if($key eq "No:"){

		if(exists($values[1])){
		
print OUT <<EndR;
  <tr>
    <th colspan="5" align="left"><span style="color:red">$values[0], $values[1]</th>
  </tr>
EndR
		}
		else{
print OUT <<EndR;
  <tr>
    <th colspan="5" align="left"><span style="color:#7A09FA">$values[0]</th>
  </tr>
EndR
		}
	}
	if($key eq "Strand:"){
		print OUT <<EndR;
  <tr>
    <th colspan="3" align="left">$values[0]</th>
  </tr>
EndR
	}
	if($key eq "PAM:"){
		print OUT <<EndR;
  <tr>
    <th align="left">Spacer-PAM:</th>
    <td>$values[0]<span style="background-color:#8FBC8F">$values[1]</td>
	<td>($values[2]% GC)</td>
	<td></td>
	<td></td>
  </tr>
EndR
	}
	if($key eq "PBS:"){
		if($first_PBS == 1){
			$first_PBS = 0;
			print OUT <<EndR;
  <tr>
    <th align="left"><span style="color:blue">PBS:</th>
    <td><span style="color:blue">Sequence</td>
	<td><span style="color:blue">Length</td>
	<td><span style="color:blue">Tm(&#176C)</td>
	<td><span style="color:blue">GC(%)</td>
  </tr>		
EndR
		}
		my $best_tm = "";
		my $best_color = "black";
		if(exists($values[4])){
			$best_tm = "Recommended!";
			$best_color = "red";
		}
		print OUT <<EndR;	
  <tr>
    <td><span style="color:$best_color">$best_tm</td>
	<td><span style="color:$best_color">$values[0]</td>
	<td><span style="color:$best_color">$values[1]</td>
	<td><span style="color:$best_color">$values[2]</td>
	<td><span style="color:$best_color">$values[3]</td>
  </tr>	
EndR
	}
	if($key eq "RT:"){
		if($first_RT == 1){
			$first_RT = 0;
			print OUT <<EndR;
  <tr>
    <th align="left"><span style="color:blue">RT template:</th>
	<td><span style="color:blue">Sequence</td>	
	<td><span style="color:blue">Length</td>	
  </tr>
EndR
		}
		my $best_rt = "";
		my $best_color = "black";
		if(exists($values[2])){
			$best_rt = "Recommended!";
			$best_color = "red";
		}
		print OUT <<EndR;	
  <tr>
    <td><span style="color:$best_color">$best_rt</td>
	<td><span style="color:$best_color">$values[0]</td>
	<td><span style="color:$best_color">$values[1]</td>
	<td></td>
	<td></td>
  </tr>
EndR
	}
	if($key eq "UpstreamPrimer:"){
		print OUT <<EndR;	
  <tr>
    <th align="left"><span style="color:blue">Primers (Recommended):</th>
  </tr>
  <tr>
    <td colspan="1"><span style="color:#7A09FA">Forward primer (5'-3')</td>
	<td colspan="4"><span style="color:black">$values[0]</td>
  </tr>
EndR
	}
	if($key eq "DownstreamPrimer:"){
		print OUT <<EndR;	
  <tr>
	<td colspan="1"><span style="color:#7A09FA">Reverse primer (5'-3')</td>
	<td colspan="4"><span style="color:black">$values[0]</td>
  </tr>
EndR
	}
}

print OUT <<EndR;
</div>

<div id="footer">
Welcome to our website
<br/>
<!--Welcome To 804 Group	
<form action="./index.CRISPR.php" method="post">
<input type="hidden" name="login_out" value="yes"/>
<input type="submit" value="Login OUT"/>
</form>
-->
</div>
</body>
</html>
EndR


close(IN);
close(OUT);




sub Test_PAM{
	my ($input_Sequence) = @_;
	if($input_Sequence eq "User_Defined"){
		print OUT "Wrong:\tEmpty pam sequence!";
		die;
	}
#	print "$input_Sequence\n";
	if($input_Sequence =~/[^atcgATCGrymkswhbvdnRYMKSWHBVDN]/){
		print OUT "Wrong:\tWrong pam sequence of $input_Sequence!";
		die;
	}
}

sub Test_Sequence{
	my ($input_Sequence) = @_;
	my $test1 = $input_Sequence;
	my @arrays_temp = split(/\(|\)/, $input_Sequence);
	my ($left, $target, $right) = split(/\(|\)/, $input_Sequence);
	if(@arrays_temp != 3){
		print OUT "Wrong:\tformat should be aaa(a/t)ggg!";
		die;
	}
	#Minimal left and right length cutoff
	if($left =~/[^atcgATGC]/){
		print OUT "Wrong:\t$left contains $&!";
		die;
	}
	if($right =~/[^atcgATGC]/){
		print OUT "Wrong:\t$right contains $&!";
		die;
	}
	if(length($left) < $left_cutoff){
		print OUT "Wrong:\tLeft flanking sequence is too short! (<$left_cutoff)";
		die;
	}	
	if(length($right) < $right_cutoff){
		print OUT "Wrong:\tRight flanking sequence is too short! (<$right_cutoff)";
		die;
	}
	my ($ref, $alt) = split(/\//, $target);
	if($ref =~/[^atcgATGC]/){
		print OUT "Wrong:\t$ref contains $&!";
		die;
	}
	if($alt =~/[^atcgATGC]/){
		print OUT "Wrong:\t$alt contains $&!";
		die;
	}
	if($ref eq $alt){
		print OUT "Wrong:\t$ref eq $alt\n";
		die;
	}
}

sub Ref_Alt{
	my $seq = $_[0];
	my ($left, $target, $right) = split(/\(|\)/, $seq);
	$left = lc($left);
	$target = uc($target);
	$right = lc($right);
	my ($ref, $alt) = split(/\//, $target);
	my $ref_full = $left.$ref.$right;
	my $alt_full = $left.$alt.$right;
	return $ref_full, $alt_full, length($left), length($right), length($ref), length($alt);
}

sub Rev_com{
	my ($temp) = @_;
	my @arrays = split(//, $temp);
	my %rev;
	$rev{"A"} = "T";
	$rev{"T"} = "A";
	$rev{"C"} = "G";
	$rev{"G"} = "C";
	$rev{"a"} = "t";
	$rev{"t"} = "a";
	$rev{"c"} = "g";
	$rev{"g"} = "c";
	$rev{"("} = ")";
	$rev{")"} = "(";
	$rev{"/"} = "/";
	my $result = "";
	for(my $i = @arrays - 1; $i >= 0; $i --){
		if(!exists($rev{$arrays[$i]})){
			$result .= $arrays[$i];
			print OUT "Wrong:\tCannot find reverse complement of $arrays[$i]\n";
			die;
		}
		else{
			$result .= $rev{$arrays[$i]};
		}		
	}
	return $result;
}

sub FindAllPam{
	my ($RefSeq, $PAM, $OnTargetLength, $CutToPAM) = @_;
#	print "$RefSeq, $PAM, $OnTargetLength, $CutToPAM\n";#Testing
	my @PAMs = split(//, $PAM);
	my @Results; #Forward_or_Reverse; OnTargetSeq; PAMSeq; Cut Position
	my $forward = 1;
	{#Forward
		my @arrays = split(//, $RefSeq);
		for(my $i = 0; $i < @arrays - $OnTargetLength - @PAMs; $i ++){
			my $match = 1;
			for (my $j = 0; $j < @PAMs; $j ++){
				my $a = $arrays[$i + $OnTargetLength + $j];
				my $b = $PAMs[$j];
				if(!Match($b,$a)){
					$match = 0;
				}				
#			print "$i, $j, $a, $b, $match\n";#Testing
			}
			if($match == 1){
				my $OnTargetSeq = "";
				for(my $j = 0; $j < $OnTargetLength; $j ++){
					$OnTargetSeq .= "$arrays[$i+$j]";
				}
				my $PAMSeq = "";
				for(my $j = 0; $j < @PAMs; $j ++){
					$PAMSeq .= "$arrays[$i + $OnTargetLength + $j]";
				}
				my $Cut_Position = $i + $OnTargetLength + $CutToPAM;
#				print "$i + $OnTargetLength + $CutToPAM\n";
				my $result = "$OnTargetSeq;$PAMSeq;$Cut_Position";
				$Results[@Results] = $result;
			}
		}
	}
	return @Results;
}

sub Match{
	my ($a, $b) = @_;
	my $result = 0;
	$a = lc($a);
	$b = lc($b);
	my %match = (
'a' => {'a' => 1},
't' => {'t' => 1},
'c' => {'c' => 1},
'g' => {'g' => 1},
'r' => {'a' => 1, 'g' => 1},
'y' => {'c' => 2, 't' => 2},
'm' => {'a' => 3, 'c' => 3},
'k' => {'g' => 4, 't' => 4},
's' => {'g' => 5, 'c' => 5},
'w' => {'a' => 6, 't' => 6},
'h' => {'a' => 7, 't' => 7, 'c' => 7},
'b' => {'g' => 8, 't' => 8, 'c' => 8},
'v' => {'g' => 9, 'a' => 9, 'c' => 9},
'd' => {'g' => 10, 'a' => 10, 't' => 10},
'n' => {'a' => 11, 't' => 11, 'c' => 11, 'g' => 11},
);
	if(exists($match{$a}{$b})){
#		print "$a\t$b\n";
		$result = 1;
	}
	return $result;
}

sub Filter_GC_PAM{
	my ($PAM_GC, @arrays) = @_;
	my ($GC_left, $GC_right) = split(/\-/, $PAM_GC);
	my @Results;
	for(my $i = 0; $i < @arrays; $i ++){
		my ($OnTargetSeq, $PAMSeq, $Cut_Position) = split(/\;/, $arrays[$i]);
		my $OnTargetGC = GC($OnTargetSeq) * 100;
#		print "$OnTargetSeq\t$OnTargetGC\n";
		if($OnTargetGC >= $GC_left && $OnTargetGC <= $GC_right){
			$Results[@Results] = "$arrays[$i]";
		}
	}
	return @Results;
}

sub Filter_PE_Window{
	my ($PE_Window, $length_left, @arrays) = @_;
	my @Results;
	my ($PE_left, $PE_Right) = split(/\-/, $PE_Window);
	for(my $i = 0; $i < @arrays; $i ++){
		my ($OnTargetSeq, $PAMSeq, $Cut_Position) = split(/\;/, $arrays[$i]);
#		print "if($Cut_Position + $PE_left -1 <= $length_left && $Cut_Position + $PE_Right -1 > $length_left){\n";
		if($Cut_Position + $PE_left -1 <= $length_left && $Cut_Position + $PE_Right -1 > $length_left){
			my $left_distance_to_cut = $length_left - $Cut_Position;#distance from cut to the replacing site
			$Results[@Results] = "$arrays[$i];$left_distance_to_cut";
		}
	}
	return @Results;
}

sub TM{
	my $input = $_[0];
	$input = lc($input);
	my @arrays = split(//, $input);
	my $TM = 0;
	for(my $i = 0; $i < @arrays; $i ++){
		if($arrays[$i] eq "a" || $arrays[$i] eq "t"){
			$TM += 2;
		}
		elsif($arrays[$i] eq "c" || $arrays[$i] eq "g"){
			$TM += 4;
		}
		else{
			print "Warning: Cannot calculate TM for $arrays[$i]\n";
			return 0;
		}
	}
	return $TM;
}

sub GC{
	my $input = $_[0];
	$input = lc($input);
	my @arrays = split(//, $input);
	my $GC = 0;
	my $AT = 0;
	for(my $i = 0; $i < @arrays; $i ++){
		if($arrays[$i] eq "a" || $arrays[$i] eq "t"){
			$AT ++;
		}
		elsif($arrays[$i] eq "c" || $arrays[$i] eq "g"){
			$GC ++;
		}
		else{
			print "Warning: Cannot calculate CG content for $arrays[$i]\n";
			return 0;
		}
	}
	my $GC_content = int($GC / ($GC + $AT) * 1000)/1000;
	return $GC_content;
}
