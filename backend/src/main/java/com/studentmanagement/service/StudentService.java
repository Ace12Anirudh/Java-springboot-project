package com.studentmanagement.service;

import com.studentmanagement.dto.StudentDTO;
import com.studentmanagement.entity.Student;
import com.studentmanagement.repository.StudentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class StudentService {
    
    @Autowired
    private StudentRepository studentRepository;
    
    /**
     * Create a new student
     */
    public StudentDTO createStudent(StudentDTO studentDTO) {
        // Check if email already exists
        if (studentDTO.getEmail() != null && studentRepository.existsByEmail(studentDTO.getEmail())) {
            throw new RuntimeException("Student with email " + studentDTO.getEmail() + " already exists");
        }
        
        Student student = new Student();
        student.setName(studentDTO.getName());
        student.setAge(studentDTO.getAge());
        student.setEmail(studentDTO.getEmail());
        student.setCourse(studentDTO.getCourse());
        
        Student savedStudent = studentRepository.save(student);
        return convertToDTO(savedStudent);
    }
    
    /**
     * Get student by name
     */
    public StudentDTO getStudentByName(String name) {
        Student student = studentRepository.findByNameIgnoreCase(name)
                .orElseThrow(() -> new RuntimeException("Student with name '" + name + "' not found"));
        return convertToDTO(student);
    }
    
    /**
     * Get all students
     */
    public List<StudentDTO> getAllStudents() {
        return studentRepository.findAll().stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Update student
     */
    public StudentDTO updateStudent(Long id, StudentDTO studentDTO) {
        Student student = studentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Student with ID " + id + " not found"));
        
        // Check if email is being changed and if new email already exists
        if (studentDTO.getEmail() != null && 
            !studentDTO.getEmail().equals(student.getEmail()) && 
            studentRepository.existsByEmail(studentDTO.getEmail())) {
            throw new RuntimeException("Student with email " + studentDTO.getEmail() + " already exists");
        }
        
        student.setName(studentDTO.getName());
        student.setAge(studentDTO.getAge());
        student.setEmail(studentDTO.getEmail());
        student.setCourse(studentDTO.getCourse());
        
        Student updatedStudent = studentRepository.save(student);
        return convertToDTO(updatedStudent);
    }
    
    /**
     * Delete student
     */
    public void deleteStudent(Long id) {
        if (!studentRepository.existsById(id)) {
            throw new RuntimeException("Student with ID " + id + " not found");
        }
        studentRepository.deleteById(id);
    }
    
    /**
     * Get student by ID
     */
    public StudentDTO getStudentById(Long id) {
        Student student = studentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Student with ID " + id + " not found"));
        return convertToDTO(student);
    }
    
    /**
     * Convert Student entity to DTO
     */
    private StudentDTO convertToDTO(Student student) {
        StudentDTO dto = new StudentDTO();
        dto.setId(student.getId());
        dto.setName(student.getName());
        dto.setAge(student.getAge());
        dto.setEmail(student.getEmail());
        dto.setCourse(student.getCourse());
        return dto;
    }
}
