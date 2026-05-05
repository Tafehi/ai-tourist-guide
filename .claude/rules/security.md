## Secrets

- Never commit API keys, tokens, or credentials
- All secrets go in `.env` (gitignored) — use `.env.example` as template
- Use pydantic-settings to load config; never hardcode connection strings

## Database (PostgreSQL)

- Always use SSL in production (`sslmode=require` or `verify-full`)
- Use parameterized queries only — never string-interpolate user input into SQL
- Use SQLAlchemy ORM or Core with bound parameters
- Connection pooling: set `pool_size`, `max_overflow`, and `pool_pre_ping=True`
- Never expose raw database errors to API responses — catch and return generic messages
- Use `pool_recycle` to avoid stale connections (set to 300s)

## API Security

- Validate all user input at the API boundary using Pydantic models
- File uploads: validate content type, enforce size limits
- Rate limiting: enforce per-user daily limits before calling Claude
- Auth: verify Sign in with Apple tokens server-side before issuing app tokens
- CORS: restrict allowed origins in production
- Never return stack traces or internal details in error responses

## Dependencies

- Run `bandit -r app/` before merging — no high-severity issues allowed
- Keep dependencies pinned to minimum versions (>=) not exact (==) for flexibility
- Review new dependencies for known vulnerabilities
