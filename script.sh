#!/bin/bash -xe

# Update system packages
sudo yum update -y

# Install Node.js
sudo curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install dev tools (needed for some npm packages)
sudo yum install -y gcc-c++ make git

# Install Nginx
sudo yum install -y nginx

# Configure Nginx to proxy to your Node.js application
sudo cat > /etc/nginx/conf.d/app.conf << 'EOF'
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

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Create app directory
sudo mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

# Clone your application (replace with your actual repository URL)
sudo git clone https://github.com/SamarMst/Cloud-back.git .


# Install application dependencies
sudo npm install

# Install PM2 globally
sudo npm install -g pm2

# Start your application with PM2
pm2 start index.js

# Set PM2 to start on system boot
pm2 startup systemd -u ec2-user --hp /home/ec2-user
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ec2-user --hp /home/ec2-user
pm2 save

# Set appropriate permissions
chown -R ec2-user:ec2-user /home/ec2-user/app

# Log the completion
echo "Application setup completed" > /home/ec2-user/setup-completed.log