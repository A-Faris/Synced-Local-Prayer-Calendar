#!/bin/bash
set -e

# ---------- LOAD CONFIG FROM .env ----------
if [ ! -f .env ]; then
  echo "❌ .env file not found!"
  exit 1
fi

export $(grep -v '^#' .env | xargs)
REQUIRED_VARS=("GOOGLE_CLOUD_PROJECT" "SA_NAME" "REGION" "SECRET_NAME")

for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ Missing required env var: $var"
    exit 1
  fi
done

SA_EMAIL="$SA_NAME@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com"

echo -e "\n🚀 Setting up service account:\n$SA_EMAIL"
echo "----------------------------------------------------"

# ---------- 1️⃣ Create service account if needed ----------
if gcloud iam service-accounts describe $SA_EMAIL --project $GOOGLE_CLOUD_PROJECT >/dev/null 2>&1; then
  echo -e "✅ Service account exists.\n"
else
  echo -e "🔹 Creating service account...\n"
  gcloud iam service-accounts create $SA_NAME \
    --project $GOOGLE_CLOUD_PROJECT \
    --display-name "Prayer Scraper Cloud Run Job Service Account"
fi

# ---------- 2️⃣ Assign roles ----------
echo "🔹 Ensuring required roles..."
for role in roles/run.jobsExecutor roles/secretmanager.secretAccessor; do
  if ! gcloud projects get-iam-policy $GOOGLE_CLOUD_PROJECT \
        --flatten="bindings[].members" \
        --format="value(bindings.role)" \
        --filter="bindings.members:serviceAccount:$SA_EMAIL" | grep -q "$role"; then
    gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
      --member="serviceAccount:$SA_EMAIL" --role="$role"
    echo "✅ Granted $role"
  else
    echo "✅ $role already granted."
  fi
done

# ---------- 3️⃣ Create secret if needed ----------
if gcloud secrets describe $SECRET_NAME --project $GOOGLE_CLOUD_PROJECT >/dev/null 2>&1; then
  echo -e "\n✅ Secret exists. Skipping key creation.\n"
else
  echo -e "\n🔹 Creating secret and adding new key..."
  gcloud secrets create $SECRET_NAME --replication-policy="automatic" --project $GOOGLE_CLOUD_PROJECT
  gcloud iam service-accounts keys create /tmp/key.json \
    --iam-account $SA_EMAIL --project $GOOGLE_CLOUD_PROJECT
  gcloud secrets versions add $SECRET_NAME --data-file=/tmp/key.json --project $GOOGLE_CLOUD_PROJECT
  rm -f /tmp/key.json
  echo -e "✅ Secret created and key added.\n"
fi

echo "🎉 Setup complete. Service account, roles, and secret are ready."
