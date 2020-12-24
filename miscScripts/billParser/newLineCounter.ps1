$fileToBill=$args[0]
$lineCount = 0
$myString=" "
$billFile="$fileToBill.bill"

foreach($line in Get-Content $fileToBill) 
{
	# Need to set value of line in string
	$myString = $line
	
	# Logic to check for ';'
	$semiColonIndex = $myString.IndexOf(";")
	if ($semiColonIndex -ne -1) {
	
		$lineCount++
	
	}
	
	#Logic to check for '('
	$openParenIndex = $myString.IndexOf("(")
	if ($openParenIndex -ne -1) {
	
		$lineCount++
	
	}
	
	#Logic to check for ')'
	$closeParenIndex = $myString.IndexOf(")") 
	if ($closeParenIndex -ne -1) {
	
		$lineCount++
	
	}
	
}

echo "Total lines billable for $fileToBill are $lineCount" > $billFile
