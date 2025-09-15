# Complete AWS CI/CD Pipeline Demo

Flask app with full CI/CD pipeline: **GitHub → CodeBuild → Docker Hub → CodeDeploy → EC2**

## Project Structure
```
ci-pipeline-demo/
├── webapp/app.py           # Flask application
├── scripts/                # CodeDeploy scripts
│   ├── start_container.sh  # Deploy script
│   └── stop_container.sh   # Cleanup script
├── Dockerfile              # Container config
├── buildspec.yml           # CodeBuild config
├── appspec.yml             # CodeDeploy config
├── requirements.txt        # Dependencies
└── ec2-setup.md           # EC2 setup guide
```

## Quick Setup Guide

### 1. Docker Hub Setup
- Create Docker Hub access token
- Store in AWS Parameter Store:
  - `/pythonapp-ci/docker-credentials/username`
  - `/pythonapp-ci/docker-credentials/password`

### 2. CodeBuild Setup
1. Create CodeBuild project
2. Connect to GitHub repo
3. Enable Docker (Privileged mode)
4. Add SSM permissions to service role

### 3. EC2 Setup for CodeDeploy
```bash
# Install CodeDeploy agent
sudo yum update -y
sudo yum install -y ruby wget docker
wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
chmod +x ./install && sudo ./install auto

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
```

### 4. IAM Roles
- **EC2 Role**: `AmazonEC2RoleforAWSCodeDeploy`
- **CodeDeploy Role**: `AWSCodeDeployRole`
- **CodeBuild Role**: SSM permissions for Parameter Store

### 5. CodeDeploy Setup
1. Create CodeDeploy application
2. Create deployment group with EC2 tags
3. Update `scripts/start_container.sh` with your Docker Hub username

## Pipeline Flow

1. **Push to GitHub** → Triggers CodeBuild
2. **CodeBuild** → Builds Docker image, pushes to Docker Hub
3. **CodeDeploy** → Pulls image, deploys to EC2
4. **EC2** → Runs Flask app on port 80

## Key Files

**buildspec.yml** - CodeBuild configuration
```yaml
version: 0.2
env:
  parameter-store:
    DOCKER_REGISTRY_USERNAME: /pythonapp-ci/docker-credentials/username
    DOCKER_REGISTRY_PASSWORD: /pythonapp-ci/docker-credentials/password
phases:
  pre_build:
    commands:
      - docker login --username $DOCKER_REGISTRY_USERNAME --password $DOCKER_REGISTRY_PASSWORD
      - cd ci-pipeline-demo && pip install -r requirements.txt
  build:
    commands:
      - docker build -t $DOCKER_REGISTRY_USERNAME/python-flask-aws-ci-app:latest .
  post_build:
    commands:
      - docker push $DOCKER_REGISTRY_USERNAME/python-flask-aws-ci-app:latest
```

**appspec.yml** - CodeDeploy configuration
```yaml
version: 0.0
os: linux
hooks:
  ApplicationStop:
    - location: scripts/stop_container.sh
      timeout: 300
      runas: root
  AfterInstall:
    - location: scripts/start_container.sh
      timeout: 300
      runas: root
```

## Screenshots

### CodeBuild Success
![CodeBuild Success](images/codebuild-success.png)

### Docker Hub Push
![Docker Hub Push](images/dockerhub-push-success.png)

## Common Issues
- **SSM Access Denied**: Add SSM permissions to CodeBuild role
- **Docker Login Failed**: Use access token, not password
- **File Not Found**: Check directory navigation in buildspec.yml
- **CodeDeploy Agent**: Ensure agent is running on EC2

## Testing
- **Local**: `docker build -t flask-app . && docker run -p 5000:5000 flask-app`
- **Production**: Access EC2 public IP on port 80

## Cleanup
- Delete CodeBuild/CodeDeploy projects
- Terminate EC2 instances
- Remove Parameter Store values
- Delete Docker Hub images