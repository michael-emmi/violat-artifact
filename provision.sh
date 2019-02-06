
echo "Installing various prerequisites"
sudo apt install -y curl
curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash -
sudo apt install -y openjdk-8-jdk-headless maven nodejs
sudo -S -u cav npm config set prefix '~/.npm-global'
sudo -S -u cav echo 'export PATH=~/.npm-global/bin:$PATH' >> .profile

echo "Installing a recent version of Gradle"
wget https://services.gradle.org/distributions/gradle-5.2-bin.zip -P Downloads
sudo unzip -d /opt Downloads/gradle-5.2-bin.zip
sudo -S -u cav echo 'export PATH=/opt/gradle-5.2/bin:${PATH}' >> .profile
export PATH=/opt/gradle-5.2/bin:${PATH}

sudo -S -u cav mkdir -p Code

echo "Downloading and building Java Pathfinder"
(cd Code && git clone https://github.com/javapathfinder/jpf-core.git)
(cd Code/jpf-core && gradle)
sudo -S -u cav echo 'export PATH=${HOME}/Code/jpf-core/bin:${PATH}' >> .profile

echo "Downloading and building Violat"
(cd Code && sudo -S -u cav git clone https://github.com/michael-emmi/violat)
(cd Code/violat && sudo -S -u cav npm link)
