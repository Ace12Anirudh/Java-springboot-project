# Student Management API Documentation

## Base URL

```
http://localhost:8080
```

For AWS deployment: `http://<alb-dns>/`

---

## Endpoints

### 1. Create Student

Create a new student record.

**Endpoint**: `POST /student/post`

**Request Body**:
```json
{
  "name": "John Doe",
  "age": 20,
  "email": "john.doe@example.com",
  "course": "Computer Science"
}
```

**Response** (200 OK):
```json
{
  "id": 1,
  "name": "John Doe",
  "age": 20,
  "email": "john.doe@example.com",
  "course": "Computer Science"
}
```

**Error Response** (400 Bad Request):
```json
{
  "error": "Student with email john.doe@example.com already exists"
}
```

**Validation Rules**:
- `name`: Required, 2-100 characters
- `age`: Required, 1-150
- `email`: Optional, must be valid email format, unique
- `course`: Optional, max 100 characters

---

### 2. Get Student by Name

Search for a student by name (case-insensitive).

**Endpoint**: `GET /student/get/{name}`

**Example**: `GET /student/get/John Doe`

**Response** (200 OK):
```json
{
  "id": 1,
  "name": "John Doe",
  "age": 20,
  "email": "john.doe@example.com",
  "course": "Computer Science"
}
```

**Error Response** (404 Not Found):
```json
{
  "error": "Student with name 'John Doe' not found"
}
```

---

### 3. Get Student by ID

Retrieve a student by their unique ID.

**Endpoint**: `GET /student/{id}`

**Example**: `GET /student/1`

**Response** (200 OK):
```json
{
  "id": 1,
  "name": "John Doe",
  "age": 20,
  "email": "john.doe@example.com",
  "course": "Computer Science"
}
```

**Error Response** (404 Not Found):
```json
{
  "error": "Student with ID 1 not found"
}
```

---

### 4. Get All Students

Retrieve all students in the database.

**Endpoint**: `GET /student/all`

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "name": "John Doe",
    "age": 20,
    "email": "john.doe@example.com",
    "course": "Computer Science"
  },
  {
    "id": 2,
    "name": "Jane Smith",
    "age": 22,
    "email": "jane.smith@example.com",
    "course": "Data Science"
  }
]
```

**Empty Response** (200 OK):
```json
[]
```

---

### 5. Update Student

Update an existing student's information.

**Endpoint**: `PUT /student/update/{id}`

**Example**: `PUT /student/update/1`

**Request Body**:
```json
{
  "name": "John Updated",
  "age": 21,
  "email": "john.updated@example.com",
  "course": "Software Engineering"
}
```

**Response** (200 OK):
```json
{
  "id": 1,
  "name": "John Updated",
  "age": 21,
  "email": "john.updated@example.com",
  "course": "Software Engineering"
}
```

**Error Response** (404 Not Found):
```json
{
  "error": "Student with ID 1 not found"
}
```

**Error Response** (400 Bad Request):
```json
{
  "error": "Student with email john.updated@example.com already exists"
}
```

---

### 6. Delete Student

Delete a student by ID.

**Endpoint**: `DELETE /student/delete/{id}`

**Example**: `DELETE /student/delete/1`

**Response** (200 OK):
```json
{
  "message": "Student deleted successfully"
}
```

**Error Response** (404 Not Found):
```json
{
  "error": "Student with ID 1 not found"
}
```

---

### 7. Health Check

Check if the backend service is running.

**Endpoint**: `GET /student/health`

**Response** (200 OK):
```json
{
  "status": "UP",
  "service": "Student Management Backend"
}
```

---

## Error Codes

| Status Code | Description |
|-------------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request (validation error or duplicate) |
| 404 | Not Found |
| 500 | Internal Server Error |

---

## CORS Configuration

The API allows cross-origin requests from all origins (`*`) with the following methods:
- GET
- POST
- PUT
- DELETE
- OPTIONS

**Note**: In production, restrict CORS to specific frontend domains.

---

## Testing with cURL

### Create Student
```bash
curl -X POST http://localhost:8080/student/post \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "age": 20,
    "email": "john.doe@example.com",
    "course": "Computer Science"
  }'
```

### Get All Students
```bash
curl http://localhost:8080/student/all
```

### Get Student by Name
```bash
curl http://localhost:8080/student/get/John%20Doe
```

### Update Student
```bash
curl -X PUT http://localhost:8080/student/update/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Updated",
    "age": 21,
    "email": "john.updated@example.com",
    "course": "Software Engineering"
  }'
```

### Delete Student
```bash
curl -X DELETE http://localhost:8080/student/delete/1
```

### Health Check
```bash
curl http://localhost:8080/student/health
```

---

## Database Schema

### students Table

| Column | Type | Constraints |
|--------|------|-------------|
| id | BIGINT | PRIMARY KEY, AUTO_INCREMENT |
| name | VARCHAR(100) | NOT NULL |
| age | INT | NOT NULL |
| email | VARCHAR(100) | UNIQUE |
| course | VARCHAR(100) | |

---

## Authentication

**Current**: No authentication required (development mode)

**Production Recommendation**: Implement JWT-based authentication or OAuth2 for secure access.
