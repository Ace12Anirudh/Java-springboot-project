package com.studentmanagement.controller;

import com.studentmanagement.dto.StudentDTO;
import com.studentmanagement.service.StudentService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/student")
@CrossOrigin(origins = "*")
public class StudentController {
    
    @Autowired
    private StudentService studentService;
    
    /**
     * Create a new student
     * POST /student/post
     */
    @PostMapping("/post")
    public ResponseEntity<?> createStudent(@Valid @RequestBody StudentDTO studentDTO) {
        try {
            StudentDTO createdStudent = studentService.createStudent(studentDTO);
            return ResponseEntity.ok(createdStudent);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }
    
    /**
     * Get student by name
     * GET /student/get/{name}
     */
    @GetMapping("/get/{name}")
    public ResponseEntity<?> getStudentByName(@PathVariable String name) {
        try {
            StudentDTO student = studentService.getStudentByName(name);
            return ResponseEntity.ok(student);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }
    
    /**
     * Get all students
     * GET /student/all
     */
    @GetMapping("/all")
    public ResponseEntity<List<StudentDTO>> getAllStudents() {
        List<StudentDTO> students = studentService.getAllStudents();
        return ResponseEntity.ok(students);
    }
    
    /**
     * Update student
     * PUT /student/update/{id}
     */
    @PutMapping("/update/{id}")
    public ResponseEntity<?> updateStudent(@PathVariable Long id, @Valid @RequestBody StudentDTO studentDTO) {
        try {
            StudentDTO updatedStudent = studentService.updateStudent(id, studentDTO);
            return ResponseEntity.ok(updatedStudent);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }
    
    /**
     * Delete student
     * DELETE /student/delete/{id}
     */
    @DeleteMapping("/delete/{id}")
    public ResponseEntity<?> deleteStudent(@PathVariable Long id) {
        try {
            studentService.deleteStudent(id);
            Map<String, String> response = new HashMap<>();
            response.put("message", "Student deleted successfully");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }
    
    /**
     * Get student by ID
     * GET /student/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getStudentById(@PathVariable Long id) {
        try {
            StudentDTO student = studentService.getStudentById(id);
            return ResponseEntity.ok(student);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }
    
    /**
     * Health check endpoint for ALB
     * GET /student/health
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> healthCheck() {
        Map<String, String> health = new HashMap<>();
        health.put("status", "UP");
        health.put("service", "Student Management Backend");
        return ResponseEntity.ok(health);
    }
}
