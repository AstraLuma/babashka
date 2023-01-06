# Show this help message
@help:
	just --list

# Install to a remote server
install HOSTNAME:
	make bin/mo
	rsync -avz ./ $HOSTNAME:.config/babashka/
