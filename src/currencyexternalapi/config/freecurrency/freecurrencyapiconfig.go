package freecurrency

import (
	"encoding/json"
	"fmt"
	"github.com/kurtosis-tech/new-obd/src/currencyexternalapi/config"
	"net/url"
	"strings"
	"time"
)

const (
	apiBaseURL              = "https://api.freecurrencyapi.com/v1/"
	apiKeyQueryParamKey     = "apikey"
	currenciesQueryParamKey = "currencies"
	currenciesEndpointPath  = "currencies"
	latestRatesEndpointPath = "latest"
)

type CurrenciesResponse struct {
	Data map[string]Currency `json:"data"`
}

type Currency struct {
	Symbol        string `json:"symbol"`
	Name          string `json:"name"`
	SymbolNative  string `json:"symbol_native"`
	DecimalDigits int    `json:"decimal_digits"`
	Rounding      int    `json:"rounding"`
	Code          string `json:"code"`
	NamePlural    string `json:"name_plural"`
	Type          string `json:"type"`
}

type LatestRatesResponse struct {
	Data LatestRates `json:"data"`
}

type LatestRates map[string]float64

func GetFreeCurrencyAPIConfig(apiKey string) *config.CurrencyAPIConfig {
	var FreeCurrencyAPIConfig = config.NewCurrencyAPIConfig(
		// saving the response for a week because app.freecurrencyapi.com has a low limit
		// and this is a demo project, it's not important to have the latest data
		168*time.Hour,
		getGetCurrenciesURLFunc(apiKey),
		getGetLatestRatesURLFunc(apiKey),
		getCurrencyListFromResponseFunc,
		getLatestRatesFromResponse,
	)
	return FreeCurrencyAPIConfig
}

func getGetCurrenciesURLFunc(apiKey string) func() (*url.URL, error) {

	getCurrenciesURLFunc := func() (*url.URL, error) {
		currenciesEndpointUrlStr := fmt.Sprintf("%s%s", apiBaseURL, currenciesEndpointPath)

		currenciesEndpointUrl, err := url.Parse(currenciesEndpointUrlStr)
		if err != nil {
			return nil, err
		}

		currenciesEndpointQuery := currenciesEndpointUrl.Query()

		currenciesEndpointQuery.Set(apiKeyQueryParamKey, apiKey)

		currenciesEndpointUrl.RawQuery = currenciesEndpointQuery.Encode()

		return currenciesEndpointUrl, nil
	}

	return getCurrenciesURLFunc
}

func getGetLatestRatesURLFunc(apiKey string) func(string, string) (*url.URL, error) {

	getLatestRatesURLFunc := func(from string, to string) (*url.URL, error) {
		latestRatesEndpointUrlStr := fmt.Sprintf("%s%s", apiBaseURL, latestRatesEndpointPath)

		latestRatesEndpointUrl, err := url.Parse(latestRatesEndpointUrlStr)
		if err != nil {
			return nil, err
		}

		latestRatesEndpointQuery := latestRatesEndpointUrl.Query()

		currenciesQueryParamValue := strings.Join([]string{strings.ToUpper(from), strings.ToUpper(to)}, ",")

		latestRatesEndpointQuery.Set(apiKeyQueryParamKey, apiKey)
		latestRatesEndpointQuery.Set(currenciesQueryParamKey, currenciesQueryParamValue)

		latestRatesEndpointUrl.RawQuery = latestRatesEndpointQuery.Encode()

		return latestRatesEndpointUrl, nil
	}

	return getLatestRatesURLFunc
}

func getCurrencyListFromResponseFunc(httpResponseBodyBytes []byte) ([]string, error) {
	currencyCodes := []string{}
	currenciesResp := &CurrenciesResponse{}
	if err := json.Unmarshal(httpResponseBodyBytes, currenciesResp); err != nil {
		return currencyCodes, err
	}

	for code := range currenciesResp.Data {
		currencyCodes = append(currencyCodes, code)
	}
	return currencyCodes, nil
}

func getLatestRatesFromResponse(httpResponseBodyBytes []byte) (map[string]float64, error) {

	data := map[string]float64{}
	latestRatesResp := &LatestRatesResponse{}
	if err := json.Unmarshal(httpResponseBodyBytes, latestRatesResp); err != nil {
		return data, err
	}
	data = latestRatesResp.Data
	return data, nil
}
