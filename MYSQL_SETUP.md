# MySQL Setup Guide for Windows

## Option 1: Install MySQL Server (Recommended for Development)

### Step 1: Download MySQL
1. Go to: https://dev.mysql.com/downloads/installer/
2. Download **MySQL Installer for Windows** (mysql-installer-community-8.0.x.msi)
3. Choose the smaller "web" installer or full installer

### Step 2: Install MySQL
1. Run the installer
2. Choose **"Developer Default"** setup type
3. Click **Next** through the installation
4. On **"Accounts and Roles"** page:
   - Set root password: `ace12mysql` (or your chosen password)
   - Click **Next**
5. On **"Windows Service"** page:
   - Keep "Configure MySQL Server as a Windows Service" checked
   - Service Name: MySQL80
   - Start at System Startup: Checked
   - Click **Next**
6. Click **Execute** to apply configuration
7. Click **Finish**

### Step 3: Verify MySQL is Running
```powershell
# Check if MySQL service is running
Get-Service MySQL80

# Should show:
# Status   Name               DisplayName
# ------   ----               -----------
# Running  MySQL80            MySQL80
```

### Step 4: Connect to MySQL
```powershell
# Add MySQL to PATH (if not already)
$env:Path += ";C:\Program Files\MySQL\MySQL Server 8.0\bin"

# Connect to MySQL
mysql -u root -p
# Enter password: ace12mysql
```

### Step 5: Create Database
```sql
CREATE DATABASE studentdb;
SHOW DATABASES;
EXIT;
```

---

## Option 2: Use Docker (If you have Docker Desktop)

### Step 1: Start MySQL Container
```powershell
docker run --name mysql-studentdb `
  -e MYSQL_ROOT_PASSWORD=ace12mysql `
  -e MYSQL_DATABASE=studentdb `
  -p 3306:3306 `
  -d mysql:8.0
```

### Step 2: Verify Container is Running
```powershell
docker ps
```

### Step 3: Connect to MySQL
```powershell
docker exec -it mysql-studentdb mysql -u root -p
# Enter password: ace12mysql
```

---

## Option 3: Use H2 Database (In-Memory, No Installation)

If you just want to test quickly without installing MySQL:

### Step 1: Update application.properties
```properties
# Comment out MySQL configuration
# spring.datasource.url=${DB_URL:jdbc:mysql://localhost:3306/studentdb}
# spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# Add H2 configuration
spring.datasource.url=jdbc:h2:mem:studentdb
spring.datasource.driver-class-name=org.h2.Driver
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
```

### Step 2: Add H2 dependency to pom.xml
```xml
<!-- Add to dependencies section -->
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>runtime</scope>
</dependency>
```

### Step 3: Run backend (no MySQL needed!)
```powershell
cd backend
mvn spring-boot:run
```

---

## Troubleshooting

### MySQL Service Not Starting
```powershell
# Start MySQL service manually
Start-Service MySQL80

# Check status
Get-Service MySQL80
```

### Can't Connect to MySQL
```powershell
# Check if MySQL is listening on port 3306
netstat -an | findstr 3306

# Should show:
# TCP    0.0.0.0:3306           0.0.0.0:0              LISTENING
```

### Forgot Root Password
1. Stop MySQL service: `Stop-Service MySQL80`
2. Reinstall MySQL or reset password using MySQL documentation

---

## Quick Start Commands

### After MySQL is Installed and Running:

```powershell
# 1. Connect to MySQL
mysql -u root -p
# Enter password: ace12mysql

# 2. Create database
CREATE DATABASE studentdb;
SHOW DATABASES;
EXIT;

# 3. Set environment variables
cd backend
$env:DB_URL="jdbc:mysql://localhost:3306/studentdb"
$env:DB_USERNAME="root"
$env:DB_PASSWORD="ace12mysql"

# 4. Run backend
mvn spring-boot:run
```

---

## Recommended Approach

For **local development**, I recommend:
1. **Option 3 (H2)** - Fastest, no installation, perfect for testing
2. **Option 1 (MySQL)** - If you want production-like environment
3. **Option 2 (Docker)** - If you already have Docker Desktop

Choose based on your needs!
