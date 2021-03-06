Function Format-DiskSize() {
    [cmdletbinding()]
    Param ([long]$Type)
    If ($Type -ge 1TB) {[string]::Format("{0:0.00} TB", $Type / 1TB)}
    ElseIf ($Type -ge 1GB) {[string]::Format("{0:0.00} GB", $Type / 1GB)}
    ElseIf ($Type -ge 1MB) {[string]::Format("{0:0.00} MB", $Type / 1MB)}
    ElseIf ($Type -ge 1KB) {[string]::Format("{0:0.00} KB", $Type / 1KB)}
    ElseIf ($Type -gt 0) {[string]::Format("{0:0.00} Bytes", $Type)}
    Else {""}
} # End of function



function Invoke-CleanDriverStore(){
    [cmdletbinding()]
    Param (
        [string]$Path
    )
    
    #Get the starting File Size
    $StartSize = (Get-ChildItem $Path -recurse | Measure-Object -property length -sum).Sum

    #----------------------------------

    #ToDo: Replace multiple Get-ChildItems with one loop and if statements to process accordingly.

    #Remove the Driver Files We don't need
    #region
    $WantedExtensions = @(
        "*.dll",
        "*.inf",
        "*.ocx",
        "*.vxd",
        "*.sys",
        "*.cat"
    )


    Get-ChildItem -Path $Path -Recurse | Where-Object {-not $_.PSIsContainer} | ForEach-Object {
        $Wanted = $false
        foreach($WantedExtension in $WantedExtensions){
            if(($_.Extension -like $WantedExtension)){
                $Wanted = $true
            }
        }
        
        if(-not $Wanted){
            #Write-Host $_.FullName
            Remove-Item -Path $_.FullName
        }
    }
    #endregion

    #Remove the Folders we don't want
    #region
    $UnwantedDriverTypes = @(
        "Keyboard", # We use the default keyboard driver
        "Keyboards",
        "Mouse", # We use the mouse drivers
        "Mice and other pointing devices",
        "Mice",
        "Display", # We'll use the default display drivers or manually add the OEM driver seprately
        "Display adapters",
        "Printers", # No need to keep printer drivers in our pack as they are managed with a print server
        "Printer", # No need to keep printer drivers in our pack as they are managed with a print server
        "WPD", # Windows Portable Device (WPD) driver (AKA Phones)
        "Realtek High Definition Audio", # Yes Realtek drivers should not be needed unless the customer requires more than default stero setups
        "Apple Mobile Device USB Driver", # Hopefully people aren't stupid enought to plug their phones into their work computer.....
        "Silicon Labs CP210x USB to UART Bridge" # Specific Removal: We don't need UART drivers
    )
    Get-ChildItem -Path $Path -Recurse | Where-Object { $_.PSIsContainer} | ForEach-Object {
        $UnWanted = $false
        foreach($UnwantedDriverType in $UnwantedDriverTypes){
            
            if(($UnwantedDriverType -like $_.Name)){
                $UnWanted = $true
            }
        }
        
        if($UnWanted){
            #Write-Host $_.FullName
            Remove-Item -Path $_.FullName -Recurse -Force
        }
        
    }
    #endregion

    #Remove the Wireless/WiFi/Bluetooth Adapter if it exists
    #region
    Get-ChildItem -Path $Path -Recurse | Where-Object { $_.PSIsContainer -and ($_.Name -eq "Net" -or $_.Name -eq "Network Adapters")} | ForEach-Object {
        
        #For Every Network Folder Check the INF to see if it is Wireless or not.
        Get-ChildItem -Path $_.FullName -Recurse | Where-Object {$_.Extension -match ".inf" } | ForEach-Object {
            #Get the number of times Wireless/WiFi/Bluetooth appears in the INF file
            $Count = @( Get-Content -Path $_.FullName | Where-Object { $_.Contains("Wireless") -or $_.Contains("WiFi") } ).Count
        }

        #If the count of Wireless/WiFi/Bluetooth in the file is more than 0 this is a dirver we don't want
        if($count -gt 0){
            Remove-Item -Path $_.FullName -Recurse -Force
        }
    }
    #endregion

    #Remove blank lines and commented lines in INF files to save even more space
    #Yes this is stupid but it will save a little more space....

    #region
    Get-ChildItem -Path $Path -Recurse | Where-Object { $_.Extension -like ".inf"} | ForEach-Object {
            #Write-Host $_.FullName
            $FileContent = Get-Content -Path $_.FullName

            $FileContent = $FileContent -replace "`0", '';
            $FileContent = $FileContent | Where-Object{$_ -match '[\w]+'};

            $FileContent = $FileContent -replace '(^;.*)',""
            #$FileContent = $FileContent | Where-Object {$_.trim() -ne ""}
            $FileContent | Set-Content $_.FullName
    }
    #endregion

    #Remove Empty Folders because why keep them?
    #region
    $dirs = Get-ChildItem -Path $Path -Recurse | Where-Object { $_.PSIsContainer } | Where-Object { (Get-ChildItem $_.FullName -Force).count -eq 0 } | Select-Object -expandproperty FullName
    $dirs | Foreach-Object { 
        Remove-Item $_ -Force
    }
    #endregion

    #----------------------------------



    $AfterSize = (Get-ChildItem $Path -recurse | Measure-Object -property length -sum).Sum


    $SizeDifference = Format-DiskSize ($StartSize - $AfterSize)

    $BeforeSize = Format-DiskSize $StartSize
    $AfterSize = Format-DiskSize $AfterSize

    Write-Host "Before Size: $($BeforeSize)"
    Write-Host "After Size: $($AfterSize)"
    Write-Host "Difference: $($SizeDifference)"

}