package com.studentmanagement.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "students")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Student {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @NotBlank(message = "Name is required")
    @Size(min = 2, max = 100, message = "Name must be between 2 and 100 characters")
    @Column(nullable = false, length = 100)
    private String name;
    
    @NotNull(message = "Age is required")
    @Min(value = 1, message = "Age must be at least 1")
    @Max(value = 150, message = "Age must be less than 150")
    @Column(nullable = false)
    private Integer age;
    
    @Email(message = "Email should be valid")
    @Column(unique = true, length = 100)
    private String email;
    
    @Size(max = 100, message = "Course name must be less than 100 characters")
    @Column(length = 100)
    private String course;
}
