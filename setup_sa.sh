#!/bin/bash
set -e  # stop on first error

# ---------- LOAD CONFIG FROM .env ----------
if [ ! -f .env ]; then
  echo "❌ .env file not found!"
  exit 1
fi

export $(grep -v '^#' .env | xargs)

# Required variables from .env:
# GOOGLE_CLOUD_PROJECT, SA_NAME, REGION, SECRET_NAME

if [[ -z "$GOOGLE_CLOUD_PROJECT" || -z "$SA_NAME" || -z "$REGION" || -z "$SECRET_NAME" ]]; then
  echo "❌ Missing required environment variables in .env!"
  exit 1
fi

SA_EMAIL="$SA_NAME@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com"

echo
echo "🚀 Setting up service account (if not existing):"
echo "$SA_EMAIL"
echo "----------------------------------------------------"
echo

# ---------- 1️⃣ Create service account if not exists ----------
if gcloud iam service-accounts describe $SA_EMAIL --project $GOOGLE_CLOUD_PROJECT >/dev/null 2>&1; then
  echo "✅ Service account already exists."
else
  echo "🔹 Creating new service account..."
  gcloud iam service-accounts create $SA_NAME \
    --project $GOOGLE_CLOUD_PROJECT \
    --display-name "Prayer Scraper Cloud Run Job Service Account"
  echo "✅ Service account created."
fi
echo

# ---------- 2️⃣ Assign roles ----------
echo "🔹 Assigning required roles (if not already assigned)..."
for role in roles/run.jobsExecutor roles/secretmanager.secretAccessor; do
  if gcloud projects get-iam-policy $GOOGLE_CLOUD_PROJECT \
       --flatten="bindings[].members" \
       --format="value(bindings.role)" \
       --filter="bindings.members:serviceAccount:$SA_EMAIL" | grep -q "$role"; then
    echo "✅ $role already assigned."
  else
    echo "🔹 Granting $role..."
    gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
      --member="serviceAccount:$SA_EMAIL" \
      --role="$role"
  fi
done
echo

# ---------- 3️⃣ Create secret if not exists ----------
if gcloud secrets describe $SECRET_NAME --project $GOOGLE_CLOUD_PROJECT >/dev/null 2>&1; then
  echo "✅ Secret already exists. Skipping key creation."
else
  echo "🔹 Creating new secret..."
  gcloud secrets create $SECRET_NAME --replication-policy="automatic" --project $GOOGLE_CLOUD_PROJECT

  echo "🔹 Generating service account key and adding to secret..."
  gcloud iam service-accounts keys create /tmp/temp-key.json \
    --iam-account $SA_EMAIL \
    --project $GOOGLE_CLOUD_PROJECT

  gcloud secrets versions add $SECRET_NAME \
    --data-file=/tmp/temp-key.json \
    --project $GOOGLE_CLOUD_PROJECT

  rm -f /tmp/temp-key.json
  echo "✅ Key added to Secret Manager and local temp file removed."
fi
echo

echo "🎉 Setup complete. Service account, roles, and secret are ready."
