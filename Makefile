all: verify

verify:
	@echo "  - Checking setup ... "
	@shlintchecker setup

	@echo "  - Checking basher ... "
	@shlintchecker $(ls basher/* | grep -v "/$") basher/langs/* 

	@echo "  - Checking scripts ... "
	(cd scripts; IGNORE_FILES="diff-highlight" shlintchecker *)
