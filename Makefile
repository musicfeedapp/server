VERSION = 2.3.0
NAME = musicfeedserver

build: clean
	docker-compose up -d
	docker build -t $(NAME) .
	docker run --rm -t -i \
		--network=$(NAME)_back-tier \
		-e BUNDLE_PATH=/app/vendor \
		-e BUNDLE_BIN=/app/vendor/ruby/2.3.0/bin/ \
		-v `pwd`:/app \
		-v `pwd`/vendor:/app/vendor \
		--dns 8.8.8.8 \
		-w /app \
		$(NAME) \
		/bin/bash -c "bundle install --path /app/vendor && bundle exec rake db:setup && RAILS_ENV=test bundle exec rake db:setup"
.PHONY: build

clean:
	docker rmi --force $(NAME) || true
.PHONY: clean

test:
	docker run --rm -t -i \
		--network=$(NAME)_back-tier \
		-e BUNDLE_PATH=/app/vendor \
		-e BUNDLE_BIN=/app/vendor/ruby/2.3.0/bin/ \
		-v `pwd`:/app \
		-v `pwd`/vendor:/app/vendor \
		-v ~/.ssh/:/root/.ssh/ \
		--dns 8.8.8.8 \
		-w /app \
		$(NAME) \
		/bin/bash -c "bundle exec rspec $(TEST_CASE)"
.PHONY: test

console:
	docker run --rm -t -i \
		--network=$(NAME)_back-tier \
		-e BUNDLE_PATH=/app/vendor \
		-e BUNDLE_BIN=/app/vendor/ruby/2.3.0/bin/ \
		-v `pwd`:/app \
		-v `pwd`/vendor:/app/vendor \
		-v ~/.ssh/:/root/.ssh/ \
		--dns 8.8.8.8 \
		-w /app \
		$(NAME) \
		/bin/bash -c "eval \$$(ssh-agent) && ssh-add ~/.ssh/deploy && /bin/bash"
.PHONY: console

deploy:
	docker run --rm -t -i \
		--network=$(NAME)_back-tier \
		-e BUNDLE_PATH=/app/vendor \
		-e BUNDLE_BIN=/app/vendor/ruby/2.3.0/bin/ \
		-v `pwd`:/app \
		-v `pwd`/vendor:/app/vendor \
		-v ~/.ssh/:/root/.ssh/ \
		--dns 8.8.8.8 \
		-w /app \
		$(NAME) \
		/bin/bash -c "eval \$$(ssh-agent) && ssh-add ~/.ssh/deploy && bundle exec cap production ROLES=app,sidekiq deploy"
.PHONY: console
