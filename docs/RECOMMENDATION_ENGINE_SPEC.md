# Recommendation Engine Specification

## Overview

A smart recommendation system that learns user preferences and enables "Steal Mode" - browse dishes from local restaurants and convert them to homemade recipes.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       Docker Compose                             │
├─────────────────┬─────────────────┬─────────────────────────────┤
│    Phoenix      │    Postgres     │    Recommendation Engine    │
│    (Elixir)     │    Database     │    (Python/FastAPI)         │
│                 │                 │                             │
│  - Main App     │  - Users        │  - Claude API (Sonnet)      │
│  - Frontend     │  - Recipes      │  - Claude API (Haiku)       │
│  - LiveView UI  │  - Preferences  │  - Yelp Fusion API          │
│                 │  - History      │  - Google Places API        │
│                 │  - Cache        │  - Image Processing         │
└─────────────────┴─────────────────┴─────────────────────────────┘
```

### Communication
- Phoenix ↔ FastAPI: HTTP REST API (internal Docker network)
- FastAPI ↔ External APIs: HTTPS
- Shared Postgres database for caching and data

---

## Features

### 1. Feed Modes

#### Normal Mode (Default)
- Shows regular recipes from the database
- Personalized based on user history and preferences
- Prioritizes recipes user can make with available ingredients

#### Steal Mode 🥷
- Toggle switch in feed header
- Shows dishes from local restaurants (via Yelp API)
- Each card displays:
  - Dish photo (from Yelp)
  - Dish name
  - Restaurant name
  - Restaurant logo
  - Rating (stars)
  - Distance from user
- Tapping a dish → AI generates homemade recipe → saves to user's recipes
- Sorted by: user preference match + ingredient availability

```
┌─────────────────────────────────────┐
│  [Recipes]  [🥷 Steal Mode]         │  ← Toggle
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │  [Photo of Orange Chicken]    │  │
│  │                               │  │
│  │  Orange Chicken               │  │
│  │  🏪 Panda Express    ⭐ 4.2   │  │
│  │  📍 0.3 mi away               │  │
│  │  ❤️ 94% match                 │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  [Photo of Crunchwrap]        │  │
│  │                               │  │
│  │  Crunchwrap Supreme           │  │
│  │  🏪 Taco Bell       ⭐ 3.8    │  │
│  │  📍 0.5 mi away               │  │
│  │  ❤️ 87% match                 │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

---

### 2. Smart Recommendations

#### Preference Learning
Tracks and learns from:
- Recipes user has liked
- Recipes user has cooked (added to calendar)
- Cuisines (Mexican, Italian, Asian, etc.)
- Cooking methods (grilled, fried, baked, etc.)
- Ingredients frequently used
- Dietary patterns (vegetarian meals, low-carb, etc.)
- Time preferences (quick meals on weekdays, elaborate on weekends)

#### Recommendation Factors
1. **Preference Match** - How well it matches user's taste profile
2. **Ingredient Availability** - Prioritize recipes user can make now
3. **Variety** - Don't show same cuisine repeatedly
4. **Seasonality** - Suggest seasonal ingredients/dishes
5. **Household** - Consider all household members' preferences

---

### 3. Local Trending ("What's Popular Nearby")

- Section in feed showing trending dishes in user's area
- Data from Yelp API popular items
- Updates based on GPS location (browser geolocation API)
- Shows:
  - Popular dishes at nearby restaurants
  - Trending cuisines in the area
  - New restaurant openings

---

### 4. Recipe Facts (Compact Info Cards)

Uber-style clean, compact facts shown on recipe detail page:

```
┌─────────────────────────────────────┐
│  💡 Did you know?                   │
│  Chicken Tikka Masala was invented  │
│  in Britain, not India!             │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  💪 Nutrition                       │
│  42g protein per serving            │
└─────────────────────────────────────┘
```

Types of facts:
- **History** - Origin, cultural significance
- **Nutrition** - Key nutritional highlights
- **Tips** - Cooking tips, substitutions
- **Fun Facts** - Interesting trivia

Implementation:
- Generate with Claude Haiku on first view
- Cache in database (hybrid approach)
- 2-3 facts per recipe, rotate display

---

### 5. Ingredient Spell-Check & Normalization

When user saves/adds ingredients:
1. AI checks for typos ("chiken" → "chicken")
2. Normalizes names ("2% milk" → "milk, 2%")
3. Standardizes units ("1 lb" → "1 pound")
4. Suggests corrections inline before saving

```
┌─────────────────────────────────────┐
│  You entered: "chiken breast"       │
│  Did you mean: "chicken breast"?    │
│  [Yes, fix it]  [No, keep original] │
└─────────────────────────────────────┘
```

---

### 6. Multi-Modal Recipe Input (Steal Mode)

#### Text Input
- Type: "Orange Chicken from Panda Express"
- AI parses restaurant + dish name
- Fetches restaurant info from Yelp
- Generates recipe

#### Photo Input
- Take photo of dish or menu
- Claude Vision identifies the dish
- Cross-reference with Yelp for restaurant
- Generate recipe

#### Voice Input
- Browser Web Speech API
- Convert speech to text
- Process same as text input

---

## API Endpoints (FastAPI)

### Recommendations
```
GET  /api/recommend/feed
     ?user_id=123
     &mode=normal|steal
     &lat=37.7749&lng=-122.4194
     &limit=20

GET  /api/recommend/trending
     ?lat=37.7749&lng=-122.4194
     &radius=5  # miles

POST /api/recommend/feedback
     { user_id, recipe_id, action: "like"|"cook"|"skip" }
```

### Steal Mode
```
POST /api/steal/from-text
     { user_id, query: "Orange Chicken from Panda Express" }

POST /api/steal/from-image
     { user_id, image_base64: "..." }

POST /api/steal/from-restaurant
     { user_id, yelp_business_id, dish_name }
```

### Recipe Enhancement
```
POST /api/recipe/facts
     { recipe_id, title, ingredients }
     → Returns 2-3 cached or generated facts

POST /api/ingredient/normalize
     { text: "chiken breast" }
     → Returns { corrected: "chicken breast", confidence: 0.98 }
```

### Local Data
```
GET  /api/local/restaurants
     ?lat=37.7749&lng=-122.4194
     &cuisine=chinese
     &radius=5

GET  /api/local/dishes
     ?yelp_business_id=abc123
```

---

## Database Schema Additions

### user_preferences
```sql
CREATE TABLE user_preferences (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  preference_type VARCHAR(50),  -- 'cuisine', 'ingredient', 'cooking_method'
  value VARCHAR(255),
  score DECIMAL(3,2),  -- 0.00 to 1.00 affinity score
  updated_at TIMESTAMP
);
```

### recipe_facts_cache
```sql
CREATE TABLE recipe_facts_cache (
  id SERIAL PRIMARY KEY,
  recipe_id INTEGER REFERENCES recipes(id),
  fact_type VARCHAR(50),  -- 'history', 'nutrition', 'tip', 'fun_fact'
  content TEXT,
  created_at TIMESTAMP
);
```

### restaurant_dishes_cache
```sql
CREATE TABLE restaurant_dishes_cache (
  id SERIAL PRIMARY KEY,
  yelp_business_id VARCHAR(100),
  restaurant_name VARCHAR(255),
  restaurant_logo_url TEXT,
  dish_name VARCHAR(255),
  dish_image_url TEXT,
  rating DECIMAL(2,1),
  latitude DECIMAL(10,7),
  longitude DECIMAL(10,7),
  cached_at TIMESTAMP,
  expires_at TIMESTAMP
);
```

### stolen_recipes
```sql
CREATE TABLE stolen_recipes (
  id SERIAL PRIMARY KEY,
  recipe_id INTEGER REFERENCES recipes(id),
  source_restaurant VARCHAR(255),
  source_dish_name VARCHAR(255),
  yelp_business_id VARCHAR(100),
  created_at TIMESTAMP
);
```

---

## External APIs

### Yelp Fusion API
- **Cost**: Free tier (5,000 calls/day)
- **Used for**:
  - Restaurant search by location
  - Business details (logo, rating, photos)
  - Popular dishes (via reviews analysis)
- **Docs**: https://docs.developer.yelp.com/docs/fusion-intro

### Google Places API (Optional)
- **Cost**: $17/1000 requests (basic), $25-35/1000 (details)
- **Used for**:
  - Additional restaurant data
  - Backup if Yelp lacks coverage
- **Docs**: https://developers.google.com/maps/documentation/places

### Claude API (Anthropic)
- **Models**:
  - Haiku: Fast, cheap ($0.25/1M input, $1.25/1M output)
  - Sonnet: Balanced ($3/1M input, $15/1M output)
- **Used for**:
  - Recipe generation from dish names (Sonnet)
  - Photo analysis/dish identification (Sonnet)
  - Fact generation (Haiku)
  - Spell-check/normalization (Haiku)
  - Preference analysis (Haiku)

---

## Cost Estimates (Monthly, ~100 users)

| Service | Usage | Cost |
|---------|-------|------|
| Claude Haiku | Spell-check, facts, preferences | $5-15 |
| Claude Sonnet | Recipe generation, photo analysis | $20-50 |
| Yelp API | Restaurant/dish data | Free |
| Google Places | Backup data (optional) | $0-20 |
| **Total** | | **$25-85/month** |

---

## Implementation Phases

### Phase 1: Foundation
- [ ] Set up FastAPI service in Docker Compose
- [ ] Create database tables
- [ ] Implement ingredient spell-check/normalization
- [ ] Add recipe facts generation + caching

### Phase 2: Recommendations
- [ ] Build preference tracking (likes, cooks, skips)
- [ ] Implement basic recommendation algorithm
- [ ] Add ingredient-based prioritization
- [ ] Create personalized feed endpoint

### Phase 3: Steal Mode
- [ ] Integrate Yelp Fusion API
- [ ] Implement restaurant/dish discovery
- [ ] Add text-based recipe stealing
- [ ] Create Steal Mode UI toggle in feed

### Phase 4: Advanced Input
- [ ] Add photo-based dish recognition (Claude Vision)
- [ ] Implement voice input (Web Speech API)
- [ ] Add local trending section

### Phase 5: Polish
- [ ] Optimize recommendation algorithm
- [ ] Add caching for performance
- [ ] Implement rate limiting
- [ ] Add analytics/monitoring

---

## File Structure (FastAPI Service)

```
recommendation-engine/
├── Dockerfile
├── requirements.txt
├── app/
│   ├── main.py              # FastAPI app entry
│   ├── config.py            # Environment config
│   ├── database.py          # DB connection
│   ├── routers/
│   │   ├── recommend.py     # Recommendation endpoints
│   │   ├── steal.py         # Steal mode endpoints
│   │   ├── facts.py         # Recipe facts endpoints
│   │   └── ingredients.py   # Spell-check endpoints
│   ├── services/
│   │   ├── claude.py        # Claude API client
│   │   ├── yelp.py          # Yelp API client
│   │   ├── recommender.py   # Recommendation logic
│   │   └── recipe_gen.py    # Recipe generation
│   ├── models/
│   │   ├── preferences.py   # Preference models
│   │   └── cache.py         # Cache models
│   └── utils/
│       ├── text.py          # Text processing
│       └── geo.py           # Geolocation utils
└── tests/
    └── ...
```

---

## Environment Variables

```env
# FastAPI
FASTAPI_PORT=8000
DATABASE_URL=postgresql://user:pass@db:5432/cuisine13

# Claude API
ANTHROPIC_API_KEY=sk-ant-...

# Yelp API
YELP_API_KEY=...

# Google Places (optional)
GOOGLE_PLACES_API_KEY=...

# Caching
CACHE_TTL_RESTAURANTS=86400  # 24 hours
CACHE_TTL_FACTS=604800       # 7 days
```

---

## Security Considerations

1. **API Keys**: Store in environment variables, never commit
2. **Rate Limiting**: Implement per-user rate limits
3. **Input Validation**: Sanitize all user inputs
4. **CORS**: Restrict to Phoenix app origin only
5. **Internal Network**: FastAPI only accessible within Docker network

---

## Success Metrics

- **Engagement**: % of users using Steal Mode
- **Conversion**: # of stolen recipes actually cooked
- **Accuracy**: Spell-check correction acceptance rate
- **Performance**: API response times < 500ms (cached), < 3s (AI generation)
- **Cost Efficiency**: Cost per active user per month

---

## Open Questions

1. Should stolen recipes be private to user or shareable?
2. How to handle restaurants not in Yelp database?
3. Should we show nutritional estimates for stolen recipes?
4. Rate limit strategy for free tier users vs premium?

---

*Last Updated: January 2026*
*Status: Planning*
