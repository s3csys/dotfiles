###################################################
# Tweaks
###################################################

# christitus tweak tool
function ctt {
    iwr -useb https://christitus.com/win | iex
}

# winaero tweaker
function wat {
    & 'C:\Program Files\Winaero Tweaker\WinaeroTweaker.exe'
}

# power toys
function pt {
    & 'C:\Users\muzam\AppData\Local\PowerToys\PowerToys.exe'
}

# debloating 
# https://github.com/Raphire/Win11Debloat
function dbt {
    & ([scriptblock]::Create((irm "https://debloat.raphi.re/"))) -RunDefaults -Silent
}

# Define Export Function
function envx {
    Export-EnvironmentVariables
}

# Define Import Function
function envi {
    Import-EnvironmentVariables -InputFile "C:\Users\muzam\.dotfiles\windows\backup-env.txt"
}

function envi {
    Import-EnvironmentVariables -InputFile "$@"
}


###################################################
# SSH Connection
###################################################

#Function ssh-server {
#    ssh -i ~/.ssh/id_rsa -p 22 $user@$ip
#}
#Set-Alias -Name $name -Value ssh-server


###################################################
# Navigation Shortcuts
###################################################

# Easier Navigation: .., ..., ...., ....., and ~
${function:~} = { Set-Location ~ }
# PoSh won't allow ${function:..} because of an invalid path error, so...
${function:Set-ParentLocation} = { Set-Location .. }; Set-Alias ".." Set-ParentLocation
${function:...} = { Set-Location ..\.. }
${function:....} = { Set-Location ..\..\.. }
${function:.....} = { Set-Location ..\..\..\.. }
${function:......} = { Set-Location ..\..\..\..\.. }

# Navigation Shortcuts
${function:drop} = { Set-Location C:\Users\$user\Dropbox }
${function:dt} = { Set-Location ~\Desktop }
${function:docs} = { Set-Location ~\Documents }
${function:dl} = { Set-Location ~\Downloads }

###################################################
# Functions
###################################################

# alias ping
function pinging {
    ping -n 100 8.8.8.8
}
Set-Alias -Name p -value pinging

# Create an alias 'dn' to shut down the computer
Function Shutdown-Computer {
    shutdown -h
#    hybernation must be enabled to work properly
}
Set-Alias -Name dn -Value Shutdown-Computer

# Create alias for Firefox
function Open-WithFirefox {
    param (
        [string]$FilePath
    )    
    $FullPath = (Get-Item $FilePath).FullName
    if (Test-Path $FullPath) {
        Start-Process 'C:\Program Files\Mozilla Firefox\firefox.exe' $FullPath
    } else {
        Write-Host "File not found."
    }
}
Set-Alias -Name firefox -Value Open-WithFirefox

Function realpath-string {
    param (
        [string]$Path
    )
    (Get-Item $Path).FullName
}
Set-Alias -Name realpath -Value realpath-string

#tmp directory
Function Set-TempAlias {
    Set-Location C:\Windows\Temp
}
Set-Alias -Name tmp -Value Set-TempAlias

# Basic commands
function which($name) { Get-Command $name -ErrorAction SilentlyContinue | Select-Object Definition }
function touch($file) { "" | Out-File $file -Encoding ASCII }

# Common Editing needs
function hh { Invoke-Expression "sudo $(if($env:EDITOR -ne $null)  {$env:EDITOR } else { 'subl' }) $env:windir\system32\drivers\etc\hosts" }
function epr { Invoke-Expression "$(if($env:EDITOR -ne $null)  {$env:EDITOR } else { 'subl' }) $profile" }

Function symlink {
  [CmdletBinding()]
  Param(
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
    [Alias("Path")]
    [string]$LinkName,

    [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $false)]
    [Alias("Target")]
    [string]$LinkTarget
  )

  Process {
    New-Item -ItemType SymbolicLink -Path $LinkName -Target $LinkTarget
  }
}

# System Update - Update RubyGems, NPM, and their installed packages
function System-Update() {
    #Install-WindowsUpdate -IgnoreUserInput -IgnoreReboot -AcceptAll
    Update-Module
    #Update-Help -Force
    gem update --system
    gem update
    npm install npm -g
    npm update -g
    choco upgrade all -y
    refreshenv
    winget --% upgrade --all
    refreshenv
}

function Reload-PowerShell {
    powershell.exe -NoExit
}

function Reload-Profile {
    Invoke-Expression -Command $profile
}

# Download a file into a temporary folder
function curlex($url) {
    $uri = New-Object System.Uri $url
    $filename = $uri.Segments | Select-Object -Last 1
    $path = Join-Path $env:Temp $filename
    if (Test-Path $path) { Remove-Item -Force $path }

    (New-Object Net.WebClient).DownloadFile($url, $path)

    $fileInfo = New-Object System.IO.FileInfo $path

    [PSCustomObject]@{
        FilePath = $fileInfo.FullName
        FileName = $fileInfo.Name
    }
}

###################################################
### File System functions
###################################################

# Create a new directory and enter it
function CreateAndSet-Directory([String] $path) { New-Item $path -ItemType Directory -ErrorAction SilentlyContinue; Set-Location $path}

# Determine size of a file or total size of a directory
function Get-DiskUsage([string] $path=(Get-Location).Path) {
    Convert-ToDiskSize `
        ( `
            Get-ChildItem .\ -recurse -ErrorAction SilentlyContinue `
            | Measure-Object -property length -sum -ErrorAction SilentlyContinue
        ).Sum `
        1
}

# Cleanup all disks (Based on Registry Settings in `windows.ps1`)
function Clean-Disks {
    Start-Process "$(Join-Path $env:WinDir 'system32\cleanmgr.exe')" -ArgumentList "/sagerun:6174" -Verb "runAs"
}

###################################################
### Environment functions
###################################################

# Export Environment Variables
function Export-EnvironmentVariables {
    param (
        [string]$OutputFile = "C:\Users\muzam\.dotfiles\windows\backup-env.txt"
    )

    $envVars = @{}

    # Get User Environment Variables
    $envVars.User = Get-ChildItem Env: | ForEach-Object { @{ Name = $_.Name; Value = $_.Value } }

    # Get System Environment Variables
    $envVars.System = [System.Environment]::GetEnvironmentVariables("Machine") | ForEach-Object {
        @{ Name = $_.Key; Value = $_.Value }
    }

    # Save to File
    $envVars.User + $envVars.System | ForEach-Object {
        "$($_.Name)=$($_.Value)"
    } | Out-File -FilePath $OutputFile -Encoding UTF8

    Write-Host "Environment variables exported to $OutputFile"
}

# Import Environment Variables
function Import-EnvironmentVariables {
    param (
        [string]$InputFile
    )

    if (-Not (Test-Path $InputFile)) {
        Write-Error "File not found: $InputFile"
        return
    }

    $envVars = Get-Content -Path $InputFile | ForEach-Object {
        # Skip empty lines and lines that don't match the expected format
        if ($_ -match "^(.*?)=(.*)$") {
            @{
                Name  = $Matches[1]
                Value = $Matches[2]
            }
        }
    }

    # Check if there are any environment variables to set
    if ($envVars.Count -eq 0) {
        Write-Warning "No valid environment variables found in the file."
        return
    }

    foreach ($var in $envVars) {
        if (![string]::IsNullOrWhiteSpace($var.Name) -and (![string]::IsNullOrWhiteSpace($var.Value))) {
            try {
                # Set environment variables
                [System.Environment]::SetEnvironmentVariable($var.Name, $var.Value, "User")   # User-level
                [System.Environment]::SetEnvironmentVariable($var.Name, $var.Value, "Machine") # System-level
                Write-Host "Imported variable: $($var.Name) = $($var.Value)"
            }
            catch {
                Write-Error "Failed to set environment variable $($var.Name): $_"
            }
        } else {
            Write-Warning "Skipping invalid variable: $($var.Name)"
        }
    }

    Write-Host "Environment variables imported from $InputFile"
}

# Usage example
# Import-EnvironmentVariables -InputFile "C:\Users\muzam\.dotfiles\windows\backup-env.txt"

###################################################
### Utilities
###################################################

function localIp {
    $file = "$env:TEMP\localip_output.txt"
    starship module localip | Tee-Object -FilePath $file > $null
    $content = Get-Content $file
    $ipAddress = $content -replace '\033\[\d+;\d+m', '' -replace '\033\[0m', '' -replace '[@:]', '' -replace '\s'
    Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
    Write-Output $ipAddress.Trim()
}

# Start IIS Express Server with an optional path and port
function Start-IISExpress {
    [CmdletBinding()]
    param (
        [String] $path = (Get-Location).Path,
        [Int32]  $port = 3000
    )

    if ((Test-Path "${env:ProgramFiles}\IIS Express\iisexpress.exe") -or (Test-Path "${env:ProgramFiles(x86)}\IIS Express\iisexpress.exe")) {
        $iisExpress = Resolve-Path "${env:ProgramFiles}\IIS Express\iisexpress.exe" -ErrorAction SilentlyContinue
        if ($iisExpress -eq $null) { $iisExpress = Get-Item "${env:ProgramFiles(x86)}\IIS Express\iisexpress.exe" }

        & $iisExpress @("/path:${path}") /port:$port
    } else { Write-Warning "Unable to find iisexpress.exe"}
}


