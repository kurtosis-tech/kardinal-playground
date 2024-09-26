package cartstore

import (
	"context"
	"fmt"
	"net"
	"time"

	cartservice_rest_types "github.com/kurtosis-tech/new-obd/src/cartservice/api/http_rest/types"
	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type Db struct {
	db *gorm.DB
}

func NewDb(
	uri string,
	host string,
	username string,
	password string,
	name string,
	port string,
) (*Db, error) {
	var dsn string
	if uri != "" {
		dsn = uri
	} else {
		dsn = fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s", host, username, password, name, port)
	}
	maxRetries := 5
	initialBackoff := 1 * time.Second
	backoffMultiplier := 2.0

	db, err := retryConnect(dsn, maxRetries, initialBackoff, backoffMultiplier)
	if err != nil {
		return nil, errors.Wrap(err, fmt.Sprintf("An error occurred opening the connection to the database with dsn %s", dsn))
	}

	logrus.Info("connected to database")

	if err = db.AutoMigrate(&Item{}); err != nil {
		return nil, errors.Wrap(err, "An error occurred migrating the database")
	}

	return &Db{
		db: db,
	}, nil
}

func retryConnect(dsn string, maxRetries int, initialBackoff time.Duration, backoffMultiplier float64) (*gorm.DB, error) {
	var (
		err error
		db  *gorm.DB
	)
	backoff := initialBackoff

	for i := 0; i < maxRetries; i++ {
		// Need to change the resolver to resolve all addresses to use ipv4 instead of ipv6
		net.DefaultResolver = &net.Resolver{
			PreferGo: true,
			Dial: func(ctx context.Context, network, address string) (net.Conn, error) {
				d := net.Dialer{
					Timeout: time.Millisecond * time.Duration(10000),
				}
				return d.DialContext(ctx, "tcp4", address)
			},
		}
		logrus.Infof("Attempting to connecting to datbase with dsn: %v\n", dsn)
		db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
		if err != nil {
			logrus.Debugf("An error occurred opening the connection to the database with dsn %s", dsn)
		} else {
			return db, nil
		}

		// Log the error and wait before retrying
		logrus.Debugf("Attempt %d failed: %v\n", i+1, err)
		time.Sleep(backoff)

		// Increase backoff duration
		backoff = time.Duration(float64(backoff) * backoffMultiplier)
	}

	return nil, fmt.Errorf("connection to db failed after %d retries: %w", maxRetries, err)
}

func (db *Db) Close() error {
	sqlDb, err := db.db.DB()
	if err != nil {
		return errors.Wrap(err, "An error occurred closing the database connection")
	}

	if err = sqlDb.Close(); err != nil {
		return errors.Wrap(err, "An error occurred closing the database connection")
	}

	return nil
}

func (db *Db) AddItem(ctx context.Context, userID, productID string, quantity int32) error {
	item := &Item{
		UserID:    userID,
		ProductID: productID,
		Quantity:  quantity,
	}

	result := db.db.WithContext(ctx).Create(item)
	if result.Error != nil {
		logrus.Infof("An error occurred creating the item in the dB. Error: %s", result.Error.Error())
		return errors.Wrap(result.Error, fmt.Sprintf("An internal error has occurred creating the item '%+v'", item))
	}
	logrus.Debugf("Success! Stored item %+v in database", item)
	return nil
}

func (db *Db) EmptyCart(ctx context.Context, userID string) error {
	result := db.db.WithContext(ctx).Where("1 = 1").Delete(&Item{})
	if result.Error != nil {
		return errors.Wrap(result.Error, fmt.Sprintf("An internal error has occurred while empty the cart"))
	}
	return nil
}

func (db *Db) GetCart(ctx context.Context, userID string) (*cartservice_rest_types.Cart, error) {
	var items []Item

	result := db.db.WithContext(ctx).Where("user_id = ?", userID).Find(&items)
	if result.Error != nil {
		return nil, errors.Wrap(result.Error, fmt.Sprintf("An internal error has occurred while getting the cart"))
	}

	cartItems := []cartservice_rest_types.CartItem{}

	for _, item := range items {
		prodId := item.ProductID
		quan := item.Quantity
		cartItemObj := cartservice_rest_types.CartItem{
			ProductId: &prodId,
			Quantity:  &quan,
		}
		cartItems = append(cartItems, cartItemObj)
	}

	cart := &cartservice_rest_types.Cart{
		UserId: &userID,
		Items:  &cartItems,
	}

	return cart, nil
}
