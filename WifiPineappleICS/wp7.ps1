# Share internet with Wifi pinapple
# Credit to the Hak5 dev team for wp7.sh and pinapple web documentation
# and Aidan Holland (thehappydinoa) for https://github.com/hak5/bashbunny-payloads/blob/master/payloads/library/general/Windows_NIC_Sharing/p.ps1
# Credit to Wasabi Fan on technet for the Com-Object stuff

Clear-Host
regsvr32 /s hnetcfg.dll # Register HNetCfg library
$NetSharing = New-Object -ComObject HNetCfg.HNetShare  # Create NetSharingManager object

$wpver=7.0
#$spineapplenmask=255.255.255.0
#$spineapplenet=172.16.42.0/24
#$spineapplelan=eth1
#$spineapplewan=wlan0
$spineapplegw=192.168.1.1
$spineapplehostip=172.16.42.42
$spineappleip=172.16.42.1
$pineMatch = "^00:C0:CA|^00:13:37"

function share ($GUID, $Public) {
    $Connection = $NetSharing.EnumEveryConnection | ?{ $NetSharing.NetConnectionProps.Invoke($_).Guid -eq $GUID } # Find Connection
    $CfgSharing = $NetSharing.INetSharingConfigurationForINetConnection.Invoke($Connection) # Get sharing config
    if ($Public) { $pubvar = 0 } else { $pubvar = 1 }
    $CfgSharing.EnableSharing($pubvar) # Enable sharing with public (public = 0, private = 1)
}
function unshare ($GUID) {
    $Connection = $NetSharing.EnumEveryConnection | ?{ $NetSharing.NetConnectionProps.Invoke($_).Guid -eq $GUID } # Find Connection
    $NetSharing.INetSharingConfigurationForINetConnection.Invoke($Connection).DisableSharing() # Disable Sharing
}

Write-Host "    _       ___ _______    ____  _                              __    ";
Write-Host "   | |     / (_) ____(_)  / __ \\(_)___  ___  ____ _____  ____  / /__ ";
Write-Host "   | | /| / / / /_  / /  / /_/ / / __ \/ _ \/ __ '/ __ \/ __ \/ / _ \\";
Write-Host "   | |/ |/ / / __/ / /  / ____/ / / / /  __/ /_/ / /_/ / /_/ / /  __/ ";
Write-Host "   |__/|__/_/_/   /_/  /_/   /_/_/ /_/\___/\__,_/ .___/ .___/_/\___/  ";
Write-Host "                                               /_/   /_/       v$wpver";
#find pinapple
Write-Host "Step 1 of 3: Find the pineapple"
Write-Host "Please connect the WiFi Pineapple to this computer."
$cnt=0
do
{
    $WMIAdapters = Get-NetAdapter | where adminstatus -eq "up"
    $pineapple = ($WMIAdapters | Where-Object {($_.MacAddress -match $pineMatch) -and ($_.PhysicalMediaType -ne 'Native 802.11')})
    if($cnt -eq 50)
    {
        Write-Host "."
        $cnt=0
    }
    else
    {
        Write-Host  -NoNewline "."
        $cnt++
    }
    Start-Sleep 1
}
until($pineapple)
Write-Host "`nPineapple Found!"
Write-Host "Network interfaces:"
$WMIAdapters | Where-Object MacAddress -notMatch $pineMatch | Select-Object ifIndex, Name, ifDesc, MacAddress | FT;
# this one my be more useful as checks for internet
# $WMIAdapters | Where-Object MacAddress -notMatch $pineMatch | Get-NetConnectionProfile -ErrorAction SilentlyContinue | Where-Object IPv4Connectivity -contains "Internet" | Select-Object InterfaceIndex, Name, InterfaceAlias

Write-Host "Step 2 of 3: Select default interface (interface use to connect to the internet)"
do 
{
    try 
	{
        $numOk = $true
        [int]$netIndex = Read-host "Interface Index"
    }
    catch {$numOK = $false}
}
until (($netIndex -in $WMIAdapters.ifIndex) -and $numOK)

$nic =  $WMIAdapters | Where-Object ifIndex -eq $netIndex

Write-Host "Step 3 of 3: Setting up interface sharing"
Write-Output "Setting up interface sharing on primary NIC...."
share -GUID $nic.InterfaceGuid -Public $true # Set live NIC to share public
Write-Output "Setting up interface sharing on Wifi Pineapple...."
share -GUID $pineapple.InterfaceGuid -Public $false # Set Wifi Pineapple NIC to share private

Write-Output "Setting static IP for Wifi Pineapple NIC..."
# if you need to set a defaultGateway add this to the new-netipaddress line:
#-DefaultGateway $spineapplegw
New-NetIPAddress –IPAddress $spineapplehostip -PrefixLength 24 -InterfaceIndex $pineapple.InterfaceIndex

# clean up
$null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$NetSharing)
[gc]::Collect()
[gc]::WaitForPendingFinalizers()
Write-Host "Finished Pineapple setup"
Remove-Variable -Name NetSharing, nic, netIndex, WMIAdapters, cnt -ErrorAction SilentlyContinue -Force