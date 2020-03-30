ifeq ($(GOPATH),)
export GOPATH=/tmp/go
endif
export PATH := $(PATH):$(GOPATH)/bin

INSTALL := /usr/bin/install
GO := /usr/local/go/bin/go
BUILD_DIR := $(GOPATH)/bin

SRC_FILES=$(shell find . -name '*.go' | grep -v '_test.go' | grep -v '/tests/')
TEST_FILES=$(wildcard *_test.go)
ifeq ($(SONIC_TELEMETRY_READWRITE),y)
BLD_FLAGS := -tags readwrite
endif

.phony: tel-deps

all: sonic-telemetry

go.mod:
	/usr/local/go/bin/go mod init github.com/Azure/sonic-telemetry
tel-deps:
	$(GO) get github.com/openconfig/gnmi@89b2bf29312cda887da916d0f3a32c1624b7935f
	$(GO) get github.com/jipanyang/gnxi@f0a90cca6fd0041625bcce561b71f849c9b65a8d
	$(GO) get golang.org/x/crypto/ssh/terminal@e9b2fee46413
	$(GO) get -x github.com/golang/glog@23def4e6c14b4da8ac2ed8007337bc5eb5007998
	rm -rf vendor
	$(GO) mod vendor
	ln -s vendor src
	cp -r $(GOPATH)/pkg/mod/github.com/openconfig/gnmi@v0.0.0-20190823184014-89b2bf29312c/* vendor/github.com/openconfig/gnmi/
	cp -r $(GOPATH)/pkg/mod/golang.org/x/crypto@v0.0.0-20191206172530-e9b2fee46413 vendor/golang.org/x/crypto
	chmod -R u+w vendor

sonic-telemetry: go.mod tel-deps
	$(GO) install -mod=vendor $(BLD_FLAGS) github.com/Azure/sonic-telemetry/telemetry
	$(GO) install -mod=vendor github.com/Azure/sonic-telemetry/dialout/dialout_client_cli
	$(GO) install github.com/jipanyang/gnxi/gnmi_get
	$(GO) install github.com/jipanyang/gnxi/gnmi_set
	$(GO) install -mod=vendor github.com/openconfig/gnmi/cmd/gnmi_cli
	rm -f -r node_exporter-0.18.1*
	wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz
	tar -xvf node_exporter-0.18.1.linux-amd64.tar.gz
	
check:
	-$(GO) test -mod=vendor -v github.com/Azure/sonic-telemetry/gnmi_server
	-$(GO) test -mod=vendor -v github.com/Azure/sonic-telemetry/dialout/dialout_client

clean:
	rm -rf vendor
	chmod -f -R u+w $(GOPATH)/pkg || true
	rm -rf $(GOPATH)
	rm -f src

install:
	$(INSTALL) -D $(BUILD_DIR)/telemetry $(DESTDIR)/usr/sbin/telemetry
	$(INSTALL) -D $(BUILD_DIR)/dialout_client_cli $(DESTDIR)/usr/sbin/dialout_client_cli
	$(INSTALL) -D $(BUILD_DIR)/gnmi_get $(DESTDIR)/usr/sbin/gnmi_get
	$(INSTALL) -D $(BUILD_DIR)/gnmi_set $(DESTDIR)/usr/sbin/gnmi_set
	$(INSTALL) -D $(BUILD_DIR)/gnmi_cli $(DESTDIR)/usr/sbin/gnmi_cli
	$(INSTALL) -D node_exporter-0.18.1.linux-amd64/node_exporter $(DESTDIR)/usr/sbin/node_exporter

deinstall:
	rm $(DESTDIR)/usr/sbin/telemetry
	rm $(DESTDIR)/usr/sbin/dialout_client_cli
	rm $(DESTDIR)/usr/sbin/gnmi_get
	rm $(DESTDIR)/usr/sbin/gnmi_set
	rm $(DESTDIR)/usr/sbin/node_exporter

