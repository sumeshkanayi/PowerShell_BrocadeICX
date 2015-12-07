# PowerShell SSH Brocade

## Description

Module and script collection for PowerShell to administrate Brocade Switches over SSH

---

With the Module "Brocade" you can execute commands over SSH without receiving the following error message: "☺Protocol error, doesn't start with scp!"

## Requirements

- Posh-SSH (https://github.com/darkoperator/Posh-SSH)

## Install

### Brocade (Module)

1. Copy the folder named "Modules/Brocade" in your Profile under C:\Users\%username%\Documents\WindowsPowerShell\Modules
2. Open a PowerShell and import the Module with "Import-Module Brocade"

## Syntax

### Brocade (Module)

#### New-BrocadeSession

New-BrocadeSession [-ComputerName] $string [[-Credentials] $pscredential ]

#### Get-BrocadeSession

Get-BrocadeSession [[-SessionID] $int[]]

Get-BrocadeSession [[-ComputerName] $string[]] [[-ExactMatch]]

#### Invoke-BrocadeSession

Invoke-BrocadeCommand [-Session] $Object [-Command] $string [-WaitTime] $int

#### Remove-BrocadeSession

Remove-BrocadeSession [-SessionID] $int[]

Remove-BrocadeSession [-Session] $Object

---

## Idea and Help

The idea comes from the contributions on StackOverflow and Reddit that describe the procedure:
- https://stackoverflow.com/questions/30603219/executing-command-using-paramiko-on-brocade-switch
- https://www.reddit.com/r/PowerShell/comments/3tgql4/poshssh_shell_reading/
