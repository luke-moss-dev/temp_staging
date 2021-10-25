configuration ActiveDirectoryForest 
{ 
   param 
   ( 
        [Parameter(Mandatory=$true)]
        [String]$Domain,

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$DomainCreds
    ) 
    
    Import-DscResource -ModuleName ActiveDirectoryDsc -ModuleVersion '4.2.0.0'
    Import-DscResource -ModuleName PSDscResources -ModuleVersion '2.12.0.0'
    Import-DscResource -ModuleName xDnsServer -ModuleVersion '1.16.0.0'

    $Users = @(
        "DeeEnd",
        "OliveYew",
        "ClydeStale",
        "AnonyMouse",
        "LynneGwistic",
        "IvanItchinos",
        "AugustaWind",
        "FrankFurter",
        "UsirName",
        "BerbDiwire"
    )

    $Ous = @("WestUS", "CentralUS", "EastUS")
   
    $Split = $Domain.Split('.')
    $Path = $null 
    foreach($Obj in $Split)
    {
        $Path += "DC=$Obj,"
    }
    $Count = $Path.Length - 1
    $Path = $Path.Remove($Count,1)

    Node localhost
    {
       LocalConfigurationManager            
       {            
          ActionAfterReboot = 'ContinueConfiguration'            
          ConfigurationMode = 'ApplyOnly'            
          RebootNodeIfNeeded = $true            
       }
        
        WindowsFeature ADDSInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services" 
        } 

        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter
        {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature DnsTools
	    {
	        Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]ADDSInstall"
	    }
         
        ADDomain FirstDomainController 
        {
            DomainName = $Domain
            Credential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            ForestMode = 'WinThreshold'
	  	    DependsOn = "[WindowsFeature]ADDSInstall"
        }

        xDnsServerForwarder Azure
        {
            IsSingleInstance = 'Yes'
            IPAddresses = '168.63.129.16'
            UseRootHint = $true
            DependsOn = "[ADDomain]FirstDomainController"
        }

        foreach($User in $Users)
        {
            ADUser $($User)
            {
                Ensure = 'Present'
                Password = $DomainCreds
                PasswordNeverResets = $false
                DomainName = $Domain
                CannotChangePassword = $true
                ChangePasswordAtLogon = $false 
                DisplayName = $User
                Enabled = $true
                PasswordNeverExpires = $true
                UserName = ($User).ToLower()
                UserPrincipalName = ($User + '@' + $Domain).ToLower()
                DependsOn = "[ADDomain]FirstDomainController"
            }
        }
        
        ADGroup WestUS
        {
            GroupName  = 'avd_users_westus'
            Members    = $Users[0..3]
            DependsOn = "[ADUser]BerbDiwire"
        }

        ADGroup CentralUS
        {
            GroupName  = 'avd_users_centralus'
            Members    = $Users[4..5]
            DependsOn = "[ADUser]BerbDiwire"
        }

        ADGroup EastUS
        {
            GroupName  = 'avd_users_eastus'
            Members    = $Users[6..9]
            DependsOn = "[ADUser]BerbDiwire"
        }

        foreach($Ou in $Ous)
        {
            ADOrganizationalUnit $Ou
            {
                Name    = $OU
                Path    = $Path
            }
        }
    }
}
