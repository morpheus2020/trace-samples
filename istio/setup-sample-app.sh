export APP_NAMESPACE=forge
export APP_DEPLOYMENT=web
kubectl create namespace $APP_NAMESPACE
export INGRESS_GATEWAY_HOST=$APP_DEPLOYMENT.$APP_NAMESPACE.com

kubectl -n $APP_NAMESPACE apply -f sample-app-deployment.yaml

kubectl -n $APP_NAMESPACE apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: $APP_DEPLOYMENT-gateway
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - $INGRESS_GATEWAY_HOST
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: $APP_DEPLOYMENT-vs
spec:
  hosts:
  - $INGRESS_GATEWAY_HOST
  gateways:
  - $APP_NAMESPACE/$APP_DEPLOYMENT-gateway
  http:
  - match:
    - uri:
        exact: /get
    route:
    - destination:
        host: $APP_DEPLOYMENT
        port:
          number: 7070
EOF

export INGRESS_HOST=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.spec.clusterIP}')
export INGRESS_PORT=80

kubectl -n $APP_NAMESPACE apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: sample-load
spec:
  containers:
  - name: curl
    image: alpine/curl
    command: ["/bin/sh", "-ce"]
    args:
      - |
        while true; do curl -i -H 'Host:web.forge.com' http://$INGRESS_HOST:$INGRESS_PORT/get; sleep 5 ; done
EOF