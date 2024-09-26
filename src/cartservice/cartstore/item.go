package cartstore

import "gorm.io/gorm"

type Item struct {
	gorm.Model
	UserID    string
	ProductID string
	Quantity  int32
}
