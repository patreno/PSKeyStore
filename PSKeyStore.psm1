function Get-PKSPlainStringFromSecureString {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [SecureString] $securePassword
    ) 		
    
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

}

function Get-PKSUserSecretVaultPath {
    $folder = Join-Path -Path $env:userprofile "PKSVault"

    if (!(Test-Path -Path $folder)) {
        New-Item -ItemType Directory $folder
    } 

    return $folder
}

function New-PKSUserSecretFromPlainText {
    param(
        [Parameter(Mandatory=$true)]
        [string] $SecretName,
        [Parameter(Mandatory=$true)]
        [string] $PlainSecret
    ) 

    $secureString = ConvertTo-SecureString -AsPlainText -Force -String $PlainSecret

    New-PKSUserSecretFromSecureString -SecretName $SecretName -SecureString $secureString
}

function New-PKSUserSecretFromSecureString {
    param(
        [Parameter(Mandatory=$true)]
        [string] $SecretName,
        [Parameter(Mandatory=$true)]
        [SecureString] $SecureString
    ) 

    $vault = Get-PKSUserSecretVaultPath
    $secretFile = Join-Path -Path $vault "$SecretName.vsec"

    Write-Output "Writing to $secretFile"

    $SecureString | ConvertFrom-SecureString  | Out-File $secretFile
}


function New-PKSSecretFromSecureUI {
    $credential = Get-Credential

    New-PKSUserSecretFromSecureString -SecretName $credential.UserName -SecureString $credential.Password
}

function Get-PKSUserSecret {
    param (
        [Parameter(Mandatory=$true)]
        [string] $SecretName
    )

    $vault = Get-PKSUserSecretVaultPath
    $secretFile = Join-Path -Path $vault "$SecretName.vsec"

    $pass = Get-Content $secretFile | ConvertTo-SecureString

    return $pass
}

function Get-PKSUserSecretAsPlain {
    param (
        [Parameter(Mandatory=$true)]
        [string] $SecretName
    )
    
    return $(Get-PKSUserSecret $SecretName | Get-PKSPlainStringFromSecureString)
}

function Get-PKSUserSecretList {
    $vault = Get-PKSUserSecretVaultPath

    Get-ChildItem -Path $vault -Filter "*.vsec" | ForEach-Object -Process {[System.IO.Path]::GetFileNameWithoutExtension($_)}
}

Export-ModuleMember -Function Get-PKSPlainStringFromSecureString
Export-ModuleMember -Function Get-PKSUserSecretVaultPath
Export-ModuleMember -Function New-PKSUserSecretFromPlainText
Export-ModuleMember -Function New-PKSUserSecretFromSecureString 
Export-ModuleMember -Function New-PKSSecretFromSecureUI
Export-ModuleMember -Function Get-PKSUserSecret
Export-ModuleMember -Function Get-PKSUserSecretAsPlain
Export-ModuleMember -Function Get-PKSUserSecretList