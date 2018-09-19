# BROADCASTER

Video blending and distribution application. Please read wiki docs to get familiar with Broadcaster https://bitbucket.org/valynteen_solutions/broadcaster/wiki/Home

## System dependencies

All software listed below must be installed on Broadcaster Server and all Delayed Job Severs. More details here https://bitbucket.org/valynteen_solutions/broadcaster/wiki/Guide%20for%20Developer%20-%20Setting%20up%20Project%20Environment

### RubyOnRails ecosystem
```bash
sudo apt-get install curl
curl -L get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvmsudo apt-get install build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion nodejs
rvm install 1.9.3
rvm install 2.1.1
rvm use 1.9.3 --default
rvm rubygems current
gem install rails
```

### ImageMagick

```bash
sudo apt-get install -y imagemagick libmagickwand-dev libpq-dev rsvg-convert exiv2

#Smart Cropper Script. It's using for AAE projects:
sudo apt-get install php5
sudo apt-get install php5-gd
sudo apt-get install php5-imagick
```

### FFMPEG

```bash
sudo apt-add-repository ppa:jon-severinsson/ffmpeg
sudo apt-get update
sudo apt-get install ffmpeg
```

You can get ffmpeg cannot recognize the '-af' option exception. It means that very old version of FFMPEG is installed. It should be upgraded.
Solutuon:
```bash
sudo add-apt-repository -y ppa:mc3man/trusty-media; sudo apt-get update; sudo apt-get install --only-upgrade ffmpeg
```

You can get ffmpeg E: Sub-process /usr/bin/dpkg returned an error code (1) exception during upgrade.
Solution:
```bash
sudo dpkg -i --force-overwrite /var/cache/apt/archives/libx265-102_2.2-1~16.04.york0_amd64.deb
sudo add-apt-repository -y ppa:mc3man/trusty-media; sudo apt-get update; sudo apt-get install --only-upgrade ffmpeg
```

### Libav Tools
```bash
sudo apt-get install libav-tools
```

### MP4Box
```bash
sudo apt-get install gpac
```

### MediaInfo
```bash
sudo apt-get install mediainfo
```

### MD5Deep
```bash
sudo apt-get install md5deep
```

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...