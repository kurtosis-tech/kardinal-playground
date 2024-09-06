package jsdelivr

import (
	"encoding/json"
	"fmt"
	"github.com/kurtosis-tech/new-obd/src/currencyexternalapi/config"
	"net/url"
	"strings"
	"time"
)

const (
	apiBaseURL              = "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/"
	apiKeyQueryParamKey     = "apikey"
	currenciesEndpointPath  = "currencies.json"
	latestRatesEndpointPath = "currencies/usd.json"
)

type LatestRatesResponse struct {
	Date string             `json:"date"`
	Usd  map[string]float64 `json:"usd"`
}

func GetJsdelivrAPIConfig(apiKey string) *config.CurrencyAPIConfig {
	var JsdelivrAPIConfig = config.NewCurrencyAPIConfig(
		5*time.Second,
		getGetCurrenciesURLFunc(apiKey),
		getGetLatestRatesURLFunc(apiKey),
		getCurrencyListFromResponseFunc,
		getLatestRatesFromResponse,
	)
	return JsdelivrAPIConfig
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

		latestRatesEndpointQuery.Set(apiKeyQueryParamKey, apiKey)

		latestRatesEndpointUrl.RawQuery = latestRatesEndpointQuery.Encode()

		return latestRatesEndpointUrl, nil
	}

	return getLatestRatesURLFunc
}

func getCurrencyListFromResponseFunc(httpResponseBodyBytes []byte) ([]string, error) {
	currencyCodes := []string{}
	currenciesResp := &map[string]string{}
	if err := json.Unmarshal(httpResponseBodyBytes, currenciesResp); err != nil {
		return currencyCodes, err
	}

	for code := range *currenciesResp {
		upperCode := strings.ToUpper(code)
		currencyCodes = append(currencyCodes, upperCode)
	}
	return currencyCodes, nil
}

func getLatestRatesFromResponse(httpResponseBodyBytes []byte) (map[string]float64, error) {

	data := map[string]float64{}
	latestRatesResp := &LatestRatesResponse{}
	if err := json.Unmarshal(httpResponseBodyBytes, latestRatesResp); err != nil {
		return data, err
	}
	data = latestRatesResp.Usd
	dataUpperCode := map[string]float64{}
	for code, rate := range data {
		upperCode := strings.ToUpper(code)
		dataUpperCode[upperCode] = rate
	}

	//add USD
	dataUpperCode["USD"] = 1
	return dataUpperCode, nil
}
