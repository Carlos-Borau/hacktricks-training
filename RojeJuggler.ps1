# List all roles
$Roles = (aws iam list-roles --output json | ConvertFrom-Json).Roles

# Attempt to assume each role
foreach ($Role in $Roles) {

    $SessionName = "RoleJugglingTest-" + (Get-Date -Format FileDateTime) + "-$($Role.RoleName)"

    try {

        $Credentials = aws sts assume-role --role-arn $Role.Arn --role-session-name $SessionName --query "Credentials" --output json 2>$null | ConvertFrom-Json
        
        if ($Credentials) {
            
            Write-Host "Successfully assumed role: $($Role.RoleName)"
            Write-Host "Access Key: $($Credentials.AccessKeyId)"
            Write-Host "Secret Access Key: $($Credentials.SecretAccessKey)"
            Write-Host "Session Token: $($Credentials.SessionToken)"
            Write-Host "Expiration: $($Credentials.Expiration)"

            # Set temporary Credentials to assume the next role
            $env:AWS_ACCESS_KEY_ID = $Credentials.AccessKeyId
            $env:AWS_SECRET_ACCESS_KEY = $Credentials.SecretAccessKey
            $env:AWS_SESSION_TOKEN = $Credentials.SessionToken

            # Remaining roles
            $RemainingRoles = @($Roles | Where-Object { $_.Arn -ne $Role.Arn })

            # Try to assume another role using the temporary Credentials
            foreach ($NextRole in $RemainingRoles) {

                    $NextSessionName = "RoleJugglingTest-" + (Get-Date -Format FileDateTime) + "-$($NextRole.RoleName)"
                    
                    try {
                        
                        $NextCredentials = aws sts assume-role --role-arn $NextRole.Arn --role-session-name $NextSessionName --query "Credentials" --output json 2>$null | ConvertFrom-Json
                        
                        if ($NextCredentials) {
                            Write-Host "Also successfully assumed role: $($NextRole.RoleName) from $($Role.RoleName)"
                            Write-Host "Access Key: $($NextCredentials.AccessKeyId)"
                            Write-Host "Secret Access Key: $($NextCredentials.SecretAccessKey)"
                            Write-Host "Session Token: $($NextCredentials.SessionToken)"
                            Write-Host "Expiration: $($NextCredentials.Expiration)"
                        }

                    } catch { }
            }

            # Reset environment variables
            Remove-Item Env:\AWS_ACCESS_KEY_ID
            Remove-Item Env:\AWS_SECRET_ACCESS_KEY
            Remove-Item Env:\AWS_SESSION_TOKEN
        } 

    } catch { }
}

Write-Host "Role juggling check complete."
