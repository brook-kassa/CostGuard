function New-CostGuardSummary {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Findings,

        [Parameter(Mandatory = $true)]
        [string]$GeneratedOn,

        [Parameter(Mandatory = $true)]
        [int]$TotalResourcesScanned,

        [Parameter(Mandatory = $true)]
        [int]$TotalFlaggedResources,

        [Parameter(Mandatory = $true)]
        [int]$TotalFindings,

        [Parameter(Mandatory = $true)]
        [int]$HealthyResources,

        [Parameter(Mandatory = $true)]
        [decimal]$TotalFlaggedCost,

        [Parameter(Mandatory = $true)]
        [decimal]$TotalEstimatedSavings,

        [Parameter(Mandatory = $true)]
        [string]$FindingsCsvPath,

        [Parameter(Mandatory = $true)]
        [string]$HtmlReportPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $summary = @()
    $summary += "CostGuard Analysis Summary"
    $summary += "Generated On: $GeneratedOn"
    $summary += ""
    $summary += "Total Resources Scanned: $TotalResourcesScanned"
    $summary += "Total Flagged Resources: $TotalFlaggedResources"
    $summary += "Total Findings: $TotalFindings"
    $summary += "Healthy Resources: $HealthyResources"
    $summary += "Total Monthly Cost of Flagged Resources: $TotalFlaggedCost"
    $summary += "Total Estimated Monthly Savings: $TotalEstimatedSavings"
    $summary += ""

    if ($Findings.Count -eq 0) {
        $summary += "No cost issues found."
    }
    else {
        $summary += "Findings by Issue:"

        $Findings | Group-Object -Property Issue | ForEach-Object {
            $summary += "- $($_.Name): $($_.Count)"
        }

        $summary += ""
        $summary += "Findings by Severity:"

        $Findings | Group-Object -Property Severity | ForEach-Object {
            $summary += "- $($_.Name): $($_.Count)"
        }

        $summary += ""
        $summary += "Detailed findings exported to: $FindingsCsvPath"
        $summary += "HTML report exported to: $HtmlReportPath"
    }

    $summary | Set-Content -Path $OutputPath
}