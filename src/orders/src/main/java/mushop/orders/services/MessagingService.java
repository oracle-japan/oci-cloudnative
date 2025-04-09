/**
 ** Copyright © 2020, Oracle and/or its affiliates. All rights reserved.
 ** Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
 **/
package mushop.orders.services;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.MeterRegistry;
import mushop.orders.repositories.CustomerOrderRepository;
import mushop.orders.values.OrderUpdate;

import org.apache.kafka.clients.producer.ProducerRecord;
import java.lang.System.Logger;
import java.lang.System.Logger.Level;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Service
public class MessagingService {
    @Autowired
    private CustomerOrderRepository customerOrderRepository;
    
    @Autowired
    private MeterRegistry meterRegistry;
    
    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;
    
    private final Logger log = System.getLogger(MessagingService.class.getName());
    private final String ordersTopicName;
    private final String shipmentsTopicName;
    private ExecutorService messageProcessingPool;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public MessagingService(
            @Value("${mushop.messaging.topics.orders}") String ordersTopicName,
            @Value("${mushop.messaging.topics.shipments}") String shipmentsTopicName) {
        this.ordersTopicName = ordersTopicName;
        this.shipmentsTopicName = shipmentsTopicName;
        this.messageProcessingPool = Executors.newCachedThreadPool();
    }

    @PostConstruct
    public void init() {
        log.log(Level.INFO, "Initialized Kafka messaging service with topics: orders={}, shipments={}", 
                ordersTopicName, shipmentsTopicName);
    }


    public void dispatchToFulfillment(OrderUpdate order) throws JsonProcessingException {
        String message = objectMapper.writeValueAsString(order);
        ProducerRecord<String, String> record = new ProducerRecord<>(
            ordersTopicName, 
            null,
            order.getOrderId().toString(),
            message
        );
        kafkaTemplate.send(record)
            .whenComplete((result, ex) -> {
                if (ex == null) {
                    log.log(Level.INFO,"Message sent successfully to topic {} with offset {}", 
                        ordersTopicName, result.getRecordMetadata().offset());
                    ProducerRecord<String, String> sentRecord = result.getProducerRecord();
                    log.log(Level.INFO,"Message sent successfully. Headers after send: ");
                    sentRecord.headers().forEach(header -> {
                        log.log(Level.INFO,"  {} : {}", 
                            header.key(), 
                            new String(header.value(), StandardCharsets.UTF_8));
                    });
                } else {
                    log.log(Level.ERROR, "Unable to send message to topic {}: {}", 
                        ordersTopicName, ex.getMessage());
                }
            });
    }

    @KafkaListener(topics = "${mushop.messaging.topics.shipments}", groupId = "orders-service")
    public void handleMessage(String message) {
        messageProcessingPool.submit(() -> {
            try {
                final OrderUpdate update = objectMapper.readValue(message, OrderUpdate.class);
                customerOrderRepository.findById(update.getOrderId())
                    .ifPresent(order -> {
                        log.log(Level.DEBUG, "Updating order {}", order.getId());
                        order.setShipment(update.getShipment());
                        customerOrderRepository.save(order);
                        log.log(Level.INFO, "order {} is now {}", order.getId(), update.getShipment().getName());
                        meterRegistry.counter("orders.fulfillment_ack").increment();
                    });
            } catch (IOException e) {
                 log.log(Level.ERROR, "Failed reading shipping message", e);
            }
        });
    }
}