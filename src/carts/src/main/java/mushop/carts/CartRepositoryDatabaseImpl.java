package mushop.carts;

import java.io.InputStream;
import java.lang.System.Logger;
import java.lang.System.Logger.Level;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

import jakarta.json.Json;
import jakarta.json.bind.Jsonb;
import jakarta.json.bind.JsonbBuilder;
import oracle.jdbc.OracleConnection;
import oracle.soda.OracleCollection;
import oracle.soda.OracleCursor;
import oracle.soda.OracleDatabase;
import oracle.soda.OracleDocument;
import oracle.soda.rdbms.OracleRDBMSClient;

/**
 * Implements CartRepository using Oracle Database JSON collections with SODA.
 * This implementation uses direct JDBC connections without UCP.
 */
public class CartRepositoryDatabaseImpl implements CartRepository {

    /** Factory for SODA (simple oracle document access) api */
    private static final OracleRDBMSClient SODA;

    /** The name of the backing collection */
    private final String collectionName;

    /** JDBC connection parameters */
    private final String jdbcUrl;
    private final String dbUser;
    private final String dbPassword;

    /** Used to automatically convert a Cart object to and from JSON */
    private Jsonb jsonb;

    private final static Logger log = System.getLogger(CartRepositoryDatabaseImpl.class.getName());

    public CartRepositoryDatabaseImpl() {
        try {
            System.setProperty("oracle.jdbc.fanEnabled", "false");
            System.setProperty("oracle.net.ssl_server_dn_match", "true");
            System.setProperty("oracle.net.ssl_version", "1.2");
            System.setProperty("oracle.jdbc.Trace", "true");

            this.jdbcUrl = "jdbc:oracle:thin:@" + System.getenv("OADB_SERVICE") + "?TNS_ADMIN=${TNS_ADMIN}";
            this.dbUser = System.getenv("OADB_USER");
            this.dbPassword = System.getenv("OADB_PW");
            
            log.log(Level.INFO, String.format("Setting up JDBC connection: %s", jdbcUrl));
            
            collectionName = "cart";

            // UCP なしで直接 JDBC 接続を作成
            try (Connection conn = getConnection()) {
                OracleConnection oraConn = conn.unwrap(OracleConnection.class);
                OracleDatabase db = SODA.getDatabase(oraConn);
                
                // コレクションが存在しない場合は作成
                OracleCollection col = db.openCollection(collectionName);
                if (col == null) {
                    try (InputStream metaData = getClass().getClassLoader().getResourceAsStream("metadata.json")) {
                        OracleDocument collMeta = db.createDocumentFrom(metaData);
                        db.admin().createCollection(collectionName, collMeta);
                    }
                }
                log.log(Level.INFO, "Connected to Oracle Database and initialized SODA collection: " + jdbcUrl);
            }
        } catch (Exception e) {
            log.log(Level.ERROR, "Failed to initialize database connection", e);
            throw new RuntimeException(e);
        }

        jsonb = JsonbBuilder.create();
    }
    
    /**
     * 新しいデータベース接続を取得
     */
    private Connection getConnection() throws SQLException {
        return DriverManager.getConnection(jdbcUrl, dbUser, dbPassword);
    }

    @Override
    public boolean deleteCart(String id) {
        try (Connection conn = getConnection()) {
            OracleDatabase db = SODA.getDatabase(conn.unwrap(OracleConnection.class));
            OracleCollection col = db.openCollection(collectionName);
            int ct = col.find().key(id).remove();
            return ct > 0;
        } catch (Exception e) {
            log.log(Level.ERROR, "Error deleting cart", e);
            throw new RuntimeException(e);
        }
    }

    @Override
    public Cart getById(String id) {
        try (Connection conn = getConnection()) {
            OracleDatabase db = SODA.getDatabase(conn.unwrap(OracleConnection.class));
            OracleCollection col = db.openCollection(collectionName);
            OracleDocument doc = col.findOne(id);
            return doc == null ? null : jsonb.fromJson(doc.getContentAsString(), Cart.class);
        } catch (Exception e) {
            log.log(Level.ERROR, "Error getting cart by ID", e);
            throw new RuntimeException(e);
        }
    }

    @Override
    public List<Cart> getByCustomerId(String custId) {
        if (custId == null) {
            throw new IllegalArgumentException("The customer id must be specified");
        }
        String filter = Json.createObjectBuilder().add("customerId", custId).build().toString();

        return getCarts(filter);
    }

    @Override
    public void save(Cart cart) {
        try (Connection conn = getConnection()) {
            OracleDatabase db = SODA.getDatabase(conn.unwrap(OracleConnection.class));
            OracleDocument cartDoc = db.createDocumentFromString(cart.getId(), jsonb.toJson(cart));
            OracleCollection col = db.openCollection(collectionName);
            col.save(cartDoc);
        } catch (Exception e) {
            log.log(Level.ERROR, "Error saving cart", e);
            throw new RuntimeException(e);
        }
    }

    /** Selects carts based on a "query by example" */
    private List<Cart> getCarts(String filter) {
        try (Connection conn = getConnection()) {
            OracleDatabase db = SODA.getDatabase(conn.unwrap(OracleConnection.class));
            OracleCollection col = db.openCollection(collectionName);
            OracleDocument filterDoc = db.createDocumentFromString(filter);

            List<Cart> result = new ArrayList<>();
            try (OracleCursor carts = col.find().filter(filterDoc).getCursor()) {
                while (carts.hasNext()) {
                    OracleDocument doc = carts.next();
                    Cart cart = jsonb.fromJson(doc.getContentAsString(), Cart.class);
                    result.add(cart);
                }
            }
            return result;
        } catch (Exception e) {
            log.log(Level.ERROR, "Error getting carts by filter", e);
            throw new RuntimeException(e);
        }
    }

    @Override
    public boolean healthCheck() {
        try (Connection conn = getConnection()) {
            OracleDatabase db = SODA.getDatabase(conn.unwrap(OracleConnection.class));
            OracleCollection col = db.openCollection(collectionName);
            String name = col.admin().getName();
            return name != null;
        } catch (Exception e) {
            log.log(Level.ERROR, "DB health-check failed.", e);
            return false;
        }
    }

    static {
        // Optimization: cache collection metadata to avoid extra roundtrips
        // to the database when opening a collection
        Properties props = new Properties();
        props.put("oracle.soda.sharedMetadataCache", "true");
        SODA = new OracleRDBMSClient(props);
    }
}
