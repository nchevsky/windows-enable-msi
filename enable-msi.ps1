[CmdletBinding(PositionalBinding = $true)]
param (
    [Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$PCIIDs
)

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

New-Variable -Option Constant InterruptManagementPath 'Device Parameters\Interrupt Management'
New-Variable -Option Constant MSIEnabledValueName 'MSISupported'
New-Variable -Option Constant MSIPropertiesPath 'MessageSignaledInterruptProperties'
New-Variable -Option Constant RootPath 'HKLM:\SYSTEM\CurrentControlSet\Enum\PCI'

class Device {
    [string]$ProductID
    [string]$VendorID

    Device([string]$vendorId, [string]$productId) {
        $this.ProductID = $productId.ToUpper()
        $this.VendorID = $vendorId.ToUpper()
    }
}

$devices = [System.Collections.Generic.HashSet[Device]]::new()


########################################################################################################################
# process parameters
########################################################################################################################

$PCIIDs.ForEach({
    if (-not ($_ -match '^(?<vid>[0-9a-f]{4}):(?<pid>[0-9a-f]{4})$')) {
        Write-Error ("PCI ID '$_' is invalid; please use syntax <vendor-id>:<product-id>.")
        Exit 1
    }
    $devices.Add([Device]::new($Matches.vid, $Matches.pid)) | Out-Null
})


########################################################################################################################
# process devices
########################################################################################################################

foreach ($device in $devices) {
    Write-Output "`nProcessing device $($device.VendorID):$($device.ProductID)."
    $deviceInstanceKeys = Get-ChildItem $RootPath -Depth 1 |
            Where-Object Name -Match "\\(VEN_$($device.VendorID)&DEV_$($device.ProductID).+\\.+)"
    if ($deviceInstanceKeys.Count -eq 0) {
        Write-Output '└ No instances found; skipping device.'
        continue
    }
    foreach ($deviceInstanceKey in $deviceInstanceKeys) {
        Write-Output "└ Found instance: $($Matches[1])"
        try {
            $interruptManagementKey = Get-Item "$($deviceInstanceKey.PSPath)\$InterruptManagementPath"
            $msiPropertiesKey = $null;
            try {
                $msiPropertiesKey = Get-Item "$($interruptManagementKey.PSPath)\$MSIPropertiesPath"
            } catch [System.Management.Automation.ItemNotFoundException] {
                Write-Output "  No '$MSIPropertiesPath' key; creating it."
                $msiPropertiesKey = New-Item "$($interruptManagementKey.PSPath)\$MSIPropertiesPath"
            }
            $msiEnabled = 0
            try {
                $msiEnabled = (Get-ItemProperty $msiPropertiesKey.PSPath $MSIEnabledValueName).$MSIEnabledValueName
            } catch [System.Management.Automation.PSArgumentException] {}
            if ($msiEnabled -eq 0) {
                Write-Output '  MSI is currently disabled; turning it on.'
                Set-ItemProperty $msiPropertiesKey.PSPath $MSIEnabledValueName 1
            } else {
                Write-Output '  MSI is already enabled; skipping instance.'
            }
        } catch [System.Management.Automation.ItemNotFoundException] {
            Write-Output "  No '$InterruptManagementPath' key; skipping instance."
        }
    }
}
