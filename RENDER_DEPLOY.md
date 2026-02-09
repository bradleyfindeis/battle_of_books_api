# Deploying Battle of Books on Render

Get the API, database, Redis, and frontend running on Render.

---

## 1. Create a PostgreSQL database

- In the Render dashboard: **New → Postgres**.
- Name it (e.g. `battle-of-books-db`), choose region, create.
- After it’s created, open it and copy the **Internal Database URL** (use this so the API and DB stay on Render’s private network).

---

## 2. Create a Redis instance (for Action Cable / quiz match)

- **New → Key Value** (Redis®-compatible).
- Name it (e.g. `battle-of-books-redis`), create.
- Copy the **Internal Connection String** (e.g. `redis://red-xxx:6379`).

---

## 3. Deploy the API as a Web Service

- **New → Web Service**.
- Connect the repo: `bradleyfindeis/battle_of_books_api` (or your fork).
- Configure:

| Field | Value |
|-------|--------|
| **Name** | `battle-of-books-api` (or any name) |
| **Region** | Same as Postgres |
| **Branch** | `main` |
| **Root Directory** | (leave blank) |
| **Runtime** | **Docker** (recommended; you have a Dockerfile) |
| **Instance Type** | Free or paid |

- **Environment variables** (Add in Dashboard → Environment):

| Key | Value | Notes |
|-----|--------|--------|
| `DATABASE_URL` | *(from Postgres service)* | Internal Database URL from step 1 |
| `REDIS_URL` | *(from Redis service)* | Internal Connection String from step 2 |
| `SECRET_KEY_BASE` | *(generate one)* | Run `bin/rails secret` locally and paste |
| `FRONTEND_URL` | `https://<your-frontend>.onrender.com` | Your Static Site URL (create in step 5 first, then come back and set this) |
| `OPENAI_API_KEY` | *(optional)* | Only if you use quiz challenge AI |

- **Advanced → Add Environment Group**: attach the Postgres database and the Redis instance so Render can inject `DATABASE_URL` and `REDIS_URL` (recommended). If you don't, set `DATABASE_URL` and `REDIS_URL` manually—without `DATABASE_URL`, the deploy fails with a PostgreSQL socket error during `db:prepare`.
- **Release Command**: With Docker, the image’s entrypoint runs `bin/rails db:prepare` on boot, so you can leave Release Command blank. If you use **Native** (no Docker), set Release Command to: `bin/rails db:migrate`
- **Start Command**: Leave default when using Docker. If you use **Native** instead of Docker, use:  
  `bundle exec rails server -p $PORT -b 0.0.0.0`
- Create the Web Service. After the first deploy, copy the API URL (e.g. `https://battle-of-books-api.onrender.com`).

---

## 4. (Optional) Tighten CORS and Cable origins

The API allows any origin (`origins '*'`). To restrict in production, in `config/initializers/cors.rb` you can replace `origins '*'` with your frontend URL.  
`FRONTEND_URL` is already used for Action Cable; keep it set so the quiz match WebSocket works.

---

## 5. Deploy the frontend as a Static Site

- **New → Static Site**.
- Connect the repo: `bradleyfindeis/battle_of_books_frontend` (or your fork).
- Configure:

| Field | Value |
|-------|--------|
| **Name** | `battle-of-books` (or any name) |
| **Branch** | `main` |
| **Root Directory** | (leave blank) |
| **Build Command** | `npm ci && npm run build` |
| **Publish Directory** | `dist` |

- **Environment** (so the built app calls your API):

| Key | Value |
|-----|--------|
| `VITE_API_URL` | `https://<your-api>.onrender.com` (the Web Service URL from step 3) |

- Create the Static Site. Copy the site URL (e.g. `https://battle-of-books.onrender.com`).
- Go back to the **API** Web Service and set **`FRONTEND_URL`** to this URL (including `https://`) so Action Cable allows the frontend origin.

---

## 6. Seed the database (one-time)

From your machine (or a one-off shell if Render provides it):

- Ensure the API is deployed and migrations have run.
- **From your local machine:** you must use the **External Database URL** (Render Postgres → Connections → "External Database URL"). The Internal URL only works from inside Render’s network.
- **From Render Shell** (if your plan has it): use the Internal URL; env vars are already set.

```bash
# Option A: Using Render Shell (if available)
# Open the API service → Shell, then:
bin/rails db:seed

# Option B: From local — use External Database URL, not Internal
cd /path/to/battle_of_books_api
RAILS_ENV=production \
DATABASE_URL="<External Database URL from Render>" \
REDIS_URL="redis://..." \
SECRET_KEY_BASE="<your secret>" \
bin/rails db:seed
```

Do not commit credentials or paste them into docs.

---

## 7. Health check

- API: open `https://<your-api>.onrender.com/up` (or your health path). Should return 200.
- Frontend: open `https://<your-frontend>.onrender.com` and log in or register using an invite code.

---

## Summary

| Service | Type | Repo / Source |
|---------|------|----------------|
| API | Web Service (Docker) | `battle_of_books_api` |
| DB | Postgres | Created in Render |
| Redis | Key Value | Created in Render |
| Frontend | Static Site | `battle_of_books_frontend` |

Required env for API: `DATABASE_URL`, `REDIS_URL`, `SECRET_KEY_BASE`, `FRONTEND_URL`.  
Required env for frontend build: `VITE_API_URL`.
