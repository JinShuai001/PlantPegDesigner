<?php
	session_start();
/*
session_start();
if(@$_SESSION['Login'] != 'Yes'){
    header("Location: ../../../membership/index.php");
    exit();
}
*/
################################ Error Capture ###################

//error handler function

	function customError($errno, $errstr) {
	  echo "<b>Error:</b> [$errno] $errstr";
	}

	//set error handler
	set_error_handler("customError");


############## to judge whether the input is empty ##############
	$search = $_POST['search'];
	$PAM = $_POST['PAM'];
	$User_PAM = $_POST['User_PAM'];
	$CutToPAM = $_POST['CutToPAM'];
	$OnTargetLength = $_POST['OnTargetLength'];
	$PE_window_min = $_POST['PE_window_min'];
	$PE_window_max = $_POST['PE_window_max'];
	$PBS_Length_min = $_POST['PBS_Length_min'];
	$PBS_Length_max = $_POST['PBS_Length_max'];
	$PBS_CG_Content_min = $_POST['PBS_CG_Content_min'];
	$PBS_CG_Content_max = $_POST['PBS_CG_Content_max']	;	
	$TM_Best = $_POST['TM_Best'];
	$RT_Length_min = $_POST['RT_Length_min']	;
	$RT_Length_max = $_POST['RT_Length_max'];
	$Tm_model = 1 ;
	$Exclude_LastG_in_RT = 1	;	
	$OnTarget_CG_Content_min = $_POST['OnTarget_CG_Content_min'];
	$OnTarget_CG_Content_max = $_POST['OnTarget_CG_Content_max'];
	$CCNNGG_model = 1;
################### Primer ###################
	$Primer = $_POST['Primer'];
	$Forward_Primer_left = $_POST['Forward_Primer_left'];
	$Forward_Primer_right = $_POST['Forward_Primer_right'];
	$Reverse_Primer_left = $_POST['Reverse_Primer_left'];
	$Reverse_Primer_right = $_POST['Reverse_Primer_right'];
	if($Primer == 'OsU3'){
		$Forward_Primer_left = 'TTGTGCAGATGATCCGTGGCG';
		$Forward_Primer_right = 'GTTTTAGAGCTAGAAATA';
		$Reverse_Primer_left = 'CTATGACCATGATTACGCCAAGCTTAAAAAAA';
		$Reverse_Primer_right = 'GCACCGACTCGGTGCCAC';		
	}
	elseif($Primer == 'TaU3'){
		$Forward_Primer_left = 'AGGCGCGGCACCAAGAAGCG';
		$Forward_Primer_right = 'GTTTTAGAGCTAGAAATA';
		$Reverse_Primer_left = 'ATTATGGAGAAACTCGAGCCATGGAAAAAAA';
		$Reverse_Primer_right = 'GCACCGACTCGGTGCCACTT';		
	}
	elseif($Primer == 'TaU6'){
		$Forward_Primer_left = 'CTTGCTGCATCAGACTTG';
		$Forward_Primer_right = 'GTTTTAGAGCTAGAAATAGC';
		$Reverse_Primer_left = 'TGGCCGATTCATTAATGCAGGGTACCAAAAAAA';
		$Reverse_Primer_right = 'GCACCGACTCGGTGCCACTT';		
	}
	elseif($Primer == 'pHn-Cas9-V2'){
		$Forward_Primer_left = 'TTGTGCAGATGATCCGTGGCG';
		$Forward_Primer_right = 'GTTTTAGAGCTAGAAATA';
		$Reverse_Primer_left = 'ACGCTGCACTGCAGGCATGCAAGCTTAAAAAAA';
		$Reverse_Primer_right = 'GCACCGACTCGGTGCCAC';		
	}
	else{
		
	}

#################### END ####################
//error handling
	if($PAM == 'User_Defined'){
		if(isset($User_PAM) and ($User_PAM)){
			$PAM = $User_PAM;
		}
	}


	if((!isset($search)) || (!isset($PAM)) || (!isset($CutToPAM)) || (!isset($OnTargetLength)) || (!isset($PE_window_min)) || (!isset($PE_window_max)) || (!isset($PBS_Length_min)) || (!isset($PBS_CG_Content_max)) || (!isset($PBS_CG_Content_min)) || (!isset($TM_Best)) || (!isset($RT_Length_min)) || (!isset($RT_Length_max)) || (!isset($OnTarget_CG_Content_min)) ||(!isset($OnTarget_CG_Content_max))){
		$message = "Please insert all fields in the form below!";
	}else{
		if(!isset($_POST['Tm_model'])){
			$Tm_model = 'False';
		}
		else{
			$Tm_model = $_POST['Tm_model'];	
		}		
		if(!isset($_POST['Exclude_LastG_in_RT'])){
			$Exclude_LastG_in_RT = 'False';
		}
		else{
			$Exclude_LastG_in_RT = $_POST['Exclude_LastG_in_RT'];	
		}		   
		if(!isset($_POST['CCNNGG_model'])){
			$CCNNGG_model = 'False';
		}	
		else{
			$CCNNGG_model = $_POST['CCNNGG_model'];	
		}
		
	}
//echo "$search";
#################### Judge batch handling or seq query #####################
//	echo $searchq;
	if(isset($_FILES['uploadedFile']) && $_FILES['uploadedFile']['error'] === UPLOAD_ERR_OK){
//		echo "OK\n";die("test proved");
//		get details of the uploaded file
		$fileTmpPath = $_FILES['uploadedFile']['tmp_name'];
		$fileName = $_FILES['uploadedFile']['name'];
		$fileSize = $_FILES['uploadedFile']['size'];
		$fileType = $_FILES['uploadedFile']['type'];
		$fileNameCmps = explode(".", $fileName);
		$fileExtension = strtolower(end($fileNameCmps));
//		echo "$fileTmpPath\n$fileName\n$fileSize\n$fileType\n$fileNameCmps\n$fileExtension\n";
		$newFileName = md5(time() . $fileName) . '.' . $fileExtension;
//		echo "New file name is $newFileName"."<br/>";
		$uploadFileDir = './uploaded_files/';
		$dest_path = $uploadFileDir . $newFileName;
		if(move_uploaded_file($fileTmpPath, $dest_path))
		{
		  $_SESSION['message'] ='File is successfully uploaded.';
		}
		else
		{
		   $_SESSION['message'] = 'There was some error moving the file to upload directory. Please make sure the upload directory is writable by web server.';
		}
//		echo $_SESSION['message']."<br/>";
################## Two Input file ############################		
		$parameter = $dest_path;
		$parameter = preg_replace("/$fileExtension$/","para",$parameter);
		$result1 = $dest_path;
		$result1 = preg_replace("/$fileExtension$/","html",$result1);
		$result2 = $dest_path;
		$result2 = preg_replace("/$fileExtension$/","txt",$result2);
		
//		$php_file = $dest_path;
//		$php_file = preg_replace("/$fileExtension$/","php",$php_file);
		$download = $dest_path;
		$download = preg_replace("/$fileExtension$/","download.php",$download);
		echo $download;
		
		exec("echo 'Input_Sequence\t$search\nPAM\t$PAM\nCutToPAM\t$CutToPAM\nOnTargetLength\t$OnTargetLength\nPE_Window\t$PE_window_min-$PE_window_max\nPBS_Length\t$PBS_Length_min-$PBS_Length_max\nPBS_CG_Content\t$PBS_CG_Content_min-$PBS_CG_Content_max\nTM_Best\t$TM_Best\nRT_Length\t$RT_Length_min-$RT_Length_max\nTm_model\t$Tm_model\nExclude_LastG_in_RT\t$Exclude_LastG_in_RT\nOnTarget_CG_Content\t$OnTarget_CG_Content_min-$OnTarget_CG_Content_max\nCCNNGG_model\t$CCNNGG_model\nUpstreamPrimer5\t$Forward_Primer_left\nUpstreamPrimer3\t$Forward_Primer_right\nDownstreamPrimer5\t$Reverse_Primer_left\nDownstreamPrimer3\t$Reverse_Primer_right' >> $parameter",$info);
######################## END ###########################
		passthru("perl PlantPegDesigner_multiple.pl $parameter $dest_path $result1 $result2");	
		
######################### download file ###############################	
		$result1dir = preg_replace("/\.\/uploaded_files\//","",$result1);
		$result2dir = preg_replace("/\.\/uploaded_files\//","",$result2);

		$currentdw = file_get_contents("format.download.php");
		$currentdw = preg_replace("/php_and_mysql_for_dummies_4th_edition.pdf/","$result2dir",$currentdw);
//		str_replace('php_and_mysql_for_dummies_4th_edition.pdf', "$newFileName", $currentdw);	
//		str_replace("register.php", "$result2", $current);
		file_put_contents($download, $currentdw);	
		$download = preg_replace("/\.\/uploaded_files\//","",$download);
############################# END #######################################
		
################ Presentation Page ##################################		
		$current = file_get_contents("$result1");
		$current = preg_replace("/login.php/","$download",$current);
//		$current = preg_replace("/register.php/","$result1",$current);
//		str_replace('login.php', "$download", $current);	
//		str_replace('register.php', "$result1", $current);
		file_put_contents($result1, $current);
		header("Location: $result1");
#########################################################################
		
################ Output file ###########################################
//		$file = fopen ( $result2, "r" );    
		//输入文件标签     
//		Header ( "Content-type: application/octet-stream" );    
//		Header ( "Accept-Ranges: bytes" );    
//		Header ( "Accept-Length: " . filesize ( $result2 ) );    
//		Header ( "Content-Disposition: attachment; filename=" . $result2 );    
		//输出文件内容     
		//读取文件内容并直接输出到浏览器    
//		echo fread ( $file, filesize ( $result2 ) );    
//		fclose ( $file ); 
//		header("Refresh: 3; url = ./batch.php"); 
#################### END ######################################		
	}
	else{
		if($search == ""){
			header("Location: index.html");
			exit();	
		}	
		$search = preg_replace("/\ |\n|\r/","",$search);
// echo "$search";
		$filename = date("Y-m-d_H:i:s");
		$file_dir = "./query/";
		$filename = $file_dir.$filename;
		if(file_exists($filename)){
			$filename .= '_'.rand();
			$filename .= '.fa';
		}
		else{
			$filename .= '.fa';
		}
		exec("echo 'Input_Sequence\t$search\nPAM\t$PAM\nCutToPAM\t$CutToPAM\nOnTargetLength\t$OnTargetLength\nPE_Window\t$PE_window_min-$PE_window_max\nPBS_Length\t$PBS_Length_min-$PBS_Length_max\nPBS_CG_Content\t$PBS_CG_Content_min-$PBS_CG_Content_max\nTM_Best\t$TM_Best\nRT_Length\t$RT_Length_min-$RT_Length_max\nTm_model\t$Tm_model\nExclude_LastG_in_RT\t$Exclude_LastG_in_RT\nOnTarget_CG_Content\t$OnTarget_CG_Content_min-$OnTarget_CG_Content_max\nCCNNGG_model\t$CCNNGG_model\nUpstreamPrimer5\t$Forward_Primer_left\nUpstreamPrimer3\t$Forward_Primer_right\nDownstreamPrimer5\t$Reverse_Primer_left\nDownstreamPrimer3\t$Reverse_Primer_right' >> $filename",$info);
		$intermediate = $filename;
		$intermediate = preg_replace("/fa$/","intermediate",$intermediate);

		$result = $filename;
		$result = preg_replace("/fa$/","result",$result);
		// echo "$result<br/>";
		passthru("perl PlantPegDesigner.pl $filename $result");
//		$file_dir = "./query/";
//		$result = $file_dir.$result;
        $file = fopen( $result, "r" );
         
        if( $file == false ) {
            echo ( "Error in opening file" );
            exit();
        }
         
        $filesize = filesize( $result );
        $filetext = fread( $file, $filesize );
        fclose( $file );
         
//         echo ( "File size : $filesize bytes" );
        echo ( "$filetext" );		
		
    }
//	$search = preg_replace("/\s+$/","",$search);
//	$query_genes = preg_split("/\s+/",$search);


?>

