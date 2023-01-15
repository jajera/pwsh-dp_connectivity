function Test-Port {
    Param(
        [parameter(ParameterSetName = 'HostDevice', Position = 0)]
        [string]
        $HostDevice,
        [parameter(Mandatory = $true , Position = 1)]
        [int]
        $Port
    )
    $test = New-Object System.Net.Sockets.TcpClient;
    Try { $test.Connect($HostDevice, $Port); Return $True }
    Catch { Return $False }
    Finally { $test.Dispose() }
}

function Test-DNS {
    Param(
        [parameter(ParameterSetName = 'HostDevice', Position = 0)]
        [string]
        $HostDevice
    )
    Try { Resolve-DnsName $HostDevice -ErrorAction Stop | Out-Null; Return $True }
    Catch { Return $False }
}

function Write-Log {
    Param(
        [string]$StringLine,
        [bool]$errDet
    )

    $fPathOK = ".\$(Get-Date -Format yyyy-MM-dd)-OK.txt"
    $fPathNG = ".\$(Get-Date -Format yyyy-MM-dd)-NG.txt"

    if ($errDet -eq $False) 
    { $StringLine | Out-File $fPathOK -Append }
    else { $StringLine | Out-File $fPathNG -Append }
}

$cmsiteInfo = Get-Content .\cmsite_config.json | Out-String | ConvertFrom-Json
$SiteServer = $cmsiteInfo.site.server
$SCode = $cmsiteInfo.site.code
#$DPs = Get-WmiObject -Namespace "ROOT\SMS\site_$SCode" -ComputerName $SiteServer -Query "SELECT DISTINCT Name FROM SMS_DistributionDPStatus"
$DPs = Get-WmiObject -Namespace "ROOT\SMS\site_$SCode" -ComputerName $SiteServer -Query "SELECT DISTINCT Name FROM SMS_DistributionDPStatus Where SiteCode = '$SCode'"
$iDPCount = $DPs.Count
$iDPCount = 2
$iCount = 0
[bool]$errStart = $False
Clear-Host
Write-Host "*****START OF CONNECTIVTY TEST ON ALL DPs*****" -ForegroundColor Cyan
foreach ($DP in $DPs.Name) {
    Write-Host "START of test on $DP" 
    if ((Test-DNS $DP) -eq $False) { 
        $errStart = $true
        Write-Host "  DNS Query = fail" -ForegroundColor Red 
        Write-Log "$DP - DNS Query = fail" $errStart
    }
    else {
        Write-Host "  DNS Query = pass" -ForegroundColor Green
        Write-Log "$DP - DNS Query = pass" $errStart
        if ((Test-Port -HostDevice $DP -Port 135) -eq $False) { 
            $errStart = $true
            Write-Host "  TCP 135 = fail" -ForegroundColor Red
            Write-Log "$DP - TCP 135 = fail" $errStart
        }
        else { 
            Write-Host "  TCP 135 = pass" -ForegroundColor Green 
            Write-Log "$DP - TCP 135 = pass" $errStart
        }
		
        if ((Test-Port -HostDevice $DP -Port 445) -eq $False) {
            $errStart = $true 
            Write-Host "  TCP 445 = fail" -ForegroundColor Red
            Write-Log "$DP - TCP 445 = fail" $errStart   
        }
        else { 
            Write-Host "  TCP 445 = pass" -ForegroundColor Green 
            Write-Log "$DP - TCP 445 = pass" $errStart  
        }

        try { 
            Get-WmiObject -Namespace "ROOT\cimv2" -Query "SELECT * FROM Win32_ComputerSystem" -ComputerName $DP -ErrorAction Stop | Out-Null
            Write-Host "  Remote WMI = pass" -ForegroundColor Green
            Write-Log "$DP - Remote WMI = pass" $errStart  
        }
        catch {
            $errStart = $true
            if ($Error[0] -match "0x80070005") { 
                Write-Host "  Remote WMI = Access Denied" -ForegroundColor Red 
                Write-Log "$DP - Remote WMI = Access Denied" $errStart  
            }
            elseif ($Error[0] -match "0x800706BA") { 
                Write-Host "  Remote WMI = RPC Unavailable" -ForegroundColor Red 
                Write-Log "$DP - Remote WMI = RPC Unavailable" $errStart  
            }
            else { 
                Write-Host "  Remote WMI = Unknown Error" -ForegroundColor Red 
                Write-Log "$DP - Remote WMI = Unknown Error" $errStart  
            }
        }
    }
    Write-Host "END of test on $DP" 
    Write-Host ""
    $iCount += 1
    Write-Progress -Activity "Connectivity Test" -Status "DP Count: $iCount" -PercentComplete ($iCount / $iDPCount * 100)
    $errStart = $false
}
Write-Host "*****END OF CONNECTIVTY TEST ON ALL DPs*****" -ForegroundColor Cyan
