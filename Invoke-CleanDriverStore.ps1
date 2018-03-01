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
    $WantedExtensions = @(
        "*.dll",
        "*.inf",
        "*.ocx",
        "*.vxd",
        "*.sys",
        "*.cat"
    )


    Get-ChildItem -Path $Path -Recurse | Where-Object {-not $_.PSIsContainer} | For-EachObject {
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

    #Remove the Folders we don't want
    $UnwantedDriverTypes = @(
        "Keyboard", # We use the default keyboard driver
        "Mouse", # We use the mouse drivers
        "Display", # We'll use the default display drivers or manually add the OEM driver seprately
        "Printers", # No need to keep printer drivers in our pack as they are managed with a print server
        "Printer", # No need to keep printer drivers in our pack as they are managed with a print server
        "WPD", # Windows Portable Device (WPD) driver (AKA Phones)
        "Realtek High Definition Audio", # Yes Realtek drivers should not be needed unless the customer requires more than default stero setups
        "Apple Mobile Device USB Driver", # Hopefully people aren't stupid enought to plug their phones into their work computer.....
        "Silicon Labs CP210x USB to UART Bridge" # Specific Removal: We don't need UART drivers
    )
    Get-ChildItem -Path $Path -Recurse | Where-Object { $_.PSIsContainer} | For-EachObject {
        $Wanted = $false
        foreach($UnwantedDriverType in $UnwantedDriverTypes){
            if(($_.Name -like $UnwantedDriverType)){
                $Wanted = $true
            }
        }
        
        if($Wanted){
            #Write-Host $_.FullName
            Remove-Item -Path $_.FullName -Recurse -Force
        }
        
    }
    
    #Remove blank lines and commented lines in INF files to save even more space
    #Yes this is stupid but it will save a little more space....
    Get-ChildItem -Path $Path -Recurse | Where-Object { $_.Extension -like ".inf"} | For-EachObject {
            Write-Host $_.FullName
            $FileContent = Get-Content -Path $_.FullName
            $FileContent = $FileContent -replace '(^;.*)',""
            $FileContent = $FileContent | Where-Object {$_.trim() -ne ""}
            $FileContent | Set-Content $_.FullName
    }

    #Remove Empty Folders because why keep them?
    $dirs = Get-ChildItem -Path $Path -Recurse | Where-Object { $_.PSIsContainer } | Where-Object { (Get-ChildItem $_.FullName -Force).count -eq 0 } | Select-Object -expandproperty FullName
    $dirs | Foreach-Object { 
        Remove-Item $_ -Force
    }
    
    
    #----------------------------------



    $AfterSize = (Get-ChildItem $Path -recurse | Measure-Object -property length -sum).Sum


    $SizeDifference = Format-DiskSize ($StartSize - $AfterSize)

    $BeforeSize = Format-DiskSize $StartSize
    $AfterSize = Format-DiskSize $AfterSize

    Write-Host "Before Size: $($BeforeSize)"
    Write-Host "After Size: $($AfterSize)"
    Write-Host "Difference: $($SizeDifference)"

}