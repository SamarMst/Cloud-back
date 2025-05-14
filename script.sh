#!/bin/bash -xe

# Update system packages
sudo yum update -y

# Install Node.js
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
sudo yum install -y nodejs gcc-c++ make git nginx

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Configure Nginx
cat << 'EOF' | sudo tee /etc/nginx/conf.d/app.conf
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Reload Nginx to apply config
sudo systemctl reload nginx

# Create app directory
APP_DIR="/home/ec2-user/app"
mkdir -p $APP_DIR
cd $APP_DIR

# Clone your app (replace with real URL)
git clone https://github.com/SamarMst/Cloud-back.git .

# Change ownership to ec2-user
sudo chown -R ec2-user:ec2-user $APP_DIR

# Switch to ec2-user context to finish setup
sudo -u ec2-user bash << 'EOF'

cd /home/ec2-user/app

# Install dependencies
npm install

# Install PM2
npm install -g pm2

# Start app with PM2 and assign name
pm2 start index.js --name backend

# Setup PM2 to start on reboot
pm2 startup systemd -u ec2-user --hp /home/ec2-user
pm2 save

EOF

# Log setup completion
echo "Setup completed successfully" | sudo tee /home/ec2-user/setup-completed.log
