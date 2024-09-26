package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	productcatalogservice_server_rest_server "github.com/kurtosis-tech/new-obd/src/productcatalogservice/api/http_rest/server"
	productcatalogservice_rest_types "github.com/kurtosis-tech/new-obd/src/productcatalogservice/api/http_rest/types"
	"github.com/sirupsen/logrus"
	"io/ioutil"
	"sync"
	"time"
)

type ListProductsResponse struct {
	Products []productcatalogservice_rest_types.Product `json:"products,omitempty"`
}

type Server struct {
	sync.Mutex
	products []productcatalogservice_rest_types.Product
}

func NewServer() Server {
	return Server{}
}

func (s Server) GetHealth(ctx context.Context, request productcatalogservice_server_rest_server.GetHealthRequestObject) (productcatalogservice_server_rest_server.GetHealthResponseObject, error) {

	status := "ok"
	now := time.Now()

	response := productcatalogservice_rest_types.HealthResponse{
		Status:    &status,
		Timestamp: &now,
	}

	return productcatalogservice_server_rest_server.GetHealth200JSONResponse(response), nil
}

func (s Server) GetProducts(ctx context.Context, request productcatalogservice_server_rest_server.GetProductsRequestObject) (productcatalogservice_server_rest_server.GetProductsResponseObject, error) {
	products := s.parseCatalog()

	return productcatalogservice_server_rest_server.GetProducts200JSONResponse(products), nil
}

func (s Server) GetProductsId(ctx context.Context, request productcatalogservice_server_rest_server.GetProductsIdRequestObject) (productcatalogservice_server_rest_server.GetProductsIdResponseObject, error) {

	var found productcatalogservice_rest_types.Product
	products := s.parseCatalog()
	for _, p := range products {
		if request.Id == *p.Id {
			found = p
		}
	}
	if &found == nil {
		return nil, errors.New(fmt.Sprintf("product with ID %s not found", request.Id))
	}

	return productcatalogservice_server_rest_server.GetProductsId200JSONResponse(found), nil
}

func (s Server) readCatalogFile() (*ListProductsResponse, error) {
	s.Lock()
	defer s.Unlock()
	catalogJSON, err := ioutil.ReadFile("data/products.json")
	if err != nil {
		logrus.Errorf("failed to open product catalog json file: %v", err)
		return nil, err
	}

	catalog := &ListProductsResponse{}
	if err := json.Unmarshal(catalogJSON, catalog); err != nil {
		logrus.Warnf("failed to parse the catalog JSON: %v", err)
		return nil, err
	}
	logrus.Info("successfully parsed product catalog json")
	return catalog, nil
}

func (s Server) parseCatalog() []productcatalogservice_rest_types.Product {
	if len(s.products) == 0 {
		catalog, err := s.readCatalogFile()
		if err != nil {
			return []productcatalogservice_rest_types.Product{}
		}
		s.products = catalog.Products
	}
	return s.products
}
