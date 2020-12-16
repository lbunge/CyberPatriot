# CyberPatriot
Tools and various scripts used to support CyberPatriot

## Syntax
Initialize-CyberPatriotCloud -resourceGroupName "MyResource" -resourceGroupLocation "azurelocation" -vmUserName "AdminUserName" -vmUserPassword "SomeSecurePassword"

## Example
Initialize-CyberPatriotCloud -resourceGroupName CyberPatriotTeam -resourceGroupLocation eastus -vmUserName CyberAdmin -vmUserPassword "D6xYwk5hX5c!Kr^y@uae"

## Expected Output
--------------------  Beginning Initialization  ---------------------
This could take a few minutes, feel free to go top off the coffee

RequestId IsSuccessStatusCode StatusCode ReasonPhrase
--------- ------------------- ---------- ------------
                         True         OK OK          
                         True         OK OK          
                         True         OK OK          
                         True         OK OK          
                         True         OK OK          
-------------------- Initialization is complete! --------------------
To tear down all the resources once you are finished, run the following:
Remove-AzResourceGroup -Name CyberPatriotTeam -Force -AsJob

To access your resources online, go to the following url:
hxxps://cyberpatriotteam-256795467.eastus.cloudapp.azure.com

## Current Limitations
Will only spin up the virtual machines in Azure. Will not configure Apache Guacamole to connect to the host machines nor setup the host machines with the required VMWare Player and zip files. These features will be implemented in the next release.

## References
[Maj Bill Blatchley's Guide to Guacamole](https://files.constantcontact.com/b6eda340101/3b2e7e3f-7e0a-425b-b5cf-6e293a41fc01.pdf)
[Azure docs](https://github.com/Azure/azure-docs-powershell-samples/blob/master/virtual-machine/create-vm-detailed/create-vm-detailed.ps1)
