package function

func Handle(req handler.Request) (handler.Response, error) {
	var err error

	return handler.Response{
		Body: []byte("Try us out today!"),
		Header: map[string][]string{
			"X-Served-By": []string{"openfaas.com"},
		},
	}, err
}
