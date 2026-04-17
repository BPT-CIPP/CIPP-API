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

    # Defaults broaden the trials-only view to include admin-direct/CSP (Tenant) owners
    # and regular paid SKUs. Callers can override via query params.
    $OwnerType  = if ($Request.Query.allotmentSourceOwnerType) { $Request.Query.allotmentSourceOwnerType } else { 'User,Tenant' }
    $SourceType = if ($Request.Query.allotmentSourceType)      { $Request.Query.allotmentSourceType }      else { 'LowFrictionTrial,Regular' }
    $State      = if ($Request.Query.allotmentSourceState)     { $Request.Query.allotmentSourceState }     else { 'Active,Deleted,Suspended,Lockout,Warning' }

    $Uri = "https://admin.microsoft.com/fd/m365licensing/v3/licensedProducts?allotmentSourceOwnerType=$OwnerType&allotmentSourceType=$SourceType&allotmentSourceState=$State&displayNameLanguage=en-GB"

    try {
        $AdminPortalLicenses = New-GraphGetRequest -scope 'https://admin.microsoft.com/.default' -TenantID $TenantFilter -Uri $Uri
    } catch {
        Write-Warning "Failed to get Admin Portal Licenses (All): $($_.Exception.Message)"
        $AdminPortalLicenses = @()
    }

    return ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = @($AdminPortalLicenses)
        })
}
