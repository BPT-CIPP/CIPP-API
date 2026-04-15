function Invoke-ExecSetLicenseRequestProcess {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        Tenant.Administration.ReadWrite
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)

    $APIName = $Request.Params.CIPPEndpoint
    $Headers = $Request.Headers
    $TenantFilter = $Request.Body.tenantFilter

    $PolicyValue = @{
        message = $Request.Body.message
    }
    if ($Request.Body.redirectUrl) {
        $PolicyValue.redirectUrl = $Request.Body.redirectUrl
    }

    $Body = @{ policyValue = $PolicyValue } | ConvertTo-Json -Depth 5 -Compress

    try {
        $Result = New-GraphPostRequest -uri 'https://admin.microsoft.com/admin/api/licenses/customRequestProcess' -scope 'https://admin.microsoft.com/.default' -tenantid $TenantFilter -type POST -body $Body
        $Message = "Successfully configured license request process for $TenantFilter"
        Write-LogMessage -headers $Headers -API $APIName -tenant $TenantFilter -message $Message -Sev 'Info'
        $StatusCode = [HttpStatusCode]::OK
        $ResponseBody = @{
            Results  = $Message
            Response = $Result
        }
    } catch {
        $ErrorMessage = Get-CippException -Exception $_
        $Message = "Failed to configure license request process for $TenantFilter. Error: $($ErrorMessage.NormalizedError)"
        Write-LogMessage -headers $Headers -API $APIName -tenant $TenantFilter -message $Message -Sev Error -LogData $ErrorMessage
        $StatusCode = [HttpStatusCode]::InternalServerError
        $ResponseBody = @{ Results = $Message }
    }

    return ([HttpResponseContext]@{
            StatusCode = $StatusCode
            Body       = $ResponseBody
        })
}
