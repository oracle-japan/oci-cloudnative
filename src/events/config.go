/**
 * Copyright © 2020, Oracle and/or its affiliates. All rights reserved.
 * The Universal Permissive License (UPL), Version 1.0
 */
package events

import (
	"os"

	"github.com/oracle/oci-go-sdk/v65/common"
	"github.com/oracle/oci-go-sdk/v65/common/auth"
	"github.com/oracle/oci-go-sdk/v65/example/helpers"
	"github.com/oracle/oci-go-sdk/v65/streaming"
)

// EnvironmentConfigurationProvider uses environment variables to get OCI config
func EnvironmentConfigurationProvider() (common.ConfigurationProvider, error) {
	provider, err := auth.InstancePrincipalConfigurationProvider()
	helpers.FatalIfError(err)
	return provider, err
}

// GetStreamClient returns a streaming client with the given configuration provider
func GetStreamClient(provider common.ConfigurationProvider) (streaming.StreamClient, error) {
	var endpoint string
	endpoint = os.Getenv("MESSAGES_ENDPOINT")
	if endpoint == "" {
		region, _ := provider.Region()
		endpoint = "https://streaming." + region + ".oci.oraclecloud.com"
	}
	return streaming.NewStreamClientWithConfigurationProvider(provider, endpoint)
}

// GetStreamID returns the events streamId
func GetStreamID() (streamId string) {
	return os.Getenv("STREAM_ID")
}
