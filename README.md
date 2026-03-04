# Workshop GCP: Serverless CRUD API with Terraform + Cloud Functions (Gen 2)

This project provisions a **serverless CRUD API** on **Google Cloud** using **Terraform** and a **Python HTTP Cloud Function (Gen 2)** backed by **Firestore**.

It is designed as a **workshop starter project** for newcomers learning how to deploy cloud-native APIs on GCP with Infrastructure as Code.

---

## What this project deploys

Terraform provisions:

- **Required APIs** (Cloud Functions, Cloud Build, Firestore, Artifact Registry, Cloud Run)
- **Firestore database** in Native mode
- **Cloud Storage bucket** for function source upload
- **Cloud Function (Gen 2)** using Python 3.11
- **Public invoker IAM binding** on underlying Cloud Run service

Main resources are defined in [main.tf](main.tf), with outputs in [outputs.tf](outputs.tf), and variables in [variables.tf](variables.tf).

---

## Runtime implementation

The API logic is in `handler` inside [src/main.py](src/main.py), using:

- `functions-framework` for HTTP function handling
- `google-cloud-firestore` for Firestore access

Dependencies are pinned in [src/requirements.txt](src/requirements.txt).

### Implemented endpoints/behavior

Collection used: `books`

- `GET /` → list all books
- `GET /<doc_id>` → get one book by document ID
- `POST /` → create a new book (requires at least `title`)
- `PUT /<doc_id>` → fully replace a book document
- `DELETE /<doc_id>` → delete a book
- `OPTIONS` → CORS preflight support

CORS is currently open (`Access-Control-Allow-Origin: *`), which is useful for workshops but should be tightened in production.

### Book document shape (based on current API logic)

The function currently enforces only one required field on create:

- Required on `POST`: `title`
- Automatically added on `POST`: `created_at` (Firestore server timestamp)

Example create payload:

```json
{
  "title": "Clean Code",
  "author": "Robert C. Martin",
  "year": 2008,
  "genre": "Software Engineering"
}
```

For `PUT /<doc_id>`, the payload is written with full overwrite semantics (`set(payload)`), so include all fields you want to keep.

---

## Repository structure

- [.gitignore](.gitignore)
- [main.tf](main.tf)
- [variables.tf](variables.tf)
- [terraform.tfvars](terraform.tfvars)
- [outputs.tf](outputs.tf)
- [src/main.py](src/main.py)
- [src/requirements.txt](src/requirements.txt)

---

## Prerequisites

Install and configure:

1. **Terraform** (>= 1.5 recommended)  
   https://developer.hashicorp.com/terraform/downloads
2. **Google Cloud SDK (gcloud CLI)**  
   https://cloud.google.com/sdk/docs/install
3. **Python 3.11** (for local testing)
4. A **GCP project** with billing enabled

---

## Configure in your own environment

### 1) Clone and enter the project

```bash
git clone <your-repo-url>
cd workshop-gcp
```

### 2) Authenticate and set project with gcloud

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project <YOUR_PROJECT_ID>
```

### 3) Update Terraform variables

Edit [terraform.tfvars](terraform.tfvars):

- `project_id` → your project
- `region` → deployment region
- `firestore_location` → Firestore location (example: `nam5`)
- `function_name` → desired function name

> Current [main.tf](main.tf) hardcodes:
> - function name as `gcp-workshop-api`
> - firestore location as `nam5`  
> If you want full configurability, wire these to `var.function_name` and `var.firestore_location`.

### 4) Initialize and deploy

```bash
terraform init
terraform plan
terraform apply
```

After apply, check endpoint from [outputs.tf](outputs.tf):

```bash
terraform output api_endpoint
```

---

## How to call the deployed API

Assume:

```bash
API_URL=$(terraform output -raw api_endpoint)
```

### Create book

```bash
curl -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d '{"title":"Clean Code","author":"Robert C. Martin","year":2008}'
```

### List books

```bash
curl "$API_URL"
```

### Get one book

```bash
curl "$API_URL/<DOCUMENT_ID>"
```

### Update one book (full replace)

```bash
curl -X PUT "$API_URL/<DOCUMENT_ID>" \
  -H "Content-Type: application/json" \
  -d '{"title":"Clean Architecture","author":"Robert C. Martin","year":2017}'
```

### Delete one book

```bash
curl -X DELETE "$API_URL/<DOCUMENT_ID>"
```

---

## Local testing (without deploying)

Local execution uses the same `handler` entrypoint via Functions Framework.

### 1) Create virtual environment and install deps

```bash
cd src
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 2) Authenticate ADC (Application Default Credentials)

The Firestore client in [src/main.py](src/main.py) uses ADC:

```bash
gcloud auth application-default login
gcloud config set project <YOUR_PROJECT_ID>
```

(Optional) set explicit project for local runtime:

```bash
export GOOGLE_CLOUD_PROJECT=<YOUR_PROJECT_ID>
```

### 3) Run the function locally

From `src/`:

```bash
functions-framework --target=handler --source=main.py --debug --port=8080
```

### 4) Test locally with curl

```bash
# List books
curl http://localhost:8080/

# Create book
curl -X POST http://localhost:8080/ \
  -H "Content-Type: application/json" \
  -d '{"title":"Domain-Driven Design","author":"Eric Evans","year":2003}'

# Get by id
curl http://localhost:8080/<DOCUMENT_ID>

# Update by id (full overwrite)
curl -X PUT http://localhost:8080/<DOCUMENT_ID> \
  -H "Content-Type: application/json" \
  -d '{"title":"Refactoring","author":"Martin Fowler","year":2018}'

# Delete by id
curl -X DELETE http://localhost:8080/<DOCUMENT_ID>
```

---

## Important Notes

- **Infra as Code**: resources are versioned in [main.tf](main.tf).
- **Gen 2 Functions** run on Cloud Run infrastructure.
- **Public API** is enabled by IAM member `allUsers` with `roles/run.invoker`.
- **Firestore Native Mode** provides simple document CRUD model.
- **CORS** and REST basics are demonstrated in `handler` in [src/main.py](src/main.py).

---

## Next Steps / Improvements

1. Use variables in [main.tf](main.tf) for function name and Firestore location.
2. Add stronger schema validation for `POST` and `PUT` payloads.
3. Return consistent JSON for errors and `404`.
4. Add `PATCH` endpoint for partial updates.
5. Restrict CORS origins for production.
6. Add automated tests (pytest + Flask test client).
7. Add CI/CD (GitHub Actions + `terraform fmt/validate/plan`).

---

## Cleanup

To remove all provisioned resources:

```bash
terraform destroy
```

---

## Useful references

### Terraform + GCP

- Google provider docs: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- Cloud Functions Gen 2 resource:  
  https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions2_function
- Firestore database resource:  
  https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/firestore_database
- Project service enablement:  
  https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_service

### Google Cloud docs

- Cloud Functions (Gen 2): https://cloud.google.com/functions/docs
- Firestore: https://cloud.google.com/firestore/docs
- Application Default Credentials: https://cloud.google.com/docs/authentication/provide-credentials-adc

### Python libraries

- Functions Framework (Python): https://github.com/GoogleCloudPlatform/functions-framework-python
- `google-cloud-firestore`: https://cloud.google.com/python/docs/reference/firestore/latest

---

## License / Usage

Intended as a workshop sample project.  
Adapt security, IAM, validation, and CORS before using in production.
