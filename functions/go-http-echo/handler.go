package function

import (
	"fmt"
	"net/http"
	"strings"

	handler "github.com/openfaas-incubator/go-function-sdk"
)

// Handle a function invocation
func Handle(req handler.Request) (handler.Response, error) {
	var err error
	var message strings.Builder

	message.WriteString(fmt.Sprintf("Hello world, input was: %s\n", string(req.Body)))

	message.WriteString(fmt.Sprintf("Headers Received from Caller: \n"))

	for name, values := range req.Header {
		for _, value := range values {
			message.WriteString(fmt.Sprintf("%s: %s\n", name, value))
		}
	}

	return handler.Response{
		Body:       []byte(message.String()),
		StatusCode: http.StatusOK,
	}, err
}
