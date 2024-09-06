package currencyexternalapi

import (
	"context"
	"github.com/kurtosis-tech/new-obd/src/currencyexternalapi/config/ghgist"
	"github.com/kurtosis-tech/new-obd/src/currencyexternalapi/config/jsdelivr"
	"github.com/stretchr/testify/require"
	"testing"
)

func Test(t *testing.T) {
	currencyAPI := NewCurrencyAPI(ghgist.GHGistCurrencyAPIConfig)

	supported, err := currencyAPI.GetSupportedCurrencies(context.Background())
	require.NoError(t, err)
	require.NotNil(t, supported)

	fromCurrencyCode := "USD"
	fromUnits := int64(0)
	fromNanos := int32(0)
	toCode := "BRL"

	code, units, nanos, err := currencyAPI.Convert(context.Background(), fromCurrencyCode, fromUnits, fromNanos, toCode)
	require.NoError(t, err)
	require.NotNil(t, code)
	require.NotNil(t, units)
	require.NotNil(t, nanos)
}

func Test2(t *testing.T) {
	currencyAPI := NewCurrencyAPI(jsdelivr.JsdelivrAPIConfig)

	supported, err := currencyAPI.GetSupportedCurrencies(context.Background())
	require.NoError(t, err)
	require.NotNil(t, supported)

	fromCurrencyCode := "USD"
	fromUnits := int64(0)
	fromNanos := int32(0)
	toCode := "BRL"

	code, units, nanos, err := currencyAPI.Convert(context.Background(), fromCurrencyCode, fromUnits, fromNanos, toCode)
	require.NoError(t, err)
	require.NotNil(t, code)
	require.NotNil(t, units)
	require.NotNil(t, nanos)
}
