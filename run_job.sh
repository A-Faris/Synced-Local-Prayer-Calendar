set -e

SERVICE_NAME=$(grep '^service_name' terraform.tfvars | awk -F'=' '{print $2}' | tr -d ' "')
REGION=$(grep '^region' terraform.tfvars | awk -F'=' '{print $2}' | tr -d ' "')
PROJECT_ID=$(grep '^project_id' terraform.tfvars | awk -F'=' '{print $2}' | tr -d ' "')

echo "Executing Cloud Run job: $SERVICE_NAME"
gcloud run jobs execute "$SERVICE_NAME" \
  --region "$REGION" \
  --project "$PROJECT_ID"