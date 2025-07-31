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

## Documentation Structure

**Project documents are organized in the `/docs` folder with clear separation of concerns:**

### Document Relationship Flow
```
Vision → Design → Plan → Implementation → Changelog
  ↑                                          ↓
  └─────── Feedback Loop ──────────────────┘
```

### Document Types

**📋 `/docs/plan.md`** - Active Task Management
- Current sprint/phase tasks and actionable todos
- Simple bullet lists with status tracking
- Updated frequently (daily/weekly)
- Current blockers and next immediate actions

**🎯 `/docs/quran_srs_vision.md`** - Foundational Philosophy  
- Complete system vision and user personas
- Comprehensive narrative approach analysis
- Reference document for overall philosophy
- Updated rarely (major vision changes only)

**🏗️ `/docs/design.md`** - Technical Implementation Guide
- Database schema, API specs, user stories
- Component architecture and implementation patterns  
- Technical decisions and rationale
- Updated as design evolves during implementation

**📝 `/docs/changelog.md`** - Historical Record
- Completed work aligned with git commit messages
- Chronological entries with dates and outcomes
- Links to relevant commits where applicable
- Updated after each significant milestone

### Usage Patterns

**For Project Owner:**
- Check `plan.md` daily for current tasks
- Reference `design.md` when making technical decisions  
- Update `changelog.md` after commits
- Review `vision.md` when onboarding others

**For AI Assistant:**
- Start with `vision.md` for context and philosophy
- Check `design.md` for technical constraints and patterns
- Read `plan.md` for current priorities and status
- Use `changelog.md` to understand completed work

**For New Team Members:**
- Begin with `vision.md` for system understanding
- Study `design.md` for technical implementation
- Check `plan.md` for current work
- Review `changelog.md` for project history

## Development Practices

### Critical Workflow Requirements

**Commit Process (ESSENTIAL):**
1. **ALWAYS stage files first** - Never commit without user review
2. **Ask for approval** - Present staged files and wait for explicit "commit" command  
3. **Fill plan.md and plan-details.md** with implementation details BEFORE asking for approval
4. **Commit message = exact task description** from plan.md (no Claude references)
5. **Atomic commits** - One task at a time, test each change, commit, then next step

**Plan Structure (MANDATORY):**
- **plan.md**: Only scannable tasks/subtasks with H2 (Phase) → H3 (Main Task) → H4 (Subtasks)
- **plan-details.md**: Comprehensive H3 → H4 explanations for developer onboarding  
- **Synchronization**: Each plan.md task has matching detailed section in plan-details.md
- **Progressive**: Only document completed work, not future plans

**Task Execution Pattern:**
1. Small step → Do → Test (context + LiveView) → Update plan & details → Commit
2. Use TodoWrite tool frequently for task tracking and progress visibility
3. Mark todos complete immediately after finishing (don't batch)
4. Only one task in_progress at a time

### UI Development Standards

**Phoenix LiveView + DaisyUI Patterns:**
- **Card-based layouts** with proper spacing and visual hierarchy
- **Horizontal toggle layouts** (avoid cramped vertical stacking)  
- **Success color theming** for enabled states (green), neutral for disabled
- **Consistent spacing**: Use DaisyUI spacing system (`space-y-4`, `gap-6`, `p-4`)
- **Responsive design**: Mobile-first with desktop enhancements
- **Semantic icons**: Use Heroicons with relationship-specific meanings

**Component Architecture:**
- **Private component functions** within LiveView modules
- **Form field integration** with Phoenix.HTML.FormField  
- **Error handling** with proper validation display
- **Real-time updates** via Phoenix.PubSub subscriptions

### MCP Tool Usage Requirements

**ALWAYS use these MCPs:**
- **Serena MCP** for code organization and analysis
- **Context7 MCP** for understanding codebase context  
- **Playwright MCP** for UI testing and screenshots (when available)

**Usage Pattern:**
- Use Context7 at start of sessions for codebase understanding
- Use Serena for organizing complex tasks and improvements
- Use Task tool with MCPs for multi-step operations

### User Journey Documentation Format

**For documenting user journeys and acceptance criteria, use this structured format:**

```
Context: [User state/permissions]

😊 Happy Path:
1. Action → Reaction → Next Action
   ✓ Acceptance criteria for this step
   ✓ UI/UX requirements
   ✓ Performance/timing requirements

2. Next Action → Next Reaction → Final Action
   ✓ Additional criteria

😞 Error Paths:
├─ Invalid input → Validation error → User corrects
│   ✓ Error message is clear and actionable
└─ Permission denied → Access blocked → Redirect to login
    ✓ Clear explanation of required permissions

🤔 Edge Cases:
├─ Server timeout → Retry prompt → Attempt again
│   ✓ Graceful degradation with retry mechanism
├─ Duplicate action → Already completed → Show status
│   ✓ Idempotent behavior prevents errors
└─ Mobile viewport → Responsive layout → Touch-friendly
    ✓ UI adapts to screen size
```

**Path Types:**
- **😊 Happy Path**: Primary success scenario where everything works as intended
- **😞 Error Paths**: User mistakes, validation failures, and recoverable errors  
- **🤔 Edge Cases**: Unusual but valid scenarios, system limitations, and boundary conditions


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