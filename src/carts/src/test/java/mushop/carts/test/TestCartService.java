package mushop.carts.test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;

import io.helidon.microprofile.tests.junit5.HelidonTest;
import jakarta.inject.Inject;
import jakarta.json.JsonArray;
import jakarta.json.JsonObject;
import jakarta.ws.rs.client.Entity;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import mushop.carts.Cart;
import mushop.carts.Item;

@HelidonTest
public class TestCartService {
    
    @Inject
    private WebTarget target;

    
    @Test
    public void testMetricsJson() {
        Response response = target.path("metrics")
                                .request(MediaType.APPLICATION_JSON)
                                .get();
        assertEquals(Response.Status.OK.getStatusCode(), response.getStatus());
        JsonObject result = response.readEntity(JsonObject.class);
        // MicroProfileの基本メトリクスがあることを確認
        assertTrue(result.getJsonObject("base") != null);
        response.close();
    }

    @Test
    public void testMetricsText() {
        Response response = target.path("metrics")
                                .request(MediaType.TEXT_PLAIN)
                                .get();
        assertEquals(Response.Status.OK.getStatusCode(), response.getStatus());
        String result = response.readEntity(String.class);
        // Prometheusフォーマットのメトリクスがあることを確認
        assertTrue(result.contains("# TYPE base_"));
        response.close();
    }

    @Test
    public void testHealthCheck() {
        Response response = target.path("health")
                                .request(MediaType.APPLICATION_JSON)
                                .get();
        assertEquals(Response.Status.OK.getStatusCode(), response.getStatus());
        JsonObject result = response.readEntity(JsonObject.class);
        assertEquals("UP", result.getString("status"));
        response.close();
    }
    
    @Test
    public void testStoreCart() {
        Item i = new Item();
        i.setUnitPrice(BigDecimal.valueOf(123));
        i.setQuantity(47);
        i.setItemId("I123");
        
        Cart c = new Cart();
        c.setId("cart1");          // カートIDを明示的に設定
        c.setCustomerId("c1");
        c.getItems().add(i);

        String cartPath = c.getId();
        String itemsPath = cartPath + "/items";

        // Create cart
        Response response = target.path("carts").path(cartPath)
                                .request(MediaType.APPLICATION_JSON)
                                .post(Entity.json(c));
        assertEquals(Response.Status.CREATED.getStatusCode(), response.getStatus());
        response.close();

        // Get items
        response = target.path("carts").path(cartPath + "/items")
                        .request(MediaType.APPLICATION_JSON)
                        .get();
        assertEquals(Response.Status.OK.getStatusCode(), response.getStatus());
        JsonArray items = response.readEntity(JsonArray.class);
        assertEquals(1, items.size());
        assertEquals(i.getItemId(), items.getJsonObject(0).getString("itemId"));
        response.close();

        // Delete item
        response = target.path("carts").path(cartPath + "/items/" + i.getItemId())
                        .request()
                        .delete();
        assertEquals(Response.Status.OK.getStatusCode(), response.getStatus());
        response.close();

        // Verify item was deleted
        response = target.path("carts").path(cartPath + "/items")
                        .request(MediaType.APPLICATION_JSON)
                        .get();
        assertEquals(Response.Status.OK.getStatusCode(), response.getStatus());
        items = response.readEntity(JsonArray.class);
        assertEquals(0, items.size());
        response.close();
    }
}
