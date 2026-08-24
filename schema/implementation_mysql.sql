-- ============================================================================
-- Question Paper Generator - MySQL Implementation Setup
-- ============================================================================
-- This file contains the actual SQL code to create and set up the database.
-- Can be run directly in MySQL or any MySQL-compatible database.
-- ============================================================================

-- Create Database
CREATE DATABASE IF NOT EXISTS question_paper_generator;
USE question_paper_generator;

-- Set UTF-8 Encoding
ALTER DATABASE question_paper_generator CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ============================================================================
-- 1. USERS & ORGANIZATIONS
-- ============================================================================

DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role ENUM('admin', 'teacher', 'institute_owner', 'student', 'parent') NOT NULL DEFAULT 'teacher',
    subscription_tier ENUM('free', 'pro', 'enterprise') NOT NULL DEFAULT 'free',
    subscription_status ENUM('active', 'inactive', 'paused', 'expired') DEFAULT 'active',
    subscription_end_date TIMESTAMP NULL,
    profile_pic_url VARCHAR(500),
    phone VARCHAR(20),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_subscription_tier (subscription_tier),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS organizations;
CREATE TABLE organizations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    type ENUM('school', 'coaching_institute', 'dpp_provider', 'individual') NOT NULL,
    description TEXT,
    logo_url VARCHAR(500),
    website VARCHAR(255),
    address VARCHAR(500),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    phone VARCHAR(20),
    email VARCHAR(255),
    subscription_tier ENUM('free', 'pro', 'enterprise') NOT NULL DEFAULT 'free',
    max_users INT DEFAULT 5,
    max_questions INT DEFAULT 1000,
    max_papers_per_month INT DEFAULT 50,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_owner_id (owner_id),
    INDEX idx_type (type),
    INDEX idx_subscription_tier (subscription_tier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS organization_members;
CREATE TABLE organization_members (
    id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    user_id INT NOT NULL,
    role ENUM('admin', 'editor', 'viewer') NOT NULL DEFAULT 'viewer',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_org_member (organization_id, user_id),
    INDEX idx_organization_id (organization_id),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 2. CURRICULUM & SUBJECTS
-- ============================================================================

DROP TABLE IF EXISTS curricula;
CREATE TABLE curricula (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    country VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY unique_curriculum (name, country),
    INDEX idx_name (name),
    INDEX idx_country (country)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS classes;
CREATE TABLE classes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    curriculum_id INT NOT NULL,
    class_number INT NOT NULL,
    name VARCHAR(100),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (curriculum_id) REFERENCES curricula(id) ON DELETE CASCADE,
    UNIQUE KEY unique_class (curriculum_id, class_number),
    INDEX idx_curriculum_id (curriculum_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS subjects;
CREATE TABLE subjects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    curriculum_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    description TEXT,
    icon_url VARCHAR(500),
    color_code VARCHAR(7),
    question_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (curriculum_id) REFERENCES curricula(id) ON DELETE CASCADE,
    UNIQUE KEY unique_subject (curriculum_id, name),
    INDEX idx_curriculum_id (curriculum_id),
    INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS topics;
CREATE TABLE topics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    subject_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    difficulty_level ENUM('easy', 'medium', 'hard') DEFAULT 'medium',
    parent_topic_id INT,
    learning_outcome TEXT,
    estimated_time_minutes INT,
    is_active BOOLEAN DEFAULT TRUE,
    question_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_topic_id) REFERENCES topics(id) ON DELETE SET NULL,
    INDEX idx_subject_id (subject_id),
    INDEX idx_parent_topic_id (parent_topic_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 3. QUESTIONS
-- ============================================================================

DROP TABLE IF EXISTS questions;
CREATE TABLE questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT,
    subject_id INT NOT NULL,
    topic_id INT,
    question_type ENUM('mcq', 'short_answer', 'long_answer', 'fill_in_blank', 'true_false', 'matching', 'numerical') NOT NULL,
    difficulty_level ENUM('easy', 'medium', 'hard') NOT NULL DEFAULT 'medium',
    content LONGTEXT NOT NULL,
    solution_text LONGTEXT,
    marks INT DEFAULT 1,
    negative_marking INT DEFAULT 0,
    time_estimate_seconds INT,
    bloom_level ENUM('remember', 'understand', 'apply', 'analyze', 'evaluate', 'create') DEFAULT 'understand',
    is_verified BOOLEAN DEFAULT FALSE,
    verification_status ENUM('pending', 'approved', 'rejected', 'revision_needed') DEFAULT 'pending',
    verified_by INT,
    verified_at TIMESTAMP NULL,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE RESTRICT,
    FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_organization_id (organization_id),
    INDEX idx_subject_id (subject_id),
    INDEX idx_topic_id (topic_id),
    INDEX idx_difficulty_level (difficulty_level),
    INDEX idx_question_type (question_type),
    INDEX idx_created_by (created_by),
    INDEX idx_verification_status (verification_status),
    INDEX idx_org_subject (organization_id, subject_id),
    FULLTEXT INDEX ft_content (content)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS question_options;
CREATE TABLE question_options (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question_id INT NOT NULL,
    option_letter VARCHAR(5),
    option_text LONGTEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    explanation TEXT,
    sequence INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    INDEX idx_question_id (question_id),
    UNIQUE KEY unique_sequence (question_id, sequence)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS question_images;
CREATE TABLE question_images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question_id INT NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    image_type ENUM('question', 'option', 'solution') DEFAULT 'question',
    alt_text VARCHAR(500),
    sequence INT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    INDEX idx_question_id (question_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS question_tags;
CREATE TABLE question_tags (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question_id INT NOT NULL,
    tag VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    INDEX idx_question_id (question_id),
    INDEX idx_tag (tag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS question_statistics;
CREATE TABLE question_statistics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    question_id INT NOT NULL,
    total_attempts INT DEFAULT 0,
    correct_attempts INT DEFAULT 0,
    average_time_seconds INT,
    difficulty_score DECIMAL(3, 2),
    discrimination_index DECIMAL(3, 2),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_question_stats (question_id),
    INDEX idx_question_id (question_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 4. QUESTION PAPER TEMPLATES
-- ============================================================================

DROP TABLE IF EXISTS paper_templates;
CREATE TABLE paper_templates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    subject_id INT,
    class_id INT,
    curriculum_id INT,
    template_type ENUM('standard', 'mock_test', 'dpp', 'assignment', 'worksheet', 'revision') NOT NULL DEFAULT 'standard',
    paper_format ENUM('mixed', 'mcq_only', 'short_answer_only', 'long_answer_only') DEFAULT 'mixed',
    is_public BOOLEAN DEFAULT FALSE,
    is_default BOOLEAN DEFAULT FALSE,
    total_marks INT NOT NULL DEFAULT 100,
    total_time_minutes INT NOT NULL DEFAULT 60,
    total_questions INT,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL,
    FOREIGN KEY (curriculum_id) REFERENCES curricula(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_organization_id (organization_id),
    INDEX idx_subject_id (subject_id),
    INDEX idx_template_type (template_type),
    INDEX idx_created_by (created_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS template_sections;
CREATE TABLE template_sections (
    id INT AUTO_INCREMENT PRIMARY KEY,
    template_id INT NOT NULL,
    section_name VARCHAR(255) NOT NULL,
    sequence INT NOT NULL,
    question_type ENUM('mcq', 'short_answer', 'long_answer', 'fill_in_blank', 'true_false', 'matching', 'numerical') NOT NULL,
    section_marks INT NOT NULL,
    min_questions INT NOT NULL,
    max_questions INT NOT NULL,
    difficulty_distribution JSON,
    instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (template_id) REFERENCES paper_templates(id) ON DELETE CASCADE,
    UNIQUE KEY unique_section_sequence (template_id, sequence),
    INDEX idx_template_id (template_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 5. QUESTION PAPERS (Generated Papers)
-- ============================================================================

DROP TABLE IF EXISTS question_papers;
CREATE TABLE question_papers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    template_id INT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    subject_id INT NOT NULL,
    class_id INT,
    curriculum_id INT,
    paper_type ENUM('mock_test', 'dpp', 'assignment', 'worksheet', 'revision', 'exam', 'practice') NOT NULL DEFAULT 'practice',
    academic_year VARCHAR(9),
    total_marks INT NOT NULL,
    total_time_minutes INT NOT NULL,
    total_questions INT NOT NULL,
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    visibility ENUM('private', 'shared', 'public') DEFAULT 'private',
    paper_date DATE,
    version INT DEFAULT 1,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    published_at TIMESTAMP NULL,
    
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (template_id) REFERENCES paper_templates(id) ON DELETE SET NULL,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE RESTRICT,
    FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE SET NULL,
    FOREIGN KEY (curriculum_id) REFERENCES curricula(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_organization_id (organization_id),
    INDEX idx_subject_id (subject_id),
    INDEX idx_status (status),
    INDEX idx_created_by (created_by),
    INDEX idx_created_at (created_at),
    INDEX idx_org_status (organization_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS paper_questions;
CREATE TABLE paper_questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    paper_id INT NOT NULL,
    question_id INT NOT NULL,
    section_id INT,
    sequence INT NOT NULL,
    marks INT NOT NULL,
    time_estimate_seconds INT,
    internal_marks INT,
    marks_distribution JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (paper_id) REFERENCES question_papers(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE RESTRICT,
    INDEX idx_paper_id (paper_id),
    INDEX idx_question_id (question_id),
    UNIQUE KEY unique_paper_question (paper_id, sequence)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS paper_metadata;
CREATE TABLE paper_metadata (
    id INT AUTO_INCREMENT PRIMARY KEY,
    paper_id INT NOT NULL,
    meta_key VARCHAR(100) NOT NULL,
    meta_value LONGTEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (paper_id) REFERENCES question_papers(id) ON DELETE CASCADE,
    INDEX idx_paper_id (paper_id),
    UNIQUE KEY unique_paper_meta (paper_id, meta_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 6. ANSWER KEYS & SOLUTIONS
-- ============================================================================

DROP TABLE IF EXISTS answer_keys;
CREATE TABLE answer_keys (
    id INT AUTO_INCREMENT PRIMARY KEY,
    paper_id INT NOT NULL,
    version INT DEFAULT 1,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_published BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMP NULL,
    
    FOREIGN KEY (paper_id) REFERENCES question_papers(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_paper_id (paper_id),
    UNIQUE KEY unique_answer_key (paper_id, version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS answer_key_solutions;
CREATE TABLE answer_key_solutions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    answer_key_id INT NOT NULL,
    paper_question_id INT NOT NULL,
    solution_text LONGTEXT,
    answer_option VARCHAR(5),
    numerical_answer DECIMAL(10, 2),
    is_correct BOOLEAN,
    partial_marking_rules JSON,
    explanation LONGTEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (answer_key_id) REFERENCES answer_keys(id) ON DELETE CASCADE,
    FOREIGN KEY (paper_question_id) REFERENCES paper_questions(id) ON DELETE CASCADE,
    INDEX idx_answer_key_id (answer_key_id),
    UNIQUE KEY unique_solution (answer_key_id, paper_question_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 7. STUDENT SUBMISSIONS & ANALYTICS
-- ============================================================================

DROP TABLE IF EXISTS student_submissions;
CREATE TABLE student_submissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    paper_id INT NOT NULL,
    student_id INT NOT NULL,
    submitted_at TIMESTAMP NULL,
    started_at TIMESTAMP NULL,
    time_taken_seconds INT,
    total_marks_obtained INT,
    percentage DECIMAL(5, 2),
    status ENUM('started', 'submitted', 'graded', 'reviewed') DEFAULT 'started',
    submission_type ENUM('online', 'offline_uploaded') DEFAULT 'online',
    submitted_file_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (paper_id) REFERENCES question_papers(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_paper_id (paper_id),
    INDEX idx_student_id (student_id),
    INDEX idx_status (status),
    INDEX idx_submissions_paper_date (paper_id, created_at),
    UNIQUE KEY unique_submission (paper_id, student_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS student_responses;
CREATE TABLE student_responses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    submission_id INT NOT NULL,
    paper_question_id INT NOT NULL,
    response_text LONGTEXT,
    selected_option VARCHAR(5),
    numerical_response DECIMAL(10, 2),
    marks_obtained INT,
    is_correct BOOLEAN,
    time_taken_seconds INT,
    flagged_by_student BOOLEAN DEFAULT FALSE,
    grader_feedback LONGTEXT,
    graded_by INT,
    graded_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (submission_id) REFERENCES student_submissions(id) ON DELETE CASCADE,
    FOREIGN KEY (paper_question_id) REFERENCES paper_questions(id) ON DELETE CASCADE,
    FOREIGN KEY (graded_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_submission_id (submission_id),
    INDEX idx_paper_question_id (paper_question_id),
    INDEX idx_responses_submission (submission_id, is_correct),
    UNIQUE KEY unique_response (submission_id, paper_question_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS student_analytics;
CREATE TABLE student_analytics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    subject_id INT,
    topic_id INT,
    organization_id INT,
    total_questions_attempted INT DEFAULT 0,
    total_correct INT DEFAULT 0,
    total_incorrect INT DEFAULT 0,
    total_skipped INT DEFAULT 0,
    accuracy_percentage DECIMAL(5, 2),
    average_time_per_question INT,
    strength_areas JSON,
    weak_areas JSON,
    recommended_topics JSON,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,
    FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE SET NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    INDEX idx_student_id (student_id),
    INDEX idx_subject_id (subject_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 8. QUESTION SHARING & COLLABORATION
-- ============================================================================

DROP TABLE IF EXISTS question_collections;
CREATE TABLE question_collections (
    id INT AUTO_INCREMENT PRIMARY KEY,
    organization_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_by INT NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    collection_type ENUM('curated', 'topic_based', 'difficulty_based', 'custom') DEFAULT 'custom',
    question_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_organization_id (organization_id),
    INDEX idx_created_by (created_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS collection_questions;
CREATE TABLE collection_questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    collection_id INT NOT NULL,
    question_id INT NOT NULL,
    sequence INT,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (collection_id) REFERENCES question_collections(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_collection_question (collection_id, question_id),
    INDEX idx_collection_id (collection_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS paper_shares;
CREATE TABLE paper_shares (
    id INT AUTO_INCREMENT PRIMARY KEY,
    paper_id INT NOT NULL,
    shared_by INT NOT NULL,
    shared_with INT,
    organization_id INT,
    permission ENUM('view', 'edit', 'admin') DEFAULT 'view',
    shared_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    access_until TIMESTAMP NULL,
    
    FOREIGN KEY (paper_id) REFERENCES question_papers(id) ON DELETE CASCADE,
    FOREIGN KEY (shared_by) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (shared_with) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    INDEX idx_paper_id (paper_id),
    INDEX idx_shared_with (shared_with),
    INDEX idx_shared_by (shared_by)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 9. AUDIT & LOGS
-- ============================================================================

DROP TABLE IF EXISTS audit_logs;
CREATE TABLE audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(255) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id INT,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_entity_type (entity_type),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 10. SAMPLE DATA FOR TESTING
-- ============================================================================

-- Insert sample users
INSERT INTO users (email, username, password_hash, first_name, last_name, role, subscription_tier) VALUES
('admin@example.com', 'admin_user', SHA2('password123', 256), 'Admin', 'User', 'admin', 'enterprise'),
('teacher1@example.com', 'teacher_ramesh', SHA2('password123', 256), 'Ramesh', 'Kumar', 'teacher', 'pro'),
('teacher2@example.com', 'teacher_priya', SHA2('password123', 256), 'Priya', 'Singh', 'teacher', 'free'),
('student1@example.com', 'student_john', SHA2('password123', 256), 'John', 'Doe', 'student', 'free'),
('student2@example.com', 'student_jane', SHA2('password123', 256), 'Jane', 'Smith', 'student', 'free');

-- Insert sample organization
INSERT INTO organizations (owner_id, name, type, subscription_tier, max_users, max_questions, max_papers_per_month) VALUES
(1, 'Delhi Public School', 'school', 'enterprise', 50, 5000, 100),
(2, 'Apex Coaching Institute', 'coaching_institute', 'pro', 10, 2000, 50);

-- Insert organization members
INSERT INTO organization_members (organization_id, user_id, role) VALUES
(1, 1, 'admin'),
(1, 2, 'editor'),
(2, 2, 'admin'),
(2, 3, 'editor');

-- Insert sample curriculum
INSERT INTO curricula (name, description, country) VALUES
('CBSE', 'Central Board of Secondary Education', 'India'),
('ICSE', 'Indian Certificate of School Education', 'India');

-- Insert sample classes
INSERT INTO classes (curriculum_id, class_number, name) VALUES
(1, 10, 'Class 10'),
(1, 11, 'Class 11'),
(1, 12, 'Class 12'),
(2, 10, 'Class 10');

-- Insert sample subjects
INSERT INTO subjects (curriculum_id, name, code, description) VALUES
(1, 'Mathematics', 'MATH-10', 'Class 10 Mathematics'),
(1, 'Physics', 'PHYS-10', 'Class 10 Physics'),
(1, 'Chemistry', 'CHEM-10', 'Class 10 Chemistry'),
(2, 'Mathematics', 'ICSE-MATH-10', 'ICSE Class 10 Mathematics');

-- Insert sample topics
INSERT INTO topics (subject_id, name, description, difficulty_level, estimated_time_minutes) VALUES
(1, 'Linear Equations', 'Solving linear equations in one and two variables', 'medium', 45),
(1, 'Quadratic Equations', 'Solving quadratic equations using various methods', 'hard', 60),
(1, 'Polynomials', 'Understanding and solving polynomials', 'medium', 50),
(2, 'Motion', 'Laws of motion and kinematics', 'medium', 90),
(2, 'Forces', 'Understanding forces and Newton\'s laws', 'hard', 120);

-- ============================================================================
-- STATUS CHECK
-- ============================================================================

-- Display all tables created
SHOW TABLES;

-- Display table structure
DESCRIBE users;
DESCRIBE organizations;
DESCRIBE questions;
DESCRIBE question_papers;
DESCRIBE student_submissions;

-- Verify indexes
SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME 
FROM INFORMATION_SCHEMA.STATISTICS 
WHERE TABLE_SCHEMA = 'question_paper_generator'
LIMIT 20;

-- Count records
SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'organizations', COUNT(*) FROM organizations
UNION ALL
SELECT 'subjects', COUNT(*) FROM subjects
UNION ALL
SELECT 'topics', COUNT(*) FROM topics;

-- ============================================================================
-- END OF SETUP
-- ============================================================================
