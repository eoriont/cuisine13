# Cuisine13

A social meal planning application that combines recipe discovery (Instagram Reels-style) with practical meal planning, grocery tracking, and preparation scheduling for roommates.

## Features

- **Recipe Feed**: Browse recipes in a card grid with like/save functionality
- **Recipe Likes**: Save recipes with a heart button - shared across household members
- **Meal Calendar**: Plan meals for the week with your household
- **Grocery List**: Auto-generated shopping list from planned meals with unit dropdown
- **Prep Timeline**: Track preparation tasks (thaw, marinate, etc.) with reminders
- **Allergen Awareness**: Tag user allergies and highlight recipes containing allergens
- **Household Collaboration**: Share meal plans, saved recipes, and grocery lists with roommates via invite codes
- **Theme Support**: Dark, light, and system theme options
- **Mobile Optimized**: iOS-friendly with safe area support for notch/Dynamic Island

## Tech Stack

- **Backend**: Elixir 1.15+ / Phoenix 1.6+
- **Database**: PostgreSQL 15+
- **Frontend**: Phoenix LiveView with TailwindCSS
- **Authentication**: Phoenix Authentication (phx.gen.auth)

## Prerequisites

- Elixir 1.15 or higher
- Erlang/OTP 26 or higher
- PostgreSQL 15 or higher
- Node.js 18+ (for asset compilation)

## Getting Started

### 1. Clone the repository

```bash
cd cuisine13
```

### 2. Install dependencies

```bash
mix deps.get
cd assets && npm install && cd ..
```

### 3. Configure database

Update `config/dev.exs` with your PostgreSQL credentials:

```elixir
config :cuisine13, Cuisine13.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "cuisine13_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

### 4. Create and migrate database

```bash
mix ecto.setup
```

This will:
- Create the database
- Run all migrations
- Run seeds (if any)

### 5. Start the Phoenix server

```bash
mix phx.server
```

Or run inside IEx:

```bash
iex -S mix phx.server
```

### 6. Visit the application

Open your browser to [`http://localhost:4000`](http://localhost:4000)

To create an account, visit [`http://localhost:4000/users/register`](http://localhost:4000/users/register)

## Database Schema

### Core Tables

- **users**: User accounts with email, password, username, and allergies
- **households**: Household groups for roommates
- **household_memberships**: Join table linking users to households
- **recipes**: Recipe information with images, times, servings, and difficulty
- **ingredients**: Recipe ingredients with quantities, allergens, and categories
- **instructions**: Step-by-step cooking instructions
- **prep_tasks**: Preparation tasks (thaw, marinate, etc.)
- **recipe_likes**: User likes/saves for recipes
- **planned_meals**: Meals scheduled on the calendar
- **grocery_items**: Shopping list items
- **prep_reminders**: Preparation task reminders

## Project Structure

```
lib/
├── cuisine13/                  # Business logic
│   ├── accounts/               # User authentication
│   │   ├── user.ex
│   │   └── user_token.ex
│   ├── households/             # Household management
│   │   ├── household.ex
│   │   └── household_membership.ex
│   ├── recipes/                # Recipe management
│   │   ├── recipe.ex
│   │   ├── ingredient.ex
│   │   ├── instruction.ex
│   │   ├── prep_task.ex
│   │   └── recipe_like.ex
│   ├── planning/               # Meal planning
│   │   └── planned_meal.ex
│   ├── groceries/              # Grocery lists
│   │   └── grocery_item.ex
│   ├── preparation/            # Prep reminders
│   │   └── prep_reminder.ex
│   ├── accounts.ex             # Accounts context
│   ├── households.ex           # Households context
│   ├── recipes.ex              # Recipes context
│   ├── planning.ex             # Planning context
│   ├── groceries.ex            # Groceries context
│   └── preparation.ex          # Preparation context
├── cuisine13_web/              # Web interface
│   ├── controllers/
│   ├── templates/
│   ├── views/
│   ├── live/                   # LiveView modules (to be created)
│   ├── router.ex
│   └── endpoint.ex
└── cuisine13.ex

priv/
└── repo/
    ├── migrations/             # Database migrations
    └── seeds.exs               # Seed data
```

## Key Contexts

### Accounts
- User registration, authentication, and profile management
- User allergies tracking

### Households
- Create and manage households
- Add/remove members
- Role-based permissions (admin/member)

### Recipes
- Recipe CRUD operations
- Recipe feed pagination
- Like/unlike recipes
- Allergen detection
- Ingredient scaling

### Planning
- Meal planning on calendar
- Portion adjustment
- Leftover tracking

### Groceries
- Auto-generate grocery lists from planned meals
- Group items by category
- Mark items as purchased
- Aggregate quantities

### Preparation
- Generate prep reminders from planned meals
- Track prep task completion
- Query upcoming tasks

## Development

### Running tests

```bash
mix test
```

### Reset database

```bash
mix ecto.reset
```

### Create a new migration

```bash
mix ecto.gen.migration migration_name
```

### Interactive console

```bash
iex -S mix
```

### Code formatting

```bash
mix format
```

## Seeding Data

To add sample recipes for development, create seed data in `priv/repo/seeds.exs`:

```elixir
alias Cuisine13.{Repo, Recipes}

# Create a sample recipe
{:ok, recipe} = Recipes.create_recipe(%{
  title: "Spaghetti Carbonara",
  description: "Classic Italian pasta dish",
  image_url: "https://example.com/image.jpg",
  prep_time_minutes: 10,
  cook_time_minutes: 20,
  total_time_minutes: 30,
  servings: 4,
  difficulty: "medium"
})

# Add ingredients
Recipes.create_ingredient(%{
  recipe_id: recipe.id,
  name: "spaghetti",
  quantity: 400,
  unit: "g",
  category: "pantry",
  order: 1
})

# Add instructions
Recipes.create_instruction(%{
  recipe_id: recipe.id,
  step_number: 1,
  description: "Bring a large pot of salted water to boil"
})
```

Then run:

```bash
mix run priv/repo/seeds.exs
```

## Implemented Features

### LiveView Pages
- Recipe feed (`/`) - Card grid with like buttons and add-to-calendar modal
- Recipe detail (`/recipes/:id`) - Full recipe view with ingredients and instructions
- Meal calendar (`/calendar`) - Weekly view with meal planning
- Saved recipes (`/recipes/saved`) - View all liked recipes
- Grocery list (`/groceries`) - Category-grouped shopping list with check-off
- Prep timeline (`/prep`) - Preparation task tracking
- Household management (`/household`) - Invite codes and member management
- Settings (`/users/settings`) - Theme selector, email/password change

### Recipe Feed
- Card grid layout with recipe images
- Like/save button with instant feedback
- Add to calendar modal with date/meal type selection
- Allergen warnings for users with allergies
- Load more pagination

### Calendar
- Weekly view with navigation
- Breakfast/lunch/dinner slots
- Add meals from feed or saved recipes

### Grocery List
- Auto-generated from planned meals
- Category grouping (produce, dairy, etc.)
- Unit dropdown with standard options and custom unit input
- Check-off items as purchased
- Refresh from calendar button

### Theme System
- Dark, light, and system theme options
- Persists in localStorage
- System option follows device preference

### Mobile Optimization
- iOS safe area support (notch/Dynamic Island, home indicator)
- 44px minimum touch targets
- LongPoll transport fallback for iOS Safari

## Future Enhancements

- Drag-and-drop calendar scheduling
- Recipe search and filtering
- Portion scaling calculator
- Push notifications for prep reminders
- Recipe import from URLs

## Production Deployment

Ready to run in production? Check out the [Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).

### Environment Variables

Set these environment variables in production:

- `DATABASE_URL`: PostgreSQL connection string
- `SECRET_KEY_BASE`: Phoenix secret (generate with `mix phx.gen.secret`)
- `PHX_HOST`: Your production hostname

## Learn More

- Official Phoenix website: https://www.phoenixframework.org/
- Phoenix Guides: https://hexdocs.pm/phoenix/overview.html
- Phoenix Docs: https://hexdocs.pm/phoenix
- Phoenix LiveView: https://hexdocs.pm/phoenix_live_view
- Elixir Forum: https://elixirforum.com/c/phoenix-forum

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]

## Support

For issues and feature requests, please create an issue in the project repository.
