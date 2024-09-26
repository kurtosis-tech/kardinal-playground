package currencyexternalapi

import (
	"sync"
	"time"
)

// CacheItem represents an item in the cache
type CacheItem struct {
	Body       []byte
	Expiration time.Time
}

// Cache is a simple in-memory cache
type Cache struct {
	mu    sync.RWMutex
	items map[string]CacheItem
}

// NewCache creates a new Cache instance
func NewCache() *Cache {
	return &Cache{
		items: make(map[string]CacheItem),
	}
}

// Get retrieves an item from the cache
func (c *Cache) Get(key string) ([]byte, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	item, ok := c.items[key]
	if !ok {
		return nil, false
	}
	if item.Expiration.Before(time.Now()) {
		// Remove expired item from cache
		delete(c.items, key)
		return nil, false
	}
	return item.Body, true
}

// Set adds an item to the cache
func (c *Cache) Set(key string, body []byte, duration time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.items[key] = CacheItem{
		Body:       body,
		Expiration: time.Now().Add(duration),
	}
}
