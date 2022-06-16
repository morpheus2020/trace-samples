1. Add Traceable Repo

helm repo add traceableai https://helm.traceable.ai

2. Install TPA with logging exporter

helm upgrade -i --namespace traceableai traceable-agent traceableai/traceable-agent \
  --create-namespace --set token=none \
  --set environment=test \
  --set logLevel=info \
  --set endpoint=localhost \
  --set tlsServerPort=443 \
  --set collector.service.pipelines.traces.exporters[0]=logging \
  --set collector.service.pipelines.metrics.exporters[0]=logging \
  --set collector.additionalExporters.logging.loglevel=debug

3. Download and install istio

curl -L https://istio.io/downloadIstio | sh -

3.1 (Optional) update the demo profile to tune the configurations

3.2 Install Istio
bin/istioctl install --set profile=demo -y \
  --set meshConfig.enableTracing=true \
  --set meshConfig.defaultConfig.tracing.sampling=100 \
  --set meshConfig.defaultConfig.tracing.zipkin.address=agent.traceableai:9411

4. Labels & Annotations

4.1 Label istio namespace for tme injection support
kubectl label ns istio-system traceableai-inject-tme=enabled

4.2 Install Istio Filters Helm Charts
helm upgrade --install traceableai-istio traceableai/traceableai-istio -n istio-system

4.3 Inject TME to Istio Ingress gateway Deployment
kubectl patch deployment.apps/istio-ingressgateway \
  -p '{"spec":{"template":{"metadata":{"annotations":{"tme.traceable.ai/inject":"true"},"labels":{"traceableai-istio":"enabled"}}}}}' \
  -n istio-system

4.4 Restart Ingress Gateway
kubectl rollout restart deployment istio-ingressgateway -n istio-system

5.
./setup-sample-app.sh