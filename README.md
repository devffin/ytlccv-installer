# ytlccv-installer
YTLCCV installer.

## Usage

From PowerShell, run the default terminal installer:

```powershell
irm https://df1011.github.io/ytlccv.ps1 | iex
```

To open the graphical installer directly from the same remote script context:

```powershell
$installer = [scriptblock]::Create((irm https://df1011.github.io/ytlccv.ps1))
& $installer -GUI
```

The installer sets the execution policy to `Bypass` for the current process,
downloads the YTLCCV archive from the fixed URL, checks the destination folder,
asks for an installation folder, and extracts the files automatically.
