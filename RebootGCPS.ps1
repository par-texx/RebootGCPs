[CmdletBinding()]

Param (
    [string]$RemoteList = $(Read-Host "Name of the file with the list of computers to reboot.")
    
    )

#Set flags for debug mode.    
If($psBoundParameters['debug'])
    {
    $DebugPreference = "Continue"
    }
Else
    {
    $DebugPreference = "SilentlyContinue"
    }


Try
    {
    $gcps = Get-Content $RemoteList -ErrorAction Stop
    }
Catch
    {
    Write-Host "File could not be read."
    Write-Debug $_.Exception.Message
    Exit
    }

$jobs = @()

$ScriptBlock =
{
	Param ([string]$computername)
    Try
    {
	Invoke-Command -computername $computername	{ shutdown /m \\$computername /r /t 0 } -ErrorAction stop
    }
    Catch
    {
        Write-Debug "Unable to connect to $computername".  
        Write-Debug $_.Exception.Message
    }
}

#Get-Content $RemoteList | Measure-Object -Line
$lines = Get-Content $RemoteList | Measure-Object -Line
Write-Host "There are $($lines | Select Lines) machines to reboot"

Foreach($gcp in $gcps)
{
	if ($gcp.StartsWith("#"))
	{
		Write-Debug "$gcp skipped..."
	}
	else
	{
		Write-Debug "Restarting $gcp"
		$jobs += Start-Job -ScriptBlock $ScriptBlock -ArgumentList $gcp
	}
}

Write-Host "Waiting for jobs to finish"

#$runningjobs = Receive-Job -ID $jobs.id -Keep
Write-Debug $jobs.id

#Do
#{#
#	Start-Sleep 1
#} Until (($jobs | Where State -eq "Running").Count -eq 0)
Wait-Job -Id $jobs.id


Remove-Job -State Completed

Read-Host -Prompt "Reboots Done - Press enter to close"