﻿#############################################################################################################
# Language     :  PowerShell 4.0
# Script Name  :  Brocade.psm1
# Autor        :  BornToBeRoot (https://github.com/BornToBeRoot)
# Description  :  Module with functions to administrate Brocade switch devices over SSH
# Repository   :  https://github.com/BornToBeRoot/PowerShell_SSH-Brocade
#############################################################################################################


### Requirements ############################################################################################
#
# - Posh-SSH (Module)
# - Brocade (Module)
# - ScanNetworkAsync.ps1 (Script)
#
#############################################################################################################


###############################################################################################################
### Global Brocade sessions
###############################################################################################################
if (!(Test-Path Variable:Global:BrocadeSessions)) 
{
    $Global:BrocadeSessions = New-Object System.Collections.ArrayList
}

###############################################################################################################
### New-BrocadeSession
###############################################################################################################
<#
    .SYNOPSIS    
    This function creates a new Brocade session over SSH
        
    .DESCRIPTION          
    This function creates a new Brocade session over SSH (requieres the "Posh-SSH"-Module)
                    
    .EXAMPLE    
    New-BrocadeSession -ComputerName TEST_DEVICE1
      
    .LINK
    Github Profil:         https://github.com/BornToBeRoot
    Github Repository:     https://github.com/BornToBeRoot/PowerShell_SSH-Brocade
#>

function New-BrocadeSession
{
    [CmdletBinding()]
    param
    (
        [Parameter(
	        Position=0,
	        Mandatory=$true,
	        HelpMessage='Hostname or IP-Address of the Brocade switch device')]
	    [String[]]$ComputerName, 
	  
	    [Parameter(
	        Position=1,
	        HelpMessage='PSCredentials for SSH connection')]
        [System.Management.Automation.PSCredential]$Credentials
	)

    Begin{}
	Process
	{
		# Check if credentials are passed as parameter
	    if($Credentials -eq $null)
		{		
			try{
				$Credentials = Get-Credential $null
			}
			catch{
				Write-Host "Entering credentials was aborted. Can't estalish SSH connection without credentials..." -ForegroundColor Red
				return
			}
	    }	
		
		# Array to create multiple sessions
		$Sessions = @()
		
		# Go trough each computer and create a new ssh session
		foreach($ComputerName1 in $ComputerName)
		{
			# Create a new SSH session
			try {
			   	$created_SSH_Session = New-SSHSession -ComputerName $ComputerName1 -Credential $Credentials -AcceptKey
		    	$SSH_Session = Get-SSHSession -SessionId $created_SSH_Session.SessionID
		    	$SSH_Stream = $SSH_Session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
		    }
			catch{
				Write-Host "$($ComputerName1): $($_.Exception.Message)" -ForegroundColor Red
				continue
			}
			
            # Create a new Brocade session PSObject
		    $Session = New-Object -TypeName PSObject 
		    Add-Member -InputObject $Session -MemberType NoteProperty -Name SessionID -Value $created_SSH_Session.SessionID
			Add-Member -InputObject $Session -MemberType NoteProperty -Name ComputerName -Value $created_SSH_Session.Host
		    Add-Member -InputObject $Session -MemberType NoteProperty -Name Session -Value $SSH_Session
		    Add-Member -InputObject $Session -MemberType NoteProperty -Name Stream -Value $SSH_Stream
		    
			Invoke-BrocadeCommand -Session $Session -Command "skip-page-display" -WaitTime 300 | Out-Null
		   
			# Add session to global array
		    $Global:BrocadeSessions.Add($Session) | Out-Null
			$Sessions += $Session
		}
		
		# Return created sessions
	    return $Sessions
	}
	End{}
}

###############################################################################################################
### Get-BrocadeSession
###############################################################################################################
<#
    .SYNOPSIS    
    This function returns all or specific Brocade sessions
        
    .DESCRIPTION           
    This function returns all or specific Brocade sessions with SessionID, ComputerName, 
    Session and Stream
    
    .EXAMPLE    
    Get-BrocadeSession -SessionID 0,2

    .EXAMPLE    
    Get-BrocadeSession -ComputerName *TEST*

    .LINK
    Github Profil:         https://github.com/BornToBeRoot
    Github Repository:     https://github.com/BornToBeRoot/PowerShell_SSH-Brocade
#>

function Get-BrocadeSession {
	[CmdletBinding(DefaultParameterSetName='SessionID')]
	param
    (
	    [Parameter(
		    ParameterSetName='SessionID',	
		    Position=0,
            HelpMessage='Session-ID of the Brocade session')]
		[Int32[]]$SessionID,
	
	    [Parameter(
		    ParameterSetName='ComputerName',
	    	Position=0,
            HelpMessage='Get all Brocade sessions with specific ComputerName (Placeholder like * can be used)')]
		[String[]]$ComputerName,

        [Parameter(
            ParameterSetName = 'ComputerName',
            Position=1,
            HelpMessage='ComputerName must match exactly (Placeholder are ignored)')]        
        [Switch]$ExactMatch
	)

    Begin{}
    Process
    {
		# Array which return the sessions
     	$Sessions = @()
        
		# Check which parameter set is used
	    if($PSCmdlet.ParameterSetName -eq 'SessionID')
	    {
		    if($PSBoundParameters.ContainsKey('SessionID'))
		    {
    		    foreach($ID in $SessionID)
			    {
				    foreach($Session in $BrocadeSessions)
				    {
					    if($Session.SessionId -eq $ID)
					    {
						    $Sessions += $Session
					    }
				    }
			    }
		    }
		    else
		    {
				$Sessions += $BrocadeSessions
		    }
	    }
	    else
	    {
		    if($PSBoundParameters.ContainsKey('ComputerName'))
		    {
			    foreach($Name in $ComputerName)
			    {
				    foreach($Session in $BrocadeSessions)
				    {
					    if($Session.ComputerName -like $Name -and (-not $ExactMatch -or $Session.ComputerName -eq $Name))
					    {
						    $Sessions += $Session
					    }
				    }
			    }
		    }
	    } 
	
	    return $Sessions
    }
    End{}
}

###############################################################################################################
### Remove-BrocadeSession
###############################################################################################################
<#
    .SYNOPSIS    
    This function removes an exiting Brocade session
        
    .DESCRIPTION                    
    This function removes an exiting Brocade session and close the SSH-Session

    .EXAMPLE    
    Get-BrocadeSession | Remove-BrocadeSession

    .EXAMPLE    
    Remove-BrocadeSession -SessionID 0,2

    .EXAMPLE    
    Remove-BrocadeSession -Session $Session

    .LINK
    Github Profil:         https://github.com/BornToBeRoot
    Github Repository:     https://github.com/BornToBeRoot/PowerShell_SSH-Brocade
#>

function Remove-BrocadeSession {
	[CmdletBinding(DefaultParameterSetName='Session')]
	param
    (
        [Parameter(
            ParameterSetName='SessionID',
		    Position=0,
			ValueFromPipelineByPropertyName=$true,	
		    Mandatory=$true,
		    HelpMessage="Session-ID of the Brocade session")]
		[Int32[]]$SessionID,

	    [Parameter(
            ParameterSetName='Session',
		    Position=0,
			ValueFromPipeline=$true,
			Mandatory=$true,
		    HelpMessage="Brocade session")]
		[PSObject[]]$Session
	)

    Begin{}
    Process{    
		# Array which sessions should be removed
        $Sessions2Remove = @()

		# Get all Brocade sessions, which should get removed
        if($PSCmdlet.ParameterSetName -eq 'SessionID')
        {
            $Sessions2Remove += Get-BrocadeSession -SessionID $SessionID
        } 
        else
        {            
			$Sessions2Remove += $Session
        }
	
		# Close SSH-Session and remove Brocade session from global array
	    foreach($Session2Remove in $Sessions2Remove)
	    {
		    Remove-SSHSession -SessionId $Session2Remove.SessionID | Out-Null
	
	        $Global:BrocadeSessions.Remove($Session2Remove)
	    }
    }
    End{}
}

###############################################################################################################
### Invoke-BrocadeCommand
###############################################################################################################
<#
    .SYNOPSIS    
    This function invokes a command into an existing Brocade session.
        
    .DESCRIPTION    
    With this function you can invoke a command over SSH into a Brocade session.
                    
    .EXAMPLE
    Invoke-BrocadeCommand -Session $Session -Command "sh ver" -WaitTime 2000
    
    .EXAMPLE
    Get-BrocadeSession | Invoke-Command -Command "show version" -WaitTime 2000 -ShowExecutedCommand

	.EXAMPLE
	(Invoke-BrocadeCommand -SessionID 0,2 -Command "show version").Result
    
    .LINK
    Github Profil:         https://github.com/BornToBeRoot
    Github Repository:     https://github.com/BornToBeRoot/PowerShell_SSH-Brocade
#>

function Invoke-BrocadeCommand
{ 
	[CmdletBinding(DefaultParameterSetName='Session')]
	param(
	    [Parameter(
            ParameterSetName='SessionID',
		    Position=0,
			ValueFromPipelineByPropertyName=$true,	
		    Mandatory=$true,
		    HelpMessage="Session-ID of the Brocade session")]
		[Int32[]]$SessionID,
		
		[Parameter(
			ParameterSetName='Session',
		    Position=0,
            ValueFromPipeline=$true,
			Mandatory=$true,
            HelpMessage="Brocade session")]
		[PSObject[]]$Session,
	  
    	[Parameter(
	    	Position=1,
	    	Mandatory=$true,
		    HelpMessage="Command to execute on Brocade switch device")]
		[String]$Command,
		
	    [Parameter(
	    	Position=2,
		    HelpMessage="Wait time in milliseconds (Default=1000)")]
		[Int32]$WaitTime=1000,

		[Parameter(
			Position=3,
			HelpMessage="Indicates whether the executed command will be showed (Default=false)"	)]
		[switch]$ShowExecutedCommand=$false
	)

    Begin{}
    Process{
		# Array of Brocade sessions, in which the command is to be executed
		$Sessions2Invoke = @()

		# Get all Brocade sessions, in which the command is to be executed
        if($PSCmdlet.ParameterSetName -eq 'SessionID')
        {
           $Sessions2Invoke += Get-BrocadeSession -SessionID $SessionID
        }
		else
		{			
			$Sessions2Invoke += $Session
		}

		# Manuell linebreak (if not already done)
		if(-not($Command.EndsWith("`n")))
        { 
		    $StreamCommand = $Command + "`n" 
	    }
        else
	    { 
		    $StreamCommand = $Command 
		}

		$Results = @()

		# Invoke command in each SSH/Brocade session
		foreach($Session2Invoke in $Sessions2Invoke)
		{
			if($ShowExecutedCommand)
			{
				Write-Host "Executed command: " -NoNewline -ForegroundColor Yellow
				Write-Host "$StreamCommand" -ForegroundColor Magenta
			}

			$Session2Invoke.Stream.Write($StreamCommand)
	
			Start-Sleep -Milliseconds $WaitTime # Waiting for result
    
			$Result_Read = $Session2Invoke.Stream.Read() -split '[\r\n]' | ? {$_} # Read the result
			
			# Built custom PSObject to return result
			$Result = New-Object -TypeName PSObject 
			Add-Member -InputObject $Result -MemberType NoteProperty -Name ComputerName -Value $Session2Invoke.ComputerName
			Add-Member -InputObject $Result -MemberType NoteProperty -Name Result -Value $Result_Read
				
			$Results += $Result
		}

		# Return custom PSObject
		return $Results
    }
    End{}
}

###############################################################################################################
### Include additional functions
###############################################################################################################

Get-ChildItem -Path $PSScriptRoot | Where-Object {$_.Name.EndsWith(".ps1")} | ForEach-Object {. $_.FullName}

   # Get-BrocadeVLAN
   # Add-BrocadeVLAN
