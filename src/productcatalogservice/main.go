package main

import (
	"fmt"
	productcatalogservice_server_rest_server "github.com/kurtosis-tech/new-obd/src/productcatalogservice/api/http_rest/server"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/sirupsen/logrus"
	"net"
)

const (
	restAPIPortAddr uint16 = 8070
	restAPIHostIP   string = "0.0.0.0"
)

var (
	defaultCORSOrigins = []string{"*"}
	defaultCORSHeaders = []string{echo.HeaderOrigin, echo.HeaderContentType, echo.HeaderAccept}
)

func main() {
	logrus.Info("Running REST API server...")

	// This is how you set up a basic Echo router
	echoRouter := echo.New()
	echoRouter.Use(middleware.Logger())

	echoRouter.Use(KardinalTraceIDMiddleware)

	// CORS configuration
	echoRouter.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: defaultCORSOrigins,
		AllowHeaders: defaultCORSHeaders,
	}))

	server := NewServer()

	productcatalogservice_server_rest_server.RegisterHandlers(echoRouter, productcatalogservice_server_rest_server.NewStrictHandler(server, nil))

	echoRouter.Start(net.JoinHostPort(restAPIHostIP, fmt.Sprint(restAPIPortAddr)))
}
