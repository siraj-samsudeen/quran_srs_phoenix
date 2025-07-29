# Quran SRS Phoenix Implementation Plan - Details

**Project Overview:** Phoenix LiveView implementation of a Quran Spaced Repetition System for memorization tracking, migrating from production FastHTML (Python) to modern Phoenix LiveView (Elixir) with 3-layer architecture.

## Phase 0: Project Setup

### New mix project with Phoenix 1.8.0-rc4 and DaisyUI

#### Create Phoenix project: `mix phx.new quran_srs_phoenix`
Generates a new Phoenix 1.8.0-rc4 project with LiveView, Ecto, and DaisyUI styling. Creates the complete project structure with authentication system, database layer, and modern UI components.

**Key Phoenix Project Structure:**
- `lib/quran_srs_phoenix/` - Core business logic (contexts, schemas, data layer)
- `lib/quran_srs_phoenix_web/` - Web interface (controllers, LiveViews, templates, router)
- `priv/repo/migrations/` - Database migrations and schema changes
- `test/` - Test files organized by feature areas
- `assets/` - Frontend assets (CSS, JavaScript, images)
- `config/` - Environment-specific configuration files
- `deps/` - External dependencies (Phoenix, Ecto, LiveView, etc.)
- `mix.exs` - Project definition, dependencies, and build configuration

#### Create empty database structure: `mix ecto.create`
Creates PostgreSQL databases `quran_srs_phoenix_dev` and `quran_srs_phoenix_test`. At this point, databases are empty with no tables - only the database structure exists.

#### Run basic setup tests (no migrations yet): `mix test`
Runs Phoenix's default test suite (5 tests) without requiring database tables. Tests basic project configuration, routing, and compilation - confirms project setup is correct.

**Test Files & Coverage:**
- `test/quran_srs_phoenix_web/controllers/page_controller_test.exs` (1 test)
  - Tests default Phoenix homepage at `/` route
  - Verifies HTTP 200 response and expected content: "Peace of mind from prototype to production"
  
- `test/quran_srs_phoenix_web/controllers/error_json_test.exs` (2 tests)  
  - Tests JSON error responses for 404 ("Not Found") and 500 ("Internal Server Error")
  - Ensures proper API error handling format
  
- `test/quran_srs_phoenix_web/controllers/error_html_test.exs` (2 tests)
  - Tests HTML error pages for 404 and 500 errors  
  - Ensures proper web browser error handling

**Key Points:**
- No database required - tests HTTP layer only (routes, controllers, error handling)
- Tests both JSON (API) and HTML (web) response formats
- Validates Phoenix installation and configuration is working correctly

#### Open database in external client - verify no tables exist
Use TablePlus/pgAdmin to connect and confirm database is empty. This establishes the clean starting point before adding any schemas.

**Database Connection:**
- Host: localhost:5432
- Username/Password: postgres/postgres
- Verify with: `psql -U postgres -d quran_srs_phoenix_dev -h localhost` then `\dt` (should show "Did not find any relations")

## Phase 1: Authentication System Setup

### Generate authentication system

#### Generate authentication system: `mix phx.gen.auth Accounts User users`
Generates Phoenix's complete authentication system including user registration, login, password reset, and session management. Creates database schemas, LiveViews, controllers, and test infrastructure.

**Generated Components:**
- **Database Schemas**: `users` table with email/password, `users_tokens` table for sessions/resets
- **Context**: `lib/quran_srs_phoenix/accounts/` with user management logic
- **LiveViews**: Registration, login, settings, confirmation pages in `lib/quran_srs_phoenix_web/live/user_live/`
- **Controllers**: Session management in `lib/quran_srs_phoenix_web/controllers/`
- **Authentication Plug**: `user_auth.ex` with authentication helpers and route protection
- **Test Infrastructure**: Complete test coverage with fixtures and helpers

**Security Features:**
- Password hashing with bcrypt
- Email confirmation required for new accounts
- Secure password reset flow with time-limited tokens
- Session-based authentication with "remember me" functionality
- CSRF protection and sudo mode for sensitive operations
- Multi-tenancy support via user scoping

#### Install dependencies: `mix deps.get`
Installs new authentication-related dependencies added by the generator, including bcrypt for password hashing and additional Phoenix components.

#### Run migrations to create auth tables: `mix ecto.migrate`
Executes database migrations to create the authentication tables. Creates `users` and `users_tokens` tables with proper indexes and constraints.

**Database Tables Created:**
- `users` - Stores user accounts (id, email, hashed_password, confirmed_at, timestamps)
- `users_tokens` - Handles multiple token types (session, email confirmation, password reset, remember me)
- Proper indexes on email, tokens, and timestamps for performance

#### Test authentication system functionality: `mix test`
Runs expanded test suite including all authentication functionality. Tests now include user registration, login flows, password resets, and session management.

**Test Coverage Expanded:**
- Original 5 basic Phoenix tests still pass
- Additional authentication tests for registration, login, logout
- Email confirmation and password reset workflows
- Session management and "remember me" functionality
- LiveView authentication flows and form validations
- Multi-tenancy and user scoping features

**Test Infrastructure Added:**
- `test/support/conn_case.ex` updated with authentication helpers
- `register_and_log_in_user/1` helper for authenticated test scenarios
- `log_in_user/3` helper for manual user login in tests
- User fixtures in `test/support/fixtures/accounts_fixtures.ex`
- Comprehensive test coverage for all authentication flows

