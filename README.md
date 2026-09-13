# ytlccv-installer
YTLCCV installer.

## Usage

From PowerShell:

```powershell
irm https://df1011.github.io/ytlccv.ps1 | iex
```

The script sets the execution policy to `Bypass` for the current process,
downloads the YTLCCV archive from the fixed URL, asks for an extraction folder,
and extracts the files automatically.
