
<#
.Synopsis
	Tests dot-sourcing of Invoke-Build.

.Description
	This script imports Invoke-Build runtime environment and tests it. It is
	supposed to be invoked by PowerShell.exe, i.e. not from a build script.
#>

Set-StrictMode -Version Latest

# to be changed/tested
$ErrorActionPreference = 'Continue'

# to be changed/tested
Set-Location -LiteralPath $HOME

# import tools
. Invoke-Build

### Test assert first of all

# `assert` works and gets the proper position
($e = try {assert 0} catch {$_ | Out-String})
assert ($e -like '*Assertion failed.*try {assert*')

### Test variables and current location

# error preference is Stop
assert ($ErrorActionPreference -eq 'Stop')

# $BuildFile is set
assert ($BuildFile -eq $MyInvocation.MyCommand.Definition) "$BuildFile -eq $($MyInvocation.MyCommand.Definition)"

# $BuildRoot is set
assert ($BuildRoot -eq (Split-Path $BuildFile))

# location is set
assert ($BuildRoot -eq (Get-Location).Path)

### Test special aliases and targets

# aliases for using

($r = Get-Alias assert)
assert ($r.Definition -ceq 'Assert-Build')

($r = Get-Alias exec)
assert ($r.Definition -ceq 'Invoke-BuildExec')

($r = Get-Alias property)
assert ($r.Definition -ceq 'Get-BuildProperty')

($r = Get-Alias use)
assert ($r.Definition -ceq 'Use-BuildAlias')

# aliases for Get-Help

($r = Get-Alias error)
assert ($r.Definition -ceq 'Get-BuildError')

($r = Get-Alias task)
assert ($r.Definition -ceq 'Add-BuildTask')

($r = Get-Alias job)
assert ($r.Definition -ceq 'New-BuildJob')

### Test special functions

Push-Location function:

# function should not exist
assert (!(Test-Path Write-Warning))

# expected public functions
$OK = 'Add-BuildTask,Assert-Build,Get-BuildError,Get-BuildFile,Get-BuildProperty,Get-BuildVersion,Invoke-BuildExec,New-BuildJob,Use-BuildAlias,Write-Build'
$KO = (Get-ChildItem *-Build* -Name | Sort-Object) -join ','
assert ($OK -ceq $KO) "Unexpected functions:
OK: [$OK]
KO: [$KO]"

# expected internal functions
$OK = '*AB,*Bad,*CP,*EI,*FP,*II,*IO,*My,*RJ,*SL,*Task,*TE,*TH,*Try,*TS,*UC,*WE'
$KO = (Get-ChildItem [*]* -Name | Sort-Object) -join ','
assert ($OK -ceq $KO) "Unexpected functions:
OK: [$OK]
KO: [$KO]"

Pop-Location

### Test exposed commands

# assert is already tested

### exec

# exec 0
($r = exec { cmd /c echo Code0 })
assert ($LASTEXITCODE -eq 0)
assert ($r -eq 'Code0')

# exec 42 works
($r = exec { cmd /c 'echo Code42&& exit 42' } (40..50))
assert ($LASTEXITCODE -eq 42)
assert ($r -eq 'Code42')

# exec 13 fails
($e = try {exec { cmd /c exit 13 }} catch {$_ | Out-String})
assert ($LASTEXITCODE -eq 13)
assert ($e -like 'exec : Command { cmd /c exit 13 } exited with code 13.*try {exec *')

### property

($r = property BuildFile)
assert ($r -eq $BuildFile)

($r = property ComputerName)
assert ($r -eq $env:COMPUTERNAME)

($r = property MissingVariable DefaultValue)
assert ($r -eq 'DefaultValue')

($e = try {property MissingVariable} catch {$_ | Out-String})
assert ($e -like 'property : Missing variable *try {property *')

### use

#! Mind \\Framework(64)?\\

use 4.0 MSBuild
($r = Get-Alias MSBuild)
assert ($r.Definition -like '?:\*\Microsoft.NET\Framework*\v4.0.*\MSBuild')

use Framework\v4.0.30319 MSBuild
($r = Get-Alias MSBuild)
assert ($r.Definition -like '?:\*\Microsoft.NET\Framework*\v4.0.30319\MSBuild')

use $BuildRoot Dot-test.ps1
($r = Get-Alias Dot-test.ps1)
assert ($r.Definition -eq $BuildFile)

($e = try {use Missing MSBuild} catch {$_ | Out-String})
assert ($e -like 'use : Cannot resolve *try {use *')

### misc

# Write-Warning works as usual
Write-Warning 'Ignore this warning.'

# done, use Write-Build
Write-Build Green Succeeded
