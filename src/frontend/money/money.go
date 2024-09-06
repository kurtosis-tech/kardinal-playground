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

package money

import (
	"errors"
	productcatalogservice_rest_types "github.com/kurtosis-tech/new-obd/src/productcatalogservice/api/http_rest/types"
)

const (
	nanosMin = -999999999
	nanosMax = +999999999
	nanosMod = 1000000000
)

var (
	ErrInvalidValue        = errors.New("one of the specified money values is invalid")
	ErrMismatchingCurrency = errors.New("mismatching currency codes")
)

// IsValid checks if specified value has a valid units/nanos signs and ranges.
func IsValid(m *productcatalogservice_rest_types.Money) bool {

	nanos := *m.Nanos
	return signMatches(m) && validNanos(nanos)
}

func signMatches(m *productcatalogservice_rest_types.Money) bool {
	nanos := *m.Nanos
	units := *m.Units

	return nanos == 0 || units == 0 || (nanos < 0) == (units < 0)
}

func validNanos(nanos int32) bool { return nanosMin <= nanos && nanos <= nanosMax }

// IsZero returns true if the specified money value is equal to zero.
func IsZero(m *productcatalogservice_rest_types.Money) bool { return *m.Units == 0 && *m.Nanos == 0 }

// IsPositive returns true if the specified money value is valid and is
// positive.
func IsPositive(m *productcatalogservice_rest_types.Money) bool {
	return IsValid(m) && *m.Units > 0 || (*m.Units == 0 && *m.Nanos > 0)
}

// IsNegative returns true if the specified money value is valid and is
// negative.
func IsNegative(m *productcatalogservice_rest_types.Money) bool {
	return IsValid(m) && *m.Units < 0 || (*m.Units == 0 && *m.Nanos < 0)
}

// AreSameCurrency returns true if values l and r have a currency code and
// they are the same values.
func AreSameCurrency(l, r *productcatalogservice_rest_types.Money) bool {
	return l.CurrencyCode == r.CurrencyCode && *l.CurrencyCode != ""
}

// AreEquals returns true if values l and r are the equal, including the
// currency. This does not check validity of the provided values.
func AreEquals(l, r *productcatalogservice_rest_types.Money) bool {
	return l.CurrencyCode == r.CurrencyCode &&
		*l.Units == *r.Units && *l.Nanos == *r.Nanos
}

// Negate returns the same amount with the sign negated.
func Negate(m *productcatalogservice_rest_types.Money) *productcatalogservice_rest_types.Money {
	units := *m.Units
	nanos := *m.Nanos
	negativeUnits := -units
	negativeNanos := -nanos

	return &productcatalogservice_rest_types.Money{
		Units:        &negativeUnits,
		Nanos:        &negativeNanos,
		CurrencyCode: m.CurrencyCode}
}

// Must panics if the given error is not nil. This can be used with other
// functions like: "m := Must(Sum(a,b))".
func Must(v *productcatalogservice_rest_types.Money, err error) *productcatalogservice_rest_types.Money {
	if err != nil {
		panic(err)
	}
	return v
}

// Sum adds two values. Returns an error if one of the values are invalid or
// currency codes are not matching (unless currency code is unspecified for
// both).
func Sum(l, r *productcatalogservice_rest_types.Money) (*productcatalogservice_rest_types.Money, error) {
	if !IsValid(l) || !IsValid(r) {
		return &productcatalogservice_rest_types.Money{}, ErrInvalidValue
	} else if *l.CurrencyCode != *r.CurrencyCode {
		return &productcatalogservice_rest_types.Money{}, ErrMismatchingCurrency
	}
	units := *l.Units + *r.Units
	nanos := *l.Nanos + *r.Nanos

	if (units == 0 && nanos == 0) || (units >= 0 && nanos >= 0) || (units < 0 && nanos <= 0) {
		// same sign <units, nanos>
		units += int64(nanos / nanosMod)
		nanos = nanos % nanosMod
	} else {
		// different sign. nanos guaranteed to not to go over the limit
		if units > 0 {
			units--
			nanos += nanosMod
		} else {
			units++
			nanos -= nanosMod
		}
	}

	return &productcatalogservice_rest_types.Money{
		Units:        &units,
		Nanos:        &nanos,
		CurrencyCode: l.CurrencyCode}, nil
}

// MultiplySlow is a slow multiplication operation done through adding the value
// to itself n-1 times.
func MultiplySlow(m *productcatalogservice_rest_types.Money, n uint32) *productcatalogservice_rest_types.Money {
	out := m
	for n > 1 {
		out = Must(Sum(out, m))
		n--
	}
	return out
}
