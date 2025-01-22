/**
 ** Copyright © 2020, Oracle and/or its affiliates. All rights reserved.
 ** Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
 **/
package  mushop.orders.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.context.annotation.Bean;
import org.springframework.beans.factory.annotation.Autowired;

import jakarta.annotation.PostConstruct;
import java.net.InetSocketAddress;
import java.net.Proxy;

@Component
public final class RestProxyTemplate {
    private final Logger logger = LoggerFactory.getLogger(getClass());

    private RestTemplate restTemplate;  

    @Value("${proxy.host:}")
    private String host;

    @Value("${proxy.port:}")
    private String port;

    public RestProxyTemplate() {
        this.restTemplate = new RestTemplate();
    }

    @Bean
    public RestTemplate restTemplate() {
        RestTemplate template = new RestTemplate();
        
        if (!host.isEmpty() && !port.isEmpty()) {
            int portNr = -1;
            try {
                portNr = Integer.parseInt(port);
            } catch (NumberFormatException e) {
                logger.error("Unable to parse the proxy port number");
                return template;
            }
            
            SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
            InetSocketAddress address = new InetSocketAddress(host, portNr);
            Proxy proxy = new Proxy(Proxy.Type.HTTP, address);
            factory.setProxy(proxy);
            
            template.setRequestFactory(factory);
        }
        
        this.restTemplate = template;  
        return template;
    }

    public RestTemplate getRestTemplate() {
        return restTemplate;
    }
}
