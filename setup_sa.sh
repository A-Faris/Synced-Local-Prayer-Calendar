#!/bin/bash
set -e  # stop on first error

# ---------- LOAD CONFIG FROM .env ----------
if [ ! -f .env ]; then
  echo "❌ .env file not found!"
  exit 1
fi

export $(grep -v '^#' .env | xargs)

# Required variables from .env:
# PROJECT_ID, SA_NAME, REGION, SECRET_NAME, KEY_FILE

if [[ -z "$PROJECT_ID" || -z "$SA_NAME" || -z "$REGION" || -z "$SECRET_NAME" || -z "$KEY_FILE" ]]; then
  echo "❌ Missing required environment variables in .env!"
  exit 1
fi

SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

echo
echo "🚀 Starting fresh setup for service account:"
echo "$SA_EMAIL"
echo "----------------------------------------------------"
echo

# ---------- 1️⃣ Delete existing service account ----------
echo "🔹 Checking for existing service account..."
if gcloud iam service-accounts describe $SA_EMAIL --project $PROJECT_ID >/dev/null 2>&1; then
  gcloud iam service-accounts delete $SA_EMAIL --quiet --project $PROJECT_ID
  echo "✅ Deleted old service account."
else
  echo "✅ No existing service account found."
fi
echo

# ---------- 2️⃣ Create new service account ----------
echo "🔹 Creating new service account..."
gcloud iam service-accounts create $SA_NAME \
  --project $PROJECT_ID \
  --display-name "Prayer Scraper Cloud Run Job Service Account"
echo "✅ Service account created."
echo

# ---------- 3️⃣ Assign roles ----------
echo "🔹 Assigning required roles..."
for role in roles/run.jobsExecutor roles/secretmanager.secretAccessor; do
  echo "🔹 Granting $role..."
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$role"
done
echo "✅ Roles assigned."
echo

# ---------- 4️⃣ Generate service account key ----------
echo "🔹 Generating new key..."
rm -f $KEY_FILE
gcloud iam service-accounts keys create $KEY_FILE \
  --iam-account $SA_EMAIL \
  --project $PROJECT_ID
echo "✅ Key created."
echo

# ---------- 5️⃣ Replace secret in Secret Manager ----------
echo "🔹 Checking for existing secret in Secret Manager..."
if gcloud secrets describe $SECRET_NAME --project $PROJECT_ID >/dev/null 2>&1; then
  gcloud secrets delete $SECRET_NAME --quiet --project $PROJECT_ID
  echo "✅ Deleted old secret."
else
  echo "✅ No existing secret found."
fi
echo

# ---------- 6️⃣ Create new secret ----------
echo "🔹 Creating fresh secret..."
gcloud secrets create $SECRET_NAME \
  --replication-policy="automatic" \
  --project $PROJECT_ID

echo "🔹 Adding key to secret..."
gcloud secrets versions add $SECRET_NAME \
  --data-file=$KEY_FILE \
  --project $PROJECT_ID

echo "✅ Secret updated."
echo

# ---------- 7️⃣ Clean up ----------
echo "🧹 Removing local key file..."
rm -f $KEY_FILE
echo "✅ Local key removed."
echo

echo "🎉 All done! Service account, roles, and secret fully reset and ready."
echo

# ---------- 8️⃣ Next steps ----------
echo "⚡ Next steps: Create a Google Calendar and share it with the service account"
echo
echo "1. Go to Google Calendar: https://calendar.google.com/"
echo "2. Click the '+' button next to 'Other calendars' → 'Create new calendar'"
echo "3. Give it a name, description (optional), and click 'Create calendar'"
echo "4. After creation, go to 'Settings and sharing' for the new calendar"
echo "5. Scroll down to 'Share with specific people' → Click 'Add people'"
echo "6. Enter the service account email:"
echo "   $SA_EMAIL"
echo "7. Select permission: 'Make changes to events'"
echo "8. Click 'Send'"
echo
echo "✅ After this, the service account will be able to manage events on this calendar."
echo
