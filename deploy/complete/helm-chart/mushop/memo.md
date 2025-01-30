# 各種Secret作成
- OCI Cache（＊）
- OCI Streaming
- OCI APM（＊）
- Autonomous Database
- Object Storage

（＊）は書籍のために作成するSecretであり、それぞれのサービスのvalues.yamlに定義する想定

# Secretの内容ををvalues.yamlに記載
- api
  - OCI Cache
- carts
  - OCI APM
- fulfillment
  - OCI APM
  - OCI Streaming
- orders
  - OCI APM
  - OCI Streaming
  - Autonomous Database
- carts
  - OCI APM
  - Autonomous Database
- assets
  - Object Storage
- catalog
  - Autonomous Database

# 作成するSecret
  
kubectl create secret generic oci-credentials \
  --namespace mushop \
  --from-literal=tenancy=ocid1.tenancy.oc1..aaaaaaaa3mb7wrcxxxxxxxxxxxc3q4mczitpdaymbuazc5tkguca \
  --from-literal=user=ocid1.user.oc1..aaaaaaaaqxehklwzd2xxxxxxxxxxv67hvpml5qtgb6d4ug3in47jeeyra \
  --from-literal=region=us-sanjose-1 \
  --from-literal=fingerprint=XX:01:81:7e:10:d6:30:XX:d1:db:06:XX:50:70:bb:03 \
  --from-literal=passphrase="" \
  --from-file=privatekey=private.pem

kubectl create secret generic oadb-admin --from-literal=oadb_admin_pw='Dear05240301' -n mushop

kubectl create secret generic oadb-wallet -n mushop --from-file=wallet

kubectl create secret generic kafka-secret -n mushop --from-literal=server=cell-1.streaming.us-sanjose-1.oci.oraclecloud.com:9092 --from-literal=config='org.apache.kafka.common.security.plain.PlainLoginModule required username="xxxxxxxxxx/oracleidentitycloudservice/xxxxxxxx@oracle.com/ocid1.streampool.oc1.us-sanjose-1.amaaaaaassl65iqxxxxxxxxxxxxxokhibpnjyxwgpq3qvm3wa" password="GA:qffZry3v)iF_NxGQ3";'

kubectl create secret generic oos-bucket \
  --namespace mushop \
  --from-literal=region=us-sanjose-1 \
  --from-literal=name=musho-backet \
  --from-literal=namespace=xxxxxxxx \
  --from-literal=parUrl=https://xxxxxxxx.objectstorage.us-sanjose-1.oci.customer-oci.com/p/O2fV-dKKTssK43Yh2ngkHs42L2P24rfTSwl-cVjz1clNalUaVuBwtYhMQuNpwyIi/n/xxxxxxxx/b/musho-backet/o/

kubectl create secret generic cache-endpoint --namespace mushop --from-literal=host=aaassl65iqag4xsvtjnpxxxxxxxxxxxx4iva-p.redis.us-sanjose-1.oci.oraclecloud.com

# Streamingは以下の2つを作成
-  mushop-shipments
-  mushop-orders

# APMは別途Manifestを適用。適用する際にはAPMのエンドポイントとアップロードプライベートキーを指定

kubectl apply -f otel.yaml 