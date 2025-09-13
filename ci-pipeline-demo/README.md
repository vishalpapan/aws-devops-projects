# AWS CI/CD Pipeline Demo with Flask App

This project demonstrates how to set up a complete CI/CD pipeline on AWS using CodeBuild to build and push a Flask application to Docker Hub.

## Project Structure
```
ci-pipeline-demo/
├── webapp/
│   └── app.py              # Flask application
├── Dockerfile              # Docker container configuration
├── buildspec.yml           # AWS CodeBuild configuration
├── requirements.txt        # Python dependencies
└── README.md              # This file
```

## Application Overview
A minimal Flask web application with two endpoints:
- `/` - Main page with welcome message
- `/health` - Health check endpoint returning JSON status

## Prerequisites
- AWS Account with appropriate permissions
- Docker Hub account
- GitHub repository
- Basic knowledge of Docker and AWS services

## Step-by-Step Implementation Guide

### 1. Local Development Setup

#### Create Flask Application
```python
# webapp/app.py
from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return '<h1>Hello from CI/CD Demo App!</h1><p>This Flask app is ready for AWS CI/CD pipeline.</p>'

@app.route('/health')
def health():
    return {'status': 'healthy', 'message': 'Application is running'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
```

#### Create Requirements File
```txt
# requirements.txt
Flask==2.3.3
```

#### Create Dockerfile
```dockerfile
FROM python:3-slim-bookworm
WORKDIR /app
COPY ./requirements.txt .
RUN pip install -r requirements.txt
COPY ./webapp/ ./webapp
EXPOSE 5000
CMD ["python", "./webapp/app.py"]
```

### 2. AWS Setup

#### Create Docker Hub Credentials in AWS Parameter Store
1. Go to AWS Systems Manager → Parameter Store
2. Create parameters:
   - Name: `/pythonapp-ci/docker-credentials/username`
   - Value: Your Docker Hub username
   - Type: String
   
   - Name: `/pythonapp-ci/docker-credentials/password`
   - Value: Your Docker Hub access token (not password!)
   - Type: SecureString

#### Create Docker Hub Access Token
1. Login to Docker Hub
2. Go to Account Settings → Security → Access Tokens
3. Create new token with Read/Write permissions
4. Use this token as the password in Parameter Store

### 3. AWS CodeBuild Setup

#### Create CodeBuild Project
1. Go to AWS CodeBuild → Create build project
2. Project configuration:
   - Project name: `pythonapp-codebuild-demo1`
   - Source provider: GitHub
   - Repository: Connect to your GitHub repo
   - Branch: main

3. Environment:
   - Environment image: Managed image
   - Operating system: Ubuntu
   - Runtime: Standard
   - Image: aws/codebuild/standard:5.0
   - Privileged: ✅ (Required for Docker)

4. Service role:
   - Create new service role
   - Add SSM permissions for Parameter Store access

#### Update Service Role Permissions
Add these policies to the CodeBuild service role:
- `AmazonSSMReadOnlyAccess` (for Parameter Store)
- Custom policy for SSM GetParameters:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameters",
                "ssm:GetParameter"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/pythonapp-ci/*"
        }
    ]
}
```

### 4. BuildSpec Configuration

The `buildspec.yml` file defines the build process:

```yaml
version: 0.2

env:
  parameter-store:
    DOCKER_REGISTRY_USERNAME: /pythonapp-ci/docker-credentials/username
    DOCKER_REGISTRY_PASSWORD: /pythonapp-ci/docker-credentials/password

phases:
  install:
    runtime-versions:
      python: 3.11
  pre_build:
    commands:
      - echo Logging in to Docker Hub...
      - docker login --username $DOCKER_REGISTRY_USERNAME --password $DOCKER_REGISTRY_PASSWORD
      - cd ci-pipeline-demo
      - pip install -r requirements.txt
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -t $DOCKER_REGISTRY_USERNAME/python-flask-aws-ci-app:latest .
      - docker tag $DOCKER_REGISTRY_USERNAME/python-flask-aws-ci-app:latest $DOCKER_REGISTRY_USERNAME/python-flask-aws-ci-app:$CODEBUILD_RESOLVED_SOURCE_VERSION
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker images...
      - docker push $DOCKER_REGISTRY_USERNAME/python-flask-aws-ci-app:latest
      - docker push $DOCKER_REGISTRY_USERNAME/python-flask-aws-ci-app:$CODEBUILD_RESOLVED_SOURCE_VERSION
```

### 5. Testing the Pipeline

1. Push code to GitHub repository
2. Trigger CodeBuild manually or via webhook
3. Monitor build logs in AWS CodeBuild console
4. Verify Docker image pushed to Docker Hub

## Build Results

### Successful CodeBuild Execution
![CodeBuild Success](images/codebuild-success.png)
*Screenshot showing successful CodeBuild execution with all phases completed*

### Docker Hub Push Confirmation
![Docker Hub Push](images/dockerhub-push-success.png)
*Screenshot showing successful Docker image push to Docker Hub repository*

## Common Issues and Solutions

### 1. Parameter Store Access Denied
**Error**: `AccessDeniedException: User is not authorized to perform: ssm:GetParameters`
**Solution**: Add SSM permissions to CodeBuild service role

### 2. Docker Login Failed
**Error**: `docker login` command fails
**Solution**: 
- Use Docker Hub access token instead of password
- Verify credentials in Parameter Store
- Check Docker Hub username (not email)

### 3. File Not Found
**Error**: `requirements.txt` not found
**Solution**: Ensure correct directory navigation in buildspec.yml

### 4. Docker Build Context
**Error**: Dockerfile not found
**Solution**: Verify build context and Dockerfile location

## Next Steps

1. **Add CodePipeline**: Create full pipeline with Source → Build → Deploy stages
2. **Add Testing**: Include unit tests in the build process
3. **Deploy to ECS**: Add deployment stage to Amazon ECS
4. **Add Notifications**: Set up SNS notifications for build status
5. **Environment Variables**: Add environment-specific configurations

## Cleanup

To avoid AWS charges:
1. Delete CodeBuild project
2. Remove Parameter Store parameters
3. Delete service roles if not needed
4. Remove Docker images from Docker Hub if desired

## Resources

- [AWS CodeBuild Documentation](https://docs.aws.amazon.com/codebuild/)
- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [AWS Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)