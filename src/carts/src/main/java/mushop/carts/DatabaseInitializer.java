package mushop.carts;

import java.lang.System.Logger;
import java.lang.System.Logger.Level;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.eclipse.microprofile.metrics.Timer;
import org.eclipse.microprofile.metrics.annotation.Metric;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Inject;
import jakarta.inject.Named;

@ApplicationScoped
public class DatabaseInitializer {

    private static final Logger log = System.getLogger(DatabaseInitializer.class.getName());
    private CartRepository carts;

    @Inject
    @Metric(name = "carts_db_conn_timer")
    private Timer dbConnectTimer;

    @Inject
    public DatabaseInitializer(@ConfigProperty(name = "mock") String mock) {
        initializeRepository(mock);
    }

    private void initializeRepository(String mock) {
        ExecutorService executorService = Executors.newSingleThreadExecutor();
        Boolean connected = false;

        if (mock.equals("true")) {
            log.log(Level.INFO, "Connecting to a Mock Database. Data is not persisted.");
            carts = new CartRepositoryMemoryImpl();
        } else {
            while (!connected) {
                try {
                    Future<Boolean> result = executorService.submit(() -> {
                        try {
                            Timer.Context context = null;
                            if (dbConnectTimer != null) {
                                context = dbConnectTimer.time();
                            }
                            carts = new CartRepositoryDatabaseImpl();
                            if (context != null) {
                                context.close();
                            }
                            return Boolean.TRUE;
                        } catch (Exception ex) {
                            log.log(Level.WARNING, "Connect failed. Retrying.");
                            log.log(Level.ERROR, ex.getMessage(), ex);
                            Thread.sleep(5000L);
                            return Boolean.FALSE;
                        }
                    });
                    connected = result.get();
                } catch (Exception e) {
                    log.log(Level.INFO, e.getMessage(), e);
                }
            }
        }
        executorService.shutdown();
    }

    @Produces
    @ApplicationScoped
    @Named("database")
    public CartRepository getRepository() {
        return carts;
    }
}
