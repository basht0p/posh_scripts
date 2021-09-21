$StartTime = (Get-Date)

function createDT()
{
    $tmpTable = New-Object System.Data.DataTable
   
    $c0 = New-Object System.Data.DataColumn("Name")
    $c1 = New-Object System.Data.DataColumn("Model")
    $c2 = New-Object System.Data.DataColumn("OS")
    $c3 = New-Object System.Data.DataColumn("OS Build")
    $c4 = New-Object System.Data.DataColumn("CPU Cores")
    $c5 = New-Object System.Data.DataColumn("RAM")
    $c6 = New-Object System.Data.DataColumn("Uptime (days)")
    $c7 = New-Object System.Data.DataColumn("Disk 1 Label")
    $c8 = New-Object System.Data.DataColumn("Disk 1 Total")
    $c9 = New-Object System.Data.DataColumn("Disk 1 Free")
    $c10= New-Object System.Data.DataColumn("Disk 2 Label")
    $c11= New-Object System.Data.DataColumn("Disk 2 Total")
    $c12= New-Object System.Data.DataColumn("Disk 2 Free")
              
    $tmpTable.columns.Add($c0)
    $tmpTable.columns.Add($c1)
    $tmpTable.columns.Add($c2)
    $tmpTable.columns.Add($c3)
    $tmpTable.columns.Add($c4)
    $tmpTable.columns.Add($c5)
    $tmpTable.columns.Add($c6)
    $tmpTable.columns.Add($c7)
    $tmpTable.columns.Add($c8)
    $tmpTable.columns.Add($c9)
    $tmpTable.columns.Add($c10)
    $tmpTable.columns.Add($c11)
    $tmpTable.columns.Add($c12)
    return ,$tmpTable
}

[System.Data.DataTable]$dTable = createDT

$srvs = (Get-ADComputer -Filter * -Properties * | where {`
($_.OperatingSystem -like "*Server*") -and `
($_.Enabled -eq $true) -and `
($_.LastLogonDate -ge ($(Get-Date).AddDays(-30)))})

$regQ = {((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' –Name UBR).UBR)}

foreach($srv in $srvs)
{
    Write-Host "Querying info from " -NoNewLine
    Write-Host "$($srv.Name)" -ForegroundColor Red

    $diskCol = @(Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" -ComputerName $srv.Name)
    $procCrs = (Get-WmiObject Win32_Processor -ComputerName $srv.Name | Select *).NumberOfLogicalProcessors
    $uptime = ($(Get-Date) - $((Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $srv.Name).LastBootUpTime))

    $row = $dTable.NewRow()
    $row["Name"]          = $srv.Name
    $row["Model"]         = ((Get-WmiObject Win32_ComputerSystem -ComputerName $srv.Name).Model)
    $row["OS"]            = $srv.OperatingSystem
    $row["OS Build"]      = $((Get-WmiObject Win32_OperatingSystem -ComputerName $srv.Name).Version) + '.' + $((Invoke-Command -ScriptBlock $regQ -ComputerName $srv.Name))
    $row["CPU Cores"]     = $procCrs[0] + $procCrs[1]
    $row["RAM"]           = [Math]::Round(($(Get-WMIObject Win32_ComputerSystem -ComputerName $srv.Name).TotalPhysicalMemory / 1gb), 2 )
    $row["Uptime"]        = $($uptime.Days).ToString() + "d " + $($uptime.Hours).ToString() + "h " + $($uptime.Minutes).ToString() + "m"
    $row["Disk 1 Label"]  = $diskCol[0].Name
    $row["Disk 1 Total"]  = [Math]::Round(($diskCol[0].Size / 1gb), 2 )
    $row["Disk 1 Free"]   = [Math]::Round(($diskCol[0].FreeSpace / 1gb), 2 )
    $row["Disk 2 Label"]  = $diskCol[1].Name
    $row["Disk 2 Total"]  = [Math]::Round(($diskCol[1].Size / 1gb), 2 )
    $row["Disk 2 Free"]   = [Math]::Round(($diskCol[1].FreeSpace / 1gb), 2 )
    
    $dTable.rows.Add($row)

    $row     = $null
    $diskCol = $null
    $srv     = $null
    $procCrs = $null
}

$EndTime = (Get-Date)

Write-Host "Script runtime: " -NoNewline
Write-Host (($EndTime-$StartTime).Hours.ToString()+"h "+($EndTime-$StartTime).Minutes.ToString()+ "m "+($EndTime-$StartTime).Seconds.ToString()+ "s")

$dTable | Out-GridView
$dTable | Export-CSV C:\boig_results.csv
