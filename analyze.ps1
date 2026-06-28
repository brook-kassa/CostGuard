. "$PSScriptRoot\rules.ps1"
. "$PSScriptRoot\report.ps1"
. "$PSScriptRoot\summary.ps1"



####################### Load Data and Prepare Output Paths #########################################################

$jsonPath = "$PSScriptRoot\resources.json"
$configPath = "$PSScriptRoot\config.json"

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFolder = Join-Path -Path "$PSScriptRoot\reports" -ChildPath $timestamp

New-Item -ItemType Directory -Path $reportFolder -Force | Out-Null

$findingsCsvPath = Join-Path -Path $reportFolder -ChildPath "findings.csv"
$summaryPath = Join-Path -Path $reportFolder -ChildPath "summary.txt"
$htmlReportPath = Join-Path -Path $reportFolder -ChildPath "report.html"

$jsonString = Get-Content -Path $jsonPath -Raw
$outputs = $jsonString | ConvertFrom-Json

$configString = Get-Content -Path $configPath -Raw
$config = $configString | ConvertFrom-Json

$findings = @()

$generatedOn = Get-Date -Format "dddd MM/dd/yyyy hh:mm tt"
$timeZone = "EDT"
$generatedOn = "$generatedOn $timeZone"

####################### Run Rules Against Each Resource #########################################################

foreach ($output in $outputs) {

    $ruleResults = @(
        Test-IdleDevVM -Resource $output -GeneratedOn $generatedOn -Config $config
        Test-OversizedVM -Resource $output -GeneratedOn $generatedOn -Config $config
        Test-UnderutilizedStorage -Resource $output -GeneratedOn $generatedOn -Config $config
        Test-UnattachedDisk -Resource $output -GeneratedOn $generatedOn -Config $config
        Test-UnattachedPublicIp -Resource $output -GeneratedOn $generatedOn -Config $config
)

    $matchedFindings = @($ruleResults | Where-Object { $null -ne $_ })

    if ($matchedFindings.Count -gt 0) {
        $findings += $matchedFindings
    }
    else {
        Write-Host "$($output.name) is Healthy"
    }
}

####################### Calculate Totals #########################################################

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

####################### Console Output and CSV Export #########################################################

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

####################### Generate Summary and HTML Report #########################################################

New-CostGuardSummary `
    -Findings $findings `
    -GeneratedOn $generatedOn `
    -TotalResourcesScanned $totalResourcesScanned `
    -TotalFlaggedResources $totalFlaggedResources `
    -TotalFindings $totalFindings `
    -HealthyResources $healthyResources `
    -TotalFlaggedCost $totalFlaggedCost `
    -TotalEstimatedSavings $totalEstimatedSavings `
    -FindingsCsvPath $findingsCsvPath `
    -HtmlReportPath $htmlReportPath `
    -OutputPath $summaryPath

New-CostGuardHtmlReport `
    -Findings $findings `
    -GeneratedOn $generatedOn `
    -TotalResourcesScanned $totalResourcesScanned `
    -TotalFlaggedResources $totalFlaggedResources `
    -HealthyResources $healthyResources `
    -TotalFindings $totalFindings `
    -TotalFlaggedCost $totalFlaggedCost `
    -TotalEstimatedSavings $totalEstimatedSavings `
    -OutputPath $htmlReportPath

Write-Host "CostGuard summary exported to $summaryPath"
Write-Host "CostGuard HTML report exported to $htmlReportPath"