#BIN_NAME:=isucondition
#SERVICE_NAME:=$(BIN_NAME).go.service
#BUILD_DIR:=/home/isucon/webapp/go
NGINX_LOG:=/var/log/nginx/access.log
DB_SLOW_LOG:=/var/log/mysql/mysql-slow.log

# bench走らせる前のログローテートなど→bench
#.PHONY: bench
#bench: bench-prepare

# bench走らせる前のログローテートなど
.PHONY: bench-prepare
bench-prepare: build mv-logs restart

# slow queryを確認する
.PHONY: slow-query
slow-query:
	sudo pt-query-digest $(DB_SLOW_LOG)

# alpでアクセスログを確認する
.PHONY: alp
alp:
	sudo alp json --file=$(NGINX_LOG) --config=alp-config.yml

.PHONY: build
build:
	cd $(BUILD_DIR); \
	go build -o $(BIN_NAME)

.PHONY: restart
restart:
	sudo touch $(DB_SLOW_LOG)
	sudo chmod 666 $(DB_SLOW_LOG)
	sudo chmod 777 /var/log/mysql
	sudo touch $(NGINX_LOG)
	sudo chmod 666 $(NGINX_LOG)
	sudo chmod 777 /var/log/nginx
	sudo systemctl daemon-reload
	sudo systemctl restart $(SERVICE_NAME)
	sudo systemctl restart mysql
	sudo systemctl restart nginx

.PHONY: mv-logs
mv-logs:
	$(eval when := $(shell date "+%H-%M-%S-%Y-%m-%d"))
	mkdir -p ~/old-logs/nginx/
	mkdir -p ~/old-logs/mysql/
	sudo touch $(NGINX_LOG) $(DB_SLOW_LOG)
	sudo mv -f $(NGINX_LOG) ~/old-logs/nginx/access.log-rotated-at-$(when)
	sudo mv -f $(DB_SLOW_LOG) ~/old-logs/mysql/slow-query-log-rotated-at-$(when)

.PHONY: install-tools
install-tools:
	sudo apt update
	sudo apt upgrade
	sudo apt install -y percona-toolkit dstat git unzip snapd graphviz tree

	# alpのインストール
	wget https://github.com/tkuchiki/alp/releases/download/v1.0.9/alp_linux_amd64.zip
	unzip alp_linux_amd64.zip
	sudo install alp /usr/local/bin/alp
	rm alp_linux_amd64.zip alp

.PHONY: watch-service-log
watch-service-log:
	sudo journalctl -u $(SERVICE_NAME) -n10 -f
