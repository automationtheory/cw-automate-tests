# This script performs automated tests of ConnectWise Automate
# Author: Jeremy Oaks, Automation Theory, LLC

param([Int]$testComputerID = 0, [Int]$testScriptID = 0, [Int]$testSleepTimeSeconds = 120, [String]$testScriptParams = "")

## Test Prep ##

# Set communications to TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install MySQL Module
if (!(Get-Module -Name SimplySql))
{
Install-Module -Name SimplySql
}

# Get LTPoSH
(new-object Net.WebClient).DownloadString('https://bit.ly/LTPoSh') | iex

# MySQL Connection details

$MySQLPassword = ConvertFrom-LTSecurity (Get-ItemProperty 'HKLM:\SOFTWARE\LabTech\Agent' -Name MysqlPass).MysqlPass
$MySQLUser = (Get-ItemProperty 'HKLM:\SOFTWARE\LabTech\Agent' -Name User).User
$MySQLHost =  (Get-ItemProperty 'HKLM:\SOFTWARE\LabTech\Agent' -Name SQLServer).SQLServer

# Open Connection
$MySQLConnection = Open-MySqlConnection -Server $MySQLHost -Database "labtech" -UserName $MySQLUser -Password $MySQLPassword

# Additional items
$testResultList = New-Object -TypeName 'System.Collections.ArrayList'; # List for results

# Function to put test results into the list
function log-test ($name, $result)
{
$automateTest = [PSCustomObject]@{
    Name     	= "$name"
    Result 		= "$result"
    }

$testResultList.Add($automateTest) | Out-Null

}


## Tests ##

# Test 1: Computer Checkin
# This test counts the number of online computers in Automate

$test1_results = Invoke-SqlQuery -Query "Select count(*) as OnlineCount from computers where lastcontact > date_add(now(), interval -5 minute);"

if ($test1_results.OnlineCount -gt 0)
{
log-test "Agent check-in" "Pass"
}
else
{
log-test "Agent check-in" "Fail"
}

# Test 2: Command execution
# This tests if computers are processing commands as expected

# Find first online PC for testing if no computer is specified in the parameter
if ($testComputerID -eq 0)
{

$onlinePC = Invoke-SqlQuery -Query "Select computerID from computers where lastcontact > date_add(now(), interval -5 minute) limit 1;"

$testComputerID = $onlinePC.computerID

}

# Issue the "hostname" command to the test agent and get the ID number to follow up
$test2_setup = Invoke-SqlScalar -Query " insert into commands (computerid, command, parameters) values ( $testComputerID, 2,  'cmd.exe!!! /c hostname');SELECT LAST_INSERT_ID();"

# Wait for the command to run
Start-Sleep -Seconds $testSleepTimeSeconds

$test2_results = Invoke-SqlQuery -Query "select * from commands where CmdID = $test2_setup;"
$testComputerName = Invoke-SqlQuery "select name from computers where computerid = $testComputerID;"

if ($test2_results.Output -eq $testComputerName.name)
{
log-test "Command execution" "Pass"
}
else
{
log-test "Command execution" "Fail"
}


# Test 3: Script execution
# This tests if scripts execute on computers correctly.


if ($testScriptID -eq 0)
{
$testScriptID = 5034 # This is the default script "Set Alert Maintenance Mode" that will set MM for 15 minutes on the target agent.

$testScriptParams = "MinutesForMaintenance=15"
}


$test3_setup = Invoke-SqlQuery -Query "insert into pendingscripts (ScriptID, ComputerID, NextRun, Parameters) values ($testScriptID, $testComputerID, now(), `"$testScriptParams`" );SELECT LAST_INSERT_ID() as scriptid;"

# Wait for the script to run
Start-Sleep -Seconds $testSleepTimeSeconds

# Dereference object for MySQL syntax
[Int] $scriptInstanceID = $test3_setup.scriptid

$test3_results = Invoke-SqlQuery -Query "select ScriptStatus from h_scripts where computerid = $testComputerID and ScriptInstanceID = $scriptInstanceID order by hisid desc limit 1;"

if ($test3_results.ScriptStatus -eq 3)
{
log-test "Script execution" "Pass"
}
else
{
log-test "Script execution" "Fail"
}

# Test 4: Heartbeat
# This tests if heartbeat is being processed correctly

$test4_results = Invoke-SqlQuery -Query "Select count(*) as OnlineCount from heartbeatcomputers where LastHeartbeatTime > date_add(now(), interval -5 minute);"

if ($test4_results.OnlineCount -gt 0)
{
log-test "Agent heartbeat" "Pass"
}
else
{
log-test "Agent heartbeat" "Fail"
}

# Test 5: Remote Monitors (and variable expansion)
# TODO: Implement test 5

# Test 6: Remote agent icons
# TODO: Implement test 6

$testResultList

# Cleanup MySQL Connection
Close-SqlConnection