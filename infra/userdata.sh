#!/bin/bash
set -e

# --- System setup ---
apt-get update -y
apt-get install -y \
  ca-certificates curl gnupg unzip jq python3-pip lsof net-tools

# --- Install Docker ---
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# --- Create app directories ---
mkdir -p /app/html /app/config /app/api /var/log/nginx

# --- Install CloudWatch Agent ---
curl -fsSL https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb \
  -o /tmp/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "web-server-access-logs",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
CWCONFIG

systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# --- Pull app source from GitHub (public repo) ---
apt-get install -y git
git clone https://github.com/shayczech/web-server.git /opt/web-server

# --- Build and run stats-api ---
cd /opt/web-server/site/api

docker build -t stats-api:latest \
  --build-arg BUILD_TIMESTAMP=$(date +%s) \
  -f Dockerfile .

echo '{"securityScore": 100}' > /app/api/security-score.json

docker run -d \
  --name stats-api \
  --restart always \
  --network host \
  -v /app/api/security-score.json:/app/security-score.json:ro \
  -v /app/api:/app/data \
  -e KITCHEN_DATA_PATH=/app/data/kitchen-data.json \
  stats-api:latest

# Wait for API
for i in $(seq 1 12); do
  curl -sf http://localhost:3000/api/stats && break
  sleep 5
done

# --- Copy static files ---
cp /opt/web-server/site/index.html       /app/html/
cp /opt/web-server/site/resume.html     /app/html/
cp /opt/web-server/site/grc.html        /app/html/
cp /opt/web-server/site/architecture.html /app/html/
mkdir -p /app/html/assets
cp -r /opt/web-server/site/assets/*     /app/html/assets/
mkdir -p /app/html/p
cp -r /opt/web-server/site/p/*         /app/html/p/ 2>/dev/null || true

# --- Nginx config (HTTP only — ALB handles SSL); clean URLs (no .html in browser) ---
cp /opt/web-server/infra/nginx.conf /app/config/nginx.conf

# --- Run Nginx container ---
docker run -d \
  --name portfolio-web \
  --restart always \
  --network host \
  -v /app/html:/usr/share/nginx/html:ro \
  -v /app/config/nginx.conf:/etc/nginx/conf.d/default.conf:ro \
  -v /var/log/nginx:/var/log/nginx \
  nginx:latest

# Restart CloudWatch Agent to pick up Nginx log
sleep 10
systemctl restart amazon-cloudwatch-agent
