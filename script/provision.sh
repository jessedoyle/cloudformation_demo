#!/usr/bin/env bash

touch /home/ec2-user/init.log
echo "START: command_install..." > /home/ec2-user/init.log
yum update -y >> /home/ec2-user/init.log 2>&1
yum install nodejs npm -y --enablerepo=epel >> /home/ec2-user/init.log 2>&1
yum groupinstall "Development Tools" -y >> /home/ec2-user/init.log 2>&1
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB >> /home/ec2-user/init.log 2>&1
\curl -sSL https://get.rvm.io | bash -s stable --ruby --gems=bundler >> /home/ec2-user/init.log 2>&1
gem install bundler >> /home/ec2-user/init.log 2>&1
mkdir -p /usr/local/rvm && chown ec2-user -R /usr/local/rvm >> /home/ec2-user/init.log 2>&1
wget -O /home/ec2-user/codedeploy-install https://aws-codedeploy-us-west-2.s3.amazonaws.com/latest/install >> /home/ec2-user/init.log 2>&1
chmod +x /home/ec2-user/codedeploy-install >> /home/ec2-user/init.log 2>&1
/home/ec2-user/codedeploy-install auto >> /home/ec2-user/init.log 2>&1
rm /home/ec2-user/codedeploy-install >> /home/ec2-user/init.log 2>&1
echo "169.254.169.254 ec2.meta" >> /etc/hosts 2>&1
echo "START: packages..." >> /home/ec2-user/init.log
yum install -y git gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison postgresql92 postgresql92-devel nginx aws-cfn-bootstrap >> /home/ec2-user/init.log 2>&1
# NOTE: some kernel upgrades may install an older version of gcc-c++ that causes native gems to error when building
yum remove -y gcc48-c++ >> /home/ec2-user/init.log 2>&1
yum install -y gcc72-c++ >> /home/ec2-user/init.log 2>&1
echo "START: filesystem..." >> /home/ec2-user/init.log
mkdir /etc/nginx/sites-enabled >> /home/ec2-user/init.log 2>&1
mkdir /etc/nginx/sites-available >> /home/ec2-user/init.log 2>&1
mkdir -p '/srv' && chown -R ec2-user:ec2-user /srv >> /home/ec2-user/init.log 2>&1
echo "START: source_code..." >> /home/ec2-user/init.log
cd /srv >> /home/ec2-user/init.log 2>&1
git clone https://github.com/jessedoyle/cloudformation_demo.git >> /home/ec2-user/init.log 2>&1
mkdir -p /srv/cloudformation_demo/tmp/sockets >> /home/ec2-user/init.log 2>&1
echo "START: application..." >> /home/ec2-user/init.log
cd /srv/cloudformation_demo
cp /home/ec2-user/.env.production .env >> /home/ec2-user/init.log 2>&1
cp /home/ec2-user/master.key config/master.key >> /home/ec2-user/init.log 2>&1
rm /home/ec2-user/.env.production /home/ec2-user/master.key >> /home/ec2-user/init.log 2>&1
chown ec2-user:ec2-user .env >> /home/ec2-user/init.log 2>&1
chown ec2-user:ec2-user config/master.key >> /home/ec2-user/init.log 2>&1
chmod 600 config/master.key >> /home/ec2-user/init.log 2>&1
chmod 400 .env >> /home/ec2-user/init.log 2>&1
/usr/local/rvm/gems/ruby-2.4.1/wrappers/bundle install --path="vendor/bundle" --without development test >> /home/ec2-user/init.log 2>&1
/usr/local/rvm/gems/ruby-2.4.1/wrappers/bundle exec rake assets:precompile >> /home/ec2-user/init.log 2>&1
mkdir -p tmp/pids >> /home/ec2-user/init.log 2>&1
chown -R ec2-user:ec2-user /srv/cloudformation_demo >> /home/ec2-user/init.log 2>&1
/usr/local/rvm/gems/ruby-2.4.1/wrappers/bundle exec rake db:migrate:status >> /home/ec2-user/init.log 2>&1 || (/usr/local/rvm/gems/ruby-2.4.1/wrappers/bundle exec rake db:create >> /home/ec2-user/init.log 2>&1 && /usr/local/rvm/gems/ruby-2.4.1/wrappers/bundle exec rake db:migrate >> /home/ec2-user/init.log 2>&1)
start puma >> /home/ec2-user/init.log 2>&1
echo "START: nginx..." >> /home/ec2-user/init.log
cp /home/ec2-user/nginx.conf /etc/nginx/nginx.conf >> /home/ec2-user/init.log 2>&1
cp /home/ec2-user/default /etc/nginx/sites-available/default >> /home/ec2-user/init.log 2>&1
rm /home/ec2-user/nginx.conf /home/ec2-user/default >> /home/ec2-user/init.log 2>&1
chmod 644 /etc/nginx/nginx.conf >> /home/ec2-user/init.log 2>&1
chmod 644 /etc/nginx/sites-available/default >> /home/ec2-user/init.log 2>&1
chown ec2-user:ec2-user /etc/nginx/nginx.conf >> /home/ec2-user/init.log 2>&1
chown ec2-user:ec2-user /etc/nginx/sites-available/default >> /home/ec2-user/init.log 2>&1
ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default >> /home/ec2-user/init.log 2>&1
echo "START: service_status..." >> /home/ec2-user/init.log
service codedeploy-agent start >> /home/ec2-user/init.log 2>&1
service nginx start >> /home/ec2-user/init.log 2>&1
echo "COMPLETE!" >> /home/ec2-user/init.log
