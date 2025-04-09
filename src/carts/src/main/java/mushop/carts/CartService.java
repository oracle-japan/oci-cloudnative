package mushop.carts;

import java.lang.System.Logger;
import java.lang.System.Logger.Level;

import org.eclipse.microprofile.metrics.Counter;
import org.eclipse.microprofile.metrics.Meter;
import org.eclipse.microprofile.metrics.Timer;
import org.eclipse.microprofile.metrics.annotation.Metric;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.json.Json;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.PATCH;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@Path("carts")
@ApplicationScoped
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class CartService {

    private final static Logger log = System.getLogger(CartService.class.getName());

    @Inject
    @Named("database")
    private CartRepository carts;

    @Inject
    @Metric(name = "carts_create_meter")
    private Meter newCartMeter;

    @Inject
    @Metric(name = "carts_update_meter")
    private Meter updateCartMeter;

    @Inject
    @Metric(name = "carts_delete")
    private Counter deleteCartCounter;

    @Inject
    @Metric(name = "carts_save_timer")
    private Timer saveCartTimer;

    /**
     * GET /{cartId}/items
     */
    @GET
    @Path("/{cartId}/items")
    public Response getCartItems(@PathParam("cartId") String cartId) {
        try {
            Cart cart = carts.getById(cartId);
            if (cart == null) {
                return Response.status(Response.Status.NOT_FOUND).build();
            }
            log.log(Level.INFO, "carts: ", cart.getItems());
            return Response.ok(cart.getItems()).build();
        } catch (Exception e) {
            log.log(Level.ERROR, "getCartItems failed.", e);
            return createErrorResponse(e.getMessage());
        }
    }

    /**
     * DELETE /{cartId}
     */
    @DELETE
    @Path("/{cartId}")
    public Response deleteCart(@PathParam("cartId") String cartId) {
        try {
            if (carts.deleteCart(cartId)) {
                deleteCartCounter.inc();
                return Response.ok().build();
            }
            return Response.status(Response.Status.NOT_FOUND).build();
        } catch (Exception e) {
            log.log(Level.ERROR, "deleteCart failed.", e);
            return createErrorResponse(e.getMessage());
        }
    }

    /**
     * DELETE /{cartId}/items/{itemId}
     */
    @DELETE
    @Path("/{cartId}/items/{itemId}")
    public Response deleteCartItem(@PathParam("cartId") String cartId, @PathParam("itemId") String itemId) {
        try {
            Cart cart = carts.getById(cartId);
            if (cart == null || !cart.removeItem(itemId)) {
                return Response.status(Response.Status.NOT_FOUND).build();
            }

            try (Timer.Context context = saveCartTimer.time()) {
                carts.save(cart);
            }
            updateCartMeter.mark();
            return Response.ok().build();
        } catch (Exception e) {
            log.log(Level.ERROR, "deleteCartItem failed.", e);
            return createErrorResponse(e.getMessage());
        }
    }

    /**
     * POST /{cartId}
     */
    @POST
    @Path("/{cartId}")
    public Response postCart(@PathParam("cartId") String cartId, Cart newCart) {
        try {
            Cart cart = carts.getById(cartId);
            if (cart == null) {
                newCart.setId(cartId);
                try (Timer.Context context = saveCartTimer.time()) {
                    carts.save(newCart);
                }
                newCartMeter.mark();
                return Response.status(Response.Status.CREATED).build();
            } else {
                cart.merge(newCart);
                try (Timer.Context context = saveCartTimer.time()) {
                    carts.save(cart);
                }
                updateCartMeter.mark();
                return Response.ok().build();
            }
        } catch (Exception e) {
            log.log(Level.ERROR, "postCart failed.", e);
            return createErrorResponse(e.getMessage());
        }
    }

    /**
     * PATCH /{cartId}/items
     */
    @PATCH
    @Path("/{cartId}/items")
    public Response updateCartItem(@PathParam("cartId") String cartId, Item qItem) {
        try {
            Cart cart = carts.getById(cartId);
            if (cart == null) {
                return Response.status(Response.Status.NOT_FOUND).build();
            }

            for (Item item : cart.getItems()) {
                if (item.getItemId().equals(qItem.getItemId())) {
                    item.setQuantity(qItem.getQuantity());
                    try (Timer.Context context = saveCartTimer.time()) {
                        carts.save(cart);
                    }
                    updateCartMeter.mark();
                    return Response.ok().build();
                }
            }
            return Response.status(Response.Status.NOT_FOUND).build();
        } catch (Exception e) {
            log.log(Level.ERROR, "updateCartItem failed.", e);
            return createErrorResponse(e.getMessage());
        }
    }

    private Response createErrorResponse(String message) {
        return Response.status(Response.Status.BAD_REQUEST)
                      .entity(Json.createObjectBuilder()
                             .add("errorMessage", message)
                             .build())
                      .build();
    }

    public boolean healthCheck() {
        try {

            return carts == null ? false : carts.healthCheck();
        } catch (Exception e) {
            log.log(Level.ERROR, "DB health-check failed.", e);
            return false;
        }
    }

}
