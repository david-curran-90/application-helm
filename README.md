# Application module

This chart is designed to cut out the repetition when deploying simple applications by providing manifests to create workloads and supporting resources like ingress/services. By providing the details in a values file it should simplify the deployment process for those less familiar with Helm and Kubernetes manifests.

## Usage

### v2

The `application` key has changed in v2.x.x to allow for multiple containers to be deployed in a pod. It adds a `containerSpec` key that specifies a list of container specs. This means you can specify one or more containers in your pod:

```yaml
app:
  version: "2"
  containerSpec:
  - name: "test"
    image: 
      uri: nginx:latest  
      pullPolicy: "IfNotPresent"
    env: []
    readinessProbe: {}
    livenessProbe: {}
    extraVolumes:
      mounts: []
    resources: {}
...
```

Note that all the keys need listing, even if empty or Helm will give errors about missing keys. Another change is with `extraVolumes`. `app.extraVolumes.volumes` remains in place but `app.extraVolumes.mounts` is now in `app.containerSpec.extraVolumes.mounts` as you mount a volume into a specific container. Also the only way to specify an image is through `image.uri`.

### In a chart

You can package the chart and store it in your own chart repo and then use it as a normal chart.

Install this by including it as a dependency in your own `Chart.yaml`

```yaml
...
dependencies:
  - name: application
    version: 2.0.0
    repository: https://hlem.myhelm.com
```

Then use in your values fil

```yaml
application:
  app:
    image:
      uri: nginx:latest
```      

You'll see output similar to below upon installing

```
test-deploy deployed into modules namespace using Application helm.
View deployment details with
  helm -n modules list test-deploy

You have deployed:

Deployment - test-deploy
Ingress - test-deploy
Service - test-deploy-svc
```

To supress this output (e.g. when performing tests) use the `quiet` value

`--set quiet=true`

or 

values.yaml

```yaml
...
quiet: true
...
```

## Limitations

### Multi app deployments

Currently it is not possible to deploy and app with more than one `app.type`. This limits a chart to defining a single app only. If more than one app is required as part of a deployment then consider bundling them together as subcharts of a larger chart.

### Horizontal Pod Autoscaler and app.type key

When using HPA with your application, `app.type` becomes case sensitive. It is therefore good practise to always use the camel case (Deployment, DaemonSet, StatefulSet)

## Values

Below is a list of values, `values.yaml` contains a full list with some examples.

### Applications

Choosing what deployment method you want is crucial to reliable operation of your app. The three options in this module are:

* [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) - deploy a simple app that has no requirement for persiting across deployments
* [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) - deploy an app with persistence requirements where storage should persist across deployments
* [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/) - deploy an app on to all nodes

| Value                             | Description                                                             | Default                         |
|-----------------------------------|-------------------------------------------------------------------------|---------------------------------|
| fullname                          | Set the name of the app, will use `.Release.Name` if empty              | `""`                            |
| namespaceOverride                 | Set the namespace to something different from whats passed to Helm      | `""`                            |                     
| quiet                             | if set to `true` NOTES.txt output will be suppressed                    | `false`                         |
| app.type                  | Type of app resource to use [Deployment | StatefulSet | DaemonSet]      | `deployment`                    |
| app.replicas              | Number of replicas to create for an app (doesn't work with DaemonSet)   | `1`                             |
| app.maxReplicas           | Number of replicas to scale up to when using HPA                        | `app.replicas`          |
| app.env                   | Environment variables for the pod                                       | `{}`                            |
| app.extraPorts            | Set container ports beyond default (v1) or all ports (v2)               | `[]`                            |
| app.garcePeriod           | Time to give a pod to terminate (only for statefulsets)                 | `10`                            |
| app.nodeSelector          | List of nodeSelectors for the app                                       | `dfi-workload: apps`            |
| app.pullSecrets           | List of imagePullSecrets                                                | `[]`                            |
| app.readinessProbe        | Rule to check that a pod is `Ready`                                     | `{}`                            |
| app.serviceAccount        | Specify the existing service account, must exist at deploy time         | `""`                            |
| app.automountServiceAccountToken | Set mount option for service account token                       | `false`                         |
| app.livenessProbe         | Rule to check that a pod is alive                                       | `{}`                            |
| app.extraVolumes.volumes  | Volume spec                                                             | `{}`                            |
| app.extraVolumes.mounts   | volumeMount spec                                                        | `{}`                            |
| app.containerSpec         | list of container specs to deploy in the pod                            | see values.yaml for information |
| persistence.enabled               | Enable persistent storage (required for statefulsets)                   | `false`                         |
| persistence.accessMode            | Access mode of the persistent storage                                   | `ReadWriteOnce`                 |
| persistence.storageClass          | Storage class to use for storage                                        | `""`                            |
| persistence.size                  | Size of volume to request                                               | `""`                            |

#### containerSpec changes

The following should be used when using `app.version: "2"` and supercede the `app.{key}` from the table above. All of these come under the `app.containerSpec` key

| Value               | replaces                          |
|---------------------|-----------------------------------|
| - name              | _helpers.tpl `app.name`   |
| image.uri           | `app.image.uri`           |
| image.pullPolicy    | `app.image.pullPolicy`    |
| env                 | `app.env`                 |
| readinessProbe      | `app.readinessProbe`      |
| livenessProbe       | `app.livenessProbe`       |
| extraVolumes.mounts | `app.extraVolumes.mounts` |
| resources           | `app.resources`           |

Other `app.{key}` keys remain the same

### Service/Ingress

Only one if `ingress.enabled` and `ingressRoute.enabled` makes sense so only use one.

| Value                         | Decsription                                                   | Default                   |
|-------------------------------|---------------------------------------------------------------|---------------------------|
| ingress.enabled               | enable the ingress                                            | `false`                   |
| ingress.hostName              | hostname for the ingress                                      | `""`                      |
| ingress.tls.enabled           | enable TLS for the ingress                                    | `""`                      |
| ingress.tls.host              | list of hosts to accept in the ingress                        | `[]`                      |
| ingress.tls.secretName        | secret for TLS certificate                                    | `""`    |
| service.enabled               | Enable the service                                            | `false`                   |
| service.type                  | Set the service type [NodePort | ClusterIP | LoadBalancer]    | `ClusterIP`               |
| service.externalPort          | Port to expose on the service                                 | `""`                      |
| service.targetPort            | Pod port                                                      | `""`                      |
| service.nodePort              | Specify the port to expose on a Node                          | `""`                      |
| service.portName              | Name of the service port                                      | `"http"`                  |
| service.portProtocol          | Protocol for the service port                                 | `"TCP"`                   |

### HPA

| Value       | Decsription                       | Default         |
|-------------|-----------------------------------|-----------------|
| hpa.enabled | enable Horizontal Pod Autoscaler  | `false`         |
| hpa.metrics | Metrics spec                      | see values.yaml |

### configuration

| Value           | Description                     | Default |
|-----------------|---------------------------------|---------|
| configmap.data  | Data to store in the configmap  | `{}`    |
