. "$PSScriptRoot\rules.ps1"

$jsonPath = "$PSScriptRoot\resources.json"

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFolder = Join-Path -Path "$PSScriptRoot\reports" -ChildPath $timestamp

New-Item -ItemType Directory -Path $reportFolder -Force | Out-Null

$findingsCsvPath = Join-Path -Path $reportFolder -ChildPath "findings.csv"
$summaryPath = Join-Path -Path $reportFolder -ChildPath "summary.txt"
$htmlReportPath = Join-Path -Path $reportFolder -ChildPath "report.html"

$jsonString = Get-Content -Path $jsonPath -Raw
$outputs = $jsonString | ConvertFrom-Json

$findings = @()
$generatedOn = Get-Date -Format "dddd MM/dd/yyyy hh:mm tt"
$timeZone = "EDT"
$generatedOn = "$generatedOn $timeZone"
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

$findings = @($findings | Sort-Object -Property EstimatedSavings -Descending)

$totalResourcesScanned = $outputs.Count
$totalFindings = $findings.Count
$totalFlaggedResources = @($findings | Select-Object -ExpandProperty ResourceName -Unique).Count
$healthyResources = $totalResourcesScanned - $totalFlaggedResources

$totalFlaggedCost = ($findings | Measure-Object -Property MonthlyCost -Sum).Sum

if ($null -eq $totalFlaggedCost) {
    $totalFlaggedCost = 0
}

$totalEstimatedSavings = ($findings | Measure-Object -Property EstimatedSavings -Sum).Sum

if ($null -eq $totalEstimatedSavings) {
    $totalEstimatedSavings = 0
}

Write-Host ""
Write-Host ""

if ($findings.Count -eq 0) {
    Write-Host "No cost issues found."
}
else {
    $findings | Format-Table -AutoSize
    $findings | Export-Csv -Path $findingsCsvPath -NoTypeInformation
    Write-Host "CostGuard analysis complete. Findings exported to $findingsCsvPath"
}

Write-Host "Total Resources Scanned: $totalResourcesScanned"
Write-Host "Total Flagged Resources: $totalFlaggedResources"
Write-Host "Total Findings: $totalFindings"
Write-Host "Healthy Resources: $healthyResources"
Write-Host "Total Monthly Cost of Flagged Resources: $totalFlaggedCost"
Write-Host "Total Estimated Monthly Savings: $totalEstimatedSavings"

$summary = @()
$summary += "CostGuard Analysis Summary"
$summary += "Generated On: $generatedOn"
$summary += ""
$summary += "Total Resources Scanned: $totalResourcesScanned"
$summary += "Total Flagged Resources: $totalFlaggedResources"
$summary += "Total Findings: $totalFindings"
$summary += "Healthy Resources: $healthyResources"
$summary += "Total Monthly Cost of Flagged Resources: $totalFlaggedCost"
$summary += "Total Estimated Monthly Savings: $totalEstimatedSavings"
$summary += ""

if ($findings.Count -eq 0) {
    $summary += "No cost issues found."
}
else {
    $summary += "Findings by Issue:"

    $findings | Group-Object -Property Issue | ForEach-Object {
        $summary += "- $($_.Name): $($_.Count)"
    }

    $summary += ""
    $summary += "Findings by Severity:"

    $findings | Group-Object -Property Severity | ForEach-Object {
        $summary += "- $($_.Name): $($_.Count)"
    }

    $summary += ""
    $summary += "Detailed findings exported to: $findingsCsvPath"
    $summary += "HTML report exported to: $htmlReportPath"
}

$summary | Set-Content -Path $summaryPath

$findingsTableRows = ""

if ($findings.Count -eq 0) {
    $findingsTableRows = "<tr><td colspan='8'>No cost issues found.</td></tr>"
}
else {
    foreach ($finding in $findings) {

        $severityClass = ""

        if ($finding.Severity -eq "High") {
            $severityClass = "severity-high"
        }
        elseif ($finding.Severity -eq "Medium") {
            $severityClass = "severity-medium"
        }
        elseif ($finding.Severity -eq "Low") {
            $severityClass = "severity-low"
        }

        $findingsTableRows += @"
<tr>
    <td class="resource-name">$($finding.ResourceName)</td>
    <td>$($finding.ResourceType)</td>
    <td>$($finding.Issue)</td>
    <td class="$severityClass">$($finding.Severity)</td>
    <td>$($finding.MonthlyCost.ToString("C"))</td>
    <td>$($finding.EstimatedSavings.ToString("C"))</td>
    <td>$($finding.Recommendation)</td>
    <td>$($finding.ActionRequired)</td>
</tr>
"@
    }
}

$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>CostGuard Report</title>
    <style>
        body {
            font-family: "Segoe UI", Arial, sans-serif;
            margin: 40px;
            background-color: #1b1a19;
            color: #ffffff;
        }

        h1 {
            margin-bottom: 5px;
            font-size: 34px;
            font-weight: 600;
        }

        h2 {
            margin-top: 32px;
            margin-bottom: 14px;
            font-size: 24px;
            font-weight: 600;
        }

        .subtitle {
            color: #c8c6c4;
            margin-bottom: 30px;
        }

        .summary-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 14px;
            margin-bottom: 34px;
        }

        .card {
            background-color: #252423;
            padding: 18px;
            border-radius: 2px;
            border: 1px solid #3b3a39;
        }

        .card-title {
            color: #c8c6c4;
            font-size: 14px;
            margin-bottom: 10px;
        }

        .card-value {
            font-size: 26px;
            font-weight: 600;
            color: #ffffff;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            background-color: #1b1a19;
            color: #ffffff;
            border: none;
        }

        thead {
            border-bottom: 1px solid #605e5c;
        }

        th {
            color: #ffffff;
            font-weight: 600;
            font-size: 15px;
            text-align: left;
            padding: 14px 12px;
            background-color: #1b1a19;
            border: none;
        }

        td {
            padding: 14px 12px;
            vertical-align: top;
            border: none;
            border-bottom: 1px solid #3b3a39;
            color: #ffffff;
        }

        tr:hover td {
            background-color: #252423;
        }

        .resource-name {
            color: #60a5fa;
            font-weight: 500;
        }

        .severity-high {
            color: #ffb4ab;
            font-weight: 600;
        }

        .severity-medium {
            color: #ffd166;
            font-weight: 600;
        }

        .severity-low {
            color: #9ee493;
            font-weight: 600;
        }

        .footer {
            margin-top: 30px;
            color: #a19f9d;
            font-size: 13px;
        }
    </style>
</head>
<body>
    <h1>CostGuard Analysis Report</h1>
    <div class="subtitle">Generated On: $generatedOn</div>

    <div class="summary-grid">
        <div class="card">
            <div class="card-title">Resources Scanned</div>
            <div class="card-value">$totalResourcesScanned</div>
        </div>

        <div class="card">
            <div class="card-title">Flagged Resources</div>
            <div class="card-value">$totalFlaggedResources</div>
        </div>

        <div class="card">
            <div class="card-title">Healthy Resources</div>
            <div class="card-value">$healthyResources</div>
        </div>

        <div class="card">
            <div class="card-title">Total Findings</div>
            <div class="card-value">$totalFindings</div>
        </div>

        <div class="card">
            <div class="card-title">Flagged Monthly Cost</div>
            <div class="card-value">$($totalFlaggedCost.ToString("C"))</div>
        </div>

        <div class="card">
            <div class="card-title">Estimated Monthly Savings</div>
            <div class="card-value">$($totalEstimatedSavings.ToString("C"))</div>
        </div>
    </div>

    <h2>Findings</h2>

    <table>
        <thead>
            <tr>
                <th>Resource Name</th>
                <th>Type</th>
                <th>Issue</th>
                <th>Severity</th>
                <th>Monthly Cost</th>
                <th>Estimated Savings</th>
                <th>Recommendation</th>
                <th>Action Required</th>
            </tr>
        </thead>
        <tbody>
            $findingsTableRows
        </tbody>
    </table>

    <div class="footer">
        Source: CostGuard Analysis
    </div>
</body>
</html>
"@

$htmlReport | Set-Content -Path $htmlReportPath

Write-Host "CostGuard summary exported to $summaryPath"
Write-Host "CostGuard HTML report exported to $htmlReportPath"