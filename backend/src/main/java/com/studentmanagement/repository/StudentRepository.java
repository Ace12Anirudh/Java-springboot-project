package com.studentmanagement.repository;

import com.studentmanagement.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface StudentRepository extends JpaRepository<Student, Long> {
    
    /**
     * Find student by name (case-insensitive)
     */
    Optional<Student> findByNameIgnoreCase(String name);
    
    /**
     * Find student by email
     */
    Optional<Student> findByEmail(String email);
    
    /**
     * Check if student exists by email
     */
    boolean existsByEmail(String email);
}
