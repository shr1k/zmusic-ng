include server.cfg

.PHONY: all clean deploy update-collection

all:
	@$(MAKE) -C frontend

clean:
	@$(MAKE) -C frontend clean
	@$(MAKE) -C backend clean

SSH_OPTS := -o ControlMaster=auto -o ControlPath=.ssh-deployment.sock

deploy: all
	@echo "    SSH     $(WEB_SERVER)"
	@ssh $(SSH_OPTS) -Nf $(WEB_SERVER)
	
	@echo "    RSYNC   frontend/ $(WEB_SERVER):$(SERVER_STATIC_PATH)"
	@ssh -t $(SSH_OPTS) $(WEB_SERVER) "sudo -u $(SERVER_STATIC_USER) -v"
	@rsync -aizm --delete-excluded --exclude=Makefile --exclude=*.swp --exclude=bin/ --exclude=Makefile \
		--include=scripts.min.js --include=styles.min.css --exclude=*.js --exclude=*.css --rsh="ssh $(SSH_OPTS)" \
		--rsync-path="sudo -n -u $(SERVER_STATIC_USER) rsync" frontend/ "$(WEB_SERVER):$(SERVER_STATIC_PATH)" 
	
	@echo "    CHOWN   $(SERVER_STATIC_USER):$(SERVER_APP_USER) $(WEB_SERVER):$(SERVER_STATIC_PATH)"
	@ssh -t $(SSH_OPTS) $(WEB_SERVER) "sudo chown -v -R $(SERVER_STATIC_USER):$(SERVER_APP_USER) '$(SERVER_STATIC_PATH)'"
	
	@echo "    RSYNC   backend/zmusic $(WEB_SERVER):$(SERVER_APP_PATH)"
	@ssh -t $(SSH_OPTS) $(WEB_SERVER) "sudo -u $(SERVER_APP_USER) -v"
	@rsync -aizm --delete-excluded  --filter="P zmusic.db" --filter="P app.cfg" --exclude=*.swp --exclude=*.pyc \
		--rsh="ssh $(SSH_OPTS)" --rsync-path="sudo -n -u $(SERVER_APP_USER) rsync" backend/zmusic/ "$(WEB_SERVER):$(SERVER_APP_PATH)"
	
	@echo "    CHOWN   $(SERVER_APP_USER):$(SERVER_APP_USER) $(WEB_SERVER):$(SERVER_APP_PATH)"
	@ssh -t $(SSH_OPTS) $(WEB_SERVER) "sudo chown -v -R $(SERVER_APP_USER):$(SERVER_APP_USER) '$(SERVER_APP_PATH)'"
	
	@echo "    CHMOD   750/640 $(WEB_SERVER):$(SERVER_APP_PATH) $(WEB_SERVER):$(SERVER_STATIC_PATH)"
	@ssh -t $(SSH_OPTS) $(WEB_SERVER) "sudo find '$(SERVER_APP_PATH)' '$(SERVER_STATIC_PATH)' -type f -exec chmod -v 640 {} \;; \
				sudo find '$(SERVER_APP_PATH)' '$(SERVER_STATIC_PATH)' -type d -exec chmod -v 750 {} \;;"
	
	@echo "    UWSGI   restart $(WEB_SERVER)"
	@ssh -t $(SSH_OPTS) $(WEB_SERVER) "sudo /etc/init.d/uwsgi restart"
	
	@echo "    SSH     $(WEB_SERVER)"
	@ssh -O exit $(SSH_OPTS) $(WEB_SERVER)

update-collection:
	@echo "    RSYNC   $(LOCAL_COLLECTION_PATH) $(UPLOAD_SERVER):$(UPLOAD_SERVER_PATH)"
	@rsync -avzPi --delete-excluded --delete-after --fuzzy --exclude=.directory '$(LOCAL_COLLECTION_PATH)/' '$(UPLOAD_SERVER):$(UPLOAD_SERVER_PATH)'
	@echo "    SCAN    $(WEB_SERVER)"
	@curl 'http://$(WEB_SERVER)/scan?username=$(ADMIN_USERNAME)&password=$(ADMIN_PASSWORD)'
