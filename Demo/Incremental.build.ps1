
<#
.Synopsis
	Tests of full incremental and partial incremental tasks.

.Description
	These examples are just tests. For a real example of partial incremental
	build with dynamic input and output see Build.ps1, task ConvertMarkdown.
#>

### Make a few temporary old and new files
function New-OldFile($Name) {
	$null > $Name
	[System.IO.File]::SetLastWriteTime("$BuildRoot\$Name", '2000-01-01')
}
# old files
$old1 = 'z.old1.tmp'
$old2 = 'z.old2.tmp'
New-OldFile($old1)
New-OldFile($old2)
# new files
$new1 = 'z.new1.tmp'
$new2 = 'z.new2.tmp'
$null > $new1
$null > $new2

# Empty Inputs as a list. All script jobs are not invoked.
task EmptyInputs1 -Inputs @() -Outputs {} { throw 'Unexpected.' }, { throw 'Unexpected.' }

# Empty Inputs as a script. All script jobs are not invoked.
task EmptyInputs2 -Inputs {} -Outputs {} { throw 'Unexpected.' }, { throw 'Unexpected.' }

# Outputs are up-to-date.
# The script job is not invoked but the task-job is invoked before.
$PreFullIncrementalOneUpToDate = 0
task PreFullIncrementalOneUpToDate { ++$script:PreFullIncrementalOneUpToDate }
task FullIncrementalOneUpToDate -Inputs { 'Incremental.build.ps1' } -Outputs 'Incremental.build.ps1' PreFullIncrementalOneUpToDate, {
	throw 'Unexpected.'
}

# Outputs are up-to-date.
# The script job is not invoked but the task-job is invoked after.
$PostPartIncrementalOneUpToDate = 0
task PostPartIncrementalOneUpToDate { ++$script:PostPartIncrementalOneUpToDate }
task PartIncrementalOneUpToDate -Inputs { 'Incremental.build.ps1' } -Outputs { 'Incremental.build.ps1' } {
	throw 'Unexpected.'
}, PostPartIncrementalOneUpToDate

# One missing output item.
# The script job is invoked with the inputs.
$FullIncrementalOneMissing = 0
task FullIncrementalOneMissing -Inputs { 'Incremental.build.ps1' } -Outputs 'missing' {
	++$script:FullIncrementalOneMissing
	assert ($Inputs.Count -eq 1)
	assert ($Inputs[0] -like '*\Demo\Incremental.build.ps1')
	assert ($Outputs -eq 'missing')
}

# One missing output item.
# The script job is invoked with the inputs.
$PartIncrementalOneMissing = 0
task PartIncrementalOneMissing -Inputs { 'Incremental.build.ps1' } -Outputs { 'missing' } {
	++$script:PartIncrementalOneMissing
	assert ($Inputs.Count -eq 1)
	assert ($Inputs[0] -like '*\Demo\Incremental.build.ps1')
	assert ($Outputs.Count -eq 1)
	assert ($Outputs[0] -eq 'missing')
}

# One out-of-date item.
# The script job is invoked with the inputs.
$FullIncrementalOneOutOfDate = 0
task FullIncrementalOneOutOfDate -Inputs { 'Incremental.build.ps1' } -Outputs $old1 {
	++$script:FullIncrementalOneOutOfDate
	assert ($Inputs.Count -eq 1)
	assert ($Inputs[0] -like '*\Demo\Incremental.build.ps1')
	assert ($Outputs -eq $old1)
}

# One out-of-date item.
# The script job is invoked with the inputs.
$PartIncrementalOneOutOfDate = 0
task PartIncrementalOneOutOfDate -Inputs { 'Incremental.build.ps1' } -Outputs { $old1 } {
	++$script:PartIncrementalOneOutOfDate
	assert ($Inputs.Count -eq 1)
	assert ($Inputs[0] -like '*\Demo\Incremental.build.ps1')
	assert ($Outputs.Count -eq 1)
	assert ($Outputs[0] -like $old1)
}

# 2+ outputs are up-to-date.
# Inputs is a list (unlike Outputs it does not change anything).
task FullIncrementalTwoUpToDate -Inputs Incremental.build.ps1, .build.ps1 -Outputs $new1, $new2 {
	throw 'Unexpected.'
}

# 2+ outputs are up-to-date.
# Inputs is a script (unlike Outputs it does not change anything).
task PartIncrementalTwoUpToDate -Inputs { 'Incremental.build.ps1'; '.build.ps1' } -Outputs { $new1; $new2 } {
	throw 'Unexpected.'
}

# One output item is missing.
# All input items are piped (2).
# Inputs is a script (unlike Outputs it does not change anything).
$FullIncrementalTwoMissing = 0
task FullIncrementalTwoMissing -Inputs { 'Incremental.build.ps1'; '.build.ps1' } -Outputs 'missing', $new2 {
	++$script:FullIncrementalTwoMissing
	assert ($Inputs.Count -eq 2)
	assert ($Inputs[0] -like '*\Demo\Incremental.build.ps1')
	assert ($Inputs[1] -like '*\Demo\.build.ps1')
	assert ($Outputs.Count -eq 2)
	assert ($Outputs[0] -eq 'missing')
	assert ($Outputs[1] -eq $new2)
}

# One output item is missing.
# Only items with missing output are piped (1).
# Inputs is an array (unlike Outputs it does not change anything).
$PartIncrementalTwoMissing = 0
task PartIncrementalTwoMissing -Inputs Incremental.build.ps1, .build.ps1 -Outputs { $new1, 'missing' } {
	++$script:PartIncrementalTwoMissing
	assert ($Inputs.Count -eq 1)
	assert ($Inputs[0] -like '*\Demo\.build.ps1')
	assert ($Outputs.Count -eq 1)
	assert ($Outputs[0] -eq 'missing')
}

# One output item is out-of-date.
# All input items are piped (2).
$FullIncrementalTwoOutOfDate = 0
task FullIncrementalTwoOutOfDate -Inputs { 'Incremental.build.ps1'; '.build.ps1' } -Outputs $new1, $old2 {
	++$script:FullIncrementalTwoOutOfDate
	assert ($Inputs.Count -eq 2)
	assert ($Inputs[0] -like '*\Demo\Incremental.build.ps1')
	assert ($Inputs[1] -like '*\Demo\.build.ps1')
	assert ($Outputs.Count -eq 2)
	assert ($Outputs[0] -eq $new1)
	assert ($Outputs[1] -eq $old2)
}

# One output item is out-of-date.
# Only items with out-of-date output are piped (1).
$PartIncrementalTwoOutOfDate = 0
task PartIncrementalTwoOutOfDate `
-Inputs { 'Incremental.build.ps1'; '.build.ps1' } `
-Outputs { $new1, $old2 } `
{process{
	++$script:PartIncrementalTwoOutOfDate
	assert ($Inputs.Count -eq 1)
	assert ($Inputs[0] -like '*\Demo\.build.ps1')
	assert ($Outputs.Count -eq 1)
	assert ($Outputs[0] -eq $old2)
	assert($_ -like '*\Demo\.build.ps1')
	assert($$ -eq $old2)
}}

# The default task calls all test tasks and then checks the expected results.
task . `
EmptyInputs1,
EmptyInputs2,
FullIncrementalOneUpToDate,
PartIncrementalOneUpToDate,
FullIncrementalOneMissing,
PartIncrementalOneMissing,
FullIncrementalOneOutOfDate,
PartIncrementalOneOutOfDate,
FullIncrementalTwoUpToDate,
PartIncrementalTwoUpToDate,
FullIncrementalTwoMissing,
PartIncrementalTwoMissing,
FullIncrementalTwoOutOfDate,
PartIncrementalTwoOutOfDate,
{
	assert ($PreFullIncrementalOneUpToDate -eq 1)
	assert ($PostPartIncrementalOneUpToDate -eq 1)

	assert ($FullIncrementalOneMissing -eq 1)
	assert ($PartIncrementalOneMissing -eq 1)

	assert ($FullIncrementalOneOutOfDate -eq 1)
	assert ($PartIncrementalOneOutOfDate -eq 1)

	assert ($FullIncrementalTwoMissing -eq 1)
	assert ($PartIncrementalTwoMissing -eq 1)

	assert ($FullIncrementalTwoOutOfDate -eq 1)
	assert ($PartIncrementalTwoOutOfDate -eq 1)

	Remove-Item z.*.tmp
}