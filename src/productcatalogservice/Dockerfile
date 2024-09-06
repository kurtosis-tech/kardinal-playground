FROM golang:1.21.9-alpine AS builder

# Set Go env
ENV CGO_ENABLED=0 GOOS=linux
WORKDIR /go/src/hipstershop

# Install dependencies
RUN apk --update --no-cache add ca-certificates make protoc


# Build Go binary
COPY Makefile go.mod go.sum ./
RUN go env -w GOPROXY=https://goproxy.io,direct/
RUN go mod download
COPY . .

# Skaffold passes in debug-oriented compiler flags
ARG SKAFFOLD_GO_GCFLAGS
RUN go build -gcflags="${SKAFFOLD_GO_GCFLAGS}" -o /go/src/hipstershop/productcatalogservice .

# Deployment container
FROM scratch

WORKDIR /hipstershop

# Definition of this variable is used by 'skaffold debug' to identify a golang binary.
# Default behavior - a failure prints a stack trace for the current goroutine.
# See https://golang.org/pkg/runtime/
ENV GOTRACEBACK=single

COPY ./data /hipstershop/data/
COPY --from=builder /etc/ssl/certs /etc/ssl/certs
COPY --from=builder /go/src/hipstershop/productcatalogservice /hipstershop/productcatalogservice

ENTRYPOINT ["/hipstershop/productcatalogservice"]
