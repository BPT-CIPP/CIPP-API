function Invoke-ExecAzureDelegatedRequest {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        CIPP.Core.Read
    .DESCRIPTION
        Proxies a GET request to https://management.azure.com using a delegated GDAP token
        acquired for the specified client tenant. Use this to hit Azure Resource Manager /
        Billing endpoints in a delegated-per-tenant context (something New-CIPPAzRestRequest
        cannot do — it uses the CIPP Function App's Managed Identity).

        CAVEAT: the GDAP relationship must include an Azure-scope RBAC role with access to the
        target resource. Standard M365-only GDAP templates do NOT grant ARM/Billing access.
    .PARAMETER Request.Query.tenantFilter
        Client tenant ID (GUID) or defaultDomainName. Required.
    .PARAMETER Request.Query.uri
        Full https://management.azure.com/... URI including api-version. Required.
    .EXAMPLE
        GET /api/ExecAzureDelegatedRequest
            ?tenantFilter=contoso.onmicrosoft.com
            &uri=https://management.azure.com/providers/Microsoft.Billing/billingAccounts?api-version=2024-04-01&$expand=soldTo
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $TenantFilter = $Request.Query.tenantFilter
    $Uri          = $Request.Query.uri

    if ([string]::IsNullOrWhiteSpace($TenantFilter)) {
        return ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::BadRequest
                Body       = @{ error = 'tenantFilter query parameter is required' }
            })
    }
    if ([string]::IsNullOrWhiteSpace($Uri)) {
        return ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::BadRequest
                Body       = @{ error = 'uri query parameter is required' }
            })
    }
    if ($Uri -notlike 'https://management.azure.com/*') {
        return ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::BadRequest
                Body       = @{ error = 'uri must start with https://management.azure.com/' }
            })
    }

    try {
        $Response = New-GraphGetRequest `
            -scope 'https://management.azure.com/.default' `
            -TenantID $TenantFilter `
            -Uri $Uri
        $StatusCode = [HttpStatusCode]::OK
    } catch {
        $Response   = @{ error = "Azure delegated request failed: $($_.Exception.Message)"; uri = $Uri; tenantFilter = $TenantFilter }
        $StatusCode = [HttpStatusCode]::InternalServerError
        Write-Warning $Response.error
    }

    return ([HttpResponseContext]@{
            StatusCode = $StatusCode
            Body       = @($Response)
        })
}
