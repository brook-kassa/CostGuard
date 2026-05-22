$jsonPath = "C:\Users\brook\Downloads\CostGuard-main\CostGuard-main\resources.json"
$findingsCsvPath = "C:\Users\brook\Downloads\CostGuard-main\CostGuard-main\findings.csv"
$summaryPath = "C:\Users\brook\Downloads\CostGuard-main\CostGuard-main\summary.txt"

$jsonString = Get-Content -Path $jsonPath -Raw
$outputs = $jsonString | ConvertFrom-Json

$findings = @()
$generatedOn = Get-Date -Format "dddd MM/dd/yyyy hh:mm tt zz"

foreach ($output in $outputs) {

    if (
        $output.type -eq "vm" -and
        $output.environment -eq "dev" -and
        $output.isRunning -eq $true -and
        $output.cpu -lt 10 -and
        $output.cost -gt 50
    ) {
        Write-Host "$($output.name) is Idle Dev VM"

        $finding = [PSCustomObject]@{
            ResourceName   = $output.name
            ResourceType   = $output.type
            MonthlyCost    = $output.cost
            Issue          = "Idle Dev VM"
            Severity       = "Medium"
            Recommendation = "Review idle dev VM and deallocate if not needed"
            Evidence       = "VM is in dev environment, running, with low CPU usage, and monthly cost is $($output.cost)"
            ActionRequired = "Manual review required before deallocation"
            Source         = "CostGuard Analysis"
            GeneratedOn    = $generatedOn
        }

        $findings += $finding
    }
    elseif (
        $output.type -eq "vm" -and
        $output.cpu -lt 5 -and
        $output.cost -gt 50
    ) {
        Write-Host "$($output.name) is Oversized"

        $finding = [PSCustomObject]@{
            ResourceName   = $output.name
            ResourceType   = $output.type
            MonthlyCost    = $output.cost
            Issue          = "Oversized VM"
            Severity       = "Medium"
            Recommendation = "Review VM size or deallocate if unused"
            Evidence       = "CPU average is $($output.cpu)% and monthly cost is $($output.cost)"
            ActionRequired = "Review Recommended"
            Source         = "CostGuard Analysis"
            GeneratedOn    = $generatedOn
        }

        $findings += $finding
    }
    elseif (
        $output.type -eq "storage" -and
        $output.lastAccessedDaysAgo -gt 90 -and
        $output.cost -gt 20
    ) {
        Write-Host "$($output.name) is Underutilized"

        $finding = [PSCustomObject]@{
            ResourceName   = $output.name
            ResourceType   = $output.type
            MonthlyCost    = $output.cost
            Issue          = "Underutilized Storage"
            Severity       = "Medium"
            Recommendation = "Review access patterns, archive if needed, or delete if unused"
            Evidence       = "Last accessed $($output.lastAccessedDaysAgo) days ago and monthly cost is $($output.cost)"
            ActionRequired = "Manual review required before deletion"
            Source         = "CostGuard Analysis"
            GeneratedOn    = $generatedOn
        }

        $findings += $finding
    }
    elseif (
        $output.type -eq "disk" -and
        $output.diskState -eq "unattached" -and
        $output.cost -gt 0
    ) {
        Write-Host "$($output.name) is Unattached Disk"

        $finding = [PSCustomObject]@{
            ResourceName   = $output.name
            ResourceType   = $output.type
            MonthlyCost    = $output.cost
            Issue          = "Unattached Disk"
            Severity       = "Medium"
            Recommendation = "Review unattached disks and delete if not needed"
            Evidence       = "Disk state is unattached and monthly cost is $($output.cost)"
            ActionRequired = "Manual review required before deletion"
            Source         = "CostGuard Analysis"
            GeneratedOn    = $generatedOn
        }

        $findings += $finding
    }
    elseif (
        $output.type -eq "publicIp" -and
        $output.ipaddressState -eq "unattached" -and
        $output.cost -gt 0
    ) {
        Write-Host "$($output.name) is Unattached Public IP"

        $finding = [PSCustomObject]@{
            ResourceName   = $output.name
            ResourceType   = $output.type
            MonthlyCost    = $output.cost
            Issue          = "Unattached Public IP"
            Severity       = "Medium"
            Recommendation = "Review unattached IP addresses and delete if not needed"
            Evidence       = "IP address is unattached and monthly cost is $($output.cost)"
            ActionRequired = "Manual review required before deletion"
            Source         = "CostGuard Analysis"
            GeneratedOn    = $generatedOn
        }

        $findings += $finding
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

Write-Host ""
Write-Host "CostGuard analysis complete. Findings exported to findings.csv"
Write-Host "Total Monthly Cost of Flagged Resources: $totalFlaggedCost"

$summary = @()
$summary += "CostGuard Analysis Summary"
$summary += "Generated On: $generatedOn"
$summary += ""
$summary += "Total Flagged Resources: $($findings.Count)"
$summary += "Total Monthly Cost of Flagged Resources: $totalFlaggedCost"
$summary += ""
$summary += "Findings by Issue:"

$findings | Group-Object -Property Issue | ForEach-Object {
    $summary += "- $($_.Name): $($_.Count)"
}

$summary += ""
$summary += "Detailed findings exported to findings.csv."

$summary | Set-Content -Path $summaryPath

Write-Host "CostGuard summary exported to summary.txt"