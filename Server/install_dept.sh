# install dependencies

sudo apt-get install -y apache2 apache2-utils libexpat1 ssl-cert
sudo apt-get install -y python3
sudo apt install -y python3-pip
sudo apt-get install -y build-essential libssl-dev libffi-dev python-dev
sudo apt-get install -y libapache2-mod-wsgi
sudo apt-get install -y mysql-server
sudo apt install -y python3-testresources

pip install --upgrade pip
pip install --upgrade Flask
pip install --upgrade numpy
pip install facebook-sdk
pip install --upgrade oauth2client
pip install -t lib google-api-python-client
pip install --upgrade mysql-connector # ==2.1.7  # 2.1.4
# sudo pip3 install --upgrade smtplib
pip install --upgrade flask_restful
