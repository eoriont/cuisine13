# Cuisine13 - Meal Planning App Specification

## Project Overview
A social meal planning application that combines recipe discovery (TikTok/Instagram Reels-style) with practical meal planning, grocery tracking, and preparation scheduling for roommates.

## Core Features

### 1. Recipe Feed (Reels-Style)
- Vertical scrolling image feed of recipes (using Google Images initially)
- Swipe up/down to browse recipes
- Image display with recipe overlay information
- Like/save functionality
- Quick view of:
  - Recipe name
  - Preparation time
  - Cooking time
  - Difficulty level
  - Serving size
- **Future**: Video playback support (architecture supports videos when ready)

### 2. Meal Calendar
- Weekly/monthly calendar view
- Assign recipes to specific dates and meals (breakfast/lunch/dinner)
- Visual indication of planned meals
- Drag-and-drop to reschedule meals
- Portion selector per meal (servings count)
- Leftover tracking and suggestions
- Multi-user calendar (roommate collaboration)

### 3. Grocery List Management
- Auto-generated grocery list from planned meals
- Grouped by category (produce, dairy, meat, pantry, etc.)
- Quantity aggregation across multiple recipes
- Check-off functionality
- Smart date grouping (what to buy when)
- Shared list between roommates

### 4. Preparation Timeline
- Automatic detection of prep-ahead tasks
- Timeline view showing:
  - When to thaw ingredients
  - When to marinate
  - When to make components (dough, sauces, etc.)
- Notifications/reminders for prep tasks
- Days-ahead calculation

### 5. Portion & Leftover Management
- Configurable serving sizes per recipe
- Leftover indication on calendar
- Smart suggestions for leftover meals
- Portion scaling (ingredients auto-adjust)

### 6. Allergen Awareness
- Users can add allergies to their profile
- Recipe feed highlights recipes containing user allergens (visual indicator)
- Recipe detail view shows which ingredients contain allergens
- **Does NOT filter out** recipes with allergens (allows users to substitute ingredients)
- Visual warnings: "⚠️ Contains allergen: nuts (from cashews, almond milk)"

## Technical Stack

### Backend
- **Framework**: Phoenix 1.7+
- **Language**: Elixir 1.15+
- **Database**: PostgreSQL 15+
- **Real-time**: Phoenix LiveView for reactive UI
- **Authentication**: Phoenix Authentication (phx.gen.auth)
- **File Storage**: Local storage or S3-compatible (for recipe videos/images)

### Frontend
- **UI Framework**: Phoenix LiveView
- **Styling**: TailwindCSS
- **JavaScript**: Alpine.js (for interactions)
- **Video Player**: Video.js or native HTML5 video
- **Calendar**: Custom LiveView component or FullCalendar integration

### Additional Tools
- **Background Jobs**: Oban (for notifications, cleanup)
- **Image Processing**: Mogrify/ImageMagick
- **Video Processing**: FFmpeg (for thumbnails, transcoding)

## Data Models

### User
```elixir
schema "users" do
  field :email, :string
  field :username, :string
  field :hashed_password, :string
  field :allergies, {:array, :string}, default: [] # list of allergens (e.g., ["nuts", "dairy", "shellfish"])

  has_many :household_memberships, HouseholdMembership
  has_many :households, through: [:household_memberships, :household]
  has_many :recipe_likes, RecipeLike

  timestamps()
end
```

### Household
```elixir
schema "households" do
  field :name, :string

  has_many :household_memberships, HouseholdMembership
  has_many :users, through: [:household_memberships, :user]
  has_many :planned_meals, PlannedMeal
  has_many :grocery_items, GroceryItem

  timestamps()
end
```

### HouseholdMembership
```elixir
schema "household_memberships" do
  belongs_to :user, User
  belongs_to :household, Household
  field :role, :string # "admin", "member"

  timestamps()
end
```

### Recipe
```elixir
schema "recipes" do
  field :title, :string
  field :description, :text
  field :image_url, :string # Google Images URL (primary for MVP)
  field :video_url, :string # nullable, for future video support
  field :thumbnail_url, :string # nullable, for future video thumbnails
  field :prep_time_minutes, :integer
  field :cook_time_minutes, :integer
  field :total_time_minutes, :integer
  field :servings, :integer
  field :difficulty, :string # "easy", "medium", "hard"
  field :source_url, :string
  field :source_attribution, :string

  has_many :ingredients, Ingredient
  has_many :instructions, Instruction
  has_many :prep_tasks, PrepTask
  has_many :recipe_likes, RecipeLike
  has_many :planned_meals, PlannedMeal

  timestamps()
end
```

### Ingredient
```elixir
schema "ingredients" do
  belongs_to :recipe, Recipe
  field :name, :string
  field :quantity, :decimal
  field :unit, :string # "cup", "tbsp", "lb", "oz", etc.
  field :category, :string # "produce", "dairy", "meat", "pantry", etc.
  field :allergens, {:array, :string}, default: [] # e.g., ["nuts", "dairy", "gluten"]
  field :notes, :string # "divided", "optional", etc.
  field :order, :integer

  timestamps()
end
```

### Instruction
```elixir
schema "instructions" do
  belongs_to :recipe, Recipe
  field :step_number, :integer
  field :description, :text
  field :duration_minutes, :integer # optional, for timed steps

  timestamps()
end
```

### PrepTask
```elixir
schema "prep_tasks" do
  belongs_to :recipe, Recipe
  field :task_type, :string # "thaw", "marinate", "make_component", "soak", etc.
  field :description, :text
  field :hours_before, :integer # how many hours before cooking this should be done
  field :duration_minutes, :integer # how long this task takes

  timestamps()
end
```

### RecipeLike
```elixir
schema "recipe_likes" do
  belongs_to :user, User
  belongs_to :recipe, Recipe

  timestamps()
end
```

### PlannedMeal
```elixir
schema "planned_meals" do
  belongs_to :household, Household
  belongs_to :recipe, Recipe
  belongs_to :added_by, User

  field :scheduled_date, :date
  field :meal_type, :string # "breakfast", "lunch", "dinner", "snack"
  field :servings, :integer # can differ from recipe default
  field :notes, :text
  field :is_leftover, :boolean, default: false
  field :leftover_from_id, :id # references another PlannedMeal

  timestamps()
end
```

### GroceryItem
```elixir
schema "grocery_items" do
  belongs_to :household, Household
  belongs_to :ingredient, Ingredient # nullable, for auto-generated items

  field :name, :string
  field :quantity, :decimal
  field :unit, :string
  field :category, :string
  field :needed_by_date, :date
  field :is_purchased, :boolean, default: false
  field :purchased_at, :naive_datetime
  field :purchased_by_id, :id # references User

  timestamps()
end
```

### PrepReminder
```elixir
schema "prep_reminders" do
  belongs_to :planned_meal, PlannedMeal
  belongs_to :prep_task, PrepTask
  belongs_to :household, Household

  field :due_at, :naive_datetime
  field :is_completed, :boolean, default: false
  field :completed_at, :naive_datetime
  field :completed_by_id, :id

  timestamps()
end
```

## Core User Flows

### 1. Recipe Discovery & Saving
1. User opens app to recipe feed
2. Swipes through vertical recipe videos/images
3. Views recipe details (overlay or tap)
4. Likes/saves recipe
5. Recipe appears in "Saved Recipes" collection

### 2. Meal Planning
1. User navigates to calendar view
2. Clicks on a date/meal slot
3. Selects from saved recipes or searches all recipes
4. Adjusts serving size
5. Confirms and adds to calendar
6. System auto-generates grocery items
7. System creates prep reminders if needed

### 3. Grocery Shopping
1. User navigates to grocery list
2. Views items grouped by category
3. Optionally filters by "needed by" date
4. Checks off items as purchased
5. List updates in real-time for roommates

### 4. Preparation Management
1. User views prep timeline
2. Sees upcoming prep tasks (e.g., "Marinate chicken - due today at 2pm")
3. Gets notifications for time-sensitive tasks
4. Marks tasks as complete
5. Timeline updates automatically

## API Endpoints (Phoenix Context Structure)

### Accounts Context
- User registration, authentication, profile management
- Household creation and management
- Household invitations

### Recipes Context
- Recipe CRUD operations
- Recipe feed pagination
- Recipe search and filtering
- Like/unlike recipes
- Ingredient and instruction management
- Prep task management

### Planning Context
- Planned meal CRUD
- Calendar queries (by date range, household)
- Portion adjustment logic
- Leftover tracking

### Groceries Context
- Auto-generate grocery list from planned meals
- Manual grocery item addition
- Mark items as purchased
- Aggregate quantities
- Category grouping

### Preparation Context
- Generate prep reminders from planned meals
- Query upcoming prep tasks
- Mark tasks complete
- Notification scheduling

## LiveView Pages

### `/` - Recipe Feed
- Infinite scroll recipe feed
- Video/image display with controls
- Like button with live updates
- Quick add to calendar modal

### `/calendar` - Meal Calendar
- Weekly/monthly calendar grid
- Planned meals display
- Drag-and-drop meal scheduling
- Quick meal details popover
- Add meal modal

### `/recipes/saved` - Saved Recipes
- Grid/list view of liked recipes
- Search and filter
- Quick add to calendar

### `/groceries` - Grocery List
- Grouped by category
- Checkboxes for purchased items
- Date-based filtering
- Add manual items

### `/prep` - Preparation Timeline
- Chronological list of prep tasks
- Grouped by date
- Completion checkboxes
- Task details

### `/household` - Household Settings
- Manage household members
- Invitations
- Household preferences

## Key Features Details

### Portion Scaling Algorithm
```elixir
# When user selects different serving size:
# - Scale all ingredient quantities proportionally
# - Round to reasonable precision
# - Maintain unit conversions where sensible
scale_factor = target_servings / recipe.servings
scaled_quantity = ingredient.quantity * scale_factor
```

### Grocery Aggregation Logic
```elixir
# When generating grocery list:
# 1. Extract all ingredients from planned meals in date range
# 2. Group by ingredient name (with fuzzy matching)
# 3. Attempt unit conversion and aggregation
# 4. Attach "needed by" date (earliest meal date)
# 5. Group by category for display
```

### Prep Task Scheduling
```elixir
# When meal is added to calendar:
# - For each prep_task in recipe
# - Calculate due_at = scheduled_datetime - hours_before
# - Create prep_reminder record
# - Schedule notification job via Oban
```

### Leftover Detection
```elixir
# User can mark a meal as "leftover from" another meal
# System can suggest: "You planned 4 servings but only 2 people - save as leftover?"
# Leftover meals don't generate duplicate grocery items
```

## UI/UX Considerations

### Recipe Feed
- Large recipe images with overlay information
- Double-tap to like (Instagram-style)
- Swipe gestures for navigation (up/down)
- Smooth transitions between recipes
- Allergen warning badge on recipes containing user allergens
- **Future**: Autoplay videos on scroll when video support is added

### Calendar
- Color-coding by meal type or person
- Visual density controls (compact/comfortable)
- Today indicator
- Quick actions on hover/long-press

### Responsive Design
- Mobile-first design
- Works on tablets and desktop
- Touch-optimized controls
- Keyboard navigation support

## Future Enhancements (V2+)
- Recipe upload/contribution by users
- Social features (sharing meal plans, following users)
- Nutritional information tracking
- Budget tracking per meal/week
- Recipe ratings and reviews
- Meal history and favorites
- Recipe recommendations based on preferences
- Integration with grocery delivery services
- Barcode scanning for pantry inventory
- Voice commands for adding items

## Development Phases

### Phase 1: MVP
- User authentication
- Basic recipe database (admin-created)
- Recipe feed with like functionality
- Calendar with meal planning
- Basic grocery list generation

### Phase 2: Collaboration
- Household management
- Multi-user calendar
- Shared grocery lists
- Real-time updates

### Phase 3: Advanced Planning
- Prep task tracking
- Reminders/notifications
- Portion scaling
- Leftover management

### Phase 4: Polish
- Video optimization
- Advanced search/filtering
- UI/UX refinements
- Performance optimization
- Mobile app considerations

## Technical Considerations

### Performance
- Paginate recipe feed (load 10-20 at a time)
- Lazy load videos (only load visible + 1-2 ahead)
- Cache frequently accessed recipes
- Optimize database queries with proper indexes
- Use LiveView for real-time updates without API overhead

### Storage
- Video storage strategy (S3/CloudFlare/local)
- Video compression and multiple quality levels
- Thumbnail generation for quick loading
- CDN for media delivery

### Testing Strategy
- Unit tests for contexts
- Integration tests for user flows
- LiveView testing for UI interactions
- Property-based testing for portion scaling
- Performance testing for feed scrolling

### Security
- Authentication required for all features
- Household-scoped data access
- Input validation and sanitization
- Rate limiting on API endpoints
- CSRF protection (Phoenix default)

## MVP Decisions (Phase 1)
1. **Recipe Content**: Start with Google Images for recipe photos (no video hosting initially)
2. **Video Support**: Architecture supports future video integration, but defer implementation
3. **Allergen Handling**: Users add allergies to profile; recipes highlight allergens but are NOT filtered out (allows ingredient substitution)
4. **Notifications**: Defer to later phase (Phase 3+)
5. **Recipe Source**: Admin-curated recipes initially

## Open Questions (Future Phases)
1. Should recipes eventually be user-generated or remain curated?
2. Do we need offline support?
3. Video hosting strategy when we add video support (S3, Cloudflare, etc.)?
4. Do we need a pantry inventory system?
5. Push notifications vs email vs in-app only for prep reminders?
