function Get-Severity {
    param (
        [Parameter(Mandatory = $true)]
        [decimal]$MonthlyCost,

        [Parameter(Mandatory = $true)]
        [object]$Config
    )

    if ($MonthlyCost -ge $Config.severity.highMonthlyCost) {
        return "High"
    }
    elseif ($MonthlyCost -ge $Config.severity.mediumMonthlyCost) {
        return "Medium"
    }
    else {
        return "Low"
    }
}

function Get-EstimatedSavings {
    param (
        [Parameter(Mandatory = $true)]
        [decimal]$MonthlyCost
    )

    return $MonthlyCost
}
function New-Finding {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Resource,

        [Parameter(Mandatory = $true)]
        [string]$Issue,

        [Parameter(Mandatory = $true)]
        [string]$Recommendation,

        [Parameter(Mandatory = $true)]
        [string]$Evidence,

        [Parameter(Mandatory = $true)]
        [string]$ActionRequired,

        [Parameter(Mandatory = $true)]
        [string]$GeneratedOn,

        [Parameter(Mandatory = $true)]
        [object]$Config
    )

    return [PSCustomObject]@{
        ResourceName     = $Resource.name
        ResourceType     = $Resource.type
        MonthlyCost      = $Resource.cost
        EstimatedSavings = Get-EstimatedSavings -MonthlyCost $Resource.cost
        Issue            = $Issue
        Severity         = Get-Severity -MonthlyCost $Resource.cost -Config $Config
        Recommendation   = $Recommendation
        Evidence         = $Evidence
        ActionRequired   = $ActionRequired
        Source           = "CostGuard Analysis"
        GeneratedOn      = $GeneratedOn
    }
}

function Test-OversizedVM {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Resource,

        [Parameter(Mandatory = $true)]
        [string]$GeneratedOn,
        
        [Parameter(Mandatory = $true)]
        [object]$Config
    )

    $configRules = $Config.rules.OversizedVM

    if ($configRules.enabled -ne $true){
        return $null
    }

    if (
        $Resource.type -eq "vm" -and
        $Resource.cpu -lt $configRules.maxCpuPercent -and
        $Resource.cost -gt $configRules.minMonthlyCost
    ) {
        Write-Host "$($Resource.name) is Oversized"

        return New-Finding `
            -Resource $Resource `
            -Issue "Oversized VM" `
            -Recommendation "Review VM size or deallocate if unused" `
            -Evidence "CPU average is $($Resource.cpu)% and monthly cost is $($Resource.cost)" `
            -ActionRequired "Review recommended" `
            -GeneratedOn $GeneratedOn `
            -Config $Config
    }

    return $null
}

function Test-UnderutilizedStorage {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Resource,

        [Parameter(Mandatory = $true)]
        [string]$GeneratedOn,

        [Parameter(Mandatory = $true)]
        [object]$Config
    )
    
    $configRules = $Config.rules.UnderutilizedStorage

    if ($configRules.enabled -ne $true){
        return $null
    }

    if (    
        $Resource.type -eq "storage" -and
        $Resource.lastAccessedDaysAgo -gt $configRules.minLastAccessedDaysAgo -and
        $Resource.cost -gt $configRules.minMonthlyCost
    )  {
        Write-Host "$($Resource.name) is Underutilized"

        return New-Finding `
            -Resource $Resource `
            -Issue "Underutilized Storage" `
            -Recommendation "Review access patterns, archive if needed, or delete if unused" `
            -Evidence "Last accessed $($Resource.lastAccessedDaysAgo) days ago and monthly cost is $($Resource.cost)" `
            -ActionRequired "Manual review required before deletion" `
            -GeneratedOn $GeneratedOn `
            -Config $Config
    }

    return $null
}

function Test-UnattachedDisk {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Resource,

        [Parameter(Mandatory = $true)]
        [string]$GeneratedOn,

        [Parameter(Mandatory = $true)]
        [object]$Config
    )
    
    $configRules = $Config.rules.UnattachedDisk

    if ($configRules.enabled -ne $true){
        return $null
    }

    if (
        $Resource.type -eq "disk" -and
        $Resource.diskState -eq "unattached" -and
        $Resource.cost -gt $configRules.minMonthlyCost
    ) {
        Write-Host "$($Resource.name) is an Unattached Disk"

        return New-Finding `
            -Resource $Resource `
            -Issue "Unattached Disk" `
            -Recommendation "Review unattached disks and delete if not needed" `
            -Evidence "Disk state is unattached and monthly cost is $($Resource.cost)" `
            -ActionRequired "Manual review required before deletion" `
            -GeneratedOn $GeneratedOn `
            -Config $Config
    }

    return $null
}

function Test-UnattachedPublicIp {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Resource,

        [Parameter(Mandatory = $true)]
        [string]$GeneratedOn,
        
        [Parameter(Mandatory = $true)]
        [object]$Config
    )

    $configRules = $Config.rules.UnattachedPublicIp

    if ($configRules.enabled -ne $true) {
        return $null
    }

    if (
        $Resource.type -eq "publicIp" -and
        $Resource.ipaddressState -eq "unattached" -and 
        $Resource.cost -gt $configRules.minMonthlyCost
    ) {
        Write-Host "$($Resource.name) is an Unattached Public IP"

        return New-Finding `
            -Resource $Resource `
            -Issue "Unattached Public IP" `
            -Recommendation "Review unattached IP addresses and delete if not needed" `
            -Evidence "IP address is unattached and monthly cost is $($Resource.cost)" `
            -ActionRequired "Manual review required before deletion" `
            -GeneratedOn $GeneratedOn `
            -Config $Config
    }

    return $null
}

function Test-IdleDevVM {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Resource,

        [Parameter(Mandatory = $true)]
        [string]$GeneratedOn,

        [Parameter(Mandatory = $true)]
        [object]$Config
    )

    $configRules = $Config.rules.IdleDevVM

    if ($configRules.enabled -ne $true) {
        return $null
    }

    if (
        $Resource.type -eq "vm" -and
        $Resource.environment -eq "dev" -and
        $Resource.isRunning -eq $true -and
        $Resource.cpu -lt $configRules.maxCpuPercent -and
        $Resource.lastAccessedDaysAgo -gt $configRules.minLastAccessedDaysAgo -and
        $Resource.cost -gt $configRules.minMonthlyCost
    ) {
        Write-Host "$($Resource.name) is an Idle Dev VM"

        return New-Finding `
            -Resource $Resource `
            -Issue "Idle Dev VM" `
            -Recommendation "Review idle dev VM and deallocate if not needed" `
            -Evidence "VM is in dev environment, running, CPU average is $($Resource.cpu)%, last accessed $($Resource.lastAccessedDaysAgo) days ago, and monthly cost is $($Resource.cost)" `
            -ActionRequired "Manual review required before deallocation" `
            -GeneratedOn $GeneratedOn `
            -Config $Config
    }

    return $null
}