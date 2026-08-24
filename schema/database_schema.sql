-- ============================================================================
-- Question Paper Generator - Database Schema
-- ============================================================================
-- This schema is designed for a scalable question paper generation platform
-- serving schools, coaching institutes, and DPP providers.
-- ============================================================================

-- ============================================================================
-- 1. USERS & ORGANIZATIONS
-- ============================================================================

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role ENUM('admin', 'teacher', 'institute_owner', 'student', 'parent') NOT NULL DEFAULT 'teacher',
    subscription_tier ENUM('free', 'pro', 'enterprise') NOT NULL DEFAULT 'free',
    subscription_status ENUM('active', 'inactive', 'paused', 'expired') DEFAULT 'active',
    subscription_end_date TIMESTAMP,
    profile_pic_url VARCHAR(500),
    phone VARCHAR(20),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE TABLE organizations (
    id SERIAL PRIMARY KEY,
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
    INDEX idx_owner_id (owner_id)
);

CREATE TABLE organization_members (
    id SERIAL PRIMARY KEY,
    organization_id INT NOT NULL,
    user_id INT NOT NULL,
    role ENUM('admin', 'editor', 'viewer') NOT NULL DEFAULT 'viewer',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_org_member (organization_id, user_id),
    INDEX idx_organization_id (organization_id),
    INDEX idx_user_id (user_id)
);

-- ============================================================================
-- 2. CURRICULUM & SUBJECTS
-- ============================================================================

CREATE TABLE curricula (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    country VARCHAR(100),
    -- Examples: ICSE, CBSE, State Board, IIT-JEE, NEET
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_curriculum (name, country),
    INDEX idx_name (name)
);

CREATE TABLE classes (
    id SERIAL PRIMARY KEY,
    curriculum_id INT NOT NULL,
    class_number INT NOT NULL,
    -- Examples: 8, 9, 10, 11, 12, Bachelor-1
    name VARCHAR(100),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (curriculum_id) REFERENCES curricula(id) ON DELETE CASCADE,
    UNIQUE KEY unique_class (curriculum_id, class_number),
    INDEX idx_curriculum_id (curriculum_id)
);

CREATE TABLE subjects (
    id SERIAL PRIMARY KEY,
    curriculum_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    description TEXT,
    icon_url VARCHAR(500),
    color_code VARCHAR(7),
    -- For analytics
    question_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (curriculum_id) REFERENCES curricula(id) ON DELETE CASCADE,
    UNIQUE KEY unique_subject (curriculum_id, name),
    INDEX idx_curriculum_id (curriculum_id),
    INDEX idx_name (name)
);

CREATE TABLE topics (
    id SERIAL PRIMARY KEY,
    subject_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    difficulty_level ENUM('easy', 'medium', 'hard') DEFAULT 'medium',
    parent_topic_id INT,
    -- For hierarchical topics
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
);

-- ============================================================================
-- 3. QUESTIONS
-- ============================================================================

CREATE TABLE questions (
    id SERIAL PRIMARY KEY,
    organization_id INT,
    -- NULL means it's from the global question bank
    subject_id INT NOT NULL,
    topic_id INT,
    question_type ENUM('mcq', 'short_answer', 'long_answer', 'fill_in_blank', 'true_false', 'matching', 'numerical') NOT NULL,
    difficulty_level ENUM('easy', 'medium', 'hard') NOT NULL DEFAULT 'medium',
    content TEXT NOT NULL,
    -- The actual question text
    solution_text TEXT,
    -- Explanation/answer
    marks INT DEFAULT 1,
    negative_marking INT DEFAULT 0,
    time_estimate_seconds INT,
    -- Average time to solve
    bloom_level ENUM('remember', 'understand', 'apply', 'analyze', 'evaluate', 'create') DEFAULT 'understand',
    is_verified BOOLEAN DEFAULT FALSE,
    verification_status ENUM('pending', 'approved', 'rejected', 'revision_needed') DEFAULT 'pending',
    verified_by INT,
    verified_at TIMESTAMP,
    created_by INT NOT NULL,
    -- User who created the question
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
    FULLTEXT INDEX ft_content (content)
);

CREATE TABLE question_options (
    id SERIAL PRIMARY KEY,
    question_id INT NOT NULL,
    option_letter VARCHAR(5),
    -- A, B, C, D, etc.
    option_text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    explanation TEXT,
    -- Why this is correct/incorrect
    sequence INT NOT NULL,
    -- Order of options
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    INDEX idx_question_id (question_id),
    UNIQUE KEY unique_sequence (question_id, sequence)
);

CREATE TABLE question_images (
    id SERIAL PRIMARY KEY,
    question_id INT NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    image_type ENUM('question', 'option', 'solution') DEFAULT 'question',
    alt_text VARCHAR(500),
    sequence INT,
    -- For multiple images
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    INDEX idx_question_id (question_id)
);

CREATE TABLE question_tags (
    id SERIAL PRIMARY KEY,
    question_id INT NOT NULL,
    tag VARCHAR(100) NOT NULL,
    -- Custom tags: 'conceptual', 'numerical', 'real-world', etc.
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    INDEX idx_question_id (question_id),
    INDEX idx_tag (tag)
);

CREATE TABLE question_statistics (
    id SERIAL PRIMARY KEY,
    question_id INT NOT NULL,
    total_attempts INT DEFAULT 0,
    correct_attempts INT DEFAULT 0,
    average_time_seconds INT,
    difficulty_score DECIMAL(3, 2),
    -- 0-1 scale: lower = harder
    discrimination_index DECIMAL(3, 2),
    -- How well it separates strong/weak students
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_question_stats (question_id),
    INDEX idx_question_id (question_id)
);

-- ============================================================================
-- 4. QUESTION PAPER TEMPLATES
-- ============================================================================

CREATE TABLE paper_templates (
    id SERIAL PRIMARY KEY,
    organization_id INT,
    -- NULL for global templates
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
);

CREATE TABLE template_sections (
    id SERIAL PRIMARY KEY,
    template_id INT NOT NULL,
    section_name VARCHAR(255) NOT NULL,
    -- "Section A: MCQs", "Section B: Short Answer"
    sequence INT NOT NULL,
    question_type ENUM('mcq', 'short_answer', 'long_answer', 'fill_in_blank', 'true_false', 'matching', 'numerical') NOT NULL,
    section_marks INT NOT NULL,
    min_questions INT NOT NULL,
    max_questions INT NOT NULL,
    difficulty_distribution VARCHAR(255),
    -- JSON: {"easy": 30, "medium": 50, "hard": 20}
    instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (template_id) REFERENCES paper_templates(id) ON DELETE CASCADE,
    UNIQUE KEY unique_section_sequence (template_id, sequence),
    INDEX idx_template_id (template_id)
);

-- ============================================================================
-- 5. QUESTION PAPERS (Generated Papers)
-- ============================================================================

CREATE TABLE question_papers (
    id SERIAL PRIMARY KEY,
    organization_id INT NOT NULL,
    template_id INT,
    -- Reference to template (if created from one)
    title VARCHAR(255) NOT NULL,
    description TEXT,
    subject_id INT NOT NULL,
    class_id INT,
    curriculum_id INT,
    paper_type ENUM('mock_test', 'dpp', 'assignment', 'worksheet', 'revision', 'exam', 'practice') NOT NULL DEFAULT 'practice',
    academic_year VARCHAR(9),
    -- 2024-2025
    total_marks INT NOT NULL,
    total_time_minutes INT NOT NULL,
    total_questions INT NOT NULL,
    status ENUM('draft', 'published', 'archived') DEFAULT 'draft',
    visibility ENUM('private', 'shared', 'public') DEFAULT 'private',
    paper_date DATE,
    -- When the paper is/was used
    version INT DEFAULT 1,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    published_at TIMESTAMP,
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
    INDEX idx_created_at (created_at)
);

CREATE TABLE paper_questions (
    id SERIAL PRIMARY KEY,
    paper_id INT NOT NULL,
    question_id INT NOT NULL,
    section_id INT,
    -- Reference to template_sections if from template
    sequence INT NOT NULL,
    marks INT NOT NULL,
    time_estimate_seconds INT,
    internal_marks INT,
    -- For papers with internal marks
    marks_distribution JSON,
    -- {"part_a": 2, "part_b": 3}
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (paper_id) REFERENCES question_papers(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE RESTRICT,
    INDEX idx_paper_id (paper_id),
    INDEX idx_question_id (question_id),
    UNIQUE KEY unique_paper_question (paper_id, sequence)
);

CREATE TABLE paper_metadata (
    id SERIAL PRIMARY KEY,
    paper_id INT NOT NULL,
    meta_key VARCHAR(100) NOT NULL,
    meta_value TEXT,
    -- Flexible key-value storage
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (paper_id) REFERENCES question_papers(id) ON DELETE CASCADE,
    INDEX idx_paper_id (paper_id),
    UNIQUE KEY unique_paper_meta (paper_id, meta_key)
);

-- ============================================================================
-- 6. ANSWER KEYS & SOLUTIONS
-- ============================================================================

CREATE TABLE answer_keys (
    id SERIAL PRIMARY KEY,
    paper_id INT NOT NULL,
    version INT DEFAULT 1,
    created_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_published BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMP,
    FOREIGN KEY (paper_id) REFERENCES question_papers(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_paper_id (paper_id),
    UNIQUE KEY unique_answer_key (paper_id, version)
);

CREATE TABLE answer_key_solutions (
    id SERIAL PRIMARY KEY,
    answer_key_id INT NOT NULL,
    paper_question_id INT NOT NULL,
    solution_text TEXT,
    answer_option VARCHAR(5),
    -- For MCQ: A, B, C, D
    numerical_answer DECIMAL(10, 2),
    is_correct BOOLEAN,
    partial_marking_rules JSON,
    -- {"step_1": 1, "step_2": 2}
    explanation TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (answer_key_id) REFERENCES answer_keys(id) ON DELETE CASCADE,
    FOREIGN KEY (paper_question_id) REFERENCES paper_questions(id) ON DELETE CASCADE,
    INDEX idx_answer_key_id (answer_key_id),
    UNIQUE KEY unique_solution (answer_key_id, paper_question_id)
);

-- ============================================================================
-- 7. STUDENT SUBMISSIONS & ANALYTICS
-- ============================================================================

CREATE TABLE student_submissions (
    id SERIAL PRIMARY KEY,
    paper_id INT NOT NULL,
    student_id INT NOT NULL,
    submitted_at TIMESTAMP,
    started_at TIMESTAMP,
    time_taken_seconds INT,
    total_marks_obtained INT,
    percentage DECIMAL(5, 2),
    status ENUM('started', 'submitted', 'graded', 'reviewed') DEFAULT 'started',
    submission_type ENUM('online', 'offline_uploaded') DEFAULT 'online',
    submitted_file_url VARCHAR(500),
    -- For offline submissions
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (paper_id) REFERENCES question_papers(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_paper_id (paper_id),
    INDEX idx_student_id (student_id),
    INDEX idx_status (status),
    UNIQUE KEY unique_submission (paper_id, student_id)
);

CREATE TABLE student_responses (
    id SERIAL PRIMARY KEY,
    submission_id INT NOT NULL,
    paper_question_id INT NOT NULL,
    response_text TEXT,
    -- For short/long answers
    selected_option VARCHAR(5),
    -- For MCQ: A, B, C, D
    numerical_response DECIMAL(10, 2),
    marks_obtained INT,
    is_correct BOOLEAN,
    time_taken_seconds INT,
    flagged_by_student BOOLEAN DEFAULT FALSE,
    grader_feedback TEXT,
    graded_by INT,
    graded_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (submission_id) REFERENCES student_submissions(id) ON DELETE CASCADE,
    FOREIGN KEY (paper_question_id) REFERENCES paper_questions(id) ON DELETE CASCADE,
    FOREIGN KEY (graded_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_submission_id (submission_id),
    INDEX idx_paper_question_id (paper_question_id),
    UNIQUE KEY unique_response (submission_id, paper_question_id)
);

CREATE TABLE student_analytics (
    id SERIAL PRIMARY KEY,
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
    -- {"topic_id": accuracy_percentage}
    weak_areas JSON,
    -- {"topic_id": accuracy_percentage}
    recommended_topics JSON,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,
    FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE SET NULL,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    INDEX idx_student_id (student_id),
    INDEX idx_subject_id (subject_id)
);

-- ============================================================================
-- 8. QUESTION SHARING & COLLABORATION
-- ============================================================================

CREATE TABLE question_collections (
    id SERIAL PRIMARY KEY,
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
);

CREATE TABLE collection_questions (
    id SERIAL PRIMARY KEY,
    collection_id INT NOT NULL,
    question_id INT NOT NULL,
    sequence INT,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (collection_id) REFERENCES question_collections(id) ON DELETE CASCADE,
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_collection_question (collection_id, question_id),
    INDEX idx_collection_id (collection_id)
);

CREATE TABLE paper_shares (
    id SERIAL PRIMARY KEY,
    paper_id INT NOT NULL,
    shared_by INT NOT NULL,
    shared_with INT,
    -- NULL if shared with organization
    organization_id INT,
    -- Shared with entire org
    permission ENUM('view', 'edit', 'admin') DEFAULT 'view',
    shared_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    access_until TIMESTAMP,
    -- When access expires
    FOREIGN KEY (paper_id) REFERENCES question_papers(id) ON DELETE CASCADE,
    FOREIGN KEY (shared_by) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (shared_with) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    INDEX idx_paper_id (paper_id),
    INDEX idx_shared_with (shared_with),
    INDEX idx_shared_by (shared_by)
);

-- ============================================================================
-- 9. AUDIT & LOGS
-- ============================================================================

CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INT,
    action VARCHAR(255) NOT NULL,
    -- 'create_paper', 'edit_question', 'delete_paper', etc.
    entity_type VARCHAR(100) NOT NULL,
    -- 'question', 'paper', 'organization', etc.
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
);

-- ============================================================================
-- 10. INDEXES FOR PERFORMANCE
-- ============================================================================

-- Composite indexes for common queries
CREATE INDEX idx_questions_org_subject ON questions(organization_id, subject_id);
CREATE INDEX idx_questions_org_status ON questions(organization_id, verification_status);
CREATE INDEX idx_papers_org_status ON question_papers(organization_id, status);
CREATE INDEX idx_submissions_paper_date ON student_submissions(paper_id, created_at);
CREATE INDEX idx_responses_submission ON student_responses(submission_id, is_correct);
