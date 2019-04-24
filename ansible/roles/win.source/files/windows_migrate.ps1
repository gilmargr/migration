# Optional parameter.  Replace (hostname).ToLower() with custom string
# $Hostname = ""
$Hostname=($env:computername).ToLower()

#######################################################################################
# Constants and Env Parameters
#######################################################################################
$TarPath = "C:\ocic_oci_mig"

$target_script_file = $TarPath + "\windows_migrate.ps1"
$recurring_interval_minutes = "2"

# https://www.petri.com/unraveling-mystery-myinvocation
$script_name=$MyInvocation.InvocationName

$metadata_filename = "host_metadata.json"
$configuration_complete_filename = $TarPath + "\configuration_complete.txt"
$SchTask_job_name = "OCIC_to_OCI__Migration"
$vm_meta_discovery_log_name = "VM_Metadata_Discovery_log.txt"
$vm_launch_log_name = "VM_Launch_log." + ("{0:yyyyMMdd}-{0:HHmmss}" -f (Get-Date)) + ".txt"

$drive_list_path =  $TarPath + "\drive_list.txt"


###############################################################################
#  Functions
###############################################################################

function get_timestamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)   
}

function get_logfile($_path, $_log_filename) {
    $LogFilePath = $_path + "\" + $_log_filename
    if (Test-Path $LogFilePath) {
	    Remove-Item $LogFilePath
    }
    New-Item $LogFilePath -ItemType file | Out-Null
    return $LogFilePath
}

function Log($msg) {
    $msg = ("$(get_timestamp) $msg")
    Add-Content $log_file $msg
}

function get_osVersion {
    $OSVerNum = [system.environment]::osversion

    if ($OSVerNum.Version.Major -eq "10") {
	    $OSVersion = "2016R1"
    }
    elseif ($OSVerNum.Version.Minor -eq "3") {
	    $OSVersion = "2012R2"
    }
    elseif ($OSVerNum.Version.Minor -eq "2") {
	    $OSVersion = "2012R1"
    }
    elseif ($OSVerNum.Version.Minor -eq "1") {
	    $OSVersion = "2008R2"
    }
    elseif ($OSVerNum.Version.Minor -eq "0") {
	    $OSVersion = "2008R1"
    }
    else {
	    $OSVersion = "UNDEFD"
    }
    return $OSVersion
}

function get_osEdition {
    $EditionNum = (get-wmiobject win32_operatingsystem).OperatingSystemSKU

    $StandarList = 7,13,40
    $EnterpriseList = 4,10,14,41
    $DatacenterList = 8,12,39

    if ($StandarList -Contains $EditionNum) {
	    $Edition = "stn"
    }
    elseif ($EnterpriseList -Contains $EditionNum) {
	    $Edition = "ent"
    }
    elseif ($DatacenterList -Contains $EditionNum) {
	    $Edition = "dat"
    }
    else {
	    $Edition = "und"
    }
    return $Edition
}

function get_filenameRoot ($OSVersion, $Edition) {
    return $FilenameRoot = ($hostname + "-" + $OSVersion + "-" + $Edition)
}

function create_scheduled_job($schTaskfile_path) {
    Log ("Creating schedule job.  Job filepath: " + $schTaskfile_path)
	$call_params = @("/Create", 
					"/SC", "MINUTE",
                    "/MO", $recurring_interval_minutes,
					"/TN", $SchTask_job_name,
					"/TR", ("powershell.exe -command `"$schTaskfile_path`""),
					"/F", #force
					"/RU", "SYSTEM",
                    "/RL", "HIGHEST")
	& "schtasks.exe" $call_params
    Log ("Job parameters: " + $call_params)
    Log "Created job"
}

function delete_scheduled_job() {
	$call_params = @("/Delete", "/TN", $SchTask_job_name, "/F")
	& "schtasks.exe" $call_params
}

function get_oci_instance_id
{
    $url = "http://169.254.169.254/opc/v1/instance/id"
    try {
        if ($PSVersionTable.PSVersion.Major -eq 2) {
            $wc = New-Object System.Net.WebClient
            $result = $wc.DownloadString($url)
        } else {
            $result = invoke-webrequest $url -UseBasicParsing -ErrorAction:Stop
        }
        return $result
    } 
    catch {
        return ""   # swallow exception and return empty string to indicate not running on OCI
    }
}

function list_targets
{
<# ListTargets output example
Microsoft iSCSI Initiator Version 6.0 Build 6000
Targets List:
   iqn.2015-12.com.oracleiaas:df0209ee-...
   iqn.2015-12.com.oracleiaas:448daae9-...
The operation completed successfully.
#>
    $results = iscsicli ListTargets | Out-String
    # targets are in output following string "Targets List:"
    $r1, $results = $results.Split(":", 2)
    $targets = $results.Trim().TrimEnd('The operation completed successfully.')
    $targets = $targets -split '\s+'
    return $targets
}

function PS_v2_find_and_login_iscsi
{
    for ($i=2; $i -lt 12; $i++) {
        $existing_targets = list_targets
        $ipaddr = "169.254.2." + $i
        Log ("Searching address: iscsicli QAddTargetPortal " + $ipaddr)
        $result = iscsicli QAddTargetPortal $ipaddr | Out-String
        if ($result.Contains("Target Error")){
            Log ("No valid target portal at address: " + $ipaddr)
            Log ("To undo QAddTargetPortal: iscsicli RemoveTargetPortal " + $ipaddr + " 3260")
            iscsicli RemoveTargetPortal $ipaddr 3260
            continue
        }

        start-sleep 2  # occasionally, I noticed new targets do not show up immediately
        $targets = list_targets
        $targets = $targets | where { $existing_targets -notcontains $_ }
        if ($targets -eq $null) {
            Log ("No new target found after adding target portal at address: " + $ipaddr)
            continue
        }
        Log ("Targets found at address: " + $ipaddr + ": " + $targets)
        foreach ( $t in $targets ) {
            Log ("Now login to target: iscsicli QLoginTarget " + $t)
            $result = iscsicli QLoginTarget $t
            Log ($result)
            Log ("iscsicli PersistentLoginTarget " + $t + " * " + $ipaddr + " 3260 * * * * * * * * * * * * * *")
            $result = iscsicli PersistentLoginTarget $t * $ipaddr 3260 * * * * * * * * * * * * * *
            Log ($result)
        }
    }
}

function PS_v2_put_disks_online()
{
<# output example for "list disk" | diskpart
Microsoft DiskPart version 6.2.9200

Copyright (C) 1999-2012 Microsoft Corporation.
On computer: WIN8-HOME

  Disk ###  Status         Size     Free     Dyn  Gpt
  --------  -------------  -------  -------  ---  ---
  Disk 0    Online           40 GB  1024 KB
  Disk 1    Offline          20 GB  8128 KB
  Disk 2    Offline          20 GB    20 MB
#>
    $ret = "list disk" | diskpart
    Log ("list disk: " + $ret)
    $lines = $ret -split '\r\n'
    $lines = $lines | where { $_.Contains("Offline") }
    if ($lines -eq $null) { return }
    foreach ( $line in $lines ) {
        $elems = $line.trim().split(' ')
        $disk_n = $elems[0] + " " + $elems[1]
        $sel_cmd = "select " + $disk_n
        $clear_rdonly = "attribute disk clear readonly"
        $online_cmd = "online disk"
        Log ("now put disk Online")
        $ret = $sel_cmd, $clear_rdonly, $online_cmd | diskpart
        Log ($ret)
    }
}

function setup_kms()
{
    $oci_kms = '169.254.169.253'
    $ocic_kms = 'kms.oraclecloud.com'
    $kms_info = C:\getkms.bat
    $current_kms = $kms_info -split '\s+' | Select-Object -Last 2 | Out-String
    $current_kms = $current_kms.trim()
    Log ("Current KMS is " + $current_kms)
    if ($current_kms -eq $oci_kms) { return }

    $opckms_path = 'C:\opckms.bat'
    (Get-Content $opckms_path) -replace $ocic_kms, $oci_kms | Set-Content $opckms_path
    cmd.exe /c $opckms_path
}

#############################################################################
#  Body
#############################################################################


# Determine if running in OCI-C or OCI
write-host("Determine platform environment.  This may take a few seconds... ")
$instance_ocid = get_oci_instance_id
    if (!$instance_ocid) {
        # An empty string means we aren't running on OCI     
        write-host("Running in OCI-C")

        If(!(test-path $TarPath))
        {
            New-Item -ItemType Directory -Force -Path $TarPath | Out-Null
        }
        
        # Move PS file to target path if not done already - required for Scheduled Task execution on target
        if ($script_name -ne $target_script_file) {
            Copy-Item $script_name -Destination $target_script_file | Out-Null
        }

        $manifestFilepath = ($TarPath + "\" + $metadata_filename)
        if (Test-Path ($manifestFilepath)) {
            write-host("OCI-C metadata file exists.  Exiting")
            Write-Host ("")
            write-host("To rerun the script, please delete $manifestFilepath manually.")
            Write-Host ("")
            exit
        }
        else {
            write-host("OCI-C metadata does not exist.  Performing discovery work")
            $log_file = get_logfile $TarPath $vm_launch_log_name
            
            Log ("Performing system discovery and generating metadata file")
            
            $OSVersion = get_osVersion
            $Edition = get_osEdition


            Log ("Hostname: " + $Hostname)
            Log ("OS Version: " + $OSVersion)
            Log  ("OS Edition: " + $Edition)

            Write-Host("    Hostname: " + $Hostname)
            Write-Host("    OS Version: " + $OSVersion)
            Write-Host("    OS Edition: " + $Edition)  
            
            # create scheduled task
            create_scheduled_job $target_script_file
            
            # Enumerate attached storage drives and loop through the disk2vhd.exe call
            $DriveList = New-Object System.Collections.ArrayList
            $VolumeArray = New-Object System.Collections.ArrayList

            $VolList = Get-WmiObject Win32_Volume |Where { $_.drivetype -eq '3' -and $_.Label -ne 'Boot'}

            Foreach ($Vol in $VolList) {
                if ($Vol.DriveLetter -ne $null -and $Vol.DriveLetter.substring(0,1) -eq "C") {
                    Write-Host("Skip drive C:\")
                    continue
                }

                $VolumeArray.add('    "' + $Vol.Name + '" : "' +  ([math]::Round(([decimal]$Vol.Capacity)/1024/1024/1024).tostring() + 'G"')) | Out-Null
                if ($Vol.DriveLetter -ne $null) {
                    $DriveList.add($Vol.SerialNumber.tostring() + "," + $Vol.DriveLetter.substring(0,1)) | Out-Null
                }
                else {
                    $DriveList.add($Vol.SerialNumber.tostring() + "," ) | Out-Null
                }
            }

            #########################################################################
            # Generate drive letter list file
            Out-File -FilePath $drive_list_path -InputObject ($DriveList)

            # Generate manifest file
            Out-File -FilePath $manifestFilepath -InputObject ('[')
            Out-File -FilePath $manifestFilepath -InputObject ('  {')  -Append
            Out-File -FilePath $manifestFilepath -InputObject ('    "' + 'hostname' + '":"' +  $hostname  + '",')  -Append
            Out-File -FilePath $manifestFilepath -InputObject ('    "' + 'os' + '":"' + "Windows" + '",')  -Append
            Out-File -FilePath $manifestFilepath -InputObject ('    "' + 'osversion' + '":"' + ($osversion + '_' + $Edition) + '",')  -Append
    
            # Process vollist array
            $VolCnt = $VolumeArray.count

            Out-File -FilePath $manifestFilepath -InputObject ('    "' + 'AttachedVolumeCount' + '":"' + ($VolCnt) + '",')  -Append

            Out-File -FilePath $manifestFilepath -InputObject ('    "' + 'AttachedVolumeDetails' + '":  {')  -Append
            if($VolCnt -ne 0) {
                Write-host("Number of attached drives to include in manifest file: " + $VolumeArray.count)
                foreach ($tmpvol in $VolumeArray) {
                    Out-File -FilePath $manifestFilepath -InputObject ('                          ' + $tmpvol + ",")  -Append
                }
            }

            Out-File -FilePath $manifestFilepath -InputObject ('                          }')  -Append
            Out-File -FilePath $manifestFilepath -InputObject ('  }')  -Append
            Out-File -FilePath $manifestFilepath -InputObject (']') -Append

            Write-Host ("")    
            Write-Host ("Processing complete")
            Write-Host ("") 
        }
    } 

    else {
        write-host("Running in OCI")
        write-host("Check if KMS is correctly setup")
        $log_file = get_logfile $TarPath $vm_launch_log_name
        setup_kms

        write-host("Check if configuration complete")
        if (Test-Path ($configuration_complete_filename)) {
            write-host("Configuration complete.  Exiting")
            exit
        } 
        else {
            write-host("Configuration not complete.  Commencing configuration")
            
            if ($PSVersionTable.PSVersion.Major -eq 2) {
                write-host ("PS v2 - requires iscsicli.exe")
                Set-Service -Name msiscsi -StartupType Automatic
                Start-Service msiscsi
                PS_v2_find_and_login_iscsi
                PS_v2_put_disks_online
            }
            else {
            # PS 3.0 or greater
                Set-Service -Name msiscsi -StartupType Automatic
                Start-Service msiscsi

                # Iterate through iscsi addresses to locate attached disks
                Log ("Iterate through iscsi addresses to locate attached disks")
                For ($i=2; $i -lt 12; $i++) {
                    $DiskPos = $i
                    Log ("Searching address: 169.254.2." + $DiskPos)
                    $TargetPortal = New-IscsiTargetPortal -TargetPortalAddress 169.254.2.$DiskPos -ErrorAction SilentlyContinue
                    if ($TargetPortal) {
                        Log ("Target Portal found at address: 169.254.2." + $DiskPos)
                        $TargetPortal | Get-IscsiTarget | Connect-IscsiTarget -NodeAddress {$_.NodeAddress} -IsPersistent $True  -ErrorAction SilentlyContinue
                    }
                }
            }

            # Iterate through available new volumes and perform configurations
            $VolumeArray = New-Object System.Collections.ArrayList

            $DriveList = Get-Content -Path ($drive_list_path)
            $SerialNumSet = @{}
            foreach ($drive in $DriveList) {
                $serial_number, $drive_letter = $drive.split(",")
                $SerialNumSet.Add($serial_number, $drive_letter)
            }

            $VolList = Get-WmiObject Win32_Volume |Where { $_.drivetype -eq '3' -and $_.Label -ne 'Boot' -and $_.Label -ne 'WinRE'}
    
            Log("Iterating through drives")
            foreach ($vol in $VolList) {
                if (($vol.DriveLetter -eq $null)) {
                    Log("Found volume without drive letter: " + $vol.Name + " with SerialNumber:" + $vol.SerialNumber.tostring())
                    if ($SerialNumSet.Contains($vol.SerialNumber.tostring())) {
                        $drive_letter = $SerialNumSet[$vol.SerialNumber.tostring()]
                        if ($drive_letter -eq "") {
                            Log("The volume has no drive letter originally, skipping: " + $vol.Name)
                        }
                        else {
                            Log("Reassign to original drive letter: " + $drive_letter)
                            $args = @{DriveLetter = $drive_letter + ":"}
                            $out_str = Set-WmiInstance -input $vol -Arguments $args  | Out-String
                            Log($out_str)
                        }
                    }
                }
                else {
                    Log("Found volume drive letter: " + $vol.DriveLetter + " with SerialNumber:" + $vol.SerialNumber.tostring())
                }
            }

            # Check if all source drives are mounted and configured
            $VolList = Get-WmiObject Win32_Volume |Where { $_.drivetype -eq '3' -and $_.Label -ne 'Boot' -and $_.Label -ne 'WinRE'}
            Foreach ($vol in $VolList) {
                $SerialNumSet.Remove($vol.SerialNumber.tostring())
            }
            if ($SerialNumSet.Count -eq 0) {
                Log ("Attached volume configuration complete")
                # post completion file
                Out-File -FilePath ($configuration_complete_filename) -InputObject ("Completed")
                Log ("delete scheduled job")
                delete_scheduled_job
            }
            else {
                Log("Attached volume configuration not yet complete. Still waiting for following volumes: ")
                Foreach ($key in $SerialNumSet.Keys) {
                    Log("Volume Serial Number: " + $key + " Drive Letter: " + $SerialNumSet[$key])
                }
                # exit, possibly generating an error 
            }
        }
    }
