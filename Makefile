# What to back up and where
BCP_HOST ?= localhost
BCP_USER ?= $(shell hostname)

# MySQL configurable options
MYSQL_USER ?= dump
MYSQL_PASS ?= dumppassword

##############################################################
#                                                            #
#        Usually no need to change stuff below               #
#                                                            #
##############################################################

VERSION := 0.1.0
RDB_DIR := /srv/backup
RDB_BIN := /usr/bin/rdiff-backup
RDB := $(RDB_BIN) --ssh-no-compression

MYSQL := /usr/bin/mysql
MYSQLDUMP := /usr/bin/mysqldump
MYSQL_DIR := $(RDB_DIR)/mysql

all: help

$(RDB_DIR):
	mkdir -p $@

.PHONY: etc
etc: $(RDB_BIN)
	$(RDB) /etc $(BCP_USER)@$(BCP_HOST)::etc

.PHONY: home
home: $(RDB_BIN)
	$(RDB) /home $(BCP_USER)@$(BCP_HOST)::home

.PHONY: opt
opt: $(RDB_BIN)
	$(RDB) /opt $(BCP_USER)@$(BCP_HOST)::opt

.PHONY: srv
srv: $(RDB_BIN)
	$(RDB) /srv $(BCP_USER)@$(BCP_HOST)::srv

$(MYSQL_DIR):
	mkdir -p $@

.PHONY: mysqldump
mysqldump: $(MYSQL) $(MYSQLDUMP) $(MYSQL_DIR)
	@for db in $$(echo 'show databases;' | $(MYSQL) -s -u$(MYSQL_USER) -p$(MYSQL_PASS)) ; do \
		echo -n "Backing up $${db}... "; \
		if [ "$${db}" = "information_schema" ] || [ "$${db}" = "performance_schema" ]; then \
			echo " Skipped."; \
		else \
			$(MYSQLDUMP) --opt -u$(MYSQL_USER) -p$(MYSQL_PASS) $${db} | gzip -c > $(MYSQL_DIR)/$${db}.txt.gz; \
			echo "Done."; \
		fi; \
	done

dpkg: $(RDB_DIR)
	@dpkg --get-selections > $</dpkg-selections.txt

.PHONY: update
update:
	wget -O Makefile https://raw.githubusercontent.com/theranger/rdiff-make/master/Makefile

.PHONY: clean
clean:
	rm -rf $(RDB_DIR)

.PHONY: help
help:
	@echo "\nRunning rdiff-make version: $(VERSION)\n"
	@echo "This is a collection of backup targets to be used with rdiff-backup tool."
	@echo "To run them, create a cron script in /etc/cron.daily with a command something like:\n"
	@echo "\tmake -C /opt/backup BCP_HOST=<rdiff-server> MYSQL_PASS=<dump_password> clean etc mysqldump dpkg srv\n"
	@echo "Note, that this script does not support parallel make.\n"
