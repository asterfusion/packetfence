SHELL = /bin/bash
.ONESHELL:
.SHELLFLAGS += -e

FREE_RADIUS_VERSION = feature/PacketFence_3.2.2
FREE_RADIUS_PATH = freeradius-server
RESULT = ../result/debian/bookworm

.PHONY: all
all:
	rm -rf $(FREE_RADIUS_PATH)
	git clone https://github.com/inverse-inc/freeradius-server.git 
	pushd $(FREE_RADIUS_PATH)
	git checkout $(FREE_RADIUS_VERSION)
	make deb
	popd
	mv *.deb $(RESULT)
