

function create-vm-switch($switchName){

    # Create VM Switch $switchName
    New-VMSwitch $switchName -NetAdapterName $switchName -MinimumBandwidthMode Weight -AllowManagementOS $false
    Set-VMSwitch $switchName -DefaultFlowMinimumBandwidthWeight 50
    
    # Check that $switchName was created successfully
    $vmSwitchName = (Get-VMSwitch $switchName).Name
    if ($vmSwitchName -ne $NULL){ 
       Write-Host "$vmSwitchName created successfully."
    }
    else {Write-Host "Error, VM Switch $switchName not created."}
}

function create-vm-adapters($switchName, $adapters){

    # Create $adapters and assign to $switchName
    foreach ($adapter in $adapters){

        Write-Host "Creating adapter $adapter and assigning to $switchName..."
        Add-VMNetworkAdapter -ManagementOS -Name $adapter -SwitchName $switchName

        # Check that adapter was created successfully
        $newAdapterName = (Get-VMNetworkAdapter -ManagementOS -Name $adapter -SwitchName $switchName).Name
        if  ($newAdapterName -ne $NULL){
            Write-Host "$newAdapterName created successfully."
        }
        else{Write-Host "Error, adapter $adapter not created."}
    }
}

function create-switches-and-adapters($switchName, $adapters){
    
    # Create the VM Switch
    Write-Host "Creating switch $switchName..."
    create-vm-switch $switchName

    # Assign $adapters to $switchNam
    Write-Host "Adding virtual adapters to $switchName..."
    create-vm-adapters $switchName $adapters
}

function configure-networking{
    
    ### Variable Declaration ###
        
        # Management vNetwork
        $managementNICTeam = "10GbE Management Team"
        $managementSwitch = "Guest Networks"
        $managementAdapters = "Host Management","CM","LM"
    
    ### Create NIC Team ###
        
        # Create Management NIC Team
        New-NetLbfoTeam $managementNICTeam –TeamMembers “NIC1”,”NIC3” –TeamNicName $managementSwitch

    ### Create Virtual Switches and Virtual Adapters ###

        # Create Management Switch and assign adapters:  Host Management, CM, LM
        Write-Host "Creating $managementSwitch and assigning $managementAdapters..."
        create-switches-and-adapters $managementSwitch $managementAdapters
        Write-Host "$managementSwitch configuration complete."
        
    ### Set Minimum Bandwidth Weight ###

        # Set weight for Management Adapters
        Write-Host "Setting minimum bandwidth weight for $managementAdapters..."
        Set-VMNetworkAdapter –ManagementOS –Name “Host Management” –MinimumBandwidthWeight 5
        Set-VMNetworkAdapter –ManagementOS –Name “CM” –MinimumBandwidthWeight 5
        Set-VMNetworkAdapter –ManagementOS –Name “LM” –MinimumBandwidthWeight 35
        Write-Host "Minimum bandwidth weight for $managementAdapters set."


    ### Set VLANs for Virtual Adapters ###
        
        # Set VLANs for Virtual NICs
        Write-Host "Assigning VLANs for $managementAdapters..."
        Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "Host Management" -Access -VlanId 1033
        Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "CM" -Access -VlanId 3019
        Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "LM" -Access -VlanId 1034
        Write-Host "VLANs for $managementAdapters set."
}
