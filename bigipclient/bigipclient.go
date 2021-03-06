/*-
 * Copyright (c) 2016-2018, F5 Networks, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR conditionS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package bigipclient

import (
	"crypto/tls"
	"io/ioutil"
	"net/http"
	"time"
)

// Client interface for the BigIPClient
//go:generate counterfeiter -o fakes/fake_client.go . Client
type Client interface {
	Get(url, user, pass string) ([]byte, error)
}

// BigIPClient is a wrapper around an http client
type BigIPClient struct {
	Client *http.Client
}

// DefaultClient returns a new default configured BIG-IP client
func DefaultClient() *BigIPClient {
	// We are going basic auth so need to disable cert checks
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true,
		},
	}
	client := &http.Client{
		Timeout:   60 * time.Second,
		Transport: tr,
	}
	return &BigIPClient{
		Client: client,
	}
}

// Get will attempt a HTTP GET request to the given URL and return a []byte
// with the response or an error.
func (c *BigIPClient) Get(url, user, pass string) ([]byte, error) {
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Accept", "application/json")
	req.SetBasicAuth(user, pass)

	resp, err := c.Client.Do(req)
	if err != nil {
		return nil, err
	}

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()

	return data, nil
}
