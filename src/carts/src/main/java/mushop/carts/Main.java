package mushop.carts;

import java.util.HashSet;
import java.util.Set;

import org.eclipse.microprofile.health.HealthCheck;
import org.eclipse.microprofile.health.HealthCheckResponse;
import org.eclipse.microprofile.health.Liveness;

import io.helidon.microprofile.server.Server;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.spi.CDI;
import jakarta.ws.rs.ApplicationPath;
import jakarta.ws.rs.core.Application;

@ApplicationScoped
@ApplicationPath("")
public class Main extends Application {

    @Override
    public Set<Class<?>> getClasses() {
        Set<Class<?>> classes = new HashSet<>();
        classes.add(CartService.class);
        classes.add(org.glassfish.jersey.jsonb.JsonBindingFeature.class);
        return classes;
    }

    public static void main(final String[] args) {
        Server server = Server.builder()
                .addApplication(Main.class)
                .build();
        server.start();
    }

    @Liveness
    public HealthCheck dbHealth() {
        CartService cartService = CDI.current().select(CartService.class).get();
        return () -> HealthCheckResponse
                .named("dbHealth")
                .status(cartService.healthCheck())
                .build();
    }
}
