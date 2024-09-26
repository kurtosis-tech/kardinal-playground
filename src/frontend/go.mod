module github.com/kurtosis-tech/new-obd/src/frontend

go 1.21.9

toolchain go1.22.4

replace (
	github.com/kurtosis-tech/new-obd/src/cartservice => ../cartservice
	github.com/kurtosis-tech/new-obd/src/currencyexternalapi => ../currencyexternalapi
	github.com/kurtosis-tech/new-obd/src/productcatalogservice => ../productcatalogservice

)

require (
	github.com/google/uuid v1.5.0
	github.com/gorilla/mux v1.8.1
	github.com/kurtosis-tech/new-obd/src/cartservice v0.0.0
	github.com/kurtosis-tech/new-obd/src/currencyexternalapi v0.0.0
	github.com/kurtosis-tech/new-obd/src/productcatalogservice v0.0.0
	github.com/pkg/errors v0.9.1
	github.com/sirupsen/logrus v1.8.1
)

require (
	github.com/apapsch/go-jsonmerge/v2 v2.0.0 // indirect
	github.com/golang/protobuf v1.5.0 // indirect
	github.com/google/go-cmp v0.5.8 // indirect
	github.com/oapi-codegen/runtime v1.1.1 // indirect
	golang.org/x/sys v0.20.0 // indirect
	google.golang.org/genproto v0.0.0-20200526211855-cb27e3aa2013 // indirect
	google.golang.org/grpc v1.42.0 // indirect
	google.golang.org/protobuf v1.31.0 // indirect
)
