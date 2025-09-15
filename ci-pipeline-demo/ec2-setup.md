# EC2 Setup for CodeDeploy

## EC2 Instance Setup Commands

### 1. Install CodeDeploy Agent
```bash
# Update system
sudo yum update -y

# Install CodeDeploy agent
sudo yum install -y ruby wget
cd /home/ec2-user
wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto

# Verify agent is running
sudo service codedeploy-agent status
```

### 2. Install Docker
```bash
# Install Docker
sudo yum install -y docker

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to docker group
sudo usermod -a -G docker ec2-user

# Verify Docker installation
docker --version
```

### 3. Required IAM Roles

#### EC2 Instance Role (attach to EC2)
- `AmazonEC2RoleforAWSCodeDeploy`
- `CloudWatchAgentServerPolicy` (optional for monitoring)

#### CodeDeploy Service Role
- `AWSCodeDeployRole`

### 4. Security Group Settings
- **Inbound Rules:**
  - HTTP (80) from 0.0.0.0/0
  - SSH (22) from your IP
  - Custom TCP (5000) from 0.0.0.0/0 (optional for direct Flask access)

### 5. Tags for EC2 Instance
Add tags to identify the instance for CodeDeploy:
- Key: `Environment`, Value: `Production`
- Key: `Application`, Value: `FlaskApp`