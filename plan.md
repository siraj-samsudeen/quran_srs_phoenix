# Quran SRS Phoenix Implementation Plan

## Phase 0: Project Setup
- [x] New mix project with Phoenix 1.8.0-rc4 and DaisyUI
  - [x] Create Phoenix project: `mix phx.new quran_srs_phoenix`
  - [x] Create empty database structure: `mix ecto.create`
  - [x] Run basic setup tests (no migrations yet): `mix test`
  - [x] Open database in external client - verify no tables exist

## Phase 1: Authentication System Setup
- [x] Generate authentication system
  - [x] Generate authentication system: `mix phx.gen.auth Accounts User users`
  - [x] Install dependencies: `mix deps.get`
  - [x] Run migrations to create auth tables: `mix ecto.migrate`
  - [x] Test authentication system functionality: `mix test`

## Phase 2: Hafiz Database Tables
- [x] Plan hafiz table structure
- [x] Generate Hafiz table
  - [x] Generate Hafiz table under existing Accounts context: `mix phx.gen.context ...`
  - [x] Run tests: `mix test`
- [x] Generate HafizUser M2M relationship table
  - [x] Generate HafizUser relationship context: `mix phx.gen.context ...`
  - [x] Run tests: `mix test`
- [x] Generate Hafiz LiveView interface
  - [x] Generate Hafiz management LiveView: `mix phx.gen.live Accounts Hafiz hafizs name:string daily_capacity:integer effective_date:date --no-context --no-schema`
  - [x] Update router with authenticated Hafiz routes
  - [x] Run migrations if any: `mix ecto.migrate`
  - [x] Test LiveView functionality: `mix test`
- [ ] Add default value for effective_date in hafiz table
  - [ ] Update hafiz schema to default effective_date to today
  - [ ] Generate migration: `mix ecto.gen.migration add_default_to_hafiz_effective_date`
  - [ ] Add database default for effective_date: `mix ecto.migrate`
  - [ ] Write context and LiveView tests
  - [ ] Run tests: `mix test`

## Phase 3: Core Database Schema (3-Layer Architecture)

### Quran Structure Tables
- [ ] Generate Mushaf context: `mix phx.gen.context Quran Mushaf mushafs name:string description:text active:boolean`
- [ ] Generate Surah context: `mix phx.gen.context Quran Surah surahs name:string arabic_name:string number:integer revelation_place:string verses_count:integer mushaf_id:references:mushafs`
- [ ] Generate Page context: `mix phx.gen.context Quran Page pages number:integer mushaf_id:references:mushafs`
- [ ] Generate Item context: `mix phx.gen.context Quran Item items page_id:references:pages surah_id:references:surahs item_type:string part:string start_text:text arabic_text:text active:boolean`

### Algorithm Layer (Layer 1)
- [ ] Generate Algorithm context: `mix phx.gen.context Algorithms Algorithm algorithms name:string description:text category:string parameters:map active:boolean`
- [ ] Generate AlgorithmParameter context: `mix phx.gen.context Algorithms AlgorithmParameter algorithm_parameters algorithm_id:references:algorithms parameter_name:string parameter_type:string default_value:string description:text`

### Pattern Layer (Layer 2)
- [ ] Generate RevisionPattern context: `mix phx.gen.context Patterns RevisionPattern revision_patterns name:string description:text algorithm_id:references:algorithms configuration:map is_template:boolean created_by_user_id:references:users shared:boolean active:boolean`
- [ ] Generate PatternSchedule context: `mix phx.gen.context Patterns PatternSchedule pattern_schedules revision_pattern_id:references:revision_patterns schedule_data:map target_pages_per_day:integer`

### Assignment Layer (Layer 3)
- [ ] Generate Hafiz context: `mix phx.gen.context Memorization Hafiz hafizs name:string user_id:references:users current_date:date progress_stats:map preferences:map active:boolean`
- [ ] Generate Assignment context: `mix phx.gen.context Memorization Assignment hafiz_assignments hafiz_id:references:hafizs item_id:references:items revision_pattern_id:references:revision_patterns status:string mode_id:integer page_number:integer last_review:date next_review:date interval:integer ease_factor:float repetitions:integer streak_good:integer streak_bad:integer assigned_at:utc_datetime`  
- [ ] Generate Revision context: `mix phx.gen.context Memorization Revision revisions hafiz_id:references:hafizs item_id:references:items revision_pattern_id:references:revision_patterns revision_date:date rating:integer response_time:integer next_interval:integer plan_id:integer notes:text`

### Advanced Features
- [ ] Generate DayPlan context: `mix phx.gen.context Planning DayPlan day_plans hafiz_id:references:hafizs plan_date:date target_pages:integer completed_pages:integer revision_pattern_id:references:revision_patterns status:string`
- [ ] Generate Plan context: `mix phx.gen.context Planning Plan plans hafiz_id:references:hafizs name:string description:text start_date:date end_date:date completed:boolean`
- [ ] Generate SimilarPassageGroup context: `mix phx.gen.context Passages SimilarPassageGroup similar_passage_groups name:string description:text difficulty_level:integer`
- [ ] Generate SimilarPassageItem context: `mix phx.gen.context Passages SimilarPassageItem similar_passage_items group_id:references:similar_passage_groups item_id:references:items similarity_score:float`

### Database Performance Optimization
- [ ] Generate migration for indexes: `mix ecto.gen.migration add_foreign_key_constraints`
- [ ] Add constraint content for performance indexes and foreign keys
- [ ] Run migration to optimize database: `mix ecto.migrate`

## Phase 4: LiveView Admin Interface

### Admin Dashboard Setup
- [ ] Create admin directory structure: `mkdir -p lib/quran_srs_phoenix_web/live/admin_live`

### Core Admin LiveViews
- [ ] Generate User management LiveView: `mix phx.gen.live Accounts User users email:string name:string role:string --web-module AdminLive --no-context`
- [ ] Generate Mushaf management LiveView: `mix phx.gen.live Quran Mushaf mushafs name:string description:text active:boolean --web-module AdminLive --no-context`
- [ ] Generate Algorithm management LiveView: `mix phx.gen.live Algorithms Algorithm algorithms name:string description:text category:string --web-module AdminLive --no-context`
- [ ] Generate RevisionPattern management LiveView: `mix phx.gen.live Patterns RevisionPattern revision_patterns name:string description:text --web-module AdminLive --no-context`
- [ ] Generate Hafiz management LiveView: `mix phx.gen.live Memorization Hafiz hafizs name:string current_date:date --web-module AdminLive --no-context`

### User-Facing LiveViews
- [ ] Generate Dashboard LiveView: `mix phx.gen.live Memorization Dashboard dashboard --web-module AppLive --no-context`
- [ ] Generate Revision LiveView: `mix phx.gen.live Memorization Revision revisions revision_date:date rating:integer --web-module AppLive --no-context`
- [ ] Generate DayPlan LiveView: `mix phx.gen.live Planning DayPlan day_plans plan_date:date target_pages:integer --web-module AppLive --no-context`

## Phase 5: Data Migration & Seeding

### Data Migration Scripts
- [ ] Generate data migration task: `mix phx.gen.task DataMigration migrate_from_sqlite`
- [ ] Generate data seeding task: `mix phx.gen.task DataSeeding seed_initial_data`

### Initial Data Setup
- [ ] Add seed data content for default mushaf, algorithms, and patterns
- [ ] Run seeds to populate initial data: `mix run priv/repo/seeds.exs`

## Phase 6: Testing & Deployment

### Testing Framework Setup
- [ ] Add Phoenix Test dependency: `{:phoenix_test, "~> 0.7.0", only: :test}` to mix.exs
- [ ] Install testing dependencies: `mix deps.get`
- [ ] Create LiveView tests using Phoenix Test framework
- [ ] Run complete test suite: `mix test`

### Production Setup
- [ ] Generate release configuration: `mix phx.gen.release`
- [ ] Generate production secret: `mix phx.gen.secret`
- [ ] Configure production database settings
- [ ] Deploy application to production environment