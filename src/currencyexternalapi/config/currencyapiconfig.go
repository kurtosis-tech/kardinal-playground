package config

import (
	"net/url"
	"time"
)

type CurrencyAPIConfig struct {
	CacheDuration               time.Duration
	GetCurrenciesURLFunc        func() (*url.URL, error)
	GetLatestRatesURLFunc       func(from string, to string) (*url.URL, error)
	GetCurrencyListFromResponse func(httpResponseBodyBytes []byte) ([]string, error)
	GetLatestRatesFromResponse  func(httpResponseBodyBytes []byte) (map[string]float64, error)
}

func NewCurrencyAPIConfig(
	cacheDuration time.Duration,
	getCurrenciesURLFunc func() (*url.URL, error),
	getLatestRatesURLFunc func(from string, to string) (*url.URL, error),
	getCurrencyListFromResponse func(httpResponseBodyBytes []byte) ([]string, error),
	getLatestRatesFromResponse func(httpResponseBodyBytes []byte) (map[string]float64, error),
) *CurrencyAPIConfig {
	return &CurrencyAPIConfig{
		CacheDuration:               cacheDuration,
		GetCurrenciesURLFunc:        getCurrenciesURLFunc,
		GetLatestRatesURLFunc:       getLatestRatesURLFunc,
		GetCurrencyListFromResponse: getCurrencyListFromResponse,
		GetLatestRatesFromResponse:  getLatestRatesFromResponse,
	}
}
