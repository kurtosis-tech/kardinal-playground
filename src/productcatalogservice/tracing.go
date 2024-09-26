package main

import (
	"github.com/kurtosis-tech/new-obd/src/productcatalogservice/consts"
	"github.com/labstack/echo/v4"
	"github.com/sirupsen/logrus"
)

// KardinalTraceIDMiddleware logs the trace ID from the request headers
func KardinalTraceIDMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		// Get the trace ID from the request header
		traceID := c.Request().Header.Get(consts.KardinalTraceIdHeaderKey)

		// Log the trace ID
		if traceID != "" {
			logrus.Infof("[KARDINAL-DEBUG] Trace ID: %s", traceID)
		} else {
			logrus.Info("[KARDINAL-DEBUG] Trace ID: not provided")
		}

		// Call the next handler
		return next(c)
	}
}
