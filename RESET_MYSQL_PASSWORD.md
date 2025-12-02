# Reset MySQL Root Password on Windows

## Method 1: Using MySQL Workbench (Easiest)

If you can connect via MySQL Workbench (password saved):

1. Open MySQL Workbench
2. Connect to your instance (it may auto-connect if password is saved)
3. Run this SQL:
```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'ace12mysql';
FLUSH PRIVILEGES;
```

---

## Method 2: Reset Password Manually

### Step 1: Stop MySQL Service
```powershell
# Run PowerShell as Administrator
Stop-Service MySQL80
```

### Step 2: Create Init File
Create a file `C:\mysql-init.txt` with this content:
```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'ace12mysql';
```

### Step 3: Start MySQL with Init File
```powershell
# Run as Administrator
cd "C:\Program Files\MySQL\MySQL Server 8.0\bin"
.\mysqld --init-file=C:\mysql-init.txt --console
```

### Step 4: Stop and Restart Normally
1. Press `Ctrl+C` to stop the console
2. Delete `C:\mysql-init.txt`
3. Start service normally:
```powershell
Start-Service MySQL80
```

### Step 5: Test New Password
```powershell
mysql -u root -p
# Enter password: ace12mysql
```

---

## Method 3: Skip Password Temporarily

### Step 1: Stop MySQL
```powershell
Stop-Service MySQL80
```

### Step 2: Start MySQL Without Password Check
```powershell
# Run as Administrator
cd "C:\Program Files\MySQL\MySQL Server 8.0\bin"
.\mysqld --skip-grant-tables --console
```

### Step 3: Connect Without Password (New PowerShell Window)
```powershell
mysql -u root
```

### Step 4: Reset Password
```sql
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'ace12mysql';
FLUSH PRIVILEGES;
EXIT;
```

### Step 5: Restart MySQL Normally
1. Press `Ctrl+C` in the console window
2. Start service:
```powershell
Start-Service MySQL80
```

---

## Quick Test After Reset

```powershell
# Test connection
mysql -u root -p
# Enter password: ace12mysql

# Create database
CREATE DATABASE studentdb;
SHOW DATABASES;
EXIT;

# Update environment variable
$env:DB_PASSWORD="ace12mysql"

# Run backend
cd backend
mvn spring-boot:run
```

---

## Recommended Approach

1. **First try**: Open MySQL Workbench and see if it auto-connects
2. **If that works**: Change password using SQL command
3. **If that fails**: Use Method 2 (init file) - safest manual reset
4. **Last resort**: Use Method 3 (skip-grant-tables) - requires stopping/starting service

Choose based on your comfort level!
