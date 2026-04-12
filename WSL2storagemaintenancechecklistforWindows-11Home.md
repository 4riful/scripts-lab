# WSL 2 storage maintenance checklist for Windows 11 Home

Use this whenever your WSL distro grows too much or `ext4.vhdx` gets much larger than the actual Linux data.

## 1) Check real usage inside Linux

Run inside the distro:

```bash
df -h /
sudo du -xh --max-depth=1 / 2>/dev/null | sort -h
```

If needed, drill down into the biggest directories:

```bash
sudo du -xh --max-depth=1 /usr 2>/dev/null | sort -h
sudo du -xh --max-depth=1 /var 2>/dev/null | sort -h
sudo du -xh --max-depth=1 /root 2>/dev/null | sort -h
sudo du -xh --max-depth=1 /opt 2>/dev/null | sort -h
```

## 2) Clean obvious junk

Safe common cleanup:

```bash
sudo apt clean
sudo apt autoremove -y
sudo journalctl --vacuum-time=7d
rm -rf /root/.cache/*
```

If you use Docker:

```bash
docker system df
docker system prune -a --volumes
```

Be careful with the prune command. It removes unused images, containers, and volumes.

## 3) Shut down WSL from Windows

Run in PowerShell:

```powershell
wsl --shutdown
```

## 4) Find the distro VHDX path

For your UbuntuRestored distro:

```powershell
(Get-ChildItem -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss |
 Where-Object { $_.GetValue("DistributionName") -eq 'UbuntuRestored' }
).GetValue("BasePath") + "\ext4.vhdx"
```

## 5) Compact the VHDX with diskpart

Open PowerShell or CMD as Administrator:

```text
diskpart
select vdisk file="C:\WSL\UbuntuRestored\ext4.vhdx"
attach vdisk readonly
compact vdisk
detach vdisk
exit
```

`readonly` is expected and safe for this operation.

## 6) Check the new VHDX size

Run in PowerShell:

```powershell
Get-Item "C:\WSL\UbuntuRestored\ext4.vhdx" | Select-Object FullName,@{Name="SizeGB";Expression={[math]::Round($_.Length/1GB,2)}}
```

## 7) Start WSL again

```powershell
wsl -d UbuntuRestored
```

Then verify again inside Linux:

```bash
df -h /
```

## 8) When compaction is not enough

If the VHDX stays much bigger than expected even after cleanup and compaction, rebuild it cleanly:

```powershell
wsl --shutdown
wsl --export UbuntuRestored D:\Backup\UbuntuRestored.tar
wsl --unregister UbuntuRestored
wsl --import UbuntuRestored D:\WSL\UbuntuRestored D:\Backup\UbuntuRestored.tar --version 2
```

This is the strongest fix for long-lived or restored distros with historical bloat.

## 9) Good habits to prevent future bloat

* Clean apt cache regularly
* Remove old Docker images and volumes
* Watch `/var`, `/root`, `/usr`, and language tool caches
* Compact after deleting large amounts of data
* Keep important distros backed up with `wsl --export`

## Quick version

```bash
# Inside WSL
df -h /
sudo du -xh --max-depth=1 / 2>/dev/null | sort -h
sudo apt clean && sudo apt autoremove -y
rm -rf /root/.cache/*
```

```powershell
# In Windows PowerShell
wsl --shutdown
diskpart
```

```text
select vdisk file="C:\WSL\UbuntuRestored\ext4.vhdx"
attach vdisk readonly
compact vdisk
detach vdisk
exit
```

```powershell
Get-Item "C:\WSL\UbuntuRestored\ext4.vhdx" | Select-Object FullName,@{Name="SizeGB";Expression={[math]::Round($_.Length/1GB,2)}}
```
