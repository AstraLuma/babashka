MO_VERSION = master

bin/mo:
	curl https://github.com/tests-always-included/mo/raw/$(MO_VERSION)/mo --output $@
	chmod +x $@
