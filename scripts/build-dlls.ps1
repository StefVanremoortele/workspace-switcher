param(
    [ValidateSet("x86", "x64", "all")]
    [string] $Architecture = "all"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$targets = @(
    @{ Name = "x64"; Rust = "x86_64-pc-windows-msvc" },
    @{ Name = "x86"; Rust = "i686-pc-windows-msvc" }
)
$backends = @(
    @{ Name = "win10"; Feature = "win10" },
    @{ Name = "win11_22h2"; Feature = "win11_22h2" },
    @{ Name = "win11_23h2"; Feature = "win11_23h2" },
    @{ Name = "win11_24h2"; Feature = "win11_24h2" }
)

if ($Architecture -ne "all") {
    $targets = @($targets | Where-Object Name -eq $Architecture)
}

Push-Location $repoRoot
try {
    $installedTargets = & rustup target list --installed
    foreach ($target in $targets) {
        if ($installedTargets -notcontains $target.Rust) {
            Write-Host "Installing Rust target $($target.Rust)..."
            & rustup target add $target.Rust
            if ($LASTEXITCODE -ne 0) {
                throw "Could not install Rust target $($target.Rust)."
            }
        }

        foreach ($backend in $backends) {
            Write-Host "Building $($backend.Name) for $($target.Name)..."
            & cargo build --release --locked --target $target.Rust --no-default-features --features $backend.Feature
            if ($LASTEXITCODE -ne 0) {
                throw "Build failed for $($backend.Name) / $($target.Name)."
            }

            $source = Join-Path $repoRoot "target\$($target.Rust)\release\vds.dll"
            $destinationDirectory = Join-Path $repoRoot "bin\$($backend.Name)-$($target.Name)"
            New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
            Copy-Item -LiteralPath $source -Destination (Join-Path $destinationDirectory "vds.dll") -Force
        }
    }
} finally {
    Pop-Location
}

Write-Host "DLLs are ready under bin\<backend>-<architecture>\."
