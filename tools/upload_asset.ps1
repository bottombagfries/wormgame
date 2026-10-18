# Uploads one file to Roblox with Open Cloud (Assets API) and prints only the new asset id.
#   powershell -File tools/upload_asset.ps1 -File assets/models/Items/SmallCoal.fbx -Type Model -Name SmallCoal
#   powershell -File tools/upload_asset.ps1 -File assets/textures/WT_Palette.png -Type Decal -Name WT_Palette
# Reads ROBLOX_API_KEY and ROBLOX_CREATOR_ID (a user id; set ROBLOX_CREATOR_TYPE=group for a group) from the
# environment. The key is never printed or written anywhere.
param(
	[Parameter(Mandatory = $true)][string]$File,
	[Parameter(Mandatory = $true)][ValidateSet("Model", "Decal")][string]$Type,
	[Parameter(Mandatory = $true)][string]$Name,
	[int]$TimeoutSeconds = 120
)
$ErrorActionPreference = "Stop"

$key = $env:ROBLOX_API_KEY
$creatorId = $env:ROBLOX_CREATOR_ID
if (-not $key -or -not $creatorId) { throw "ROBLOX_API_KEY and ROBLOX_CREATOR_ID must be set" }

$path = (Resolve-Path $File).Path
$extension = [IO.Path]::GetExtension($path).ToLower()
$contentType = switch ($extension) {
	".fbx" { "model/fbx" }
	".png" { "image/png" }
	default { throw "Unsupported file type $extension" }
}
$creator = if ($env:ROBLOX_CREATOR_TYPE -eq "group") { @{ groupId = "$creatorId" } } else { @{ userId = "$creatorId" } }
$request = @{
	assetType = $Type
	displayName = $Name
	description = "Wormtown asset $Name"
	creationContext = @{ creator = $creator }
} | ConvertTo-Json -Depth 5 -Compress

# Build the multipart body by hand (Windows PowerShell 5.1 has no -Form).
$boundary = [Guid]::NewGuid().ToString()
$encoding = [Text.Encoding]::UTF8
$stream = New-Object IO.MemoryStream
function Write-Text([string]$text) { $bytes = $encoding.GetBytes($text); $stream.Write($bytes, 0, $bytes.Length) }
Write-Text "--$boundary`r`nContent-Disposition: form-data; name=`"request`"`r`nContent-Type: application/json`r`n`r`n$request`r`n"
Write-Text "--$boundary`r`nContent-Disposition: form-data; name=`"fileContent`"; filename=`"$([IO.Path]::GetFileName($path))`"`r`nContent-Type: $contentType`r`n`r`n"
$fileBytes = [IO.File]::ReadAllBytes($path)
$stream.Write($fileBytes, 0, $fileBytes.Length)
Write-Text "`r`n--$boundary--`r`n"

$headers = @{ "x-api-key" = $key }
try {
	$operation = Invoke-RestMethod -Method Post -Uri "https://apis.roblox.com/assets/v1/assets" -Headers $headers `
		-ContentType "multipart/form-data; boundary=$boundary" -Body $stream.ToArray()
} catch {
	$detail = $_.ErrorDetails.Message
	throw "Upload failed: $($_.Exception.Message) $detail"
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while (-not $operation.done) {
	if ((Get-Date) -gt $deadline) { throw "Timed out waiting for operation $($operation.path)" }
	Start-Sleep -Seconds 2
	$operation = Invoke-RestMethod -Method Get -Uri "https://apis.roblox.com/assets/v1/$($operation.path)" -Headers $headers
}
if ($operation.error) { throw "Upload rejected: $($operation.error | ConvertTo-Json -Compress)" }
Write-Output $operation.response.assetId
