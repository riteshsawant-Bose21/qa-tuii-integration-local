package utils

import (
	"reflect"
	"testing"
)

func TestCoerceStringSlice(t *testing.T) {
	tests := []struct {
		name string
		in   any
		want []string
	}{
		{
			name: "nil returns empty slice",
			in:   nil,
			want: []string{},
		},
		{
			name: "string slice is normalized",
			in:   []string{" lobby ", "", "gym"},
			want: []string{"lobby", "gym"},
		},
		{
			name: "interface slice from json is normalized",
			in:   []interface{}{"lobby", " gym "},
			want: []string{"lobby", "gym"},
		},
		{
			name: "string is not coerced",
			in:   "lobby, gym",
			want: []string{},
		},
		{
			name: "empty string returns empty slice",
			in:   " ",
			want: []string{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := CoerceStringSlice(tt.in)
			if !reflect.DeepEqual(got, tt.want) {
				t.Fatalf("CoerceStringSlice(%#v) = %#v, want %#v", tt.in, got, tt.want)
			}
		})
	}
}
