package mushop;
/**
 ** Copyright © 2020, Oracle and/or its affiliates. All rights reserved.
 ** Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
 **/

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Collections;
import java.util.Properties;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import org.apache.kafka.clients.CommonClientConfigs;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.config.SaslConfigs;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.apache.kafka.common.serialization.StringSerializer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fasterxml.jackson.databind.ObjectMapper;

import io.micrometer.core.instrument.MeterRegistry;
import io.micronaut.context.annotation.Context;
import io.micronaut.context.annotation.Value;
import io.micronaut.core.annotation.Introspected;
import io.opentelemetry.instrumentation.kafkaclients.v2_6.TracingConsumerInterceptor;
import io.opentelemetry.instrumentation.kafkaclients.v2_6.TracingProducerInterceptor;
import jakarta.annotation.PostConstruct;
import jakarta.inject.Singleton;

@Context
@Singleton
@Introspected
public class FulfillmentService {

    private static final Logger log = LoggerFactory.getLogger(FulfillmentService.class);
    private final ObjectMapper objectMapper = new ObjectMapper();
    
    private final KafkaProducer<String, String> producer;
    private KafkaConsumer<String, String> consumer;
    private Properties consumerProps;
    private final ExecutorService messageProcessingPool;
    private final MeterRegistry meterRegistry;
    
    @Value("${mushop.messaging.subjects.orders}")
    private String mushopOrdersSubject;
    
    @Value("${mushop.messaging.subjects.shipments}")
    private String mushopShipmentsSubject;
    
    @Value("${mushop.messaging.simulation-delay}")
    private Long simulationDelay;

    public FulfillmentService(MeterRegistry meterRegistry) {
        log.info("FulfillmentService constructor called");  
        messageProcessingPool = Executors.newCachedThreadPool();
        this.meterRegistry = meterRegistry;

        Properties producerProps = new Properties();
        producerProps.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, System.getenv("KAFKA_BOOTSTRAP_SERVERS"));
        producerProps.put(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");
        producerProps.put(SaslConfigs.SASL_MECHANISM, "PLAIN");
        producerProps.put(SaslConfigs.SASL_JAAS_CONFIG, System.getenv("KAFKA_CONFIG"));
        producerProps.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        producerProps.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        producerProps.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, "false");
        producerProps.put(ProducerConfig.MAX_BLOCK_MS_CONFIG, "30000");
        producerProps.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG, TracingProducerInterceptor.class.getName());
        this.producer = new KafkaProducer<>(producerProps);

        this.consumerProps = new Properties();
        consumerProps.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, System.getenv("KAFKA_BOOTSTRAP_SERVERS"));
        consumerProps.put(ConsumerConfig.GROUP_ID_CONFIG, "fulfillment-service");
        consumerProps.put(CommonClientConfigs.SECURITY_PROTOCOL_CONFIG, "SASL_SSL");
        consumerProps.put(SaslConfigs.SASL_MECHANISM, "PLAIN");
        consumerProps.put(SaslConfigs.SASL_JAAS_CONFIG, System.getenv("KAFKA_CONFIG"));
        consumerProps.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        consumerProps.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        consumerProps.put(ConsumerConfig.INTERCEPTOR_CLASSES_CONFIG, TracingConsumerInterceptor.class.getName());
        consumerProps.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        consumerProps.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "true");
    }

    @PostConstruct
    void init() {
        log.info("PostConstruct init() called");
        log.info("ServiceReadyEvent received. Orders subject: {}", mushopOrdersSubject);
        this.consumer = new KafkaConsumer<>(consumerProps);

        Thread consumerThread = new Thread(() -> {
            try {
                log.info("Subscribing to topic {}", mushopOrdersSubject);
                consumer.subscribe(Collections.singletonList(mushopOrdersSubject));

                while (!Thread.currentThread().isInterrupted()) {
                    ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(100));
                    for (ConsumerRecord<String, String> record : records) {
                        try {
                            log.info("Message received. Topic: {}, Partition: {}, Offset: {}", 
                            record.topic(), record.partition(), record.offset());
                            log.info("Headers:");
                            record.headers().forEach(header -> {
                                log.info("  {} : {}", 
                                    header.key(), 
                                    new String(header.value(), StandardCharsets.UTF_8));
                            });
                            OrderUpdate update = handleMessage(record);
                            meterRegistry.counter("orders.received", "app", "fulfillment").increment();
                            fulfillOrder(update);
                        } catch (Exception e) {
                            log.error("Error processing message", e);
                        }
                    }
                }
            } catch (Exception e) {
                log.error("Fatal error in consumer loop", e);
            } finally {
                consumer.close();
            }
        }, "kafka-consumer-thread");
        
        consumerThread.setDaemon(true);
        consumerThread.start();
        log.info("Started Kafka consumer for topic {}", mushopOrdersSubject);
    }

    private OrderUpdate handleMessage(ConsumerRecord<String, String> record) throws Exception {
        OrderUpdate update = objectMapper.readValue(record.value(), OrderUpdate.class);
        log.info("Got message {} on the mushop orders subject", update);
        return update;
    }

    private void fulfillOrder(OrderUpdate order) {
        messageProcessingPool.submit(() -> {
            try {
                Thread.sleep(simulationDelay);
                Shipment shipment = new Shipment(UUID.randomUUID().toString(), "Shipped");
                order.setShipment(shipment);
                String msg = objectMapper.writeValueAsString(order);
                log.info("Sending shipment update {}", msg);
                
                producer.send(new ProducerRecord<>(mushopShipmentsSubject, msg))
                    .get();  // Ensure the message is sent
                    
                meterRegistry.counter("orders.fulfilled", "app", "fulfillment").increment();
            } catch (Exception e) {
                log.error("Error fulfilling order", e);
            }
        });
    }

}