# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Todo Timers+** is a mobile-first personal productivity application for managing and tracking time spent on tasks. The app is built with Ruby on Rails 8 backend and modern frontend technologies.

## Architecture

### Backend (Ruby on Rails 8)
- **Framework**: Ruby on Rails 8 with built-in authentication
- **Database**: SQLite3 (all environments)
- **Core Models**: Timer model tracks `user_id`, `task_name`, `start_time`, `end_time`, `duration`, `tags`

### Frontend
- **Bundler**: `ruby_vite` for asset compilation
- **Framework**: Vanilla JS or light Alpine.js for reactivity
- **Styling**: Tailwind CSS (mobile-first approach)
- **Charts**: Chart.js or ApexCharts for analytics visualization

### Key Views Structure
- Home (Active Timers)
- Task Log / History
- Analytics Dashboard
- Settings/Profile

## Development Commands

**Note**: This is a new Rails project. Standard Rails commands should be used:

```bash
# Setup and development
bundle install              # Install Ruby dependencies
rails db:create db:migrate  # Setup database
rails server               # Start development server

# Testing
rails test                 # Run unit and integration tests (Minitest)
rails test:system         # Run system tests (Capybara with mobile viewport)

# Database operations
rails db:migrate          # Run migrations
rails db:seed            # Seed database
rails db:reset           # Reset database

# Asset compilation
rails assets:precompile   # Compile assets for production
```

## Core Features Implementation

### Timer Management
- Todo timer creation, start/pause/stop functionality
- Timer persistence across sessions
- Task categorization via tags/groups
- Template system for recurring tasks

### Analytics & Insights
- Time tracking per task with duration calculations
- Session frequency and streak analysis
- Calendar view of timer history
- Task-based heatmaps and visualizations

### Mobile-First Design
- Responsive Tailwind CSS components
- Touch-optimized controls for mobile devices
- Offline usage capability via localStorage

### Gamification System
- Badge system for consistency and time milestones
- Task leveling with XP progression
- Progress tracking and achievements

## Key Technical Considerations

- **Mobile-First**: All UI components must be responsive and touch-friendly
- **Data Persistence**: Timer state must persist across browser sessions
- **Real-time Updates**: Timer display should update in real-time
- **Performance**: Analytics queries should be optimized for large datasets
- **Security**: User authentication and data isolation are critical

## Testing Strategy

- **Unit/Integration**: Minitest for backend logic
- **System Tests**: Capybara with mobile viewport simulation
- **Frontend**: Test timer functionality and responsive behavior
- **Analytics**: Verify data accuracy and chart rendering