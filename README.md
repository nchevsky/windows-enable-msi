# Usage
```
PS> .\enable-msi.ps1 <vendor-id>:<device-id> [<vendor-id>:<device-id> ...]
```
## Example
```
PS> .\enable-msi.ps1 10DE:1D01 8086:A348

Processing device 10DE:1D01.
└ Found instance: VEN_10DE&DEV_1D01&SUBSYS_8C981462&REV_A1\4&3335b6e8&0&00E0
  MSI is currently disabled; turning it on.

Processing device 8086:A348.
└ Found instance: VEN_8086&DEV_A348&SUBSYS_1A1D15D9&REV_10\5&226b9205&0&E008F0
  MSI is already enabled; skipping instance.
```

# Group Policy Deployment
💡 Since a device's MSI flag gets reset whenever its driver is updated, setting the script to run automatically at shutdown/startup ensures MSI stays enabled.
1. Decide whether to deploy as a shutdown or startup script. Shutdown is recommended as MSI is enabled at the next startup, while this takes an extra reboot with a startup script.
2. Install `enable-msi.ps1` to `\\<domain>\SYSVOL\<domain>\Policies\<policy-guid>\MACHINE\Scripts\<Shutdown|Startup>`.
3. In _Group Policy Management Editor_ (`gpedit.msc`):
   
   _Computer Configuration_ ➡ _Policies_ ➡ _Windows Settings_ ➡ _Scripts (Startup/Shutdown)_ ➡
<_Shutdown_|_Startup_> ➡ _PowerShell Scripts_ ➡ _Add..._
   - _Script Name:_ `enable-msi.ps1`
   - _Script Parameters:_ `<vendor-id>:<device-id> [<vendor-id>:<device-id> ...]` (e.g. `10DE:1D01 8086:A348`)

# Mode of Operation
The script finds devices with the given PCI IDs in the registry and sets their `MSISupported` property to `1`, creating intermediate keys as needed.

`HKLM\SYSTEM\CurrentControlSet\Enum\PCI\<device-instance-path>\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties`
- `MSISupported` (DWORD): `0` ➡ `1`
