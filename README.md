# Seeker

A Rails 8 price tracking application that monitors product prices from retailers such as Amazon and Target. Users are notified via email when prices drop to their price targets.

![Screenshot](https://res.cloudinary.com/dkdkftvsq/image/upload/v1768243643/CleanShot_2026-01-12_at_13.46.46_kpfcaz.png)

## Links

- [Deploy](https://seeker-wls9.onrender.com/)

## Features

#### **Price Alerts**
- Track price alerts for products from retailers such as Amazon and Target
- Price updates via Action Cable WebSockets and Turbo Streams when a product is scrapped

#### **Email Notifications**
- Automatic notifications when prices targets are reached after a scrape

#### **Price History**
- Provides historical data on product's price. e.g. lowest price recorded from initial scrape

#### **Product Scraping**
- Uses multiple parser for site specific CSS selectors, structured data, and meta tags
- Headless browser automation with Playwright for JS rendered content

## Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Rails 8.1.1 |
| **Language** | Ruby 3.3.6 |
| **Database** | PostgreSQL |
| **Frontend** | Turbo Streams, Stimulus |
| **Scraping** | Playwright |
| **Background Jobs** | Solid Queue |
| **Caching** | Solid Cache |
| **WebSockets** | Solid Cable / Action Cable |
| **Email** | Gmail SMTP |
| **Deployment** | Render, NeonDB |

## Architecture

**Initial Scrape:**
- User adds product → Triggered scrape job → Product data stored in Postgres

**Scheduled Scrapes:**
- Every 6 hours via Solid Queue recurring jobs
- Scrapes all products with active alerts
- Updates prices and checks notification conditions

![Price Check Architecture](https://res.cloudinary.com/dkdkftvsq/image/upload/c_pad,w_615,h_520,e_improve,e_sharpen/v1767994973/CleanShot_2026-01-09_at_16.11.55_a6y05e.png)

## Prerequisites

- Ruby 3.3.6
- PostgreSQL
- Node.js and npm (for Playwright)

## Local Development Setup

1. **Clone and install**
   ```bash
   git clone https://github.com/nevin-chen/seeker.git
   cd seeker
   bundle install
   ```

2. **Install Playwright browsers**
   ```bash
   rails playwright:install
   ```

3. **Setup database**
   [*Add PostgreSQL env*](#env) *before running*

   ```bash
   docker compose up -d
   ```

   ```bash
   rails db:create db:migrate
   ```

4. **Start development server**
   ```bash
   bin/dev
   ```

5. **Open application**
   ```
   http://localhost:3000
   ```


## Testing

```bash
bin/rails test
```

### Environment Variables (Local Dev) {#env}

```bash
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=POSTGRESQL_USERNAME
DB_PASSWORD=POSTGRESQL_PASSWORD
DB_NAME=POSTGRESQL_DB_NAME
```

## Features Roadmap

- Add cron jobs to periodically scrape active alerts
- Price trend predictions using historical data
- Historical charts
- Bulk alert import from CSV
- Browser extension
- SMS notifications

## Notes

The goal of this project was to take full advantange of Rails 8 suite of "Solid" features:
- **Solid Queue**: Background job processing
- **Solid Cache**: Database caching layer
- **Solid Cable**: Action Cable adapter for WebSockets

## Author

**Author:** [Nevin Chen](https://linkedin.com/in/nevin-chen) | [Portfolio](https://nevinchen.dev)
