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
├── requirements.txt        # Dependencies
└── ec2-setup.md           # EC2 setup guide
```

## CI/CD Flow Diagram

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
│   GitHub    │───▶│  CodeBuild   │───▶│ Docker Hub  │───▶│  CodeDeploy  │
│   (Source)  │    │   (Build)    │    │  (Registry) │    │   (Deploy)   │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────────┘
                                                                    │
                                                                    ▼
                                                           ┌──────────────┐
                                                           │     EC2      │
                                                           │ (Production) │
                                                           └──────────────┘
```

## Setup Flow (Step by Step)

### Phase 1: CI Setup (CodeBuild)

**1. Docker Hub Setup**
- Create Docker Hub access token
- Store in AWS Parameter Store:
  - `/pythonapp-ci/docker-credentials/username`
  - `/pythonapp-ci/docker-credentials/password`

**2. CodeBuild Setup**
1. Create CodeBuild project
2. Connect to GitHub repo
3. Enable Docker (Privileged mode)
4. Add SSM permissions to service role

### Phase 2: CD Setup (CodeDeploy)

**3. Create EC2 Instance**
1. Launch EC2 instance (Amazon Linux 2)
2. Add tags: `Environment: Production`, `Application: FlaskApp`
3. Security Group: Allow HTTP (80), SSH (22)

**4. Install CodeDeploy Agent on EC2**
```bash
# SSH into EC2 and run:
sudo yum update -y
sudo yum install -y ruby wget docker
wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
chmod +x ./install && sudo ./install auto

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Verify agent
sudo service codedeploy-agent status
```

**5. Create IAM Roles**
- **EC2 Instance Role**: `AmazonEC2RoleforAWSCodeDeploy`
- **CodeDeploy Service Role**: `AWSCodeDeployRole`
- Attach EC2 role to your instance

**6. CodeDeploy Application Setup**
1. Create CodeDeploy application: `code-deploy-test`
2. Create deployment group: `new-deployment-group`
3. Select EC2 instances by tags
4. Choose service role created above

**7. Deploy Application**
- Repository: `vishalpapan/aws-devops-projects`
- Commit ID: Latest commit hash
- appspec.yml location: Root directory

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

**appspec.yml** - CodeDeploy configuration (at root)
```yaml
version: 0.0
os: linux
hooks:
  ApplicationStop:
    - location: ci-pipeline-demo/scripts/stop_container.sh
      timeout: 300
      runas: root
  AfterInstall:
    - location: ci-pipeline-demo/scripts/start_container.sh
      timeout: 300
      runas: root
```

## Screenshots

### CodeDeploy Success
<img width="975" height="405" alt="image" src="https://github.com/user-attachments/assets/53fffab5-a681-4602-a67c-6dbd42fabb59" />


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
