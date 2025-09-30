param (
    [String] $AWSProfile = "default"
)

$User = aws sts get-caller-identity --profile $AWSProfile

if ($?) {

    $User = ($User | ConvertFrom-Json).Arn 

    if ($User -match "arn:aws:iam::\d{12}:user/(.*)") { 

        $Output = aws sts get-federation-token --profile $AWSProfile --name $Matches[1] --policy-arns arn=arn:aws:iam::aws:policy/AdministratorAccess 

        if ($?) {

            $Output = $Output | ConvertFrom-Json

            $Credentials = @{
                sessionId = $Output.Credentials.AccessKeyId
                sessionKey = $Output.Credentials.SecretAccessKey
                sessionToken = $Output.Credentials.SessionToken
            }

            $Body = @{
                Action = "getSigninToken"
                SessionDuration = 43200
                Session = $Credentials | ConvertTo-Json
            }

            $FederationEndpoint="https://signin.aws.amazon.com/federation"

            $Response = Invoke-RestMethod -Method Get -Uri $FederationEndpoint -Body $Body

            $Token = $Response.SigninToken

            Start-Process "https://signin.aws.amazon.com/federation?Action=login&Issuer=example.com&Destination=https%3A%2F%2Fconsole.aws.amazon.com%2F&SigninToken=$Token"

        } else { [Console]::Error.WriteLine("Could not retrieve federated token") }

    } else { [Console]::Error.WriteLine("Missmatch user arn") }

} else { [Console]::Error.WriteLine("Could not retrieve caller identity") }


