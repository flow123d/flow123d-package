# To allow running powershell scripts, open powershell as admin and run:
# Set-ExecutionPolicy Unrestricted

# get script location
$cwd = split-path -parent $MyInvocation.MyCommand.Definition
cd "$cwd"

# executes mingw shell command
function exec-install-shell($bash) {
    $command = '"' + $bash + '" --login -i "uninstall.sh" '
    iex "& $command"
}

# prints message and separator
function status-line($msg) {
    Write-Host $msg
    Write-Host "----------------------------------------------------------"
}

# finds executable in path and return it (or null)
function which($name) {
    Try {
        $path = (Get-Command $name).Path 2> $null
        if (!$path) {
            return $null
        }
          return $path
    } Catch {
        return $null
    }
}

# get bash location from arguments
$bash = $args[0]
status-line "Executing shell using $bash"
exec-install-shell "$bash"

# remove from Path
status-line "Removing bin folder from path"
$binFolder = ";$cwd\bin;"
$paths = [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
$paths = $paths.replace($binFolder, "")
[Environment]::SetEnvironmentVariable("Path", $paths + $binFolder, [System.EnvironmentVariableTarget]::User)

# call uninstall 
status-line "Removing Docker Toolbox"
$dockerPath = which docker
$dockerDir  = split-path -parent $dockerPath
$dockerUnin = $dockerDir + '\unins000.exe'
iex "& '$dockerUnin'"