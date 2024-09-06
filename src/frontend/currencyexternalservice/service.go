package currencyexternalservice

import (
	"context"
	"github.com/kurtosis-tech/new-obd/src/currencyexternalapi"
	productcatalogservice_rest_types "github.com/kurtosis-tech/new-obd/src/productcatalogservice/api/http_rest/types"
)

type CurrencyExternalService struct {
	primaryApi *currencyexternalapi.CurrencyAPI
}

func NewService(primaryApi *currencyexternalapi.CurrencyAPI) *CurrencyExternalService {
	return &CurrencyExternalService{primaryApi: primaryApi}
}

func (s *CurrencyExternalService) GetSupportedCurrencies(ctx context.Context) ([]string, error) {

	var (
		currencyCodes []string
		err           error
	)

	currencyCodes, err = s.primaryApi.GetSupportedCurrencies(ctx)
	if err != nil {
		return nil, err
	}

	return currencyCodes, nil
}

func (s *CurrencyExternalService) Convert(ctx context.Context, fromCode string, fromUnits int64, fromNanos int32, to string) (*productcatalogservice_rest_types.Money, error) {

	var (
		money = &productcatalogservice_rest_types.Money{}
		code  string
		units int64
		nanos int32
		err   error
	)

	code, units, nanos, err = s.primaryApi.Convert(ctx, fromCode, fromUnits, fromNanos, to)
	if err != nil {
		return nil, err
	}

	money.CurrencyCode = &code
	money.Units = &units
	money.Nanos = &nanos

	return money, nil
}
