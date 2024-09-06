package main

import (
	"context"
	cartservice_server_rest_server "github.com/kurtosis-tech/new-obd/src/cartservice/api/http_rest/server"
	cartservice_rest_types "github.com/kurtosis-tech/new-obd/src/cartservice/api/http_rest/types"
	"github.com/kurtosis-tech/new-obd/src/cartservice/cartstore"
	"github.com/sirupsen/logrus"
	"time"
)

type Server struct {
	Store cartstore.CartStore
}

func NewServer(store cartstore.CartStore) Server {
	return Server{Store: store}
}

func (s Server) GetHealth(ctx context.Context, request cartservice_server_rest_server.GetHealthRequestObject) (cartservice_server_rest_server.GetHealthResponseObject, error) {

	status := "ok"
	now := time.Now()

	response := cartservice_rest_types.HealthResponse{
		Status:    &status,
		Timestamp: &now,
	}

	return cartservice_server_rest_server.GetHealth200JSONResponse(response), nil
}

func (s Server) PostCart(ctx context.Context, object cartservice_server_rest_server.PostCartRequestObject) (cartservice_server_rest_server.PostCartResponseObject, error) {
	logrus.Infof("Post cart request - UserID: %s, ProductID: %s, Quantity: %d", *object.Body.UserId, *object.Body.Item.ProductId, *object.Body.Item.Quantity)
	if err := s.Store.AddItem(ctx, *object.Body.UserId, *object.Body.Item.ProductId, *object.Body.Item.Quantity); err != nil {
		logrus.Infof("An error occurred storing the item in the store. Error: %s", err.Error())
		return nil, err
	}
	return cartservice_server_rest_server.PostCart200JSONResponse{}, nil
}

func (s Server) GetCartUserId(ctx context.Context, request cartservice_server_rest_server.GetCartUserIdRequestObject) (cartservice_server_rest_server.GetCartUserIdResponseObject, error) {
	cart, err := s.Store.GetCart(ctx, request.UserId)
	if err != nil {
		return nil, err
	}

	response := cartservice_rest_types.Cart{
		UserId: cart.UserId,
		Items:  cart.Items,
	}

	return cartservice_server_rest_server.GetCartUserId200JSONResponse(response), nil
}

func (s Server) DeleteCartUserId(ctx context.Context, request cartservice_server_rest_server.DeleteCartUserIdRequestObject) (cartservice_server_rest_server.DeleteCartUserIdResponseObject, error) {
	if err := s.Store.EmptyCart(ctx, request.UserId); err != nil {
		return nil, err
	}
	return cartservice_server_rest_server.DeleteCartUserId200JSONResponse{}, nil
}
