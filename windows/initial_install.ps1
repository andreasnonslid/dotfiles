# Install Chocolatey if not present
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Install core tools
$tools = @('git', 'make', 'cmake', 'alacritty', 'fzf', 'sudo', 'ripgrep', 'jq', 'bat', 'zoxide', 'just', 'fd', 'sd', 'ag', 'tldr', 'delta', 'starship', 'neovim', 'jre8', 'vcredist140', 'notepadplusplus', 'sysinternals', 'vscode', 'ninja', 'autoruns', 'everything', 'flux', 'grepwin', 'winaero-tweaker', 'wincompose', 'ultravnc', 'powertoys', 'teracopy', 'nerd-fonts-meslo', 'autohotkey', 'shutup10', 'geekuninstaller', 'ditto', 'directoryopus', 'screentogif', 'lua')
foreach ($tool in $tools) { choco install $tool -y }

# Install pyenv-win (Python version manager)
choco install pyenv-win -y
$env:PATH += ";$env:USERPROFILE\.pyenv\pyenv-win\bin;$env:USERPROFILE\.pyenv\pyenv-win\shims"

# Install nvm-windows (Node.js version manager)
choco install nvm -y
$env:NVM_HOME = "$env:APPDATA\nvm"
$env:NVM_SYMLINK = "$env:ProgramFiles\nodejs"
$env:PATH += ";$env:NVM_HOME;$env:NVM_SYMLINK"

# Install rustup (Rust version manager)
Invoke-WebRequest -Uri https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe -OutFile rustup-init.exe
Start-Process -Wait -NoNewWindow -FilePath .\rustup-init.exe -ArgumentList '-y'
Remove-Item .\rustup-init.exe

# Install Node.js LTS and xpm
nvm install lts
nvm use lts
npm install --global xpm typescript

# Install Python versions
pyenv install 3.8.12
pyenv install 3.13.0
pyenv global 3.13.0

Write-Host "All version managers and tools installed. Use pyenv, nvm, rustup, and xpm for further tool management."

Write-Host "Please install the following tools manually:"
Write-Host "ExplorerPatcher: https://github.com/valinet/ExplorerPatcher"
