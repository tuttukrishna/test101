$path = "c:\Users\tuttu\OneDrive\Desktop\index-with-admin-1.html"
$lines = [System.IO.File]::ReadAllLines($path)
$outLines = @()

$skip = $false
$bracketCount = 0

foreach ($line in $lines) {
    if (-not $skip) {
        if ($line.Trim().StartsWith("const PROPERTIES = [") -or 
            $line.Trim().StartsWith("const AGENT_BOOKINGS = [") -or 
            $line.Trim().StartsWith("const TOUR_PACKAGES = [") -or 
            $line.Trim().StartsWith("const ADMIN_USERS = [") -or 
            $line.Trim().StartsWith("const ADMIN_LISTINGS_DATA = [") -or 
            $line.Trim().StartsWith("const ADMIN_ALL_BOOKINGS = [") -or
            $line.Trim().StartsWith("let SAVED_ITEMS = [") -or
            $line.Trim().StartsWith("const SAVED_ITEMS = [")) {
            
            $skip = $true
            $bracketCount = ($line.Length - $line.Replace("[", "").Length) - ($line.Length - $line.Replace("]", "").Length)
            
            # extract variable name (e.g., 'PROPERTIES')
            $parts = $line.Trim() -split "\s+"
            $varName = $parts[1]
            $outLines += "let $varName = [];"
            
            if ($bracketCount -eq 0) {
                $skip = $false
            }
            continue
        }
        $outLines += $line
    } else {
        $bracketCount += ($line.Length - $line.Replace("[", "").Length) - ($line.Length - $line.Replace("]", "").Length)
        if ($bracketCount -eq 0) {
            $skip = $false
        }
    }
}

[System.IO.File]::WriteAllLines($path, $outLines, [System.Text.Encoding]::UTF8)
