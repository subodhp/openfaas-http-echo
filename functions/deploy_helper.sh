#!/bin/bash

faas-cli remove -f go-http-echo.yml; sleep 10; faas-cli build -f go-http-echo.yml; sleep 10; faas-cli push -f go-http-echo.yml; sleep 10; faas-cli deploy -f go-http-echo.yml
