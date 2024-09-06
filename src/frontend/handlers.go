// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"context"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gorilla/mux"
	cartservice_rest_types "github.com/kurtosis-tech/new-obd/src/cartservice/api/http_rest/types"
	"github.com/kurtosis-tech/new-obd/src/frontend/consts"
	"github.com/kurtosis-tech/new-obd/src/frontend/money"
	productcatalogservice_rest_types "github.com/kurtosis-tech/new-obd/src/productcatalogservice/api/http_rest/types"
	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
)

type platformDetails struct {
	css      string
	provider string
}

var (
	isCymbalBrand = strings.ToLower(os.Getenv("CYMBAL_BRANDING")) == "true"
	templates     = template.Must(template.New("").
			Funcs(template.FuncMap{
			"renderMoney":        renderMoney,
			"renderCurrencyLogo": renderCurrencyLogo,
		}).ParseGlob("templates/*.html"))
	plat platformDetails
)

const (
	userID = "0494c5e0-dde0-48fa-a6d8-f7962f5476bf"
)

func (fe *frontendServer) homeHandler(w http.ResponseWriter, r *http.Request) {
	currencies, err := fe.currencyService.GetSupportedCurrencies(r.Context())
	if err != nil {
		renderHTTPError(r, w, errors.Wrapf(err, "error retrieving currencies"), http.StatusInternalServerError)
		return
	}

	setKardinalReqEditorFcn := getSetTraceIdHeaderRequestEditorFcn(r)

	productResponse, err := fe.productCatalogService.GetProductsWithResponse(r.Context(), setKardinalReqEditorFcn)
	if err != nil {
		renderHTTPError(r, w, errors.Wrapf(err, "could not retrieve products"), http.StatusInternalServerError)
		return
	}
	productsList := productResponse.JSON200

	cartResponse, err := fe.cartService.GetCartUserIdWithResponse(r.Context(), userID, setKardinalReqEditorFcn)
	if err != nil {
		renderHTTPError(r, w, errors.Wrap(err, "could not retrieve cart"), http.StatusInternalServerError)
		return
	}

	cart := cartResponse.JSON200

	type productView struct {
		Item  productcatalogservice_rest_types.Product
		Price *productcatalogservice_rest_types.Money
	}

	products := []productcatalogservice_rest_types.Product{}
	if productsList != nil {
		products = *productsList
	}

	ps := make([]productView, len(products))
	for i, p := range products {
		price, err := fe.currencyService.Convert(r.Context(), *p.PriceUsd.CurrencyCode, *p.PriceUsd.Units, *p.PriceUsd.Nanos, currentCurrency(r))
		if err != nil {
			renderHTTPError(r, w, errors.Wrapf(err, "could not convert currency for product #%s", *p.Id), http.StatusInternalServerError)
			return
		}
		newPV := productView{p, price}
		ps[i] = newPV
	}

	if err := templates.ExecuteTemplate(w, "home", map[string]interface{}{
		"session_id":    sessionID(r),
		"request_id":    r.Context().Value(ctxKeyRequestID{}),
		"user_currency": currentCurrency(r),
		"show_currency": true,
		"currencies":    currencies,
		"products":      ps,
		"cart_size":     cartSize(*cart.Items),
		"banner_color":  os.Getenv("BANNER_COLOR"), // illustrates canary deployments
		//"ad":                fe.chooseAd(r.Context(), []string{}, log), //TODO fix
		"platform_css":    plat.css,
		"platform_name":   plat.provider,
		"is_cymbal_brand": isCymbalBrand,
	}); err != nil {
		logrus.Error(err)
	}
}

func (fe *frontendServer) productHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	if id == "" {
		renderHTTPError(r, w, errors.New("product id not specified"), http.StatusBadRequest)
		return
	}

	setKardinalReqEditorFcn := getSetTraceIdHeaderRequestEditorFcn(r)

	fmt.Printf("product: %p\n", r.Context())
	productResponse, err := fe.productCatalogService.GetProductsIdWithResponse(r.Context(), id, setKardinalReqEditorFcn)
	if err != nil {
		renderHTTPError(r, w, errors.Wrapf(err, "could not retrieve product #%s", id), http.StatusInternalServerError)
		return
	}
	productFromCatalog := productResponse.JSON200

	currencies, err := fe.currencyService.GetSupportedCurrencies(r.Context())
	if err != nil {
		renderHTTPError(r, w, errors.Wrapf(err, "error retrieving currencies"), http.StatusInternalServerError)
		return
	}

	cartResponse, err := fe.cartService.GetCartUserIdWithResponse(r.Context(), userID, setKardinalReqEditorFcn)
	if err != nil {
		renderHTTPError(r, w, errors.Wrap(err, "could not retrieve cart"), http.StatusInternalServerError)
		return
	}

	cart := cartResponse.JSON200

	price, err := fe.currencyService.Convert(r.Context(), *productFromCatalog.PriceUsd.CurrencyCode, *productFromCatalog.PriceUsd.Units, *productFromCatalog.PriceUsd.Nanos, currentCurrency(r))
	if err != nil {
		renderHTTPError(r, w, errors.Wrapf(err, "could not convert currency for product #%s", *productFromCatalog.Id), http.StatusInternalServerError)
		return
	}

	var productInView struct {
		Item  productcatalogservice_rest_types.Product
		Price *productcatalogservice_rest_types.Money
	}
	var isProduct bool

	if productFromCatalog != nil {
		productInView = struct {
			Item  productcatalogservice_rest_types.Product
			Price *productcatalogservice_rest_types.Money
		}{*productFromCatalog, price}
		isProduct = true
	}

	if err := templates.ExecuteTemplate(w, "product", map[string]interface{}{
		"session_id":         sessionID(r),
		"request_id":         r.Context().Value(ctxKeyRequestID{}),
		"user_currency":      currentCurrency(r),
		"show_currency":      true,
		"currencies":         currencies,
		"product":            productInView,
		"cart_size":          cartSize(*cart.Items),
		"platform_css":       plat.css,
		"platform_name":      plat.provider,
		"is_cymbal_brand":    isCymbalBrand,
		"is_present_feature": false,
		"is_product":         isProduct,
		"id":                 id,
	}); err != nil {
		log.Println(err)
	}
}

func (fe *frontendServer) addToCartHandler(w http.ResponseWriter, r *http.Request) {
	quantity, _ := strconv.ParseUint(r.FormValue("quantity"), 10, 32)
	productID := r.FormValue("product_id")
	if productID == "" || quantity == 0 {
		renderHTTPError(r, w, errors.New("invalid form input"), http.StatusBadRequest)
		return
	}

	setKardinalReqEditorFcn := getSetTraceIdHeaderRequestEditorFcn(r)

	productResponse, err := fe.productCatalogService.GetProductsIdWithResponse(r.Context(), productID, setKardinalReqEditorFcn)
	if err != nil {
		renderHTTPError(r, w, errors.Wrapf(err, "could not retrieve product #%s", productID), http.StatusInternalServerError)
		return
	}
	p := productResponse.JSON200

	quantityInt32 := int32(quantity)
	userId := userID

	body := cartservice_rest_types.AddItemRequest{
		Item: &cartservice_rest_types.CartItem{
			ProductId: p.Id,
			Quantity:  &quantityInt32,
		},
		UserId: &userId,
	}
	postCartResponse, err := fe.cartService.PostCartWithResponse(r.Context(), body, setKardinalReqEditorFcn)
	logrus.Infof("Post cart response status code: %d", postCartResponse.StatusCode())
	if postCartResponse.StatusCode() != 200 || err != nil {
		renderHTTPError(r, w, errors.Wrapf(err, "could not retrieve execute post cart request for product #%s", productID), http.StatusInternalServerError)
		return
	}

	w.Header().Set("location", "/cart")
	w.WriteHeader(http.StatusFound)
}

func (fe *frontendServer) emptyCartHandler(w http.ResponseWriter, r *http.Request) {
	setKardinalReqEditorFcn := getSetTraceIdHeaderRequestEditorFcn(r)

	userId := userID
	if _, err := fe.cartService.DeleteCartUserId(r.Context(), userId, setKardinalReqEditorFcn); err != nil {
		renderHTTPError(r, w, errors.Wrap(err, "failed to empty cart"), http.StatusInternalServerError)
		return
	}
	w.Header().Set("location", "/")
	w.WriteHeader(http.StatusFound)
}

func (fe *frontendServer) viewCartHandler(w http.ResponseWriter, r *http.Request) {
	setKardinalReqEditorFcn := getSetTraceIdHeaderRequestEditorFcn(r)

	currencies, err := fe.currencyService.GetSupportedCurrencies(r.Context())
	if err != nil {
		renderHTTPError(r, w, errors.Wrapf(err, "error retrieving currencies"), http.StatusInternalServerError)
		return
	}

	cartResponse, err := fe.cartService.GetCartUserIdWithResponse(r.Context(), userID, setKardinalReqEditorFcn)
	if err != nil {
		renderHTTPError(r, w, errors.Wrap(err, "could not retrieve cart"), http.StatusInternalServerError)
		return
	}

	cart := cartResponse.JSON200

	type cartItemView struct {
		Item       productcatalogservice_rest_types.Product
		Quantity   int32
		IsAPresent bool
		Price      *productcatalogservice_rest_types.Money
	}
	items := make([]cartItemView, len(*cart.Items))
	currentCurrencyObj := currentCurrency(r)
	zeroNanos := int32(0)
	zeroUnits := int64(0)
	totalPrice := &productcatalogservice_rest_types.Money{
		CurrencyCode: &currentCurrencyObj,
		Nanos:        &zeroNanos,
		Units:        &zeroUnits,
	}

	cartItems := *cart.Items

	for i, item := range cartItems {
		productResponse, err := fe.productCatalogService.GetProductsIdWithResponse(r.Context(), *item.ProductId, setKardinalReqEditorFcn)
		if err != nil {
			renderHTTPError(r, w, errors.Wrapf(err, "could not retrieve product #%s", *item.ProductId), http.StatusInternalServerError)
			return
		}
		p := productResponse.JSON200
		price, err := fe.currencyService.Convert(r.Context(), *p.PriceUsd.CurrencyCode, *p.PriceUsd.Units, *p.PriceUsd.Nanos, currentCurrency(r))
		if err != nil {
			renderHTTPError(r, w, errors.Wrapf(err, "could not convert currency for product #%s", *item.ProductId), http.StatusInternalServerError)
			return
		}

		logrus.Debugf("Price is %+v", price)

		multPrice := money.MultiplySlow(price, uint32(*item.Quantity))

		prod := *p
		quan := *item.Quantity

		items[i] = cartItemView{
			Item:     prod,
			Quantity: quan,
			Price:    multPrice,
		}

		totalPrice = money.Must(money.Sum(totalPrice, multPrice))
	}

	year := time.Now().Year()
	if err := templates.ExecuteTemplate(w, "cart", map[string]interface{}{
		"session_id":    sessionID(r),
		"request_id":    r.Context().Value(ctxKeyRequestID{}),
		"user_currency": currentCurrency(r),
		"currencies":    currencies,
		//"recommendations":   recommendations,
		"cart_size": cartSize(*cart.Items),
		//"shipping_cost":     shippingCost,
		"show_currency":    true,
		"total_cost":       totalPrice,
		"items":            items,
		"expiration_years": []int{year, year + 1, year + 2, year + 3, year + 4},
		"platform_css":     plat.css,
		"platform_name":    plat.provider,
		"is_cymbal_brand":  isCymbalBrand,
		//"deploymentDetails": deploymentDetailsMap,
	}); err != nil {
		log.Println(err)
	}
}

func (fe *frontendServer) setCurrencyHandler(w http.ResponseWriter, r *http.Request) {
	log := r.Context().Value(ctxKeyLog{}).(logrus.FieldLogger)
	cur := r.FormValue("currency_code")
	log.WithField("curr.new", cur).WithField("curr.old", currentCurrency(r)).
		Debug("setting currency")

	if cur != "" {
		http.SetCookie(w, &http.Cookie{
			Name:   cookieCurrency,
			Value:  cur,
			MaxAge: cookieMaxAge,
		})
	}
	referer := r.Header.Get("referer")
	if referer == "" {
		referer = "/"
	}
	w.Header().Set("Location", referer)
	w.WriteHeader(http.StatusFound)
}

func (plat *platformDetails) setPlatformDetails(env string) {
	if env == "aws" {
		plat.provider = "AWS"
		plat.css = "aws-platform"
	} else if env == "onprem" {
		plat.provider = "On-Premises"
		plat.css = "onprem-platform"
	} else if env == "azure" {
		plat.provider = "Azure"
		plat.css = "azure-platform"
	} else if env == "gcp" {
		plat.provider = "Google Cloud"
		plat.css = "gcp-platform"
	} else if env == "alibaba" {
		plat.provider = "Alibaba Cloud"
		plat.css = "alibaba-platform"
	} else {
		plat.provider = "local"
		plat.css = "local"
	}
}

func renderMoney(money productcatalogservice_rest_types.Money) string {
	currencyLogo := renderCurrencyLogo(*money.CurrencyCode)
	units := *money.Units
	nanos := *money.Nanos
	return fmt.Sprintf("%s%d.%02d", currencyLogo, units, nanos/10000000)
}

func sessionID(r *http.Request) string {
	v := r.Context().Value(ctxKeySessionID{})
	if v != nil {
		return v.(string)
	}
	return ""
}

func currentCurrency(r *http.Request) string {
	c, _ := r.Cookie(cookieCurrency)
	if c != nil {
		return c.Value
	}
	return defaultCurrency
}

func renderCurrencyLogo(currencyCode string) string {
	logos := map[string]string{
		"USD": "$",
		"CAD": "$",
		"JPY": "¥",
		"EUR": "€",
		"TRY": "₺",
		"GBP": "£",
	}

	logo := "$" // default
	if val, ok := logos[currencyCode]; ok {
		logo = val
	}
	return logo
}

func renderHTTPError(r *http.Request, w http.ResponseWriter, err error, code int) {
	logrus.Errorf("requested error: %s", err)
	errMsg := fmt.Sprintf("%+v", err)

	w.WriteHeader(code)

	if templateErr := templates.ExecuteTemplate(w, "error", map[string]interface{}{
		"session_id":  sessionID(r),
		"request_id":  r.Context().Value(ctxKeyRequestID{}),
		"error":       errMsg,
		"status_code": code,
		"status":      http.StatusText(code),
		//"deploymentDetails": deploymentDetailsMap,
	}); templateErr != nil {
		log.Println(templateErr)
	}
}

func cartSize(c []cartservice_rest_types.CartItem) int {
	cartSize := 0
	for _, item := range c {
		cartSize += int(*item.Quantity)
	}
	return cartSize
}

func getSetTraceIdHeaderRequestEditorFcn(upsTreamRequest *http.Request) func(ctx context.Context, req *http.Request) error {
	traceID := upsTreamRequest.Header.Get(consts.KardinalTraceIdHeaderKey)

	setKardinalReqEditorFcn := func(ctx context.Context, req *http.Request) error {
		req.Header.Set(consts.KardinalTraceIdHeaderKey, traceID)
		return nil
	}

	return setKardinalReqEditorFcn
}
