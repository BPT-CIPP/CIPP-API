function Invoke-ListAdminPortalLicensesAll {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        CIPP.Core.Read
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $TenantFilter = $Request.Query.tenantFilter

    try {
        $AdminPortalLicenses = New-GraphGetRequest -scope 'https://admin.microsoft.com/.default' -TenantID $TenantFilter -Uri 'https://admin.microsoft.com/fd/m365licensing/v3/licensedProducts?allotmentSourceState=Active,Deleted,Suspended,Lockout,Warning&displayNameLanguage=en-GB'

    } catch {
        Write-Warning 'Failed to get Admin Portal Licenses (All)'
        $AdminPortalLicenses = @()
    }

    return ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = @($AdminPortalLicenses)
        })
}
