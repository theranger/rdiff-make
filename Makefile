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

RDB_DIR := /srv/backup
RDB_BIN := /usr/bin/rdiff-backup
RDB := $(RDB_BIN) --ssh-no-compression

MYSQL := /usr/bin/mysql
MYSQLDUMP := /usr/bin/mysqldump
MYSQL_DIR := $(RDB_DIR)/mysql

.PHONY $(MYSQLDUMP) $(MYSQL) $(RDB_BIN)

all:

$(RDB_DIR):
	mkdir -p $@

etc: $(RDB_BIN)
	$(RDB) /etc $(BCP_USER)@$(BCP_HOST)::etc

srv: $(RDB_BIN)
	$(RDB) /srv $(BCP_USER)@$(BCP_HOST)::srv

$(MYSQL_DIR):
	mkdir -p $@

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

clean:
	rm -rf $(RDB_DIR)
