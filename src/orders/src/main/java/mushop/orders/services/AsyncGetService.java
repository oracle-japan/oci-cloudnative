/**
 ** Copyright © 2020, Oracle and/or its affiliates. All rights reserved.
 ** Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
 **/
package  mushop.orders.services;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import mushop.orders.config.RestProxyTemplate;
import java.lang.System.Logger;
import java.lang.System.Logger.Level;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.hateoas.EntityModel;
import org.springframework.hateoas.MediaTypes;
import org.springframework.hateoas.mediatype.hal.Jackson2HalModule;
import org.springframework.hateoas.server.core.TypeReferences;
import org.springframework.http.MediaType;
import org.springframework.http.RequestEntity;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.AsyncResult;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;
import java.net.URI;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Future;

import static org.springframework.hateoas.MediaTypes.HAL_JSON;

@Service
public class AsyncGetService {
    private final Logger log = System.getLogger(AsyncGetService.class.getName());

    private final RestProxyTemplate restProxyTemplate;

    private final RestTemplate halTemplate;

    @Autowired
    public AsyncGetService(RestProxyTemplate restProxyTemplate) {
        this.restProxyTemplate = restProxyTemplate;
        this.halTemplate = new RestTemplate(restProxyTemplate.getRestTemplate().getRequestFactory());

        ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, true);
        objectMapper.registerModule(new Jackson2HalModule());
        MappingJackson2HttpMessageConverter halConverter = new MappingJackson2HttpMessageConverter();
        halConverter.setSupportedMediaTypes(Arrays.asList(MediaTypes.HAL_JSON));
        halConverter.setObjectMapper(objectMapper);
        halTemplate.setMessageConverters(Collections.singletonList(halConverter));
    }

    @Async
    public <T> Future<EntityModel<T>> getResource(URI url, TypeReferences.EntityModelType<T> type) throws
            InterruptedException, IOException {
        RequestEntity<Void> request = RequestEntity.get(url).accept(HAL_JSON).build();
        log.log(Level.DEBUG, "Requesting: " + request.toString());
        EntityModel<T> body = restProxyTemplate.getRestTemplate().exchange(request, type).getBody();
        log.log(Level.DEBUG, "Received: " + body.toString());
        return new AsyncResult<>(body);
    }
    
    @Async
    public <T> Future<T> getObject(URI url,ParameterizedTypeReference<T> type) throws
            InterruptedException, IOException {
        RequestEntity<Void> request = RequestEntity.get(url).accept(MediaType.APPLICATION_JSON).accept(HAL_JSON).build();
        log.log(Level.DEBUG, "Requesting: " + request.toString());
        ResponseEntity<T> body = restProxyTemplate.getRestTemplate().exchange(request, type);
        log.log(Level.DEBUG, "ReceivedCustomer: " + body.toString());
        return new AsyncResult<T>(body.getBody());
    }

    @Async
    public <T> Future<EntityModel<T>> getDataList(URI url, TypeReferences.EntityModelType<T> type) throws
            InterruptedException, IOException {
        RequestEntity<Void> request = RequestEntity.get(url).accept(HAL_JSON).build();
        log.log(Level.DEBUG, "Requesting: " + request.toString());
        EntityModel<T> body = restProxyTemplate.getRestTemplate().exchange(request, type).getBody();
        log.log(Level.DEBUG, "Received: " + body.toString());
        return new AsyncResult<>(body);
    }

    @Async
    public <T> Future<List<T>> getDataList(URI url, ParameterizedTypeReference<List<T>> type) throws
            InterruptedException, IOException {
        RequestEntity<Void> request = RequestEntity.get(url).accept(MediaType.APPLICATION_JSON).build();
        log.log(Level.DEBUG, "Requesting: " + request.toString());
        List<T> body = restProxyTemplate.getRestTemplate().exchange(request, type).getBody();
        log.log(Level.DEBUG, "Received: " + body.toString());
        return new AsyncResult<>(body);
    }

    @Async
    public <T, B> Future<T> postResource(URI uri, B body, ParameterizedTypeReference<T> returnType) {
        RequestEntity<B> request = RequestEntity.post(uri).contentType(MediaType.APPLICATION_JSON).accept(MediaType
                .APPLICATION_JSON).body(body);
        log.log(Level.DEBUG, "Requesting: " + request.toString());
        T responseBody = restProxyTemplate.getRestTemplate().exchange(request, returnType).getBody();
        log.log(Level.DEBUG, "Received: " + responseBody);
        return new AsyncResult<>(responseBody);
    }

    @Async
    public void deleteResource(URI uri) {
        log.log(Level.DEBUG, "Deleteing: " + uri.toString());
        restProxyTemplate.getRestTemplate().delete(uri);
    }
}
