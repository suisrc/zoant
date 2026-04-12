.PHONY: start build

NOW = $(shell date -u '+%Y%m%d%I%M%S')

APP = $(shell cat vname)

# 初始化mod
init:
	go mod init ${APP}

tidy:
	go mod tidy

# -eng rdx/mux/map
main:
	go run main.go -eng map -local -dual -c zoo.test.toml

build:
	CGO_ENABLED=0 go build -ldflags "-w" -o ./dist/$(APP)

# go env -w GOPROXY=https://proxy.golang.com.cn,direct
proxy:
	go env -w GO111MODULE=on
	go env -w GOPROXY=http://mvn.res.local/repository/go,direct
	go env -w GOSUMDB=sum.golang.google.cn

helm:
	helm -n default template deploy/chart > deploy/bundle.yml

# -tpl ./tmpl
tenv:
	ZOO_PRIONT="true" go run main.go -local -debug -port 81

tbin:
	dist/$(APP) -local -port 81 -c zoo.test.toml

hello:
	go run main.go hello

# https://storage.googleapis.com/kubebuilder-tools/kubebuilder-tools-v1.19.2-linux-amd64.tar.gz
test-kube:
	TEST_ASSET_ETCD=dist/kubebuilder/bin/etcd \
	TEST_ASSET_KUBE_APISERVER=dist/kubebuilder/bin/kube-apiserver \
	TEST_ASSET_KUBECTL=dist/kubebuilder/bin/kubectl \
	go test -v -run TestCustom testdata/custom_test.go

custom:
	go test -v cmd/custom_test.go

cert:
	go run main.go cert -path dist/cert

cert-ca:
	go run main.go certca -path dist/cert

cert-sa:
	go run main.go certsa -path dist/cert

cert-ce:
	go run main.go certce -path dist/cert

cert-ex:
	go run main.go certex

push:
	git push --set-upstream origin $b

git:
	@if [ -z "$(tag)" ]; then \
		echo "error: 'tag' not specified! Please specify the 'tag' using 'make git tag=(version)";\
		exit 1; \
	fi
	git tag -a $(tag) -m "${tag}" && git push origin $(tag)

wgetar:
	@if [ -z "$(tag)" ]; then \
		echo "error: 'tag' not specified! Please specify the 'tag' using 'make xxx tag=(version)";\
		exit 1; \
	fi
	cp doc/w.Dockerfile Dockerfile
	git commit -am "${tag}" && git tag -a $(tag)-wgetar -m "${tag}" && git push origin $(tag)-wgetar && git reset --hard HEAD~1
