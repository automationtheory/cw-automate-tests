# cw-automate-tests
Automated tests for CWA patch validation

## Testing CWA Patches, devops style
CWA patching can be hit-or-miss, and unfortunately for MSPs a bad Automate patch can cause a slew of issues ranging from broken features to server functionality issues. As a core element of service delivery, it's critical that Automate is stable, and that patches be tested.

This project is the start of automated tests for CW Automate. The intent is that this script could be run on an NFR install of Automate with a new patch and test the basic functionality. Our hope in open sourcing this project is that others would contribute additional test cases, and that over time the community would have a fast and easy way to validate patch functionality.

## Getting started
1. Download the repository and unzip it.
2. Run the script (default options) on your Automate application server:    

`.\automate_tests.ps1`  
	
or customize the tests:    

	.\automate_tests.ps1 -testComputerID 1 -testScriptID 300 -testSleepTimeSeconds 300 -testScriptParams "param=value"

The script will attempt to install the required MySQL module, and administrator permissions are required for this. However, after the module install the script can be run as a normal user.


## How it works

The script loads the MySQL connection information out of the registry (with some help from the LTPoSH module) and then it connects and runs queries to check the status of various items. It also triggers certain events (currently command and script execution) and then checks back to see if they ran successfully and the expected values were returned.

## Contributing
There are several ways to contribute: 
 * Add test cases to the script (we love pull requests!)
 * Testing your Automate server/NFR environment
 * Joining the discussion: https://forums.mspgeek.org/topic/6768-automate-patch-upgrade-guide-2022/
 
 
## Credits
This module makes use of the LTPoSH module, found here: https://github.com/LabtechConsulting/LabTech-Powershell-Module 