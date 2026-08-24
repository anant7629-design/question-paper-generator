# Database Schema Documentation
## Question Paper Generator Platform

---

## Overview

This database schema is designed for a scalable, multi-tenant question paper generation platform serving:
- **Schools** (need varied question sets for assessments)
- **Coaching institutes** (require DPPs and mock tests)
- **DPP providers** (daily practice problems)
- **Individual educators** (supplementary materials)

### Key Design Principles

1. **Multi-tenancy**: Organizations can manage their own question banks and papers
2. **Scalability**: Optimized indexes for fast queries on large datasets
3. **Flexibility**: Support for multiple question types, curricula, and paper formats
4. **Analytics**: Rich data for tracking student performance and question effectiveness
5. **Audit Trail**: Complete tracking of changes for compliance and debugging

---

## Schema Overview

### 1. Users & Organizations (Multi-tenancy Layer)

#### `users` Table
Stores all users in the system across different roles.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | INT | Primary key |
| `email` | VARCHAR(255) UNIQUE | User email (login credential) |
| `username` | VARCHAR(100) UNIQUE | Display name |
| `role` | ENUM | admin, teacher, institute_owner, student, parent |
| `subscription_tier` | ENUM | free, pro, enterprise (for individuals) |
| `subscription_status` | ENUM | active, inactive, paused, expired |
| `subscription_end_date` | TIMESTAMP | When subscription expires |

**Key Relationships:**
- `users` → `organizations` (via `organization_members`)
- `users` → `question_papers` (as creator)
- `users` → `student_submissions` (as student)

#### `organizations` Table
Represents schools, coaching institutes, DPP providers, etc.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | INT | Primary key |
| `owner_id` | INT FK | Owner of organization |
| `type` | ENUM | school, coaching_institute, dpp_provider, individual |
| `subscription_tier` | ENUM | Org-level subscription (free/pro/enterprise) |
| `max_users` | INT | Limit on team members (5 for free tier) |
| `max_questions` | INT | Question bank size limit |
| `max_papers_per_month` | INT | Paper generation limit |

**Use Case:**
```
Organization "XYZ Coaching" (owner_id=5)
├── Member: Teacher A (role: editor)
├── Member: Teacher B (role: viewer)
└── Max 50 papers/month, 1000 questions
```

#### `organization_members` Table
Junction table for users in organizations.

---

### 2. Curriculum Structure (Content Framework)

#### `curricula` Table
Defines curriculum standards (CBSE, ICSE, IIT-JEE, etc.).

```
CBSE (India)
ICSE (India)
IIT-JEE (Competitive Exam)
AP (USA)
```

#### `classes` Table
Represents class levels within a curriculum.

```
CBSE → Class 8, Class 9, Class 10, Class 11, Class 12
IIT-JEE → Bachelor-1, Bachelor-2
```

#### `subjects` Table
Subjects within classes.

```
Class 10 CBSE:
├── Mathematics
├── Physics
├── Chemistry
├── Biology
└── English
```

#### `topics` Table
Hierarchical topics within subjects.

```
Mathematics
├── Algebra
│   ├── Linear Equations
│   ├── Quadratic Equations
│   └── Polynomials
├── Geometry
│   ├── Triangles
│   ├── Circles
│   └── Coordinate Geometry
└── Calculus
    ├── Limits
    └── Derivatives
```

**Key Feature:** Supports parent-child relationship for hierarchical organization.

---

### 3. Questions (Core Content)

#### `questions` Table
Central table storing all questions in the system.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | INT | Primary key |
| `organization_id` | INT FK | NULL = global question bank |
| `subject_id` | INT FK | Which subject |
| `topic_id` | INT FK | Which topic |
| `question_type` | ENUM | mcq, short_answer, long_answer, fill_in_blank, true_false, matching, numerical |
| `difficulty_level` | ENUM | easy, medium, hard |
| `content` | TEXT | Actual question text |
| `solution_text` | TEXT | Answer/explanation |
| `marks` | INT | Marks for this question |
| `negative_marking` | INT | Negative marks for wrong answers |
| `bloom_level` | ENUM | remember, understand, apply, analyze, evaluate, create |
| `verification_status` | ENUM | pending, approved, rejected, revision_needed |
| `created_by` | INT FK | User who created it |
| `verified_by` | INT FK | User who verified it |

**Key Features:**
- Questions can be **organization-specific** (owned by coaching institute) or **global** (NULL organization_id)
- **Verification workflow** ensures quality control
- **Bloom's taxonomy** support for higher-order thinking questions
- **Full-text search** on content column for quick discovery

#### `question_options` Table
Options for MCQ/multiple-choice questions.

```
Question: "What is 2+2?"
├── Option A: "3" (is_correct: false)
├── Option B: "4" (is_correct: true) ← Answer
├── Option C: "5" (is_correct: false)
└── Option D: "6" (is_correct: false)
```

#### `question_images` Table
Stores image URLs for questions (diagrams, figures, etc.).

```
Question: "What is the area of this triangle?"
└── Image: [diagram_url] (image_type: 'question')

Question: "Choose the correct diagram"
├── Image: [option_A_diagram]
├── Image: [option_B_diagram]
└── Image: [option_C_diagram]
```

#### `question_tags` Table
Flexible tagging system for questions.

```
Question #123 tags:
├── "conceptual"
├── "numerical"
├── "real-world-application"
└── "exam-2024"
```

#### `question_statistics` Table
Performance analytics for each question.

| Column | Type | Purpose |
|--------|------|---------|
| `total_attempts` | INT | How many students attempted it |
| `correct_attempts` | INT | How many got it right |
| `average_time_seconds` | INT | Avg time to solve |
| `difficulty_score` | DECIMAL | 0-1 scale (lower = harder) |
| `discrimination_index` | DECIMAL | How well it separates strong/weak students |

**Use Case:** If a question has difficulty_score=0.8 (80% of students got it right), it's too easy and might be removed.

---

### 4. Question Paper Templates & Generation

#### `paper_templates` Table
Reusable templates for generating papers.

```
Template: "Class 10 Mathematics Mock Test"
├── Subject: Mathematics
├── Class: 10
├── Total Marks: 100
├── Total Time: 3 hours
├── Total Questions: 30
└── Sections:
    ├── Section A: 10 MCQs (10 marks)
    ├── Section B: 8 Short Answer (16 marks)
    └── Section C: 3 Long Answer (24 marks)
```

| Column | Type | Purpose |
|--------|------|---------|
| `template_type` | ENUM | standard, mock_test, dpp, assignment, worksheet, revision |
| `paper_format` | ENUM | mixed, mcq_only, short_answer_only, long_answer_only |
| `is_public` | BOOLEAN | Can other organizations use it? |
| `is_default` | BOOLEAN | System-recommended template |

#### `template_sections` Table
Sections within a template with specific constraints.

| Column | Type | Purpose |
|--------|------|---------|
| `section_name` | VARCHAR | "Section A: Multiple Choice" |
| `question_type` | ENUM | Questions to include in this section |
| `section_marks` | INT | Total marks for section |
| `min_questions` | INT | Minimum questions to include |
| `max_questions` | INT | Maximum questions to include |
| `difficulty_distribution` | JSON | `{"easy": 30, "medium": 50, "hard": 20}` |

**Example:**
```json
{
  "section_name": "Section A",
  "question_type": "mcq",
  "section_marks": 10,
  "min_questions": 10,
  "max_questions": 10,
  "difficulty_distribution": {"easy": 40, "medium": 40, "hard": 20}
}
```

#### `question_papers` Table
Actual generated papers (instances of templates).

| Column | Type | Purpose |
|--------|------|---------|
| `template_id` | INT FK | Reference to template (nullable) |
| `title` | VARCHAR | "Class 10 Math Mock Test - August 2024" |
| `paper_type` | ENUM | mock_test, dpp, assignment, worksheet, revision, exam, practice |
| `status` | ENUM | draft, published, archived |
| `visibility` | ENUM | private, shared, public |
| `paper_date` | DATE | When the paper is/was used |
| `version` | INT | For tracking revisions |

#### `paper_questions` Table
Junction table: which questions go into which papers.

```
Paper #42 "Mock Test 1":
├── Question #100 (Sequence: 1, Marks: 1)
├── Question #101 (Sequence: 2, Marks: 2)
├── Question #102 (Sequence: 3, Marks: 2)
└── Question #103 (Sequence: 4, Marks: 1)
```

---

### 5. Answer Keys & Solutions

#### `answer_keys` Table
Master answer key for a paper.

| Column | Type | Purpose |
|--------|------|---------|
| `paper_id` | INT FK | Which paper |
| `version` | INT | Version 1, 2, 3... (if corrections made) |
| `is_published` | BOOLEAN | Released to students? |
| `published_at` | TIMESTAMP | When released |

#### `answer_key_solutions` Table
Individual solutions for each question in the answer key.

| Column | Type | Purpose |
|--------|------|---------|
| `answer_option` | VARCHAR | For MCQ: "A", "B", "C", "D" |
| `numerical_answer` | DECIMAL | For numerical questions |
| `partial_marking_rules` | JSON | `{"step_1": 1, "step_2": 2}` |
| `explanation` | TEXT | Detailed solution |

**Example (Physics Question):**
```json
{
  "answer": "32 m/s",
  "partial_marking_rules": {
    "correct_formula": 1,
    "correct_substitution": 2,
    "correct_calculation": 2
  },
  "explanation": "Using v² = u² + 2as, where u=0, a=10m/s², s=51.2m..."
}
```

---

### 6. Student Submissions & Analytics

#### `student_submissions` Table
Tracks when students attempt papers.

| Column | Type | Purpose |
|--------|------|---------|
| `paper_id` | INT FK | Which paper |
| `student_id` | INT FK | Which student |
| `started_at` | TIMESTAMP | When they started |
| `submitted_at` | TIMESTAMP | When they submitted |
| `time_taken_seconds` | INT | Duration |
| `total_marks_obtained` | INT | Final score |
| `percentage` | DECIMAL | Score % |
| `status` | ENUM | started, submitted, graded, reviewed |

#### `student_responses` Table
Individual responses for each question.

| Column | Type | Purpose |
|--------|------|---------|
| `submission_id` | INT FK | Which submission |
| `paper_question_id` | INT FK | Which question in paper |
| `response_text` | TEXT | Student's answer (for essay) |
| `selected_option` | VARCHAR | For MCQ: "A", "B", "C", "D" |
| `numerical_response` | DECIMAL | For numerical |
| `marks_obtained` | INT | Marks awarded |
| `is_correct` | BOOLEAN | Correct or not |
| `time_taken_seconds` | INT | Time spent on this question |
| `flagged_by_student` | BOOLEAN | Did student mark for review? |
| `grader_feedback` | TEXT | Teacher's feedback |
| `graded_by` | INT FK | Which teacher graded it |
| `graded_at` | TIMESTAMP | When graded |

**Use Case:**
```
Student A attempts "Mock Test 1":
├── Q1 (MCQ): selected "B" → is_correct: true → marks: 1
├── Q2 (Short): "Photosynthesis is..." → marks: 1.5/2 → feedback: "Good but..."
├─��� Q3 (Essay): "Explain democracy" → marks: 0 → feedback: "Incomplete"
└── Overall: 45/100 = 45%
```

#### `student_analytics` Table
Aggregated performance analytics per student.

| Column | Type | Purpose |
|--------|------|---------|
| `student_id` | INT FK | Which student |
| `subject_id` | INT FK | Which subject |
| `topic_id` | INT FK | Which topic (optional) |
| `total_questions_attempted` | INT | Total attempted |
| `total_correct` | INT | Correct answers |
| `accuracy_percentage` | DECIMAL | (correct/attempted)*100 |
| `average_time_per_question` | INT | Avg seconds |
| `strength_areas` | JSON | Topics with high accuracy |
| `weak_areas` | JSON | Topics with low accuracy |
| `recommended_topics` | JSON | Where to focus |

**Example:**
```json
{
  "student_id": 42,
  "subject_id": 5,
  "accuracy_percentage": 72.5,
  "strength_areas": {"algebra": 85, "geometry": 78},
  "weak_areas": {"trigonometry": 45, "calculus": 38},
  "recommended_topics": ["trigonometry", "calculus"]
}
```

---

### 7. Question Sharing & Collaboration

#### `question_collections` Table
Curated collections of questions.

```
Collection: "Important Questions - Chapter 5"
├── Question 1
├── Question 2
├── Question 3
└── Question 4
```

#### `collection_questions` Table
Junction table for questions in collections.

#### `paper_shares` Table
Share papers with other users/organizations.

| Column | Type | Purpose |
|--------|------|---------|
| `shared_by` | INT FK | Who shared it |
| `shared_with` | INT FK | Shared with user (nullable) |
| `organization_id` | INT FK | Or with entire org |
| `permission` | ENUM | view, edit, admin |
| `access_until` | TIMESTAMP | When access expires |

---

### 8. Audit & Compliance

#### `audit_logs` Table
Complete audit trail of all changes.

| Column | Type | Purpose |
|--------|------|---------|
| `user_id` | INT FK | Who made change |
| `action` | VARCHAR | create_paper, edit_question, delete_paper, etc. |
| `entity_type` | VARCHAR | question, paper, organization |
| `entity_id` | INT | ID of changed entity |
| `old_values` | JSON | Previous state |
| `new_values` | JSON | New state |
| `ip_address` | VARCHAR | From where |
| `user_agent` | VARCHAR | Browser/client info |
| `created_at` | TIMESTAMP | When changed |

**Example:**
```json
{
  "user_id": 15,
  "action": "edit_question",
  "entity_type": "question",
  "entity_id": 1234,
  "old_values": {"difficulty_level": "easy", "marks": 1},
  "new_values": {"difficulty_level": "medium", "marks": 2},
  "ip_address": "192.168.1.1",
  "created_at": "2024-08-24T10:30:00Z"
}
```

---

## Key Queries

### 1. Generate a Paper from Template

```sql
-- Get template structure
SELECT ts.* FROM template_sections ts
WHERE ts.template_id = 1
ORDER BY ts.sequence;

-- For each section, select random questions matching criteria
SELECT q.* FROM questions q
WHERE q.subject_id = (SELECT subject_id FROM paper_templates WHERE id=1)
AND q.difficulty_level IN ('easy', 'medium', 'hard')
AND q.question_type = 'mcq'
AND q.verification_status = 'approved'
ORDER BY RAND()
LIMIT 10;

-- Insert into paper_questions
INSERT INTO paper_questions (paper_id, question_id, section_id, sequence, marks)
VALUES (new_paper_id, q_id, section_id, sequence, marks);
```

### 2. Student Performance Report

```sql
SELECT 
  sr.question_id,
  q.content,
  COUNT(*) as total_attempts,
  SUM(CASE WHEN sr.is_correct THEN 1 ELSE 0 END) as correct_count,
  (SUM(CASE WHEN sr.is_correct THEN 1 ELSE 0 END) / COUNT(*)) * 100 as accuracy
FROM student_responses sr
JOIN paper_questions pq ON sr.paper_question_id = pq.id
JOIN questions q ON pq.question_id = q.id
WHERE pq.paper_id = 42
GROUP BY sr.question_id
ORDER BY accuracy ASC;
```

### 3. Identify Weak Topics

```sql
SELECT 
  t.name as topic,
  COUNT(DISTINCT sr.submission_id) as students_attempted,
  SUM(CASE WHEN sr.is_correct THEN 1 ELSE 0 END) as correct_count,
  (SUM(CASE WHEN sr.is_correct THEN 1 ELSE 0 END) / COUNT(*)) * 100 as accuracy
FROM student_responses sr
JOIN paper_questions pq ON sr.paper_question_id = pq.id
JOIN questions q ON pq.question_id = q.id
JOIN topics t ON q.topic_id = t.id
WHERE pq.paper_id IN (SELECT id FROM question_papers WHERE organization_id = 5)
GROUP BY t.id
HAVING accuracy < 50
ORDER BY accuracy ASC;
```

### 4. Question Effectiveness

```sql
SELECT 
  q.id,
  q.content,
  qs.total_attempts,
  qs.correct_attempts,
  (qs.correct_attempts / qs.total_attempts) * 100 as difficulty_score,
  qs.discrimination_index
FROM questions q
JOIN question_statistics qs ON q.id = qs.question_id
WHERE q.subject_id = 5
AND qs.discrimination_index < 0.2  -- Poor discrimination
ORDER BY qs.discrimination_index ASC;
```

---

## Performance Optimization

### Indexes Added
1. **Full-text search:** `questions(content)` - Find questions by keyword
2. **Composite indexes:** 
   - `questions(organization_id, subject_id)`
   - `questions(organization_id, verification_status)`
   - `question_papers(organization_id, status)`
   - `student_submissions(paper_id, created_at)`
   - `student_responses(submission_id, is_correct)`

### Query Optimization Tips
1. Always filter by `organization_id` first (multi-tenancy)
2. Use `paper_id` in student analytics queries
3. Cache question statistics (updated daily)
4. Paginate large result sets (limit 50-100)

---

## Scalability Considerations

### For 1M+ Questions
- Partition `questions` table by `subject_id`
- Archive old `student_responses` (> 1 year)
- Move `question_statistics` to separate analytics database
- Use Redis cache for question access patterns

### For 100K+ Active Users
- Read replicas for analytics queries
- Cache frequently accessed questions
- Queue-based paper generation (background jobs)
- CDN for question images

### For Concurrent Paper Generation
- Use UUID for idempotency
- Queue-based paper generation
- Lock mechanism on template access
- Batch question selection

---

## Migration Path

### Phase 1 (MVP - Week 1-2)
- Core tables: users, organizations, subjects, topics, questions, question_papers, paper_questions

### Phase 2 (Week 3-4)
- Add: answer_keys, student_submissions, student_responses, question_statistics

### Phase 3 (Week 5-6)
- Add: templates, sharing, collaboration features

### Phase 4 (Week 7+)
- Add: audit_logs, advanced analytics, integrations

---

## ER Diagram (Simplified)

```
users (admin, teacher, student)
  ├─ organizations (schools, coaching institutes)
  ├─ organization_members
  ├─ questions (created_by, verified_by)
  ├─ question_papers (created_by)
  └─ student_submissions (student_id)

curricula
  ├─ classes
  ├─ subjects
  │   └─ topics
  │       └─ questions
  │           ├─ question_options
  │           ├─ question_images
  │           ├─ question_tags
  │           └─ question_statistics

question_papers
  ├─ paper_templates
  │   └─ template_sections
  ├─ paper_questions
  │   ├─ answer_key_solutions
  │   └─ student_responses
  ├─ paper_shares
  └─ paper_metadata

student_submissions
  ├─ student_responses
  └─ student_analytics

audit_logs
```

---

## API Endpoints (Future Reference)

```
POST   /api/questions              - Create question
GET    /api/questions/:id          - Get question
PUT    /api/questions/:id          - Edit question
DELETE /api/questions/:id          - Delete question

POST   /api/papers                 - Generate paper
GET    /api/papers/:id             - Get paper
PUT    /api/papers/:id             - Edit paper
GET    /api/papers/:id/pdf         - Export as PDF

POST   /api/papers/:id/submit      - Student submits
GET    /api/papers/:id/results     - View results
GET    /api/papers/:id/analytics   - Analytics

GET    /api/students/:id/analytics - Student performance
```

---

## Conclusion

This schema provides a robust foundation for scaling the question paper generation platform. It balances:
- **Flexibility** (multiple question types, paper formats)
- **Performance** (indexed queries, optimized joins)
- **Compliance** (audit trails, verification workflows)
- **Analytics** (rich student and question performance data)

Next steps: Implement REST API layer and frontend UI!
