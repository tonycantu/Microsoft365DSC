function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $GroupID,

        [Parameter()]
        [System.String]
        $AllowGiphy,

        [Parameter()]
        [ValidateSet("Strict", "Moderate")]
        [System.String]
        $GiphyContentRating,

        [Parameter()]
        [System.String]
        $AllowStickersAndMemes,

        [Parameter()]
        [System.String]
        $AllowCustomMemes,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )

    Test-TeamsServiceConnection -GlobalAdminAccount $GlobalAdminAccount

    $nullReturn = @{
        GroupID               = $GroupID
        AllowGiphy            = $null
        GiphyContentRating    = $null
        AllowStickersAndMemes = $null
        AllowCustomMemes      = $null
        Ensure                = "Absent"
    }


    Write-Verbose -Message "Getting Team fun settings for $GroupID"

    $teamExists = Get-TeamByGroupID $GroupID
    if ($teamExists -eq $false)
    {
        throw "Team with groupid of  $GroupID doesnt exist in tenant"
    }

    $teamFunSettings = Get-TeamFunSettings -GroupId $GroupID -ErrorAction SilentlyContinue
    if ($null -eq $teamFunSettings)
    {
        Write-Verbose "The specified Team doesn't exist."
        return $nullReturn
    }

    Write-Verbose "Team fun settings for AllowGiphy = $($teamFunSettings.AllowGiphy)"
    Write-Verbose "Team fun settings for GiphyContentRating = $($teamFunSettings.GiphyContentRating)"
    Write-Verbose "Team fun settings for AllowStickersAndMemes = $($teamFunSettings.AllowStickersAndMemes)"
    Write-Verbose "Team fun settings for AllowCustomMemes = $($teamFunSettings.AllowCustomMemes)"

    return @{
        GroupID               = $GroupID
        AllowGiphy            = $teamFunSettings.AllowGiphy
        GiphyContentRating    = $teamFunSettings.GiphyContentRating
        AllowStickersAndMemes = $teamFunSettings.AllowStickersAndMemes
        AllowCustomMemes      = $teamFunSettings.AllowCustomMemes
        Ensure                = "Present"
    }

}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $GroupID,

        [Parameter()]
        [System.String]
        $AllowGiphy,

        [Parameter()]
        [ValidateSet("Strict", "Moderate")]
        [System.String]
        $GiphyContentRating,

        [Parameter()]
        [System.String]
        $AllowStickersAndMemes,

        [Parameter()]
        [System.String]
        $AllowCustomMemes,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )

    if ('Absent' -eq $Ensure)
    {
        throw "This resource cannot delete Managed Properties. Please make sure you set its Ensure value to Present."
    }

    Test-TeamsServiceConnection -GlobalAdminAccount $GlobalAdminAccount

    $CurrentParameters = $PSBoundParameters
    $CurrentParameters.Remove("GlobalAdminAccount")
    $CurrentParameters.Remove("Ensure")
    Set-TeamFunSettings @CurrentParameters
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $GroupID,

        [Parameter()]
        [System.String]
        $AllowGiphy,

        [Parameter()]
        [ValidateSet("Strict", "Moderate")]
        [System.String]
        $GiphyContentRating,

        [Parameter()]
        [System.String]
        $AllowStickersAndMemes,

        [Parameter()]
        [System.String]
        $AllowCustomMemes,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )

    Write-Verbose -Message "Testing Team fun settings for  $GroupID"
    $CurrentValues = Get-TargetResource @PSBoundParameters


    return Test-Office365DSCParameterState -CurrentValues $CurrentValues `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("GiphyContentRating", `
            "AllowGiphy", `
            "AllowStickersAndMemes", `
            "AllowCustomMemes", `
            "Ensure"
    )
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $GroupID,

        [Parameter()]
        [System.String]
        $AllowGiphy,

        [Parameter()]
        [ValidateSet("Strict", "Moderate")]
        [System.String]
        $GiphyContentRating,

        [Parameter()]
        [System.String]
        $AllowStickersAndMemes,

        [Parameter()]
        [System.String]
        $AllowCustomMemes,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )
    Test-TeamsServiceConnection -GlobalAdminAccount $GlobalAdminAccount
    $result = Get-TargetResource @PSBoundParameters
    $content = "TeamsFunSettings " + (New-GUID).ToString() + "`r`n"
    $content += "{`r`n"
    $content += Get-DSCBlock -Params $result -ModulePath $PSScriptRoot
    $content += "}`r`n"
    return $content
}

Export-ModuleMember -Function *-TargetResource