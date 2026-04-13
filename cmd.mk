.PHONY: start build

NOW = $(shell date -u '+%Y%m%d%I%M%S')

helm:
	helm -n default template deploy/chart > deploy/bundle.yml

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
	go run main.go cert

cert-ct:
	go run main.go cert -path dist/cert

cert-ca:
	go run main.go certca -path dist/cert

cert-sa:
	go run main.go certsa -path dist/cert

cert-ce:
	go run main.go certce -path dist/cert

cert-ex:
	go run main.go certex

wgetar:
	@if [ -z "$(tag)" ]; then \
		echo "error: 'tag' not specified! Please specify the 'tag' using 'make xxx tag=(version)";\
		exit 1; \
	fi
	cp doc/w.Dockerfile Dockerfile
	git commit -am "${tag}" && git tag -a $(tag)-wgetar -m "${tag}" && git push origin $(tag)-wgetar && git reset --hard HEAD~1
