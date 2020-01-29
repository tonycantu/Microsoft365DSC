function Get-O365StubFiles
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DestinationFilePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )

    if ($null -eq $GlobalAdminAccount)
    {
        $GlobalAdminAccount = Get-Credential
    }

    if (Test-Path $DestinationFilePath)
    {
        $answer = $null
        do
        {
            $answer = Read-Host "A file already exists at the specified location. Remove it? (y/n)"
        } while ($answer -ne 'y' -and $answer -ne 'n')

        if ($answer -eq 'y')
        {
            Remove-Item -Path $DestinationFilePath -Confirm:$false
        }
    }

    $Modules = @(
        @{
            Platform   = 'AzureAD'
            ModuleName = 'AzureAD'
        },
        @{
            Platform     = 'ExchangeOnline'
            ModuleName   = $null
            RandomCmdlet = 'Add-AvailabilityAddressSpace'
        },
        @{
            Platform   = 'MicrosoftTeams'
            ModuleName = 'Microsoft.TeamsCmdlets.PowerShell.Custom'
        },
        @{
            Platform   = 'PnP'
            ModuleName = 'SharePointPnPPowerShellOnline'
        },
        @{
            Platform   = 'PowerPlatforms'
            ModuleName = 'Microsoft.PowerApps.Administration.PowerShell'
        },
        @{
            Platform     = 'SecurityComplianceCenter'
            ModuleName   = $null
            RandomCmdlet = 'Add-ComplianceCaseMember'
        },
        @{
            Platform   = 'SharePointOnline'
            ModuleName = 'Microsoft.Online.SharePoint.PowerShell'
        },
        @{
            Platform     = 'SkypeForBusiness'
            ModuleName   = $null
            RandomCmdlet = 'Clear-CsOnlineTelephoneNumberReservation'
        }
    )

    foreach ($Module in $Modules)
    {
        Write-Host "Generating Stubs for {$($Module.Platform)}..." -NoNewline
        $CurrentModuleName = $Module.ModuleName
        if ($null -eq $CurrentModuleName)
        {
            Test-MSCloudLogin -Platform $Module.Platform -CloudCredential $GlobalAdminAccount
            $foundModule = Get-Module | Where-Object -FilterScript {$_.ExportedCommands.Values.Name -ccontains $Module.RandomCmdlet}
            $CurrentModuleName = $foundModule.Name
        }
        else
        {
            Test-MSCloudLogin -Platform $Module.Platform -CloudCredential $GlobalAdminAccount
        }

        $cmdlets = Get-Command | Where-Object -FilterScript { $_.Source -eq $CurrentModuleName }
        $StubContent = ''
        $i = 1
        foreach ($cmdlet in $cmdlets)
        {
            Write-Progress -Activity "Generating Stubs" -Status $cmdlet.Name -PercentComplete (($i/$cmdlets.Length)*100)
            $signature = $null
            $metadata = New-Object -TypeName System.Management.Automation.CommandMetaData -ArgumentList $cmdlet

            if ($metadata.DefaultParameterSetName -ne 'InvokeByDynamicParameters')
            {
                $definition = [System.Management.Automation.ProxyCommand]::Create($metadata)

                foreach ($line in $definition -split "`n")
                {
                    if ($line.Trim() -eq 'begin')
                    {
                        break
                    }
                    $signature += $line
                }
                $StubContent += "function $($cmdlet.Name)`n{`r`n    $signature}`n"
            }
            else
            {
                $parameters = (Get-Command $cmdlet).Parameters
                $StubContent += "function $($cmdlet.Name)`n{`r`n    [CmdletBinding()]`r`n    param(`r`n"
                foreach ($key in $parameters.Keys)
                {
                    $parameter = $parameters.$key
                    if ($parameter.ParameterType.ToString() -ne 'System.Management.Automation.ActionPreference' -and `
                        $parameter.ParameterType.ToString() -ne 'System.Management.Automation.SwitchParameter' -and `
                        $key -ne 'InformationVariable' -and $key -ne 'WarningVariable' -and $key -ne 'ErrorVariable' -and `
                        $key -ne 'OutVariable' -and $key -ne 'OutBuffer' -and $key -ne 'PipelineVariable')
                    {
                        $StubContent += "        [Parameter()]`r`n"
                        $StubContent += "        [$($parameter.ParameterType.ToString())]`r`n"
                        $StubContent += "        `${$key},`r`n`r`n"
                    }
                }
                $StubContent = $StubContent.Remove($StubContent.Length-5, 5)
                $StubContent += "`r`n    )`r`n}`n"
            }
            $i ++
        }
        Write-Progress -Activity "Generating Stubs" -Completed

        $Content += "#region $($Module.Platform)`r`n"

        $TypesToConvert = @('Microsoft.Online.SharePoint.PowerShell.SpoHubSitePipeBind', `
            'Microsoft.Online.SharePoint.PowerShell.SpoSitePipeBind'
        )

        foreach ($type in $TypesToConvert)
        {
            $StubContent = $StubContent.Replace($type, 'Object')
        }
        $Content += $StubContent
        $Content += "#endregion`r`n"
        Write-Host "Done" -ForegroundColor Green
    }
    $Content | Out-File $DestinationFilePath -Encoding utf8
}
