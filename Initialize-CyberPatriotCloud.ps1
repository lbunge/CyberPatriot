<#
.Synopsis
   PowerShell script to build out virtual machines for CyberPatriot in Azure Cloud
.DESCRIPTION
   This PowerShell script takes an array of hostnames ["Host-Win","Host-Server","Host-Linux","Host-Cisco","Guacamole"]
   and creates virtual machines in Azure Cloud based on a pre-determined configuration. The host machines are located
   on an internal network with the Guacamole machine utilizing Apache Guacamole with a public IP address to connect to
   the internal machines.
.EXAMPLE
   Initialize-CyberPatriotCloud -resourceGroupName CyberPatriot -resourceGroupLocation eastus -vmLocalAdminUser CyberAdmin -vmUserPassword SomeS3cr3tP@ssw0rd!
#>
function Initialize-CyberPatriotCloud
{
    [CmdletBinding()]
    Param
    (
        $resourceGroupName = "CyberPatriot",
        $resourceGroupLocation = "eastus",
        $vmLocalAdminUser = "CyberAdmin",
        $vmUserPassword = "Cyb3rP@tri0t!",
        $url1 = 'https://files.constantcontact.com/b6eda340101/23cb064f-6d36-4146-9472-0ba2bc586728.pdf',
        $url2 = 'hhttps://s3.amazonaws.com/UserGuides/Install_7zip_2019.pdf',
        $url3 = 'https://s3.amazonaws.com/UserGuides/Install_WinMD5_2019.pdf'
    )
    Begin
    {
        # Powershell 5.1 or later
        if ($PSVersionTable.PSversion.Major -lt 5 -or ($PSVersionTable.PSversion.Major -eq 5 -and $PSVersionTable.PSversion.Minor -lt 1)) {
           throw "Update to PowerShell 5.1 or later: https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/install/installing-windows-powershell#upgrading-existing-windows-powershell"
        }# End if
        
        # Multiple Azure Modules OR Already Installed
        if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
            Write-Warning -Message ('Az module not installed. Having both the AzureRM and Az modules installed at the same time is not supported.')
        } else {
            if (Get-InstalledModule -Name Az){
            } else {
                Install-Module -Name Az -AllowClobber -Scope CurrentUser
            }# End if
        }# End if

        # Check for Context
        if (!$context) {$context = Connect-AzAccount}
    }
    Process
    {
        $startTime = Get-Date -Format "HH:mm:ss"
        Write-Host "--------------------  Beginning Initialization  ---------------------" -ForegroundColor Cyan
        Write-Host "This could take a few minutes, feel free to go top off the coffee" -ForegroundColor Cyan
        Write-Host "Script Start Time: $startTime" -ForegroundColor Cyan
        Write-Host "`n`n`n`n" -ForegroundColor Cyan     # Adding lines for the progress box
        
        ### Create Resource Group
        $null = New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation -InformationAction SilentlyContinue
        
        ### Create credential object
        $vmLocalAdminSecurePassword = $vmUserPassword | ConvertTo-SecureString -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($vmLocalAdminUser, $vmLocalAdminSecurePassword)
        
        ### Network Configuration
        $networkName = $resourceGroupName + "-vnet"
        $subnetName = $resourceGroupName + "-subnet"
        $subnetAddressPrefix = "192.168.1.0/24"
        $networkAddressPrefix = "192.168.0.0/16"
        $publicIP = New-AzPublicIpAddress `
            -ResourceGroupName $resourceGroupName `
            -Location $resourceGroupLocation `
            -Name "$resourceGroupName-PublicIP" `
            -DomainNameLabel "$($resourceGroupName.ToLower())-$(Get-Random)"`
            -AllocationMethod Static `
            -IdleTimeoutInMinutes 4 `
            -WarningAction Ignore
        $subnet = New-AzVirtualNetworkSubnetConfig `
            -Name $subnetName `
            -AddressPrefix $subnetAddressPrefix `
            -WarningAction Ignore
        $vnet = New-AzvirtualNetwork `
            -Name $networkName `
            -ResourceGroupName $resourceGroupName `
            -Location $resourceGroupLocation `
            -AddressPrefix $networkAddressPrefix `
            -Subnet $subnet

        ### Network Security Group Configuration
        $nsgRuleHTTP = New-AzNetworkSecurityRuleConfig `
            -Name http-rule `
            -Description "Allow HTTP" `
            -Access Allow `
            -Protocol Tcp `
            -Direction Inbound `
            -Priority 101 `
            -SourceAddressPrefix Internet `
            -SourcePortRange * `
            -DestinationAddressPrefix * `
            -DestinationPortRange 80
        $nsgRuleHTTPS = New-AzNetworkSecurityRuleConfig `
            -Name https-rule `
            -Description "Allow HTTPS" `
            -Access Allow `
            -Protocol Tcp `
            -Direction Inbound `
            -Priority 102 `
            -SourceAddressPrefix Internet `
            -SourcePortRange * `
            -DestinationAddressPrefix * `
            -DestinationPortRange 443
        $nsg = New-AzNetworkSecurityGroup `
            -ResourceGroupName $resourceGroupName `
            -Location $resourceGroupLocation `
            -Name "$resourceGroupName-SG" `
            -SecurityRules $nsgRuleHTTP,$nsgRuleHTTPS

        ### Build VM's for each image host
        $vmhosts = @("Host-Win","Host-Server","Host-Linux","Host-Cisco","Guacamole") # Array of hostnames - Can add more names to create more VM's
        $vmSize = "Standard_D2_v4" # 2-core 8gb RAM
        foreach ($vmhost in $vmhosts){
            Write-Progress -Activity "Creating $($vmhosts.count) Virtual Machines" `
                -Status "Progress:" `
                -CurrentOperation "Spinning up `"$vmhost`" ($($vmhosts.IndexOf($vmhost)+1)/$($vmhosts.count))" `
                -PercentComplete ((($vmhosts.IndexOf($vmhost)+1)/$vmhosts.count)*80)
            
            ## Specific configuration for Apache Guacamole VM
            if ($vmhost -eq "Guacamole"){
                $NIC = New-AzNetworkInterface `
                    -Name "$vmhost-nic" `
                    -ResourceGroupName $resourceGroupName `
                    -Location $resourceGroupLocation `
                    -SubnetId $vnet.Subnets[0].Id `
                    -PublicIpAddressId $publicIP.Id `
                    -NetworkSecurityGroupId $nsg.Id
                $vm = New-AzVMConfig `
                    -VMName $vmhost `
                    -VMSize "Standard_B1s"
                $vm = Set-AzVMSourceImage `
                    -VM $vm `
                    -PublisherName "OpenLogic" `
                    -Offer "CentOS" `
                    -Skus "7.7" `
                    -Version latest
            } else{     # Configuration for host vm's
                $NIC = New-AzNetworkInterface `
                    -Name "$vmhost-nic" `
                    -ResourceGroupName $resourceGroupName `
                    -Location $resourceGroupLocation `
                    -SubnetId $vnet.Subnets[0].Id
                $vm = New-AzVMConfig `
                    -VMName $vmhost `
                    -VMSize $vmSize
                $vm = Set-AzVMSourceImage `
                    -VM $vm `
                    -PublisherName "Canonical" `
                    -Offer "UbuntuServer" `
                    -Skus "18.04-LTS" `
                    -Version latest
            }# End host config if
            $vm = Set-AzVMOperatingSystem `
                -VM $vm `
                -Linux `
                -ComputerName $vmhost `
                -Credential $cred 
            $vm = Add-AzVMNetworkInterface `
                -VM $vm `
                -Id $NIC.Id

            ## Create the vm
            $null = New-AzVM -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -VM $vm -WarningAction Ignore -InformationAction SilentlyContinue
        }# End foreach

        Write-Host "-------------------- VM's have been built --------------------" -ForegroundColor Cyan
        Write-Host "Sending configuration scripts to VM's in the background..." -ForegroundColor Cyan
        Write-Host "Please allow 20-30 mins before accessing your resources." -ForegroundColor Cyan
        Write-Host "" -ForegroundColor Cyan
        
        ### Prepare and upload the execution script for each vm
        foreach ($vmhost in $vmhosts) {
            ## Configuration Script for Guacamole VM is pulled from GitHub and sent to the VM for execution
            if ($vmhost -eq "Guacamole"){
                $settings = '{"fileUris":["https://raw.githubusercontent.com/lbunge/CyberPatriot/main/guac-install.sh"],
                        "commandToExecute":"bash ./guac-install.sh"}'
                $null = Set-AzVMExtension `
                    -ResourceGroupName $resourceGroupName `
                    -Location $resourceGroupLocation `
                    -VMName "Guacamole" `
                    -Name "ConfigureGuacScript" `
                    -Publisher "Microsoft.Azure.Extensions" `
                    -ExtensionType "CustomScript" `
                    -TypeHandlerVersion "2.1" `
                    -SettingString $settings `
                    -AsJob
            }# End Guacamole if
            ## Configuration Script for Host VM's is pulled from GitHub and sent to the VM as a job
            $settings = "{`"fileUris`":[`"https://raw.githubusercontent.com/lbunge/CyberPatriot/main/host-install.sh`"],
                    `"commandToExecute`":`"bash ./host-install.sh $url1 $url2 $url3 $vmLocalAdminUser $vmUserPassword >> /tmp/scriptOutput.txt`"}"
            $null = Set-AzVMExtension `
                -ResourceGroupName $resourceGroupName `
                -Location $resourceGroupLocation `
                -VMName "Host-Win" `
                -Name "ConfigureHostScript" `
                -Publisher "Microsoft.Azure.Extensions" `
                -ExtensionType "CustomScript" `
                -TypeHandlerVersion "2.1" `
                -SettingString $settings `
                -AsJob
        }# End foreach

        Write-Host "Collecting IP Information from VM's..." -ForegroundColor Cyan
        Write-Host "" -ForegroundColor Cyan

        ### Collect IP Information to display for Guacamole input
        $vmInformation = @()
        foreach ($vmhost in $vmhosts){
            if ($vmhost -ne "Guacamole"){
                $data = [PSCustomObject]@{
                    VM              = $vmhost
                    IP              = Get-AzNetworkInterface -Name "$vmhost-nic" -ResourceGroupName $resourceGroupName | 
                                        Select-Object -ExpandProperty IpConfigurations | 
                                        Select-Object -ExpandProperty PrivateIPAddress
                    "VNC Username"  = $vmLocalAdminUser
                    "VNC Password"  = $(($vmUserPassword).Substring(0,8))
                }# End data
                $vmInformation += $data     # Add object to array
            }# End if
        }# End foreach

        $endTime = Get-Date -Format "HH:mm:ss"
    }
    End
    {
        Write-Host "-------------------- Initialization is complete! --------------------" -ForegroundColor Cyan
        Write-Host "Script End Time: $endTime" -ForegroundColor Cyan
        Write-Host "Total Run Time: $(New-TimeSpan -Start $startTime -End $endTime)" -ForegroundColor Cyan
        Write-Host "" -ForegroundColor Cyan
        Write-Host "To tear down all the resources once you are finished, run the following:" -ForegroundColor Cyan
        Write-Host "Remove-AzResourceGroup -Name $resourceGroupName -Force -AsJob"
        Write-Host ""
        Write-Host "To access your resources online, go to the following url:" -ForegroundColor Cyan
        Write-Host "https://$((Get-AzPublicIpAddress -name $publicIP.Name -ResourceGroupName $resourceGroupName).DnsSettings.Fqdn)"
        $vmInformation

    }
}


Initialize-CyberPatriotCloud