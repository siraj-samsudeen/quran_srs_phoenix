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

## Phase 2: Hafiz Database Tables

### Plan hafiz table structure
Many-to-many relationship between users and hafiz profiles to support sharing (parents, teachers, family members).

**Hafiz Table Fields:**
- `name` - String, name for the hafiz profile
- `daily_capacity` - Integer, pages per day capacity
- `effective_date` - Date, current "today" date for this hafiz (allows time travel)

**Hafiz_Users Relationship Table Fields:**
- `user_id` - Foreign key to users table
- `hafiz_id` - Foreign key to hafizs table  
- `relationship` - Ecto.Enum, values: [:owner, :parent, :teacher, :student, :family]

**Business Rules:**
- Exactly one `:owner` per hafiz (the creator)
- Only `:owner` can add/remove other user relationships
- `:owner` relationship cannot be deleted (only hafiz deletion removes owner)
- Users can have multiple relationships to different hafiz profiles
- Same user can have different relationship types to different hafiz profiles

### Generate Hafiz table
Creates Hafiz schema, context functions, migration, and comprehensive test coverage. Uses existing Accounts context since hafiz profiles are user account extensions.

#### Generate Hafiz table under existing Accounts context: `mix phx.gen.context ...`
Command executed: `mix phx.gen.context Accounts Hafiz hafizs name daily_capacity:integer effective_date:date`

**Generated Files:**
- `lib/quran_srs_phoenix/accounts/hafiz.ex` - Schema with changeset validation and user scoping
- `priv/repo/migrations/*_create_hafizs.exs` - Migration with foreign key to users and index
- Enhanced `lib/quran_srs_phoenix/accounts.ex` - CRUD functions with authorization
- Test fixtures and 10 comprehensive tests covering authorization and CRUD operations

### Generate HafizUser M2M relationship table
Creates the many-to-many relationship table between users and hafiz profiles with Ecto.Enum for relationship types.

#### Generate HafizUser relationship context: `mix phx.gen.context Accounts HafizUser hafiz_users user_id:references:users hafiz_id:references:hafizs relationship:enum:owner:parent:teacher:student:family`
Command executed with enum values specified directly in the generator.

**Generated Files:**
- `lib/quran_srs_phoenix/accounts/hafiz_user.ex` - Schema with Ecto.Enum relationship field
- `priv/repo/migrations/20250729064900_create_hafiz_users.exs` - Migration with foreign keys to users and hafizs tables
- Enhanced `lib/quran_srs_phoenix/accounts.ex` - CRUD functions for managing relationships
- Test fixtures and 10 comprehensive tests for relationship management (130 total tests pass)

**Key Features:**
- Ecto.Enum with values [:owner, :parent, :teacher, :student, :family]
- Foreign key constraints to both users and hafizs tables with cascade delete
- User scoping authorization ensuring users only access their own relationships
- Indexes on both user_id and hafiz_id for query performance

**Fixed Issues:**
- Removed duplicate user_id field from schema and migration generated by Phoenix
- Cleaned up duplicate indexes in migration

### Generate Hafiz LiveView interface
Creates Phoenix LiveView interface for managing Hafiz profiles with full CRUD operations and real-time updates.

#### Generate Hafiz management LiveView: `mix phx.gen.live Accounts Hafiz hafizs name:string daily_capacity:integer effective_date:date --no-context --no-schema`
Generates LiveView modules without creating new context or schema files (since we already have them from Phase 2).

**Generated Files:**
- `lib/quran_srs_phoenix_web/live/hafiz_live/index.ex` - List view for all hafiz profiles
- `lib/quran_srs_phoenix_web/live/hafiz_live/show.ex` - Detail view for single hafiz
- `lib/quran_srs_phoenix_web/live/hafiz_live/form.ex` - Form component for create/edit
- `test/quran_srs_phoenix_web/live/hafiz_live_test.exs` - Comprehensive LiveView tests

**LiveView Features:**
- Index page with sortable table showing name, daily capacity, effective date
- Row click navigation to show page
- Inline edit and delete actions with confirmation
- Real-time updates via Phoenix.PubSub subscriptions
- Form validation with live feedback
- User scoping through `current_scope` assign

#### Update router with authenticated Hafiz routes
Added routes within the authenticated `live_session` block to ensure only logged-in users can access hafiz management.

**Routes Added:**
```elixir
# Hafiz management routes
live "/hafizs", HafizLive.Index, :index
live "/hafizs/new", HafizLive.Form, :new
live "/hafizs/:id", HafizLive.Show, :show
live "/hafizs/:id/edit", HafizLive.Form, :edit
```

**Security Features:**
- Routes protected by `:require_authenticated_user` pipeline
- `on_mount` callback ensures authentication before LiveView loads
- All queries automatically scoped to current user via `current_scope`

#### Run migrations if any: `mix ecto.migrate`
No new migrations needed - LiveView uses existing hafizs table from Phase 2.

#### Test LiveView functionality: `mix test`
All 136 tests passing, including new LiveView tests. Test coverage includes:
- Index page rendering and navigation
- Create/Read/Update/Delete operations
- Form validation and error handling
- Real-time updates between connected clients
- User scoping and authorization

**Important Discovery - User Scoping:**
Phoenix 1.8 introduced automatic user scoping when generating contexts within the Accounts module. This explains why `user_id` was automatically added to the hafizs table even though it wasn't specified in our generator command. This is a security-first feature that prevents broken access control (OWASP #1 vulnerability) by automatically scoping all queries to the current user.

**Hybrid Ownership Model:**
The current implementation has both direct ownership (user_id in hafizs) and many-to-many relationships (hafiz_users table). This creates a powerful hybrid model:

1. **Direct Ownership (user_id in hafizs table)**
   - Represents the creator/owner of the hafiz profile
   - Automatically secured through Phoenix scoping
   - Owner has full control (edit, delete, share)
   - Simple queries for "my hafizs"

2. **Shared Access (hafiz_users table)**
   - Additional users with various relationship types
   - Parents, teachers, students can have different access levels
   - Flexible permission model
   - Enables "shared with me" functionality

**Benefits of Hybrid Approach:**
- Secure by default - can't accidentally access others' data
- Clear ownership model with audit trail
- Flexible sharing capabilities
- Efficient queries for both owned and shared hafizs
- Follows Phoenix 1.8 best practices

**Implementation Strategy for Future Enhancement:**
```elixir
# List hafizs I own (already implemented via scoping)
def list_owned_hafizs(scope)

# List hafizs shared with me (to be implemented)
def list_shared_hafizs(scope)  

# List all accessible hafizs (owned + shared)
def list_all_hafizs(scope)
```

**Next Steps:**
The Hafiz LiveView provides basic CRUD functionality with ownership scoping. Future enhancements will include:
- Implement shared hafiz access through hafiz_users relationships
- Add UI for managing user relationships (invite parents/teachers)
- Permission-based actions based on relationship type
- Hafiz switching dropdown showing owned + shared profiles
- Integration with revision and memorization features

### Add default value for effective_date in hafiz table
Enhances user experience by automatically setting effective_date to today when creating a new hafiz profile, removing the need for users to manually select today's date.

#### Update hafiz schema to default effective_date to today
Modified `lib/quran_srs_phoenix/accounts/hafiz.ex` to handle default date setting at the application level.

**Changes:**
- Removed `effective_date` from `validate_required/2` list
- Added `put_default_effective_date/1` private function that:
  - Checks if effective_date is nil using `get_field/2`
  - Sets it to `Date.utc_today()` if not provided
  - Returns changeset unchanged if date already exists

#### Generate migration: `mix ecto.gen.migration add_default_to_hafiz_effective_date`
Created migration file `20250729103237_add_default_to_hafiz_effective_date.exs` to add database-level default.

#### Add database default for effective_date: `mix ecto.migrate`
Migration adds database-level default using PostgreSQL's `CURRENT_DATE` function.

**Migration content:**
```elixir
alter table(:hafizs) do
  modify :effective_date, :date, default: fragment("CURRENT_DATE")
end
```

**Benefits:**
- Database consistency - even direct SQL inserts get today's date
- Works with both application and database level operations
- No breaking changes for existing records

#### Write context and LiveView tests
Added comprehensive test coverage to ensure the feature works correctly.

**Context Test** (`test/quran_srs_phoenix/accounts_test.exs`):
- Test: "create_hafiz/2 without effective_date defaults to today"
- Verifies that `Accounts.create_hafiz/2` without effective_date uses `Date.utc_today()`
- Ensures the default is applied at the schema level

**LiveView Test** (`test/quran_srs_phoenix_web/live/hafiz_live_test.exs`):
- Test: "saves new hafiz without effective_date uses today's date"
- Verifies form submission without date input shows today's date in the UI
- Confirms user experience matches expected behavior

#### Run tests: `mix test`
Both new tests pass successfully:
- Context test verifies schema behavior
- LiveView test verifies UI behavior
- No regression in existing tests

### Create configurable permission system for hafiz relationships
Implements a flexible permission system where users can configure what different relationship types (parent, teacher, student, family) are allowed to do with hafiz profiles. This transforms rigid role-based permissions into user-customizable relationship permissions.

#### Generate Permissions context: `mix phx.gen.context Permissions RelationshipPermission relationship_permissions`
Created separate Permissions context to avoid cluttering the Accounts context and maintain clean separation of concerns.

**Command executed:** 
```bash
mix phx.gen.context Permissions RelationshipPermission relationship_permissions relationship:enum:parent:teacher:student:family can_view_progress:boolean can_edit_details:boolean can_manage_users:boolean can_delete_hafiz:boolean can_edit_preferences:boolean
```

**Generated Files:**
- `lib/quran_srs_phoenix/permissions/relationship_permission.ex` - Schema with Ecto.Enum for relationship types
- `lib/quran_srs_phoenix/permissions.ex` - Context with CRUD operations and helper functions
- `priv/repo/migrations/*_create_relationship_permissions.exs` - Migration with unique constraint
- `test/quran_srs_phoenix/permissions_test.exs` - Comprehensive test coverage
- `test/support/fixtures/permissions_fixtures.ex` - Test fixtures

**Database Schema:**
- `relationship` - Enum: [:parent, :teacher, :student, :family]
- `can_view_progress` - Boolean: View hafiz memorization progress
- `can_edit_details` - Boolean: Edit hafiz name, capacity, effective date
- `can_manage_users` - Boolean: Add/remove users from hafiz profile
- `can_delete_hafiz` - Boolean: Delete entire hafiz profile
- `can_edit_preferences` - Boolean: Modify memorization preferences
- `user_id` - Foreign key with cascade delete
- Unique constraint on [relationship, user_id] prevents duplicates

#### Define default permission configurations for all relationship types
Instead of storing system defaults in database (which caused foreign key issues), defaults are stored as module attributes in the Permissions context.

**Default Permission Matrix:**
```elixir
@default_permissions %{
  parent: %{
    can_view_progress: true,
    can_edit_details: true,
    can_manage_users: false,
    can_delete_hafiz: false,
    can_edit_preferences: true
  },
  teacher: %{
    can_view_progress: true,
    can_edit_details: true,      # Per user requirement
    can_manage_users: false,
    can_delete_hafiz: false,
    can_edit_preferences: true   # Per user requirement
  },
  student: %{
    can_view_progress: true,
    can_edit_details: false,
    can_manage_users: false,
    can_delete_hafiz: false,
    can_edit_preferences: true   # Hafiz can edit own preferences
  },
  family: %{
    can_view_progress: true,
    can_edit_details: false,
    can_manage_users: false,
    can_delete_hafiz: false,
    can_edit_preferences: false  # Read-only access
  }
}
```

**Key Design Decisions:**
- Teachers get edit permissions as requested by user
- Students (hafiz themselves) can edit their own preferences
- Family members get read-only access
- No relationship type gets user management or deletion rights by default (only owners)

#### Add permission helper functions for dynamic permission checking
Created intelligent helper functions that seamlessly blend defaults with user customizations.

**Core Helper Functions:**
- `get_default_permissions/1` - Returns default permissions for any relationship type
- `get_all_default_permissions/0` - Returns complete default configuration map
- `get_relationship_permission/2` - Returns configured permission or default if not set
- `ensure_user_permissions/1` - Auto-creates missing permissions with defaults for new users

**Smart Permission Resolution:**
```elixir
def get_relationship_permission(%Scope{} = scope, relationship) do
  case Repo.get_by(RelationshipPermission, user_id: scope.user.id, relationship: relationship) do
    nil -> 
      # Return struct with default permissions - no database hit needed
      default = get_default_permissions(relationship)
      struct(RelationshipPermission, Map.put(default, :relationship, relationship))
    permission -> permission  # Return user's custom configuration
  end
end
```

**Benefits:**
- **Zero Setup Required**: System works immediately with sensible defaults
- **No Database Overhead**: Defaults don't require database storage or lookups
- **Progressive Enhancement**: Users can customize permissions as needed
- **Consistent API**: Same function works for defaults and custom configurations

#### Write comprehensive tests for permission system
Created 14 tests covering both basic CRUD operations and intelligent permission helpers.

**Test Categories:**
1. **Basic CRUD Tests (10 tests)** - Generated tests ensuring database operations work correctly with user scoping and security
2. **Permission Helper Tests (4 tests)** - Custom tests for the intelligent permission system:
   - `get_default_permissions/1` - Verifies correct defaults for each relationship type
   - `get_relationship_permission/2` returns default - Tests fallback when not configured
   - `get_relationship_permission/2` returns configured - Tests custom override behavior
   - `ensure_user_permissions/1` - Tests auto-creation of missing permissions

**Security Testing:**
- User scoping: Every operation restricted to current user's data
- Cross-user protection: Users cannot access others' permission configurations
- Data validation: Invalid permission configurations properly rejected

#### Run tests: `mix test`
All 152 tests pass, including 14 new permission system tests. No regressions in existing functionality.

**Test Results:**
- Permission system fully functional with defaults and customization
- Security constraints working properly
- Helper functions provide seamless default/custom permission resolution
- Foundation ready for admin UI and hafiz relationship management features

