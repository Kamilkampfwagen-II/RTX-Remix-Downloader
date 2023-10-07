$ErrorActionPreference = 'SilentlyContinue'
rem <#
	cls
	@echo off
	cd %~dp0
	set "helper=$args=$args -split '';$Error.Clear();Set-Variable PSScript -Option Constant -Value ([ordered]@{Root=$args[0].Substring(0,$args[0].Length-1);Name=$args[1];FullName=$args[2];Args=$args[3..$args.length]}).AsReadOnly();Invoke-Command([ScriptBlock]::Create((Get-Content $args[2] -Raw))) -NoNewScope -ArgumentList $args[3..$args.Length]"

	:initArg
	set args=%~dp0%~nx0%0
	if '%1'=='' goto exec
	set args=%args%%1

	:addArg
	shift
	if '%1'=='' goto exec
	set args=%args%%1
	goto addArg

	:exec
	Powershell.exe -ExecutionPolicy Bypass -Command $ErrorActionPreference = 'Continue';$args = '%args%';%helper%
	exit
rem #>

#	---RTX Remix Downloader---
$ErrorActionPreference = 'Inquire'
Add-Type -Assembly 'System.IO.Compression.Filesystem'

$debug = $false
$dxvkRepo = 'NVIDIAGameWorks/dxvk-remix'
$bridgeRepo = 'NVIDIAGameWorks/bridge-remix'
$workflow = 'build'
$branch = 'main'


Write-Host 'RTX Remix Downloader'
Write-Host 'This script is dependant on the nightly.link project by oprypin'
Write-Host 'This script is not affiliated with the RTX Remix project by NVIDIAGameWorks' -ForegroundColor Red
Write-Host ''

Write-Host '0 - Release Build (default)'
Write-Host '1 - Debug Optimized Build'
Write-Host '> ' -NoNewline
if (($Host.UI.ReadLine()) -eq 1) {
	$linkIndex = 4
	$targetFolder = 'remix-debug'
} else {
	$linkIndex = 6
	$targetFolder = 'remix-release'
}
Write-Host ''

New-Item -Path "$($PSScript.Root)/$targetFolder/temp" -ItemType Directory -Force | Out-Null
Set-Location "$($PSScript.Root)/$targetFolder"


# Remove any possible leftovers to prevent stupid Powershell cmdlets from failing
Remove-Item -Path './temp/*' -Recurse -Force -ErrorAction Ignore


$dxvkDated = $false
$bridgeDated = $false
$currentRunList = Get-Content './version.txt' -ErrorAction Ignore
if ($currentRunList) {
	$currentDxvkRun = $currentRunList[0]
	$currentBridgeRun = $currentRunList[1]
} else {
	$currentDxvkRun = ''
	$currentBridgeRun = ''
}


Write-Host 'Fetching the latest dxvk-remix build info..'
$progressPreference = 'SilentlyContinue'
$dxvkNightlyInfo = Invoke-WebRequest -Uri "https://nightly.link/$dxvkRepo/workflows/$workflow/$branch" -UseBasicParsing
$progressPreference = 'Continue'
$latestDxvkRun = $dxvkNightlyInfo.Links[$linkIndex].href.Split('-')[3]

if ($currentDxvkRun -eq $latestDxvkRun) {
    Write-Host 'Up to date!' -ForegroundColor Green
} else {
	$dxvkDated = $true
    Write-Host 'A new build is available: ' -NoNewline
    Write-Host $latestDxvkRun -ForegroundColor Blue
}


Write-Host 'Fetching the latest bridge-remix build info..'
$progressPreference = 'SilentlyContinue'
$bridgeNightlyInfo = Invoke-WebRequest -Uri "https://nightly.link/$bridgeRepo/workflows/$workflow/$branch" -UseBasicParsing
$progressPreference = 'Continue'
$latestBridgeRun = $bridgeNightlyInfo.Links[$linkIndex].href.Split('-')[3]

if ($currentBridgeRun -eq $latestBridgeRun) {
    Write-Host 'Up to date!' -ForegroundColor Green
} else {
	$bridgeDated = $true
    Write-Host 'A new build is available: ' -NoNewline
    Write-Host $latestBridgeRun -ForegroundColor Blue
}


if (!$dxvkDated -and !$bridgeDated) {
	Remove-Item -Path './temp' -Recurse -Force
	Write-Host ''
	Read-Host -Prompt "Press enter to open the $targetFolder folder"
	& explorer.exe .
	exit
}


if ($debug) {
	$dxvkNightlyLink = 'file:///D:/Projects/Powershell/RTX-Remix-Downloader/Test/dxvk-remix-release.zip'
	$bridgeNightlyLink = 'file:///D:/Projects/Powershell/RTX-Remix-Downloader/Test/bridge-remix-release.zip'
} else {
	$dxvkNightlyLink = $dxvkNightlyInfo.Links[$linkIndex].href
	$bridgeNightlyLink = $bridgeNightlyInfo.Links[$linkIndex].href
}


if ($dxvkDated) {

	Write-Host 'Downloading the latest dxvk-remix build from ' -NoNewline
	Write-Host 'NVIDIAGameWorks/dxvk-remix' -ForegroundColor Blue
	$progressPreference = 'SilentlyContinue'
	Invoke-WebRequest -Uri $dxvkNightlyLink -OutFile './temp/dxvk-remix.zip' -UseBasicParsing
	$progressPreference = 'Continue'
	

	Write-Host 'Extracting files from the archive..'
	[System.IO.Compression.ZipFile]::ExtractToDirectory("$($PSScript.Root)/$targetFolder/temp/dxvk-remix.zip", "$($PSScript.Root)/$targetFolder/temp/dxvk-remix")


	Move-Item -Path './temp/dxvk-remix' -Destination './.trex' -Force

}


if ($bridgeDated) {

	Write-Host 'Downloading the latest bridge-remix build from ' -NoNewline
	Write-Host 'NVIDIAGameWorks/bridge-remix' -ForegroundColor Blue
	$progressPreference = 'SilentlyContinue'
	Invoke-WebRequest -Uri $bridgeNightlyLink -OutFile './temp/bridge-remix.zip' -UseBasicParsing
	$progressPreference = 'Continue'


	Write-Host 'Extracting files from the archive..'
	[System.IO.Compression.ZipFile]::ExtractToDirectory("$($PSScript.Root)/$targetFolder/temp/bridge-remix.zip", "$($PSScript.Root)/$targetFolder/temp/bridge-remix")


	Move-Item -Path './temp/bridge-remix/d3d9.dll', './temp/bridge-remix/NvRemixLauncher32.exe' -Destination '.' -Force
	Move-Item -Path './temp/bridge-remix/.trex/NvRemixBridge.exe' -Destination './.trex' -Force

}


Write-Host 'Updating version info..'
Set-Content -Path './version.txt' -Value ($latestDxvkRun,$latestBridgeRun) -Force


Write-Host 'Cleaning up..'
Remove-Item -Path './temp' -Recurse -Force
Remove-Item -Path '*.pdb' -Recurse -Force


Write-Host 'Done!' -ForegroundColor Green
Write-Host ''
Read-Host -Prompt "Press enter to open the $targetFolder folder"
& explorer.exe .