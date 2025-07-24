Check technical blog here : [Traffic Shifting for AWS Lambda Deployments Using LocalStack and Terraform](https://dev.to/aws-builders/traffic-shifting-for-aws-lambda-deployments-using-localstack-and-terraform-4acn)


> *"This project simulates a Traffic Shifting-style deployment using AWS Lambda aliases and manual traffic shifting via a script, suitable for testing in LocalStack. While not a true CodeDeploy-managed canary deployment, it mimics rollout behavior and can later be upgraded to full AWS CodeDeploy."*

## Technologies Used
- **Terraform** for infrastructure-as-code
- **[awslocal](https://github.com/localstack/awscli-local) and [tflocal](https://github.com/localstack/terraform-local)** for interaction with aws cli and terraform
- **LocalStack** for simulating AWS locally
- **AWS Lambda** with versioned deployments
- **API Gateway** to expose Lambda function
- **Shell script** to shift traffic between aliases

## Infrastructure Modules and Files Overview

> You can find the complete code and project structure on GitHub: [HERE](https://github.com/axeldlv/traffic-shifting-localstack)

| Module / Directory   | File              | Purpose                                                                                      |
|---------------------|-------------------|----------------------------------------------------------------------------------------------|
| **Root Directory**   |                   | Combines all modules and manages overall infrastructure                                   |
|                     | `main.tf`         | Calls all modules (Lambda, API Gateway, IAM) and wires them together                        |
|                     | `provider.tf`     | Configures LocalStack AWS provider and endpoint overrides                                  |
|                     | `variables.tf`    | Declares global variables used in root module or passed to submodules                      |
|                     | `locals.tf`       | Centralizes constants, derived values, or map-like logic                                  |
|                     | `output.tf`       | Outputs: API Gateway invoke URL                                              |
| **modules/lambda**  |                   | Deploy and version Lambda functions, manage aliases                                       |
|                     | `main.tf`         | Creates the Lambda function, publishes versions, sets up aliases                             |
|                     | `variables.tf`    | Declares inputs: function name, runtime, handler, IAM role ARN                      |
|                     | `output.tf`       | Outputs: Lambda function name, ARN, alias, version                                          |
| **modules/iam**     |                   | Set up IAM roles and attach necessary permissions                                         |
|                     | `main.tf`         | Creates Lambda execution role and policy documents                                          |
|                     | `variables.tf`    | common tags                                                   |
|                     | `output.tf`       | Outputs: IAM role ARN (used by Lambda module)                                              |
| **modules/apigateway** |                 | Configure API Gateway to expose Lambda with alias support                                |
|                     | `main.tf`         | Creates REST API, resources, methods, integrations with Lambda                              |
|                     | `variables.tf`    | Declares inputs: Lambda alias ARN, stage name, HTTP methods                                |
|                     | `output.tf`       | Outputs: invoke URL                                              |
| **script**          |                   | Deployment logic and simulation scripts                                                  |
|                     | `traffic-shifting.sh`| Simulates alias-based routing by invoking different Lambda versions manually based on random chance |

## Traffic Shifting Script Breakdown
###  Configuration Section
```bash
FUNCTION_NAME="lambda_function"
ZIP_PATH=$1
REST_API_ID=$2
ALIAS_NAME="live"
REGION="eu-west-1"
WAIT_SECONDS=10
HEALTH_URL="http://$REST_API_ID.execute-api.localhost.localstack.cloud:4566/prod/test"
EXPECTED_STATUS=200
```

### Step 1: Publish New Lambda Version
```bash
NEW_VERSION=$(awslocal lambda update-function-code \
  --function-name "$FUNCTION_NAME" \
  --zip-file "fileb://${ZIP_PATH}" \
  --publish \
  --query 'Version' \
  --output text)
```
- Uploads new function code and publishes a version.
- Stores the new version number for later use.

### Step 2: Get Current Alias Version
```bash
CURRENT_VERSION=$(awslocal lambda get-alias \
  --function-name "$FUNCTION_NAME" \
  --name "$ALIAS_NAME" \
  --query 'FunctionVersion' \
  --output text)
```
- Retrieves the currently live version the alias points to (used for rollback if needed).

### Step 3: Shift 100% Traffic to New Version
```bash
awslocal lambda update-alias \
  --function-name "$FUNCTION_NAME" \
  --name "$ALIAS_NAME" \
  --function-version "$NEW_VERSION"
```
- Updates the alias (e.g., `live`) to fully route traffic to the new version.

### Step 4: Perform Health Check
```bash
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL")
```
- Waits a few seconds, then hits the API endpoint.
- Checks if the response code matches the expected value (`200`).

### Step 5: Promote or Rollback
```bash
if [ "$STATUS_CODE" -eq "$EXPECTED_STATUS" ]; then
  echo "Health check passed — keeping v$NEW_VERSION live"
  echo "Traffic shifting deployment finished."
else
  echo "Health check failed (got $STATUS_CODE) — rolling back to v$CURRENT_VERSION"
  awslocal lambda update-alias \
    --function-name "$FUNCTION_NAME" \
    --name "$ALIAS_NAME" \
    --function-version "$CURRENT_VERSION"
    echo "Traffic shifting deployment failed."
fi
```
- If the health check passes: the new version stays live.
- If it fails: rollback to the previous stable version.

This is a lightweight, local traffic shifting strategy for testing Lambda changes safely using LocalStack.

## Running and Verifying Infrastructure Locally

### 1. Set up and run LocalStack using Docker
Make sure Docker is installed on your machine.

Run LocalStack container with AWS services enabled (Lambda, API Gateway, IAM, etc.):

```bash
docker run \
  -d \
  -p 127.0.0.1:4566:4566 \
  -p 127.0.0.1:4510-4559:4510-4559 \
  -p 127.0.0.1:443:443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  localstack/localstack
```

### 2. Configure AWS CLI to point to LocalStack
Set AWS CLI environment variables for LocalStack endpoint (replace values as needed):

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_REGION=eu-west-1
export AWS_ENDPOINT_URL=http://localhost:4566
```

### 3. Deploy your Terraform infrastructure to LocalStack
In your Terraform root directory, initialize and apply:

```bash
tflocal init
tflocal apply
```

```bash
Outputs:
api_gateway_invoke_url = "http://psjlmrppsc.execute-api.localhost.localstack.cloud:4566"
```

The invoke URL format is:
```
http://{rest_api_id}.execute-api.localhost.localstack.cloud:4566/{stage_name}/test
```
For example, if `rest_api_id = psjlmrppsc` and your stage_name is `prod`:
```bash
curl -X GET http://psjlmrppsc.execute-api.localhost.localstack.cloud:4566/prod/test
```

Expected output should be something like:
```
Hello from version 1 !
```

### 4. Verify resources in LocalStack
```bash
awslocal lambda list-functions --endpoint-url=http://localhost:4566
awslocal apigateway get-rest-apis --endpoint-url=http://localhost:4566
```
Or use LocalStack’s web UI if available on https://app.localstack.cloud.

### 5. Traffic Shifting script

To invoke traffic shiffting script:

```bash
./script/traffic-shifting.sh {rest_api_id} {path_lambda_zip}
```
For example, if `rest_api_id = psjlmrppsc` and your path_lambda_zip is `./lambda/v2/lambda-v2.zip`:
```bash
./script/traffic-shifting.sh psjlmrppsc ./lambda/v2/lambda-v2.zip
```

#### Updating to version 2
Run your script to simulate traffic shifting deployment:
```bash
./script/traffic-shifting.sh psjlmrppsc ./lambda/v2/lambda-v2.zip
```

```bash
Publishing new Lambda version from ./lambda/v2/lambda-v2.zip
Current version: 1, New version: 2
Simulating traffic shifting: updating alias to v2 (100%)
{
    "AliasArn": "arn:aws:lambda:eu-west-1:000000000000:function:lambda_function:live",
    "Name": "live",
    "FunctionVersion": "2",
    "Description": "",
    "RevisionId": "3d562afa-4d56-4447-b7a0-f7b44e6d86cf"
}
Waiting 10 seconds for traffic to flow...
Checking health at http://psjlmrppsc.execute-api.localhost.localstack.cloud:4566/prod/test
Health check passed — keeping v2 live
Traffic shifting deployment finished.
```
The script should invoke the Lambda functions through the API Gateway alias routing locally via LocalStack.

Test the API endpoint to verify it's responding with the correct V2 response:
```bash
curl -X GET http://psjlmrppsc.execute-api.localhost.localstack.cloud:4566/prod/test
```
Expected output should be something like:
```
Hello from version 2 !
```

#### Updating to version 3
Run your script to simulate traffic shifting deployment:
```bash
./script/traffic-shifting.sh psjlmrppsc ./lambda/v3/lambda-v3.zip
```

```bash
Publishing new Lambda version from ./lambda/v3/lambda-v3.zip
Current version: 2, New version: 3
Simulating traffic shifting: updating alias to v3 (100%)
{
    "AliasArn": "arn:aws:lambda:eu-west-1:000000000000:function:lambda_function:live",
    "Name": "live",
    "FunctionVersion": "3",
    "Description": "",
    "RevisionId": "c913bf5e-caf2-4354-bdc3-57594adc5b5d"
}
Waiting 10 seconds for traffic to flow...
Checking health at http://psjlmrppsc.execute-api.localhost.localstack.cloud:4566/prod/test
Health check failed (got 502) — rolling back to v2
{
    "AliasArn": "arn:aws:lambda:eu-west-1:000000000000:function:lambda_function:live",
    "Name": "live",
    "FunctionVersion": "2",
    "Description": "",
    "RevisionId": "107f7f53-0c87-414f-8aa7-07732b47b4a9"
}
Traffic shifting deployment failed.
```
Try calling the same endpoint again:
```bash
curl -X GET http://psjlmrppsc.execute-api.localhost.localstack.cloud:4566/prod/test
```

If traffic shifting is properly configured or your script handles fallback logic, you should still receive the response from version 2, confirming resilience as the v3 application raise an error.

```
Hello from version 2 !
```

## Destroy terraform environment
when you have finished, don't forget to destroy the environment :

```bash
tflocal destroy -auto-approve
```

## Conclusion
Implementing traffic shifting deployments for AWS Lambda using Terraform both on LocalStack and real AWS brings the best of both development speed and production safety. By simulating real-world deployment flows locally, you can test new Lambda versions, validate functionality through health checks, and automate rollback when things go wrong all without risking your live environment.

Whether you're building locally or deploying to AWS, this approach provides a repeatable, reliable, and testable strategy for Lambda version management.

Picture of <a href="https://unsplash.com/fr/@savosave?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">David S</a> on <a href="https://unsplash.com/fr/photos/un-avion-jaune-assis-au-sommet-dun-champ-couvert-dherbe-LDm9u2enYmo?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>