# CLAUDE.md

## Project Overview

TripCraft AI — serverless backend on AWS (Lambda + API Gateway + DynamoDB + ECR) with an iOS client (SwiftUI). Deployed via Terraform and GitHub Actions.

## Architecture

- **Backend**: Python (FastAPI) in `backend/`, containerized and deployed to AWS Lambda
- **iOS App**: SwiftUI + MVVM in `ios/`, targeting iOS 17+
- **Infrastructure**: Terraform in `backend/infrastructure/terraform/` (main) and `backend/infrastructure/terraform-ecr/` (ECR-only, separate state)
- **CI/CD**: GitHub Actions in `.github/workflows/actions.yaml` (orchestrator) calling reusable workflows

### Security Architecture
- **API Key (Backend)**: Stored in AWS Secrets Manager with 14-day auto-rotation (rotation Lambda)
- **API Key Validation**: `hmac.compare_digest()` for timing-safe comparison
- **Secret Retrieval**: boto3 with 5-minute TTL cache (no credentials in env vars)
- **TLS**: REST API Gateway with `SecurityPolicy_TLS13_1_3_2025_09`

### iOS Security Layers
- **API Key Protection**: Multi-layer XOR+salt obfuscation in binary → decoded once → stored in Keychain → memory wiped
- **Certificate Pinning**: SHA-256 pins for Amazon Root CA 1-4, rejects mismatched certs (prevents MITM)
- **Network**: Ephemeral URLSession (no cache/cookies), HTTPS-only (no ATS exceptions)
- **Jailbreak Detection**: File checks + writable system path test + DYLD injection detection → blocks app
- **Input Validation**: Length limits (200/500 chars), forbidden characters (`<>{}[]`), whitespace trimming
- **Device ID**: UUID generated once, Keychain-persisted (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`)
- **StoreKit 2**: Rejects unverified transactions, replay-safe via backend conditional writes
- **Speech**: On-device processing only, no transcript persistence, proper privacy permissions
- **Voice Input**: Apple Speech framework with real-time transcription on destination/origin/notes fields

### Bedrock (LLM) Integration
- **Client**: `anthropic.AnthropicBedrock` (Python SDK) — NOT direct Anthropic API
- **Region**: eu-west-1 (source) → EU cross-region inference routing
- **Model IDs**: Must use `eu.anthropic.claude-*` prefix for cross-region inference from eu-west-1
- **Current model**: `eu.anthropic.claude-haiku-4-5-20251001-v1:0` (both simple and complex)
- **Max tokens**: 4096 (to stay within API Gateway 29s timeout)
- **Response parsing**: Strip markdown fences, check `stop_reason != "max_tokens"`

## Terraform Structure

Two separate Terraform root modules with **independent S3 state files**:
- `terraform-ecr/` → `s3://fvc-terraform-state-bucket-dev/tripcraft-ai/ecr/terraform.tfstate`
- `terraform/` → `s3://fvc-terraform-state-bucket-dev/tripcraft-ai/terraform.tfstate`

The main module references ECR via `data "aws_ecr_repository"` (read-only lookup), NOT as a managed resource.

## CI/CD Pipeline Flow

```
Setup → Test + Security + iOS Build → Initialize → ECR Ensure + Docker Prepare → Terraform Plan → Deploy
```

- **Test & Lint**: Python ruff + mypy + pytest (backend)
- **Security**: pip-audit + bandit (backend)
- **iOS Build & Test**: Xcode build + unit tests + SwiftLint + security audit (ios)
- **ECR Ensure**: Applies `terraform-ecr/` to guarantee ECR repo exists (separate state)
- **Terraform Plan**: Plans main infra (requires ECR to exist for data source lookup)
- **Deploy**: Builds/pushes Docker image → full `terraform apply` on main config → updates Lambda

### iOS CI Checks (`.github/workflows/ios.yaml`)
- **Build & Test**: `xcodebuild build` + `xcodebuild test` on iOS Simulator (macos-15 runner)
- **SwiftLint**: Strict mode with `.swiftlint.yml` config
- **Security Audit**: Scans for hardcoded secrets, verifies no ATS exceptions, ensures all URLs are HTTPS

## Lessons Learned (CRITICAL)

### Never use `terraform apply -target` in CI/CD pipelines
- `-target` causes partial state management — non-targeted resources may be "forgotten" between runs
- AWS resources like API Gateway API keys and APIs allow duplicate names — Terraform happily creates new ones if state tracking is lost
- This led to 4 orphaned API keys that couldn't be deleted manually
- **Solution**: Use separate Terraform root modules with their own state files for bootstrap resources (ECR, S3 buckets, etc.)

### Never use `terraform state rm` in CI
- Removing resources from state causes "already exists" errors on next apply
- The resource still exists in AWS but Terraform thinks it needs to create it
- **Solution**: Removed ALL `state rm` and `state mv` commands from workflows. S3 backend tracks state correctly. If you need a clean slate, destroy and recreate — don't manipulate state.

### Chicken-and-egg dependencies (ECR ↔ Lambda image)
- Lambda requires `image_uri` pointing to an image in ECR
- Docker push requires ECR repo to exist
- **Solution**: Separate ECR into its own Terraform config/state, ensure it exists early, push image, then apply main infra

### AWS API Gateway allows duplicate resource names
- Unlike most AWS resources, API keys and REST APIs can have identical names
- Terraform won't detect duplicates — if state is lost, it creates new ones alongside old ones
- Old ones become orphaned (can't delete via console if Terraform state references them)

### HTTP APIs (apigatewayv2) do NOT support TLS security policies
- TLS 1.3 enforcement requires REST API (`aws_api_gateway_rest_api`)
- HTTP APIs (apigatewayv2) don't support `aws_api_gateway_domain_name` security_policy
- Converted from HTTP API to REST API for TLS 1.3 support

### Bedrock model IDs differ by region
- In-region (e.g., eu-west-2 for Sonnet 4.6): `anthropic.claude-sonnet-4-6`
- Cross-region from eu-west-1: `eu.anthropic.claude-sonnet-4-6`
- Global: `global.anthropic.claude-sonnet-4-6`
- Using wrong format → `ValidationException` or "model identifier is invalid"

### Bedrock first-invoke marketplace subscription
- First call to a new model requires `aws-marketplace:ViewSubscriptions` + `aws-marketplace:Subscribe` permissions
- Lambda IAM roles typically don't have these
- **Solution**: Invoke the model once from the AWS console Playground or CLI with admin credentials. This activates the model account-wide.

### REST API Gateway has a hard 29-second integration timeout
- Cannot be extended (AWS hard limit)
- LLM calls that exceed 29s → `504 Gateway Timeout` to client
- **Solution**: Reduce `max_tokens`, simplify prompts for concise responses, or use async pattern for long operations

### Claude may return JSON wrapped in markdown fences
- Even with "No markdown" in system prompt, models sometimes wrap output in ` ```json...``` `
- Always strip markdown fences before `json.loads()`
- Also validate `stop_reason != "max_tokens"` to detect truncated (invalid) JSON

### S3 backend must have state locking enabled
- Without `use_lockfile = true`, concurrent pipeline runs can corrupt state
- This was a contributing factor to duplicate resource creation
- Always add `use_lockfile = true` to S3 backend configs

### IAM for cross-region Bedrock inference
- Must allow `bedrock:InvokeModel` on:
  - `arn:aws:bedrock:<region>:<account>:inference-profile/eu.anthropic.*` (inference profiles)
  - `arn:aws:bedrock:*::foundation-model/anthropic.*` (destination region models)

## Commands

```bash
# Backend
cd backend && uv run python -m pytest    # Run tests (NOT bare pytest — venv resolution issues)
cd backend && ruff check --fix . && ruff format .  # Lint/Format (run before commit)

# iOS
cd ios && xcodebuild build -scheme TripCraftAI -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' CODE_SIGNING_ALLOWED=NO
cd ios && xcodebuild test -scheme TripCraftAI -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' CODE_SIGNING_ALLOWED=NO
cd ios && swiftlint lint --strict TripCraftAI/  # Lint (requires: brew install swiftlint)
```

## Environment

- AWS Region: eu-west-1
- GitHub Environment: TripCraft-AI-Dev
- Branches: main (production), test* (staging), dev*/feature/* (development)

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | None | Health check |
| POST | `/itinerary/generate` | API Key + Device ID | Generate itinerary (costs 1 credit) |
| GET | `/itinerary/credits` | API Key + Device ID | Check credit balance |
| POST | `/itinerary/credits/purchase` | API Key + Device ID | Add credits after IAP |

### Required Headers (all except /health)
- `X-Api-Key`: API key from Secrets Manager
- `X-Device-ID`: 8-128 char alphanumeric identifier
- `Content-Type`: application/json

### Credits System
- 1 free credit on first request
- Products: `com.tripcraft.trip.1` (1), `.trip.3` (3), `.trip.10` (10)
- Transaction replay prevention via DynamoDB conditional writes

## iOS Project Structure (`ios/`)

```
TripCraftAI/
├── App/                    # Entry point + config
├── Models/                 # Codable request/response models
├── Services/               # APIClient, Keychain, DeviceID, StoreKit, SpeechRecognizer
├── ViewModels/             # TripFormViewModel, CreditsViewModel
├── Views/                  # SwiftUI views + Components/
├── Utilities/              # Security: APIKeyObfuscation, CertificatePinning, IntegrityCheck, InputValidator
└── Assets.xcassets/        # App icon (1024x1024 travel-themed)
```

Key files:
- `Services/APIClient.swift` — Ephemeral URLSession + cert pinning + auto-headers
- `Utilities/IntegrityCheck.swift` — Jailbreak detection (blocks app on compromised devices)
- `Utilities/InputValidator.swift` — Input sanitization before API calls
- `Services/SpeechRecognizer.swift` — Voice-to-text using Apple Speech framework
- `ios/.swiftlint.yml` — SwiftLint config (strict mode)
