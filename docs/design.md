# User Stories & Requirements

## Ahmed's Complete Journey: Registration → Memorization Tracking

### User Journey: New User Registration & First Login
```
Context: [Anonymous visitor, no existing account, Phoenix auth system with email confirmation]

😊 Happy Path:
1. User visits /users/register → Enters email/password → Clicks "Create account"
   ✓ Email format validated (must be valid email format with @ sign, no spaces)
   ✓ Password requirements: minimum 12 characters OR minimum 8 with mixed case, numbers, symbols
   ✓ Form validates on submit, not real-time
   ✓ Submit button always enabled (validation happens server-side)

2. Successful registration → Redirected to /users/log-in → Sees confirmation message
   ✓ User account created but unconfirmed (confirmed_at: nil)
   ✓ Email confirmation token generated with 7-day expiry
   ✓ Confirmation email sent to provided address
   ✓ Flash message: "A link to confirm your account has been sent to your email address"

3. User opens confirmation email → Clicks "Confirm my account" → Redirected to root path
   ✓ Email contains confirmation link: /users/confirm/:token
   ✓ Valid token confirms user account (sets confirmed_at timestamp)
   ✓ User automatically logged in after confirmation
   ✓ Success message shows "User confirmed successfully"

4. User enters credentials on login → Clicks "Log in" → Sees authenticated dashboard
   ✓ Session token created and stored in encrypted cookie
   ✓ Remember me checkbox available (extends session to 60 days)
   ✓ User redirected to intended page or root path
   ✓ Navigation shows "Log out" and account settings links

😞 Error Paths:
├─ Invalid email format → Form error "must have the @ sign and no spaces" → User corrects
│   ✓ Error shown after form submission with invalid email
│   ✓ Form preserves other field values during validation
├─ Weak password → Form error "should be at least 12 character(s)" → User strengthens
│   ✓ Password complexity error shown on submit
│   ✓ Clear requirements displayed to user
├─ Email already exists → Form error "has already been taken" → Redirect to login suggested
│   ✓ Link to login page provided in error message
│   ✓ No sensitive information revealed about existing accounts
├─ Wrong login credentials → "Invalid email or password" → User retries
│   ✓ Generic error message for security (doesn't reveal if email exists)
│   ✓ No account lockout by default (configurable)
└─ Expired confirmation token → "User confirmation link is invalid or it has expired" → Resend available
    ✓ New confirmation link can be requested at /users/confirm/new
    ✓ Previous tokens invalidated when new ones generated

🤔 Edge Cases:
├─ User already authenticated tries to register → Redirect to settings → No error shown
│   ✓ Silent redirect prevents confusion
│   ✓ User sent to appropriate authenticated page
├─ Confirmation link clicked multiple times → "Magic link is invalid or it has expired" → Login redirect
│   ✓ Graceful handling of already-confirmed accounts
│   ✓ Previously confirmed user remains confirmed
├─ Unconfirmed user tries sensitive actions → "You must confirm your account" → Blocked access
│   ✓ Email confirmation required for password changes and sensitive operations
│   ✓ User redirected to confirmation instructions page
└─ User session expires → Automatic logout → Redirect to login with message
    ✓ Session timeout handling with "You must log in to access this page"
    ✓ Intended destination saved for post-login redirect
```

### User Journey: Creating First Hafiz Profile
```
Context: [Authenticated user, no hafiz profiles exist]

😊 Happy Path:
1. User sees welcome dashboard → Clicks "Create Your First Hafiz Profile" → Opens profile form
   ✓ Clear call-to-action prominently displayed
   ✓ Form loads within 2 seconds
   ✓ Form fields have helpful placeholder text

2. Enters profile name → Sets daily capacity → Sees auto-filled effective date → Clicks "Create"
   ✓ Profile name accepts 3-50 characters
   ✓ Daily capacity slider shows 5-50 pages with recommended default (20)
   ✓ Effective date defaults to today, editable if needed

3. Profile created → Redirected to profile dashboard → Sees profile settings card
   ✓ Success message confirms profile creation
   ✓ Profile card displays all entered settings
   ✓ "Start Your First Session" button prominently displayed

😞 Error Paths:
├─ Empty profile name → Validation error → User enters name
│   ✓ "Profile name is required" error message
├─ Invalid daily capacity → Range error → User adjusts slider
│   ✓ "Daily capacity must be between 5-50 pages"
└─ Network error during creation → Error banner → Retry button available
    ✓ Form data preserved for retry

🤔 Edge Cases:
├─ User navigates away during form → Unsaved changes warning → Confirm/cancel options
│   ✓ Browser prevents accidental navigation loss
├─ Very long profile name → Character counter → Truncation at limit
│   ✓ Real-time character count (45/50)
└─ Future effective date → Confirmation dialog → Explains implications
    ✓ "Starting in future means no sessions until that date"
```

### User Journey: First Revision Session
```
Context: [User has hafiz profile, never completed a session]

😊 Happy Path:
1. User clicks "Start Today's Session" → Sees page list → Reviews first page mentally
   ✓ Session loads with 20 pages (user's daily capacity)
   ✓ Pages numbered clearly (1-20) with Mushaf page references
   ✓ Rating buttons visible and accessible: Strong/Good/Weak/Failed

2. Clicks rating for page 1 → Page marked as rated → Moves to page 2
   ✓ Visual feedback shows page 1 completed (checkmark or color change)
   ✓ Progress indicator updates (1/20 completed)
   ✓ Can change rating before session completion

3. Completes all 20 pages → Clicks "Complete Session" → Sees session summary
   ✓ All pages must be rated before completion button enables
   ✓ Summary shows performance breakdown (X strong, Y good, Z weak, W failed)
   ✓ "Tomorrow's Preview" shows next 20 pages to be reviewed

😞 Error Paths:
├─ User tries to complete with unrated pages → Warning message → Highlights missed pages
│   ✓ "Please rate all pages before completing session"
├─ Network error during rating → Rating not saved → Retry notification
│   ✓ "Rating not saved, please try again"
└─ Session interrupted/closed → Progress saved → Resume option on return
    ✓ "Continue your session from page 12/20"

🤔 Edge Cases:
├─ User rates same page multiple times → Last rating kept → Visual confirmation
│   ✓ Rating buttons show current selection clearly
├─ User completes session very quickly → Quality warning → Confirmation dialog
│   ✓ "Session completed in 2 minutes. Are you sure ratings are accurate?"
└─ Mobile user rotates device → Layout adapts → Ratings preserved
    ✓ Responsive design maintains usability across orientations
```

### User Journey: Setting Up Memorization Status & Preferences  
```
Context: [User completed first session, wants to configure existing memorization]

😊 Happy Path:
1. User accesses profile settings → Clicks "Configure Memorized Pages" → Sees page status interface
   ✓ Settings accessible from profile dashboard
   ✓ Page status interface shows all 604 Mushaf pages
   ✓ Clear legend explains status options (Memorized/In Progress/Not Started)

2. Marks pages 1-500 as "Memorized" → Sets pages 501-510 as "In Progress" → Saves configuration
   ✓ Bulk selection tools for efficient marking (select range, select all)
   ✓ Visual progress indicator shows memorization status
   ✓ Auto-save prevents data loss

3. System updates session patterns → Shows customized daily sessions → Confirms changes applied
   ✓ Next sessions focus on memorized pages for revision
   ✓ In-progress pages get priority attention
   ✓ Configuration changes take effect immediately

😞 Error Paths:
├─ User marks conflicting statuses → Validation warning → Suggests corrections
│   ✓ "Page 505 cannot be memorized if page 504 is not started"
├─ Network timeout during save → Save failed notification → Auto-retry mechanism
│   ✓ "Settings not saved. Retrying automatically..."
└─ User marks too many pages as memorized → Reality check dialog → Confirmation required
    ✓ "You've marked 600 pages as memorized. This will create intensive revision sessions."

🤔 Edge Cases:
├─ User has gaps in memorization → Workflow guidance → Suggests logical approach
│   ✓ "Consider marking intermediate pages as 'In Progress' for better flow"
├─ User imports from another system → Bulk import tool → Data validation
│   ✓ Upload CSV/Excel with page numbers and status
└─ User changes mind frequently → Undo functionality → Recent changes history
    ✓ "Undo last 3 changes" with clear history list
```

### US015: Multi-User Coordination & Communication
**As any user in a multi-user context, I want to:**
- Coordinate seamlessly with other users in my network
- Receive appropriate notifications and updates
- Maintain clear communication channels

**Acceptance Criteria:**
- [ ] System coordinates between parents, teachers, and students automatically  
- [ ] Users receive relevant notifications without being overwhelmed
- [ ] Clear communication of role changes, permission updates, milestones
- [ ] Magic links work for users without system accounts
- [ ] Email notifications are contextual and actionable
- [ ] System handles complex family structures (divorced parents, multiple teachers)

## Database Schema

To be filled after user stories are finalized.