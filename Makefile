PROJECT_DIR = Camera

.PHONY: All
ALL: ruby-configure \
	cocoapod-configure

.PHONY: ruby-configure
ruby-configure:
	if [ ! -e /usr/local/bin/rbenv ]; then\
		brew install rbenv; \
	fi

	rbenv install 2.7.4 -v -s
	rbenv local 2.7.4
	rbenv exec gem install bundler
	rbenv rehash
	cd ${PROJECT_DIR} && \
	bundle install --path vendor/bundle

.PHONY: cocoapod-configure
cocoapod-configure:
	cd ${PROJECT_DIR} && \
	bundle exec pod install --repo-update
