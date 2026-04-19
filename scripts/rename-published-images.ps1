[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$PublishedImagesPath = ''
)

if ([string]::IsNullOrWhiteSpace($PublishedImagesPath)) {
    $scriptRoot = $PSScriptRoot

    if ([string]::IsNullOrWhiteSpace($scriptRoot) -and -not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
        $scriptRoot = Split-Path -Parent $PSCommandPath
    }

    if ([string]::IsNullOrWhiteSpace($scriptRoot) -and $MyInvocation.MyCommand.Path) {
        $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }

    if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
        $scriptRoot = (Get-Location).Path
    }

    $PublishedImagesPath = Join-Path $scriptRoot '..\_published_images'
}

function Convert-PublishedImageName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )

    $extension = [System.IO.Path]::GetExtension($FileName).ToLowerInvariant()
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $parts = $stem -split '_'

    if ($parts.Count -lt 4) {
        return $null
    }

    $userIndex = -1
    for ($i = 0; $i -lt $parts.Count; $i++) {
        if ($parts[$i] -match '^u?\d+$') {
            $userIndex = $i
            break
        }
    }

    if ($userIndex -lt 2) {
        return $null
    }

    $firstPart = $parts[0]
    $lastPart = $parts[$userIndex - 1]
    $middlePart = if (($userIndex - 2) -ge 1) { $parts[1] } else { '' }
    $userId = ([regex]::Match($parts[$userIndex], '\d+')).Value

    if ([string]::IsNullOrWhiteSpace($firstPart) -or [string]::IsNullOrWhiteSpace($lastPart) -or [string]::IsNullOrWhiteSpace($userId)) {
        return $null
    }

    $cursor = $userIndex + 1
    $sourceSegment = $null
    if ($cursor -lt $parts.Count -and $parts[$cursor] -match '^src\d+$') {
        $sourceSegment = $parts[$cursor].ToLowerInvariant()
        $cursor++
    }

    if ($cursor -ge $parts.Count) {
        return $null
    }

    $variantSegment = ($parts[$cursor..($parts.Count - 1)] -join '_').ToLowerInvariant()

    $newParts = @(
        $firstPart.Substring(0, 1).ToLowerInvariant()
    )

    if (-not [string]::IsNullOrWhiteSpace($middlePart)) {
        $newParts += $middlePart.Substring(0, 1).ToLowerInvariant()
    }

    $newParts += $lastPart.ToLowerInvariant()
    $newParts += "u$userId"

    if ($sourceSegment) {
        $newParts += $sourceSegment
    }

    $newParts += $variantSegment

    return ($newParts -join '_') + $extension
}

if (-not (Test-Path -LiteralPath $PublishedImagesPath -PathType Container)) {
    throw "Published images path not found: $PublishedImagesPath"
}

$renamed = 0
$skipped = 0
$warnings = 0

Get-ChildItem -LiteralPath $PublishedImagesPath -File | ForEach-Object {
    $newName = Convert-PublishedImageName -FileName $_.Name

    if (-not $newName) {
        Write-Warning "Could not parse filename: $($_.Name)"
        $warnings++
        return
    }

    if ($newName -ceq $_.Name) {
        $skipped++
        return
    }

    $targetPath = Join-Path $_.DirectoryName $newName
    if (Test-Path -LiteralPath $targetPath) {
        Write-Warning "Target already exists, skipping: $newName"
        $warnings++
        return
    }

    if ($PSCmdlet.ShouldProcess($_.FullName, "Rename to $newName")) {
        Rename-Item -LiteralPath $_.FullName -NewName $newName
        $renamed++
    }
}

Write-Host "Renamed: $renamed"
Write-Host "Skipped: $skipped"
Write-Host "Warnings: $warnings"