# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install tools using Chocolatey
@('git', 'make', 'cmake', 'alacritty', 'fzf', 'sudo', 'ripgrep', 'jq', 'bat', 'zoxide', 'just', 'fd', 'sd', 'ag', 'tldr', 'delta', 'starship', 'neovim', 'python38', 'python39', 'python310', 'python311', 'python312', 'jre8', 'vcredist140', 'notepadplusplus', 'sysinternals', 'nodejs', 'vscode', 'ninja', 'autoruns', 'everything', 'flux', 'grepwin', 'winaero-tweaker', 'wincompose', 'ultravnc', 'powertoys'. 'teracopy', 'nerd-fonts-meslo', 'autohotkey', 'shutup10', 'geekuninstaller', 'ditto', 'directoryopus', 'screentogif', 'lua') |
ForEach-Object { choco install $_ -y }

# Print tools to be installed manually
Write-Host "Please install the following tools manually:"
Write-Host "ExplorerPatcher: https://github.com/valinet/ExplorerPatcher"
