# CyberPatriot
Tools and various scripts used to support CyberPatriot

## Syntax
```Initialize-CyberPatriotCloud -resourceGroupName "MyResource" -resourceGroupLocation "azurelocation" -vmUserName "AdminUserName" -vmUserPassword "SomeSecurePassword"```

## Example
```Initialize-CyberPatriotCloud``` if you want to run with all defaults
```Initialize-CyberPatriotCloud -resourceGroupName CyberPatriotTeam -resourceGroupLocation eastus -vmUserName CyberAdmin -vmUserPassword "D6xYwk5hX5c!Kr^y@uae"```

## Expected Output
```
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
```
## Current Limitations
Will only spin up the virtual machines in Azure. Will not configure Apache Guacamole to connect to the host machines. You'll have to manually set up the connections in Guacamole yourself.

## Troubleshooting
- If one of the hosts are displaying properly, the vncserver may not be running
-- You'll have to log into the Azure portal and open the guacamole settings to add a network security group rule to allow ssh (port 22)
-- Then ssh into the Guacamole via it's public IP address or dns name. The username and password will be defaulted to CyberAdmin and Cyb3rP@tri0t! or whatever you put when you ran it
-- Once ssh'd into the Guacamole server, you can pivot and ssh into the Host machine that is causing problems. You can ping it first to see if it's alive.
-- Once ssh'd into the affected Host machine, you can run the following command:
```vncserver -geometry 1920x1080```
-- You should get a message saying the display was started on :1. If it was started on :2 then you'll have to change the port in Guacamole to 5902 instead of 5901 (vnc port is 5900 + display number)
- If the vmware player is not starting after you click finish on the license screen, it's probably due to the policy authentication agent not being ran in the background.
-- Following the steps above to ssh into the affected Host machine, run the following commands once there:
```lxpolkit &```
```disown -h```

## References
[Maj Bill Blatchley's Guide to Guacamole](https://files.constantcontact.com/b6eda340101/3b2e7e3f-7e0a-425b-b5cf-6e293a41fc01.pdf)

[Azure docs](https://github.com/Azure/azure-docs-powershell-samples/blob/master/virtual-machine/create-vm-detailed/create-vm-detailed.ps1)
