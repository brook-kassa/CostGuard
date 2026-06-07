## Example Output

When `analyze.ps1` is run, CostGuard reviews the mock Azure resources and displays flagged resources in the terminal.

Example findings:

| Resource Name | Resource Type | Issue | Monthly Cost | Severity |
|---|---|---|---:|---|
| vm-prod-01 | vm | Oversized VM | 120 | Medium |
| old-storage-acct | storage | Underutilized Storage | 35 | Medium |
| vm-dev-01-disk | disk | Unattached Disk | 15 | Medium |
| ip-address-01 | publicIp | Unattached Public IP | 5 | Medium |
| vm-dev-02 | vm | Idle Dev VM | 60 | Medium |

Total monthly cost of flagged resources:

```text
$235