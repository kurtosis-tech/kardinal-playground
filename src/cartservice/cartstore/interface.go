package cartstore

import (
	"context"
	cartservice_rest_types "github.com/kurtosis-tech/new-obd/src/cartservice/api/http_rest/types"
)

type CartStore interface {
	AddItem(ctx context.Context, userID, productID string, quantity int32) error
	EmptyCart(ctx context.Context, userID string) error
	GetCart(ctx context.Context, userID string) (*cartservice_rest_types.Cart, error)
}
