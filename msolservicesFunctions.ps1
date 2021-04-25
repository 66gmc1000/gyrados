##----------------------------------------------------------------------------------------------------##
####################################------- Common Functions -------####################################
##                                                                                                    ##
## ----------------------------------------- MSOLServices -------------------------------------------_##
function Connect-Enterprise {
    $cCredentials = Get-Credential -Message "Enter your Office 365 admin credentials" -Username 'adminian.ovenell@smithtech.com'
    $iCredentials = Get-Credential -Message "Enter your Integra admin credentials" -UserName 'INTEGRA\administrator'
    $sCredentials = Get-Credential -Message "Enter your SmithTech admin credentials" -UserName "CORP\adminian.ovenell"
            function Connect-EOP {
                Param ($cloudCredentials)
                $URL = "https://ps.protection.outlook.com/powershell-liveid"
                # $cloudCredentials = Get-Credential -Message "Enter your Office 365 admin credentials" -Username '@smithtech.com'
                $SessionEOP = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $URL -Credential $cloudCredentials -Authentication Basic -AllowRedirection -Name "SmithEOP"
                Import-PSSession $SessionEOP -Prefix 'EOP_'
            }
            function Connect-IntegraEX {
                Param ($igCredentials)
                $URL = "http://phoenix02.corp.integragroup.com/PowerShell"
                # $igCredentials = Get-Credential -Message "Enter your Integra admin credentials" -UserName "INTEGRA\"
                $SessionIntegraEX = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $URL -Credential $igCredentials -Authentication Kerberos -AllowRedirection -Name "Phoenix02-IG"
                Import-PSSession $SessionIntegraEX -Prefix 'IG_'
            }
            
            function Connect-SmithEX {
                Param ($stCredentials)
                $URL = "http://phoenix01.corp.smithtech.com/PowerShell"
                # $stCredentials = Get-Credential -Message "Enter your SmithTech admin credentials" -UserName "CORP\"
                $SessionSmithTechEX = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $URL -Credential $stCredentials -Authentication Kerberos -AllowRedirection -Name "Phoenix01-ST"
                Import-PSSession $SessionSmithTechEX -Prefix 'ST_' 
            }
            function ConnectTo-SmithTechEXO {
                Param ($cloudCredentials)
                $URL = "https://outlook.office365.com/powershell-liveid"
                # $cloudCredentials = Get-Credential -Message "Enter your Office 365 admin credentials" -Username '@smithtech.com'
                $SessionEXO = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $URL -Credential $cloudCredentials -Authentication Basic -AllowRedirection -Name "SmithEXO"
                Import-PSSession $SessionEXO -Prefix 'EXO_'
            }
            
            function Connect-SmithTechAD {
                Param ($stCredentials)
                $SmithAD = New-PSsession -Computername "bel-dc-01.corp.smithtech.com" -Credential $stCredentials
                Invoke-Command -Command {Import-Module ActiveDirectory} -Session $SmithAD
                Import-PSSession -Session $SmithAD -Module ActiveDirectory -Prefix "SD_"
            }
            
            function Connect-IntegraAD {
                Param ($igCredentials)
                $IntegraAD = New-PSsession -Computername "dc02.corp.integragroup.com" -Credential $igCredentials
                Invoke-Command -Command {Import-Module ActiveDirectory} -Session $IntegraAD
                Import-PSSession -Session $IntegraAD -Module ActiveDirectory -Prefix "ID_"
            }
            function Connect-ADSyncServer {
                Param ($stCredentials)
                $SmithSync = New-PSsession -Computername "spa-utility-01.corp.smithtech.com" -Credential $stCredentials
                Invoke-Command -Command {Import-Module ADSync} -Session $SmithSync
                Import-PSSession -Session $SmithSync -Module ADSync
            }
            
            

    Connect-EOP $cCredentials
    Connect-IntegraEX $iCredentials
    Connect-SmithEX $sCredentials
    ConnectTo-SmithTechEXO $cCredentials
    Connect-SmithTechAD $sCredentials
    Connect-IntegraAD $iCredentials
    Connect-MsolService -Credential $cCredentials
    Connect-ADSyncServer $sCredentials
    Import-Module AzureRM
    Connect-AzureRmAccount

}

function Check-O365License {
    $ADUsers = Invoke-Command bel-dc-01.corp.smithtech.com {Get-ADUser -Filter * -SearchBase 'OU=Users,OU=ANA,DC=corp,DC=smithtech,DC=com'}
    $LicNo = ForEach ($ADUser in $ADUsers){
    $UserLic = Get-MsolUser -UserPrincipalName $ADUser.UserPrincipalName
    If ($UserLic.IsLicensed -eq $false){
        Write-output "$($ADUser.UserPrincipalName) is unlicensed"
         }
    }
}

function Assign-O365e3License {
    Param ($Alias)
    Set-MsolUserLicense -UserPrincipalName $Alias@smithtech.com -AddLicenses "Smithtec:ENTERPRISEPACK"
    Set-MsolUserLicense -UserPrincipalName $Alias@smithtech.com -AddLicenses "Smithtec:EMS"
}

function Fix-OnMicrosoftUsername {
    Param ($alias)
    Set-MsolUserPrincipalName `
    -UserPrincipalName "$alias@smithtec.onmicrosoft.com" `
    -NewUserPrincipalName "$alias@smithtech.com"
}

########  Export distribution groups and their respective users to a CSV for reimport in a new domain  ###########

    Get-ID_ADGroup -Filter {GroupCategory -eq "Distribution"}| ForEach-Object{
        $group=$_
        $users=Get-ID_ADGroupMember "$group"
        foreach ($dguser in $users){
        New-Object -TypeName PSobject -Property @{
        SAM="$(($dguser.Name -split " ")[0]).$(($dguser.Name -split " ")[1])"
        Group=$group.name
        }
        }
        }|Export-Csv -Path "c:\Export\DGusers.csv"

########  -------------------------------------------------------------------------------------------  ###########

########  Import distribution groups and their respective users to a CSV for reimport in a new domain  ###########
Import-Csv "C:\Export\DGusers.csv" | ForEach{Add-ST_DistributionGroupMember $_.Group -Member $_.SAM}

### Push public folder permissions
Import-Csv "C:\Users\Public\IG-PublicFolderClientPermission.csv" | ForEach{Get-EXO_PublicFolder -Identity $_.Identity | Add-EXO_PublicFolderClientPermission  –User $_.User –AccessRights $_.AccessRights}


$firstname = ($dguser.Name -split " ")[0]
$lastname = ($dguser.Name -split " ")[1]
$samaccountname = "$(($dguser.Name -split " ")[0]).$(($dguser.Name -split " ")[1])"



Get-IG_PublicFolder "Integra.com” –Recurse | Add-IG_PublicFolderClientPermission –User Anonymous –AccessRights PublishingEditor

Get-MsolUser -all |where-object {$_.UserPrincipalName -like "*.onmicrosoft.com"} | foreach-object {
    $msoluser=$_
    $alias = "$(($msoluser.UserPrincipalName -split "@")[0])"
    Set-MsolUserPrincipalName `
    -UserPrincipalName "$alias@smithtec.onmicrosoft.com" `
    -NewUserPrincipalName "$alias@smithtech.com"
}

function Fix-OnMicrosoftUsername {
    Param ($alias)
    Set-MsolUserPrincipalName `
    -UserPrincipalName "$alias@smithtec.onmicrosoft.com" `
    -NewUserPrincipalName "$alias@smithtech.com"
}

function Dump-IGpublicFolderPermissions {
    Get-IG_PublicFolder \ -Recurse | `
    Get-IG_PublicFolderClientPermission | `
    Select-Object Identity,@{Expression={$_.User};Label="User";},@{Expression={$_.AccessRights};Label="AccessRights";} | `
    Export-Csv C:\PublicFolderClientPermission.csv
}
