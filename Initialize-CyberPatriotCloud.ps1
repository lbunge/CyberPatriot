<#
.Synopsis
   PowerShell script to build out virtual machines for CyberPatriot in Azure Cloud
.DESCRIPTION
   This PowerShell script takes an array of hostnames ["Host-Win","Host-Server","Host-Linux","Host-Cisco","Guacamole"]
   and creates virtual machines in Azure Cloud based on a pre-determined configuration. The host machines are located
   on an internal network with the Guacamole machine utilizing Apache Guacamole with a public IP address to connect to
   the internal machines.
.EXAMPLE
   Initialize-CyberPatriotCloud -resourceGroupName CyberPatriot -resourceGroupLocation eastus -vmUserName CyberAdmin -vmUserPassword SomeS3cr3tP@ssw0rd!
#>
function Initialize-CyberPatriotCloud
{
    [CmdletBinding()]
    Param
    (
        # Name for Resource Group
        [Parameter(ValueFromPipelineByPropertyName=$true
        )]
        [string]
        $resourceGroupName = "CyberPatriot",
        
        # Location in Azure
        [Parameter(ValueFromPipelineByPropertyName=$true
        )]
        [string]
        $resourceGroupLocation = "eastus",

        # Administrator account in VM's
        [Parameter(ValueFromPipelineByPropertyName=$true
        )]
        [string]
        $vmUserName = "CyberAdmin",

        # Administrator password in VM's.
        [Parameter(ValueFromPipelineByPropertyName=$true
        )]
        [string]
        $vmUserPassword = "Cyb3rP@tri0t!"
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
        Write-Host "--------------------  Beginning Initialization  ---------------------" -ForegroundColor Cyan
        Write-Host "This could take a few minutes, feel free to go top off the coffee" -ForegroundColor Cyan
        New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation -InformationAction SilentlyContinue
        $vmLocalAdminUser = $vmUserName
        $vmLocalAdminSecurePassword = $vmUserPassword | ConvertTo-SecureString -AsPlainText -Force
        $vmSize = "Standard_D2_v4" # 2-core 8gb RAM

        $networkName = $resourceGroupName + "-vnet"
        $subnetName = $resourceGroupName + "-subnet"
        $subnetAddressPrefix = "192.168.1.0/24"
        $networkAddressPrefix = "192.168.0.0/16"
        $publicIP = New-AzPublicIpAddress `
            -ResourceGroupName $resourceGroupName `
            -Location $resourceGroupLocation `
            -Name "$resourceGroupName-PulbicIP" `
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
             
        $cred = New-Object System.Management.Automation.PSCredential ($vmLocalAdminUser, $vmLocalAdminSecurePassword)
        $vmhosts = @("Host-Win","Host-Server","Host-Linux","Host-Cisco","Guacamole") # Array of hostnames - Can add more names to create more VM's

        # Build VM's for each image host
        foreach ($vmhost in $vmhosts){
            Write-Progress -Activity "Creating $($vmhosts.count) Virtual Machines" `
                -Status "Progress:" `
                -CurrentOperation "Spinning up `"$vmhost`" ($($vmhosts.IndexOf($vmhost)+1)/$($vmhosts.count))" `
                -PercentComplete ((($vmhosts.IndexOf($vmhost)+1)/$vmhosts.count)*80)
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
            } else{
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
            }# End if
                $vm = Set-AzVMOperatingSystem `
                    -VM $vm `
                    -Linux `
                    -ComputerName $vmhost `
                    -Credential $cred 
                $vm = Add-AzVMNetworkInterface `
                    -VM $vm `
                    -Id $NIC.Id
                New-AzVM -ResourceGroupName $resourceGroupName -Location $resourceGroupLocation -VM $vm -WarningAction Ignore -InformationAction SilentlyContinue
        }
    }
    End
    {
        Write-Host "-------------------- Initialization is complete! --------------------" -ForegroundColor Cyan
        Write-Host "To tear down all the resources once you are finished, run the following:" -ForegroundColor Cyan
        Write-Host "Remove-AzResourceGroup -Name $resourceGroupName -Force -AsJob"
        Write-Host ""
        Write-Host "To access your resources online, go to the following url:" -ForegroundColor Cyan
        Write-Host "https://$((Get-AzPublicIpAddress -name $publicIP.Name -ResourceGroupName $resourceGroupName).DnsSettings.Fqdn)"
    }
}

Initialize-CyberPatriotCloud