. "$PSScriptRoot\rules.ps1"

$jsonPath = "$PSScriptRoot\resources.json"
$findingsCsvPath = "$PSScriptRoot\findings.csv"
$summaryPath = "$PSScriptRoot\summary.txt"

$jsonString = Get-Content -Path $jsonPath -Raw
$outputs = $jsonString | ConvertFrom-Json

$findings = @()
$generatedOn = Get-Date -Format "dddd MM/dd/yyyy hh:mm tt zz"

foreach ($output in $outputs) {

    $ruleResults = @(
        Test-IdleDevVM -Resource $output -GeneratedOn $generatedOn
        Test-OversizedVM -Resource $output -GeneratedOn $generatedOn
        Test-UnderutilizedStorage -Resource $output -GeneratedOn $generatedOn
        Test-UnattachedDisk -Resource $output -GeneratedOn $generatedOn
        Test-UnattachedPublicIp -Resource $output -GeneratedOn $generatedOn
    )

    $matchedFindings = @($ruleResults | Where-Object { $null -ne $_ })

    if ($matchedFindings.Count -gt 0) {
        $findings += $matchedFindings
    }
    else {
        Write-Host "$($output.name) is Healthy"
    }
}

Write-Host ""
$findings | Format-Table -AutoSize

$findings | Export-Csv -Path $findingsCsvPath -NoTypeInformation

$totalFlaggedCost = ($findings | Measure-Object -Property MonthlyCost -Sum).Sum

if ($null -eq $totalFlaggedCost) {
    $totalFlaggedCost = 0
}

$totalEstimatedSavings = ($findings | Measure-Object -Property EstimatedSavings -Sum).Sum

if ($null -eq $totalEstimatedSavings) {
    $totalEstimatedSavings = 0
}

Write-Host ""
Write-Host "CostGuard analysis complete. Findings exported to findings.csv"
Write-Host "Total Monthly Cost of Flagged Resources: $totalFlaggedCost"
Write-Host "Total Estimated Monthly Savings: $totalEstimatedSavings"

$summary = @()
$summary += "CostGuard Analysis Summary"
$summary += "Generated On: $generatedOn"
$summary += ""
$summary += "Total Flagged Resources: $($findings.Count)"
$summary += "Total Monthly Cost of Flagged Resources: $totalFlaggedCost"
$summary += "Total Estimated Monthly Savings: $totalEstimatedSavings"
$summary += ""
$summary += "Findings by Issue:"

$findings | Group-Object -Property Issue | ForEach-Object {
    $summary += "- $($_.Name): $($_.Count)"
}

$summary += ""
$summary += "Detailed findings exported to findings.csv."

$summary | Set-Content -Path $summaryPath

Write-Host "CostGuard summary exported to summary.txt"