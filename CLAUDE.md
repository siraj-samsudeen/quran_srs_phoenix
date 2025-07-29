## Project Overview

**Quran SRS Phoenix** is a Phoenix LiveView implementation of a Quran Spaced Repetition System for memorization tracking. This project migrates from a production FastHTML (Python) application to modern Phoenix LiveView (Elixir) with a revolutionary 3-layer architecture.

**Key Features:**
- Spaced repetition algorithms for efficient Quran memorization
- 3-layer architecture: Algorithm → Pattern → Assignment
- User management with authentication (students, teachers, admins)  
- Real-time LiveView interface
- DaisyUI styling for modern UI
- Multi-tenancy support for teacher-student relationships

**Architecture Philosophy:**
1. **Algorithm Layer** - Core memorization algorithms (Full Cycle, SRS, New Memorization, etc.)
2. **Pattern Layer** - User-configurable revision patterns built on algorithms
3. **Assignment Layer** - Runtime execution for specific users and dates

## Development Practices

- No references to claude code in commit message - synchronise the commit message with the matching task in plan.md so that plan.md serves as changelog as well as plan
- Plan structure: plan.md contains only tasks/subtasks for easy scanning, plan-details.md contains explanations for developer onboarding
- Follow exact task hierarchy: H2 (Phase) → H3 (Main Task) → H4 (Subtasks) with descriptive text before commands

## Database Management

- Use `mix ecto.drop` and `mix ecto.create` to reset database to clean state when needed
- Fresh Phoenix project: `mix test` runs without migrations (5 basic tests)
- Database connection: localhost:5432, postgres/postgres for dev database
- Verify empty database with `\dt` showing "Did not find any relations"

## Phoenix Project Structure

**Core Directories:**
- `lib/quran_srs_phoenix/` - Core business logic (contexts, schemas, data layer)
- `lib/quran_srs_phoenix_web/` - Web interface (controllers, LiveViews, templates, router)
- `priv/repo/migrations/` - Database migrations and schema changes
- `test/` - Test files organized by feature areas
- `assets/` - Frontend assets (CSS, JavaScript, images)
- `config/` - Environment-specific configuration files

## Authentication System

**Generated with `mix phx.gen.auth Accounts User users`:**
- Complete user registration, login, password reset flow
- Email confirmation required for new accounts
- Session-based authentication with "remember me"
- CSRF protection and sudo mode for sensitive actions
- Multi-tenancy support via user scoping

**Database Tables Created:**
- `users` - User accounts (email, hashed_password, confirmed_at)
- `users_tokens` - Session, confirmation, reset, and remember tokens

## Testing Framework

**Default Phoenix Tests (5 tests):**
- `page_controller_test.exs` (1) - Tests homepage route and content
- `error_json_test.exs` (2) - Tests JSON error responses (404, 500)
- `error_html_test.exs` (2) - Tests HTML error pages (404, 500)

**Key Points:**
- No database required for basic tests - HTTP layer only
- Tests both JSON (API) and HTML (web) response formats
- Validates Phoenix installation and configuration

## Phoenix Test Framework Integration

- Phoenix Test `~> 0.7.0` for intuitive LiveView testing
- Real browser simulation for user interactions
- Form submission and validation testing
- Component state and event testing
- End-to-end user workflow testing

## Backup Strategy

- `.plan-backup/` directory for storing detailed plan content
- Full backup created before reorganizing documentation
- Allows recovery of detailed implementation notes

## Development Workflow

1. **Task Planning**: All tasks defined in plan.md with clear hierarchy
2. **Progressive Documentation**: Details added to plan-details.md only as tasks are completed
3. **Developer Onboarding**: New developers can see exactly what's completed vs pending
4. **Clean Commits**: Each commit corresponds to completed plan.md tasks

## Database Schema Design

**3-Layer Architecture Implementation:**

**Quran Structure:**
- Mushaf (604 pages) → Surahs → Pages → Items
- Support for multiple Mushaf types and recitations

**Algorithm Layer:**
- Algorithms (Full Cycle, SRS, New Memorization, Watch List, Recent Review)
- AlgorithmParameters for configurable algorithm behavior

**Pattern Layer:**
- RevisionPatterns built on algorithms with user configuration
- PatternSchedules for timing and daily targets
- Template patterns for reuse across users

**Assignment Layer:**
- Hafiz (memorization profiles) linked to users
- Assignments tracking individual item progress with SRS data
- Revisions recording performance and calculating next intervals

**Advanced Features:**
- DayPlans for daily revision organization
- Plans for long-term memorization goals
- SimilarPassageGroups for handling confusing similar verses

## Performance Considerations

- Comprehensive indexing strategy for foreign keys
- Composite indexes for common query patterns
- Efficient handling of large datasets (604 pages × multiple users)

# important-instruction-reminders

Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.