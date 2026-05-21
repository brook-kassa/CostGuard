$jsonString = Get-Content -Path "C:\Users\brook\Downloads\CostGuard-main\CostGuard-main\resources.json" -Raw 

$outputs = $jsonString | ConvertFrom-Json
$findings = @()
foreach ($output in $outputs) {
    if ($output.type -eq "vm" -and $output.cpu -lt 5 -and $output.cost -gt 50){
        Write-Host $output.name "is Oversized"
        $finding = [PSCustomObject]@{
            ResourceName = $output.name
            ResourceType = $output.type
            MonthlyCost = $output.cost
            Issue = "Oversized VM"
            Severity = "Medium"
            Recommendation = "Review VM size or deallocate if unused"
            Evidence = "CPU average is $($output.cpu)% and monthly cost is $($output.cost)"
            Source = "CostGuard Analysis"
            GeneratedOn = Get-Date -Format "dddd MM/dd/yyyy hh:mm tt"
        }
        $findings += $finding   
    } elseif ($output.type -eq "storage" -and $output.lastAccessedDaysAgo -gt 90 -and $output.cost -gt 20){
        Write-Host $output.name "is Underutilized"
        $finding = [PSCustomObject]@{
            ResourceName = $output.name
            ResourceType = $output.type
            MonthlyCost = $output.cost
            Issue = "Underutilized Storage"
            Severity = "Medium"
            Recommendation = "Review access patterns, archive if needed, or delete if unused"
            Evidence = "Last accessed $($output.lastAccessedDaysAgo) days ago and monthly cost is $($output.cost)"
            Source = "CostGuard Analysis"
            GeneratedOn = Get-Date -Format "dddd MM/dd/yyyy hh:mm tt" 
        }
        $findings += $finding
    } else {
        Write-Host $output.name "is Healthy"
    }
}
$findings | Format-Table -AutoSize
$findings[0] | Format-List *
$findings | Export-Csv -Path "C:\Users\brook\Downloads\CostGuard-main\CostGuard-main\findings.csv" -NoTypeInformation

Write-Host "CostGuard analysis complete. Findings exported to findings.csv"

$findings | Measure-Object -Property MonthlyCost -Sum | ForEach-Object {
    Write-Host "Total Monthly Cost of Flagged Resources: "$"$($_.Sum)"
}