<<<<<<< HEAD
. "$PSScriptRoot\rules.ps1" #[loads rules.ps1] 
function Test-CostGuardConfig {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config
    )

    $requiredSeverityProperties = @(
        "highMonthlyCost",
        "mediumMonthlyCost"
    )
=======
. "$PSScriptRoot\rules.ps1"
. "$PSScriptRoot\report.ps1"
. "$PSScriptRoot\summary.ps1"



####################### Load Data and Prepare Output Paths #########################################################

$jsonPath = "$PSScriptRoot\resources.json"
$configPath = "$PSScriptRoot\config.json"
>>>>>>> 8328d7a3c952c75b00ba256e7ea9f4d72bf6465c

    $requiredRuleProperties = @{
        IdleDevVM = @(
            "enabled",
            "maxCpuPercent",
            "minMonthlyCost",
            "minLastAccessedDaysAgo"
        )

        OversizedVM = @(
            "enabled",
            "maxCpuPercent",
            "minMonthlyCost"
        )

        UnderutilizedStorage = @(
            "enabled",
            "minLastAccessedDaysAgo",
            "minMonthlyCost"
        )

        UnattachedDisk = @(
            "enabled",
            "minMonthlyCost"
        )

        UnattachedPublicIp = @(
            "enabled",
            "minMonthlyCost"
        )
    }

    if ($null -eq $Config.rules) {
        throw "Configuration validation failed: missing 'rules' section."
    }

    if ($null -eq $Config.severity) {
        throw "Configuration validation failed: missing 'severity' section."
    }

    foreach ($propertyName in $requiredSeverityProperties) {
        if ($null -eq $Config.severity.$propertyName) {
            throw "Configuration validation failed: missing severity property '$propertyName'."
        }
    }

    foreach ($ruleName in $requiredRuleProperties.Keys) {
        $ruleConfig = $Config.rules.$ruleName

        if ($null -eq $ruleConfig) {
            throw "Configuration validation failed: missing rule '$ruleName'."
        }

        foreach ($propertyName in $requiredRuleProperties[$ruleName]) {
            if ($null -eq $ruleConfig.$propertyName) {
                throw "Configuration validation failed: rule '$ruleName' is missing property '$propertyName'."
            }
        }
    }

    return $true
}

$jsonPath = "$PSScriptRoot\resources.json" #Loads resources.json into jsonPath
$configPath = "$PSScriptRoot\config.json" #loads config.json into configPath

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss" #Formats date (ex: 2026-06-24_01:50:59)
$reportFolder = Join-Path -Path "$PSScriptRoot\reports" -ChildPath $timestamp #names the report folder the timestamp

New-Item -ItemType Directory -Path $reportFolder -Force | Out-Null 

$findingsCsvPath = Join-Path -Path $reportFolder -ChildPath "findings.csv"
$summaryPath = Join-Path -Path $reportFolder -ChildPath "summary.txt"
$htmlReportPath = Join-Path -Path $reportFolder -ChildPath "report.html"

$jsonString = Get-Content -Path $jsonPath -Raw #Grabs resource.json data into single-line format 
$outputs = $jsonString | ConvertFrom-Json #Converts resource json data to PSObject(s)

<<<<<<< HEAD
$configString = Get-Content -Path $configPath -Raw #Grabs config.json data into single-line format
$config = $configString | ConvertFrom-Json #Converts config.json data into PSObject(s)

Test-CostGuardConfig -Config $config | Out-Null

$findings = @() #creates a findings array
$generatedOn = Get-Date -Format "dddd MM/dd/yyyy hh:mm tt" #generates date-time 
$timeZone = "EDT" # time zone (may turn to EST? or dynamic time zones)
$generatedOn = "$generatedOn $timeZone"
#tests each rule on each resource, grabs the generation time and applies config rules 
foreach ($output in $outputs) { 
=======
$configString = Get-Content -Path $configPath -Raw
$config = $configString | ConvertFrom-Json

$findings = @()

$generatedOn = Get-Date -Format "dddd MM/dd/yyyy hh:mm tt"
$timeZone = "EDT"
$generatedOn = "$generatedOn $timeZone"

####################### Run Rules Against Each Resource #########################################################

foreach ($output in $outputs) {
>>>>>>> 8328d7a3c952c75b00ba256e7ea9f4d72bf6465c

    $ruleResults = @(
        Test-IdleDevVM -Resource $output -GeneratedOn $generatedOn -Config $config
        Test-OversizedVM -Resource $output -GeneratedOn $generatedOn -Config $config
        Test-UnderutilizedStorage -Resource $output -GeneratedOn $generatedOn -Config $config
        Test-UnattachedDisk -Resource $output -GeneratedOn $generatedOn -Config $config
        Test-UnattachedPublicIp -Resource $output -GeneratedOn $generatedOn -Config $config
<<<<<<< HEAD
    )
=======
)
>>>>>>> 8328d7a3c952c75b00ba256e7ea9f4d72bf6465c

    $matchedFindings = @($ruleResults | Where-Object { $null -ne $_ }) 

    if ($matchedFindings.Count -gt 0) { #place any matchedfindings into findings array
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