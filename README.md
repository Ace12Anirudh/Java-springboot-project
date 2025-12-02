# Student Management System

A modern, full-stack Student Management System built with **Java Spring Boot** backend and **Python Streamlit** frontend, designed for AWS deployment with CI/CD using Jenkins and SonarQube.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                    ┌────▼────┐
                    │   ALB   │ (Application Load Balancer)
                    └────┬────┘
                         │
            ┌────────────┴────────────┐
            │                         │
       ┌────▼─────┐            ┌─────▼────┐
       │ Frontend │            │ Backend  │
       │   ASG    │            │   ASG    │
       │(Streamlit)            │ (Spring  │
       │ Port 80  │            │  Boot)   │
       └──────────┘            │ Port 8080│
                               └─────┬────┘
                                     │
                               ┌─────▼────┐
                               │   RDS    │
                               │  MySQL   │
                               └──────────┘
```

## ✨ Features

### Backend (Java Spring Boot)
- ✅ RESTful API with full CRUD operations
- ✅ MySQL database integration via Spring Data JPA
- ✅ Input validation and error handling
- ✅ CORS configuration for frontend integration
- ✅ Health check endpoints for ALB monitoring
- ✅ SonarQube integration for code quality

### Frontend (Python Streamlit)
- ✅ Modern glassmorphism design with gradient backgrounds
- ✅ Google Fonts (Inter) integration
- ✅ Smooth animations and micro-interactions
- ✅ Full CRUD operations (Add, Search, Update, Delete, List)
- ✅ Real-time metrics dashboard
- ✅ Responsive and premium UI/UX

### DevOps
- ✅ Jenkins CI/CD pipeline
- ✅ SonarQube code analysis
- ✅ Terraform infrastructure as code
- ✅ AWS deployment (VPC, ALB, ASG, RDS, Bastion)
- ✅ Automated deployment via SSH through bastion

## 📁 Project Structure

```
java-springboot-project/
├── backend/                    # Spring Boot application
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/studentmanagement/
│   │   │   │   ├── StudentManagementApplication.java
│   │   │   │   ├── controller/
│   │   │   │   │   └── StudentController.java
│   │   │   │   ├── service/
│   │   │   │   │   └── StudentService.java
│   │   │   │   ├── repository/
│   │   │   │   │   └── StudentRepository.java
│   │   │   │   ├── entity/
│   │   │   │   │   └── Student.java
│   │   │   │   ├── dto/
│   │   │   │   │   └── StudentDTO.java
│   │   │   │   └── config/
│   │   │   │       └── WebConfig.java
│   │   │   └── resources/
│   │   │       └── application.properties
│   │   └── test/
│   ├── pom.xml
│   └── sonar-project.properties
│
├── frontend/                   # Streamlit application
│   ├── src/
│   │   └── app.py
│   ├── requirements.txt
│   └── sonar-project.properties
│
├── infra/                      # Terraform infrastructure
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── Jenkinsfile
│   ├── modules/
│   │   ├── vpc/
│   │   ├── alb/
│   │   ├── asg_backend/
│   │   ├── asg_frontend/
│   │   ├── rds/
│   │   ├── bastion/
│   │   └── launch_template/
│   └── envs/
│       └── dev.tfvars
│
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- **Java 17** or higher
- **Maven 3.6+**
- **Python 3.8+**
- **MySQL 8.0** (for local development)
- **Git**

### Local Development

#### 1. Start Backend

```bash
cd backend

# Configure database (or use environment variables)
export DB_URL="jdbc:mysql://localhost:3306/studentdb?createDatabaseIfNotExist=true"
export DB_USERNAME="root"
export DB_PASSWORD="your_password"

# Build and run
mvn spring-boot:run
```

Backend will start on `http://localhost:8080`

#### 2. Start Frontend

```bash
cd frontend

# Install dependencies
pip install -r requirements.txt

# Set backend URL
export API_URL="http://localhost:8080"

# Run Streamlit
streamlit run src/app.py
```

Frontend will start on `http://localhost:8501`

### Testing the Application

1. Open browser to `http://localhost:8501`
2. Add a student using the "Add Student" tab
3. Search for students by name
4. View all students in the "All Students" tab
5. Update or delete students as needed

## 📡 API Endpoints

See [API.md](backend/API.md) for detailed API documentation.

**Base URL**: `http://localhost:8080`

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/student/post` | Create a new student |
| GET | `/student/get/{name}` | Get student by name |
| GET | `/student/{id}` | Get student by ID |
| GET | `/student/all` | Get all students |
| PUT | `/student/update/{id}` | Update student |
| DELETE | `/student/delete/{id}` | Delete student |
| GET | `/student/health` | Health check |

## 🔧 Configuration

### Backend Configuration

Edit `backend/src/main/resources/application.properties`:

```properties
# Database
spring.datasource.url=${DB_URL:jdbc:mysql://localhost:3306/studentdb}
spring.datasource.username=${DB_USERNAME:root}
spring.datasource.password=${DB_PASSWORD:password}

# Server
server.port=8080
```

### Frontend Configuration

Set environment variable:

```bash
export API_URL="http://your-backend-url:8080"
```

## ☁️ AWS Deployment

### Prerequisites

- AWS account with appropriate permissions
- Jenkins server with required tools (Maven, Python, AWS CLI, Terraform)
- SonarQube server
- SSH key pair for EC2 instances

### Deployment Steps

1. **Configure Terraform Variables**

Edit `infra/envs/dev.tfvars`:

```hcl
aws_region = "us-east-1"
ssh_public_key = "your-ssh-public-key"
jenkins_ssh_cidr = ["your-jenkins-ip/32"]
rds_password = "your-secure-password"
```

2. **Configure Jenkins Credentials**

- `aws-creds`: AWS access key and secret
- `jenkins-ssh-key`: Private SSH key for EC2 access
- `sonar-token`: SonarQube authentication token

3. **Run Jenkins Pipeline**

The pipeline will:
- Checkout code
- Run SonarQube analysis on frontend and backend
- Build backend JAR file
- Package frontend Python files
- Apply Terraform infrastructure
- Deploy artifacts to EC2 instances via SSH through bastion

4. **Access Application**

After deployment, get the ALB DNS:

```bash
cd infra
terraform output alb_dns_name
```

Access frontend: `http://<alb-dns>/`

## 🧪 Testing

### Backend Tests

```bash
cd backend
mvn test
```

### SonarQube Analysis

```bash
# Backend
cd backend
mvn clean verify sonar:sonar -Dsonar.login=<your-token>

# Frontend
cd frontend
sonar-scanner -Dsonar.login=<your-token>
```

## 🔐 Security Notes

- ⚠️ Restrict `jenkins_ssh_cidr` to Jenkins server IP only
- ⚠️ Use AWS Secrets Manager for RDS password in production
- ⚠️ Enable HTTPS on ALB using ACM certificates
- ⚠️ Review and restrict CORS origins in production
- ⚠️ Implement authentication/authorization for production use

## 📊 Monitoring

- **Backend Health**: `http://<alb-dns>/student/health`
- **ALB Health Checks**: Configured in Terraform
- **Application Logs**: Available via SSH to instances through bastion

## 🛠️ Troubleshooting

### Backend won't start
- Check MySQL is running and accessible
- Verify database credentials
- Check Java version: `java -version` (should be 17+)

### Frontend can't connect to backend
- Verify `API_URL` environment variable is set correctly
- Check backend is running and accessible
- Verify CORS configuration in backend

### Jenkins deployment fails
- Check Jenkins credentials are configured
- Verify SSH key has access to bastion
- Check Terraform state is not locked
- Review Jenkins console output for specific errors

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and SonarQube analysis
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License.

## 👥 Authors

- MultiCloudDevOps Team

## 🙏 Acknowledgments

- Spring Boot framework
- Streamlit framework
- AWS for cloud infrastructure
- Jenkins for CI/CD
- SonarQube for code quality
