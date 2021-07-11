# AWS GitHub AKM

An AWS serverless management tool for AWS Access Key Manager and your GitHub [Encrypted Secrets](https://docs.github.com/en/actions/reference/encrypted-secrets). AWS GitHub Secrets Access Key Manager (AWS-GHS-AKM) is a solution to automatically rotate AWS IAM User API Access Keys and then sync those keys into user-defined GitHub repository secrets.

## General Use-Case

You have one to many GitHub repositories that leverage GitHub Action Secrets with the same AWS IAM User Access Key. You and/or your security team wants to ensure the following:

1. The IAM User Access key is rotated frequently at specified time (weekly, daily, hourly)
2. GitHub Secret within specified repositories are updated/sync'ed when AWS access keys are rotated
3. IAM User Access Key and GitHub Secrets are managed without need of someone knowing the secret
4. The access key management solution operates within the AWS environment boundary

## Prerequisites

`AWS GitHub AKM` interfaces with GitHub and the AWS account which your IAM User is provisioned prior to launch. Once launched, changes can be made or modified.

### GitHub Requirements

The following will be required from your GitHub environment:

- A GitHub machine user account with a [personal access token](https://github.com/settings/tokens) and appropriate permissions for GitHub Actions and repo management
- Access setup for the GitHub machine user account to each repo with appropriate permissions (maintain)

 > **Note:** A GitHub Machine User account is recommended for best practices. For more information and details about a GitHub Machine User reference [GitHub Documentation on Machine Users](https://docs.github.com/en/developers/overview/managing-deploy-keys#machine-users)

### AWS Requirements

The following will be required within your AWS account:

- AWS Account with IAM User which has appropriate permissions for your CICD needs
- Ability to deploy the CloudFormation stack resources

## Deployment

1. Open your web browser and login to your AWS Account.
2. Click this button to launch stack.
3. Fill out parameters

> **Note:** If you want to open the link as a new tab use `ctrl+click` when clicking the *launch Stack* button below or do the two-finger click and select `open new tab`

[![Launch Stack](https://cdn.rawgit.com/buildkite/cloudformation-launch-stack-button-svg/master/launch-stack.svg)](https://console.aws.amazon.com/cloudformation/home#/stacks/new?templateURL=https://rolston-cloud-library.s3.amazonaws.com/aws-github-akm/aws-github-akm.yml)

## Parameters

The follow parameters will need to be supplied upon deploying the stack

| Parameter | Description | Type | Default |
| --------- | ----------- | ---- | ------- |
| SNS Email Address | Email address for send lambda errors to | String | |
| Repo Config S3 Bucket Name | S3 Bucket to be created and store repo access list | String | |
| Repo Config Key | The S3 Object (file) which will contain the repo list in json format | String | `repos.json` |
| Solution Name | Friendly name of solution to identify IAM user being managed for API Key rotation | String | |
| GitHub Machine User Name | GitHub user account name | String | |
| GitHub Token | GitHub user personal access token | String | |
| IAM User Arn | Full ARN associated with the IAM user to manage API key rotation | String | |
| IAM User Name | User name of the IAM account to have API keys rotated | String |  |
| Hours To Rotate | Hours between each key rotation | Number | `12` |
| GitHub Secret Name AWS Key ID | The GitHub Secret Name value for the AWS Key ID | String | `AWS_ACCESS_KEY_ID` |
| GitHub Secret Name AWS Key | The GitHub Secret Name value for the AWS Key | String | `AWS_SECRET_ACCESS_KEY` |


## S3 Repository List

The stack deploys an S3 Bucket where a json file that contains a list of repositories **will need to be uploaded**. Note after stack deployment, the file uploaded to the S3 bucket must be named the same as the parameter `Repo Config Key`. Each repo defined in the json format contains the attribute `Name` which is the name of the repository and the attribute `owner` which is either the organization or the personal owner the repo is under.

> **Note:** The S3 repository config file must be uploaded after solution is deployed and be in the specified format below.


The following is the json format for a single repository:

```json
{
  "Repos":[
    {
      "Name":"key-management-1",
      "Owner":"grolston"
    }
  ]
}
```

The following example illustrates the format for multiple repositories:

```json
{
  "Repos":[
    {
      "Name":"key-management-4",
      "Owner":"grolston"
    },
    {
      "Name":"key-management-3",
      "Owner":"grolston-aws"
    },
    {
      "Name":"key-management-2",
      "Owner":"grolston"
    },
    {
      "Name":"key-management-1",
      "Owner":"grolston"
    }
  ]
}
```