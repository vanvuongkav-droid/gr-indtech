CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  parent_id uuid REFERENCES departments(id) ON DELETE SET NULL,
  code text NOT NULL,
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (organization_id, code)
);

CREATE TABLE employees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  department_id uuid REFERENCES departments(id) ON DELETE SET NULL,
  manager_id uuid REFERENCES employees(id) ON DELETE SET NULL,
  employee_code text NOT NULL,
  full_name text NOT NULL,
  email text NOT NULL,
  phone text,
  position text,
  system_role text NOT NULL DEFAULT 'employee' CHECK (system_role IN ('administrator','director','department_head','team_lead','employee','customer')),
  join_date date,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','locked','transferred','resigned')),
  workload_percent numeric(5,2) NOT NULL DEFAULT 0 CHECK (workload_percent >= 0),
  monthly_kpi numeric(5,2) NOT NULL DEFAULT 0 CHECK (monthly_kpi BETWEEN 0 AND 100),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (organization_id, employee_code),
  UNIQUE (organization_id, email)
);

CREATE TABLE projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  project_code text NOT NULL,
  name text NOT NULL,
  investor text,
  contract_value numeric(18,2),
  start_date date,
  end_date date,
  manager_id uuid REFERENCES employees(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'planning' CHECK (status IN ('planning','active','paused','completed','cancelled')),
  progress_percent numeric(5,2) NOT NULL DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (organization_id, project_code)
);

CREATE TABLE project_members (
  project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  project_role text NOT NULL,
  join_date date,
  leave_date date,
  allocation_percent numeric(5,2) NOT NULL DEFAULT 0 CHECK (allocation_percent >= 0),
  PRIMARY KEY (project_id, employee_id)
);

CREATE TABLE tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  project_id uuid REFERENCES projects(id) ON DELETE SET NULL,
  parent_task_id uuid REFERENCES tasks(id) ON DELETE SET NULL,
  task_code text NOT NULL,
  title text NOT NULL,
  description text,
  assigner_id uuid REFERENCES employees(id) ON DELETE SET NULL,
  assignee_id uuid REFERENCES employees(id) ON DELETE SET NULL,
  start_date date,
  due_date date,
  priority text NOT NULL DEFAULT 'medium' CHECK (priority IN ('urgent','high','medium','low')),
  status text NOT NULL DEFAULT 'not_started' CHECK (status IN ('not_started','in_progress','pending_approval','completed','paused','cancelled')),
  progress_percent numeric(5,2) NOT NULL DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (organization_id, task_code)
);

CREATE TABLE task_collaborators (
  task_id uuid NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  PRIMARY KEY (task_id, employee_id)
);

CREATE TABLE work_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  progress_before numeric(5,2) NOT NULL CHECK (progress_before BETWEEN 0 AND 100),
  progress_after numeric(5,2) NOT NULL CHECK (progress_after BETWEEN 0 AND 100),
  hours_spent numeric(7,2) NOT NULL DEFAULT 0 CHECK (hours_spent >= 0),
  completed_content text NOT NULL,
  blocker text,
  support_request text,
  remaining_work text,
  evidence_url text,
  review_status text NOT NULL DEFAULT 'pending' CHECK (review_status IN ('pending','approved','revision_required')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE approvals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  project_id uuid REFERENCES projects(id) ON DELETE SET NULL,
  task_id uuid REFERENCES tasks(id) ON DELETE SET NULL,
  requester_id uuid REFERENCES employees(id) ON DELETE SET NULL,
  approval_type text NOT NULL CHECK (approval_type IN ('task','acceptance','document','cost')),
  title text NOT NULL,
  description text,
  result_value text,
  current_level smallint NOT NULL DEFAULT 1 CHECK (current_level BETWEEN 1 AND 4),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','returned','cancelled')),
  decided_by uuid REFERENCES employees(id) ON DELETE SET NULL,
  decided_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE skills (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  category text NOT NULL,
  UNIQUE (organization_id, name)
);

CREATE TABLE employee_skills (
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  skill_id uuid NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
  skill_level smallint NOT NULL CHECK (skill_level BETWEEN 1 AND 5),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (employee_id, skill_id)
);

CREATE TABLE certificates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  certificate_name text NOT NULL,
  issuer text,
  issue_date date,
  expiry_date date,
  file_url text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE project_org_nodes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  parent_id uuid REFERENCES project_org_nodes(id) ON DELETE CASCADE,
  employee_id uuid REFERENCES employees(id) ON DELETE SET NULL,
  role_name text NOT NULL,
  function_group text,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  notification_type text NOT NULL,
  title text NOT NULL,
  body text,
  channel text NOT NULL DEFAULT 'web' CHECK (channel IN ('web','mobile','email','sms','zalo')),
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE audit_logs (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  actor_employee_id uuid REFERENCES employees(id) ON DELETE SET NULL,
  entity_type text NOT NULL,
  entity_id text NOT NULL,
  action text NOT NULL,
  reason text,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_tasks_assignee_status ON tasks (assignee_id, status);
CREATE INDEX idx_tasks_project_due ON tasks (project_id, due_date);
CREATE INDEX idx_work_logs_task_created ON work_logs (task_id, created_at DESC);
CREATE INDEX idx_approvals_status_created ON approvals (status, created_at DESC);
CREATE INDEX idx_certificates_expiry ON certificates (expiry_date);
CREATE INDEX idx_notifications_employee_unread ON notifications (employee_id, read_at);
CREATE INDEX idx_audit_logs_entity ON audit_logs (entity_type, entity_id, created_at DESC);

