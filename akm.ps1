$ErrorActionPreference = 'Stop';
Install-Module AWS.Tools.IdentityManagement -confirm:$false -Force
Install-Module PSSodium -confirm:$false -Force
Install-Module AWS.Tools.S3 -Confirm:$false -Force
Import-Module PSSodium;
Import-Module AWS.Tools.IdentityManagement;
Import-Module AWS.Tools.S3

$payload = $env:InputPayload | ConvertFrom-Json;
$REPO_BUCKET= $payload.REPO_BUCKET
$S3_KEY= $payload.S3_KEY
$IAM_USERNAME= $payload.IAM_USERNAME
$GITHUB_USER= $payload.GITHUB_USER
$GITHUB_USER_TOKEN= $payload.GITHUB_USER_TOKEN
$GITHUB_SECRET_NAME_ACCESS_KEY_ID= $payload.GITHUB_SECRET_NAME_ACCESS_KEY_ID
$GITHUB_SECRET_NAME_ACCESS_KEY= $payload.GITHUB_SECRET_NAME_ACCESS_KEY
# Deletes all IAM Access keys
function Delete-IamUserAccessKeys {
  PARAM([string]$IamUserName)
  $AccessKeys = Get-IamAccessKey -UserName $IamUserName
  if($AccessKeys.Count -gt 0){
    foreach ($accesskey in $AccessKeys){
      Remove-IAMAccessKey -AccessKeyId $accesskey.AccessKeyId -UserName $IamUserName -Force -Verbose
    }
  }
}

function Set-RepoSecret {
    [CmdletBinding()]
    Param(
        [string]$repoOwner, [string]$repoName,
        [string]$keyId, [string]$SecretValue,
        [string]$SecretName, [string]$GitHubToken,
        [string]$GitHubUser
    )
        $token = "$($GitHubUser):$($GitHubToken)"
        $base64Token = [System.Convert]::ToBase64String([char[]]$token)
        $headers = @{Authorization = 'Basic {0}' -f $base64Token};
        $repoPutSecretURL = 'https://api.github.com/repos/'+ $repoOwner + '/'+ $repoName + '/actions/secrets/'+ $SecretName
        $parameters = @{"encrypted_value" = $SecretValue; "key_id" = $keyId} | ConvertTo-Json
        $response = Invoke-RestMethod -Headers $headers -Uri $repoPutSecretURL -Method Put -Body $parameters
        return $response
}

function Get-GitHubRepoPublicKey {
  [CmdletBinding()]
  Param(
    [string]$repoOwner, [string]$repoName, [string]$GitHubToken,[string]$GitHubUser
    )
  $token = "$($GitHubUser):$($GitHubToken)"
  $base64Token = [System.Convert]::ToBase64String([char[]]$token)
  $headers = @{Authorization = 'Basic {0}' -f $base64Token};
  $url = "https://api.github.com/repos/$repoOwner/$repoName/actions/secrets/public-key"
  $response = Invoke-RestMethod -Headers $headers -Uri $url
  return $response
}

Delete-IamUserAccessKeys -IamUserName $IAM_USERNAME
$IamNewAccessKey = New-IAMAccessKey -UserName $IAM_USERNAME

Read-S3Object -BucketName $REPO_BUCKET -Key $S3_KEY -File $S3_KEY
$Repos = (Get-Content $S3_KEY | ConvertFrom-Json).Repos

foreach($repo in $Repos){
  Write-Host "Updating $($repo.Name) in $($repo.Owner) org/profile"
  $key_response = Get-GitHubRepoPublicKey -repoOwner $repo.Owner -repoName $repo.Name -GitHubToken $GITHUB_USER_TOKEN -GitHubUser $GITHUB_USER
  $keyId = $key_response.key_id
  $key = $key_response.key
  $repoEncryptedStringAccessKey = ConvertTo-SodiumEncryptedString -Text $IamNewAccessKey.SecretAccessKey -PublicKey $key
  $repoEncryptedStringAccessKeyId = ConvertTo-SodiumEncryptedString -Text $IamNewAccessKey.AccessKeyId -PublicKey $key

  Set-RepoSecret -repoOwner $repo.Owner -repoName $repo.Name -keyId $keyId -GitHubToken $GITHUB_USER_TOKEN -GitHubUser $GITHUB_USER -SecretName $GITHUB_SECRET_NAME_ACCESS_KEY -SecretValue $repoEncryptedStringAccessKey
  Set-RepoSecret -repoOwner $repo.Owner -repoName $repo.Name -keyId $keyId -GitHubToken $GITHUB_USER_TOKEN -GitHubUser $GITHUB_USER -SecretName $GITHUB_SECRET_NAME_ACCESS_KEY_ID -SecretValue $repoEncryptedStringAccessKeyId
}
Write-Host "Sync Complete"