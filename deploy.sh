#!/bin/bash
set -e

# ---------- LOAD CONFIG FROM .env ----------
if [ ! -f .env ]; then
  echo "❌ .env file not found!"
  exit 1
fi

set -o allexport
source .env
set +o allexport

# ---------- REQUIRED VARS ----------
REQUIRED_VARS=("GOOGLE_CLOUD_PROJECT" "REGION" "REPO" "IMAGE_NAME" "SERVICE_NAME" "SCHEDULE" "TIMEZONE" "SA_NAME")
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ Missing required env var: $var"
    exit 1
  fi
done

SA_EMAIL="$SA_NAME@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com"
IMAGE_URI="$REGION-docker.pkg.dev/$GOOGLE_CLOUD_PROJECT/$REPO/$IMAGE_NAME"

echo -e "\n🚀 FULL DEPLOYMENT START"
echo "Project: $GOOGLE_CLOUD_PROJECT"
echo "Region: $REGION"
echo "Repo: $REPO"
echo "Image: $IMAGE_URI"
echo "Cloud Run Job: $SERVICE_NAME"
echo "Schedule: $SCHEDULE ($TIMEZONE)"
echo "Using Service Account: $SA_EMAIL"
echo "----------------------------------------------------"

# ---------- ENSURE Artifact Registry REPO EXISTS ----------
echo "🔍 Checking Artifact Registry repo..."
if ! gcloud artifacts repositories describe "$REPO" \
     --location="$REGION" \
     --project="$GOOGLE_CLOUD_PROJECT" >/dev/null 2>&1; then
  echo "⚠️ Repo missing — creating..."
  gcloud artifacts repositories create "$REPO" \
    --repository-format=docker \
    --location="$REGION" \
    --project="$GOOGLE_CLOUD_PROJECT"
  echo "✅ Repo created"
else
  echo "✅ Repo exists"
fi

# ---------- BUILD & PUSH DOCKER IMAGE ----------
echo "🐳 Building Docker image..."
docker build -t "$IMAGE_URI" .

echo "📤 Pushing image to Artifact Registry..."
docker push "$IMAGE_URI"
echo "✅ Image pushed"

# ---------- DEPLOY Cloud Run JOB ----------
echo "🛠 Deploying Cloud Run Job..."
gcloud run jobs deploy "$SERVICE_NAME" \
  --image "$IMAGE_URI" \
  --region "$REGION" \
  --project "$GOOGLE_CLOUD_PROJECT" \
  --max-retries=0 \
  --memory=512Mi \
  --cpu=1 \
  --service-account="$SA_EMAIL"

echo "✅ Cloud Run Job deployed"

# ---------- RECREATE Cloud Scheduler ----------
echo "⏰ Recreating Cloud Scheduler..."
gcloud services enable cloudscheduler.googleapis.com

# Delete old scheduler job if exists
gcloud scheduler jobs delete "$SERVICE_NAME-job" \
  --location="$REGION" \
  --quiet >/dev/null 2>&1 || true

# Create fresh scheduler job
gcloud scheduler jobs create http "$SERVICE_NAME-job" \
  --schedule="$SCHEDULE" \
  --time-zone="$TIMEZONE" \
  --http-method=POST \
  --uri="https://${REGION}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${GOOGLE_CLOUD_PROJECT}/jobs/${SERVICE_NAME}:run" \
  --oidc-service-account-email="$SA_EMAIL" \
  --location="$REGION" \
  --project="$GOOGLE_CLOUD_PROJECT"

echo "✅ Cloud Scheduler job created"

echo -e "\n🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
echo "Cloud Run Job: $SERVICE_NAME"
echo "Scheduler Job: $SERVICE_NAME-job"
