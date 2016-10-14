﻿[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try {

    . .\Octopus-VSTS.ps1

    $OctoConnectedServiceName = Get-VstsInput -Name OctoConnectedServiceName
    $ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName
    $Project = Get-VstsInput -Name Project -Require
    $From = Get-VstsInput -Name From -Require
    $To = Get-VstsInput -Name To -Require
    $ShowProgress = Get-VstsInput -Name ShowProgress -AsBool
    $DeployForTenants = Get-VstsInput -Name DeployForTenants
	$DeployForTenantTags = Get-VstsInput -Name DeployForTenantTags
    $AdditionalArguments = Get-VstsInput -Name AdditionalArguments

    # Get required parameters
	if ([System.String]::IsNullOrWhiteSpace($OctoConnectedServiceName) -and [System.String]::IsNullOrWhiteSpace($ConnectedServiceName)) {
		throw "No Service Endpoint has been specified. You must provide either a Generic or an Octopus Endpoint."
	}
	if (-not [System.String]::IsNullOrWhiteSpace($OctoConnectedServiceName)) {
		$connectedServiceDetails = Get-VstsEndpoint -Name "$OctoConnectedServiceName" -Require
		$credentialParams = Get-OctoCredentialArgsForOctoConnection($connectedServiceDetails)
	} else {
        $connectedServiceDetails = Get-VstsEndpoint -Name "$ConnectedServiceName" -Require
		$credentialParams = Get-OctoCredentialArgs($connectedServiceDetails)
        Write-Warning "You're currently using a Generic Service Endpoint to connect to Octopus Deploy. This Endpoint Type will be deprecated in Octopus Deploy tasks in the future. We strongly recommend updating to the new Octopus Deploy Service Endpoint type."
	}
    $octopusUrl = $connectedServiceDetails.Url

    # Call Octo.exe
    $octoPath = Get-OctoExePath
    $Arguments = "promote-release --project=`"$Project`" --from=`"$From`" --server=$octopusUrl $credentialParams $AdditionalArguments"
    
    if ($ShowProgress) {
       $Arguments += " --progress"
    }
    
    if ($To) {
        ForEach($Environment in $To.Split(',').Trim()) {
            $Arguments = $Arguments + " --to=`"$Environment`""
        }
    }

    # optional deployment tenants & tags
	if (-not [System.String]::IsNullOrWhiteSpace($DeployForTenants)) {
        ForEach($Tenant in $DeployForTenants.Split(',').Trim()) {
            $Arguments = $Arguments + " --tenant=`"$Tenant`""
        }
	}

	if (-not [System.String]::IsNullOrWhiteSpace($DeployForTenantTags)) {
        ForEach($Tenant in $DeployForTenantTags.Split(',').Trim()) {
            $Arguments = $Arguments + " --tenanttag=`"$Tenant`""
		}
	}
    
    Invoke-VstsTool -FileName $octoPath -Arguments $Arguments -RequireExitCodeZero

} finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
