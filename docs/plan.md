#### Database Changes
- [ ] Add `added_by_user_id` to hafiz_users table (track who added relationships)
- [ ] Add `created_by_relationship` to hafizs table (:self, :parent, :teacher)  
- [ ] Add `is_active` boolean to both tables for soft deletion
- [ ] Migration: enhance existing tables without breaking current functionality

#### Backend Logic
- [ ] Create `list_owned_hafizs(scope)` - hafizs user owns
- [ ] Create `list_shared_hafizs(scope)` - hafizs shared with user
- [ ] Create `group_shared_by_owner(shared_hafizs)` - group by who shared them
- [ ] Enhance `get_user_relationship_to_hafiz(user, hafiz)` - determine user's role
- [ ] Add context functions for permission summaries per relationship

#### UI Components
- [ ] Replace current hafiz index with multi-section dashboard
- [ ] "My Hafiz Profiles" section - owned profiles with management actions
- [ ] "Shared With Me" section - grouped by owner/sharer with role indicators
- [ ] Role badges showing relationship type and permission level
- [ ] Quick action buttons appropriate for each relationship type
- [ ] Responsive grid layout working on mobile and desktop

#### Routes & Navigation
- [ ] Update `/hafizs` route to render new dashboard
- [ ] Add `/hafizs/dashboard` as explicit dashboard route
- [ ] Context-aware navigation showing appropriate menu items
- [ ] Breadcrumb system showing current context (owner vs. shared)

#### Seed Data Creation
- [ ] Create `priv/repo/seeds_demo.exs` for comprehensive demo data
- [ ] Generate realistic user accounts (students, parents, teachers, family)
- [ ] Create varied hafizs with different management patterns
- [ ] Realistic relationship structures for testing
- [ ] "Ahmed Family" - Traditional family with 2 children, both parents active
- [ ] "Fatima's Independent Journey" - Older student managing own hafiz
- [ ] "Teacher Sarah's Classroom" - Teacher with 5 students from different families
