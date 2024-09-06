package ghgist

import (
	"encoding/json"
	"fmt"
	"github.com/kurtosis-tech/new-obd/src/currencyexternalapi/config"
	"net/url"
	"time"
)

const (
	apiBaseURL              = "https://gist.githubusercontent.com/leoporoli/"
	currenciesEndpointPath  = "4801500594b953e33fb87d2a34d31281/raw/dbb5537bf7f4cbe90cfca3f45fc7712d28a63944/currencies.json"
	latestRatesEndpointPath = "b84dc6e408cfeb4319840c1daf8bbc1f/raw/4257228f98aeb5ae1f0d4f7e258e9295c9c8cad8/latest.json"
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

var GHGistCurrencyAPIConfig = config.NewCurrencyAPIConfig(
	5*time.Second,
	getCurrenciesURL,
	getLatestRatesURL,
	getCurrencyListFromResponseFunc,
	getLatestRatesFromResponse,
)

func getCurrenciesURL() (*url.URL, error) {
	currenciesEndpointUrlStr := fmt.Sprintf("%s%s", apiBaseURL, currenciesEndpointPath)

	currenciesEndpointUrl, err := url.Parse(currenciesEndpointUrlStr)
	if err != nil {
		return nil, err
	}

	return currenciesEndpointUrl, nil
}

func getLatestRatesURL(from string, to string) (*url.URL, error) {
	latestRatesEndpointUrlStr := fmt.Sprintf("%s%s", apiBaseURL, latestRatesEndpointPath)

	latestRatesEndpointUrl, err := url.Parse(latestRatesEndpointUrlStr)
	if err != nil {
		return nil, err
	}

	return latestRatesEndpointUrl, nil
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
