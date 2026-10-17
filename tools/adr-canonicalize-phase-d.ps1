param()
$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
if (!(Test-Path -LiteralPath (Join-Path $root '.git'))) { throw 'Run from the Wafferly repository root.' }
$gitStatus = git status --porcelain
if ($LASTEXITCODE -ne 0) { throw 'Unable to read Git status.' }
if ($gitStatus) { throw "Working tree is not clean. Commit/stash first; refusing to continue.`n$gitStatus" }
$apply = $env:APPLY_ADR_CANONICALIZATION -eq '1'
$groups = @(
  @{ Prefix='ADR-004'; Title='Domain Mutation Execution'; Hash='7f034cc9ce8a73518525dfa505d171ad614b26a6e1c5f09a662fa6a03b876331' },
  @{ Prefix='ADR-028'; Title='Allocation Contract'; Hash='9b40006b75d479f89d1c0a48e2b1f3a8e6e74b0900d22e99d8a02fbc231d3343' }
)
$adrRoot = Join-Path $root 'docs/02-ADR'
$archiveRoot = Join-Path $adrRoot '_archive/phase-d'
foreach ($group in $groups) {
  $candidates = @()
  Get-ChildItem -LiteralPath $adrRoot -File -Recurse | Where-Object { $_.FullName -notlike '*\_archive\*' -and $_.Name.StartsWith($group.Prefix) -and $_.Name.Contains($group.Title) } | ForEach-Object {
    $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -eq $group.Hash) { $candidates += $_ }
  }
  if ($candidates.Count -lt 2) {
    Write-Host "SKIP $($group.Prefix): found $($candidates.Count) file(s) with expected title and hash; expected at least 2." -ForegroundColor Yellow
    continue
  }
# Keep the shortest matching filename as canonical.
$ordered = @($candidates | Sort-Object `
  @{ Expression = { $_.Name.Length }; Ascending = $true }, `
  @{ Expression = { $_.Name }; Ascending = $true })

$canonical = $ordered[0]
  Write-Host "CANONICAL: $($canonical.FullName)" -ForegroundColor Cyan
  foreach ($file in @($ordered | Select-Object -Skip 1)) {
    $relative = [IO.Path]::GetRelativePath($root, $file.FullName).Replace('\','/')
    $leaf = $file.Name
    $escaped = [regex]::Escape($leaf)
    $references = @()
    $tracked = git ls-files
    foreach ($item in $tracked) {
      if ($item -eq $relative -or $item -match '/_archive/') { continue }
      $candidatePath = Join-Path $root $item
      if (!(Test-Path -LiteralPath $candidatePath -PathType Leaf)) { continue }
      try {
        if (Select-String -LiteralPath $candidatePath -Pattern $escaped -Quiet -ErrorAction Stop) { $references += $item }
      } catch { }
    }
    if ($references.Count -gt 0) {
      Write-Host "BLOCKED references found for $relative : $($references -join ', ')" -ForegroundColor Yellow
      continue
    }
    $destination = Join-Path $archiveRoot $leaf
    if (Test-Path -LiteralPath $destination) { throw "Archive destination already exists: $destination" }
    if ($apply) {
      New-Item -ItemType Directory -Path $archiveRoot -Force | Out-Null
      Move-Item -LiteralPath $file.FullName -Destination $destination
      Write-Host "ARCHIVED: $relative -> docs/02-ADR/_archive/phase-d/$leaf" -ForegroundColor Green
    } else {
      Write-Host "DRY RUN: would archive $relative -> docs/02-ADR/_archive/phase-d/$leaf"
    }
  }
}
if (!$apply) { Write-Host 'Dry run only. Review the output. To apply, set $env:APPLY_ADR_CANONICALIZATION="1" and rerun.' -ForegroundColor Cyan }
