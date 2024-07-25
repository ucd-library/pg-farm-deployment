# pg-farm-deployment
Deployment repo for PG Farm

## Kubernetes Local Deployment

  - [Prerequisites](#prerequisites)
  - [Setup Kubernetes locally](#setup-kubernetes-locally)
  - [Deploy the application](#deploy-the-application)
  - [Access the application](#access-the-application)
  - [Restart Services](#restart-services)
    - [Logging after restarting a service.](#logging-after-restarting-a-service)
  - [Stop the application](#stop-the-application)

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

### Setup Kubernetes locally

1. Clone this repository
2. Enable Kubernetes in [Docker Desktop](https://docs.docker.com/desktop/kubernetes/)
3. Deploy the dashboard

```bash
./cmds/local-dev.sh create-dashboard
```

This will create the dashboard deployment inside kubernetes as well as create the k8s service account for the dashboard.  Note, follow the instructions printed by the above command about editing dashboard configs `--token-ttl` flag.

4. Access the dashboard by running 

`kubectl proxy` or VS Code task `Proxy Dashboard`.

Then navigate to http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy

5. Get the token for the dashboard

Run `./cmds/local-dev.sh dashboard-token` or VS Code task `Generate Dashboard Token`. Use token to login to the dashboard.

**Note.**  Kubectl can speak to any k8s cluster, local or cloud (GKE).  You can ensure you are speaking to the correct cluster by running `kubectl config get-contexts` and `kubectl config use-context [context-name]` to switch between clusters.  For local development you want `kubectl config use-context docker-desktop`.

### Deploy the application 

The application will run under the `pg-farm` kubernetes namespace.  Make sure you use this namespace when running kubectl commands or accessing the dashboard.  The `./cmds/local-dev.sh start` script will automatically create and switch to the `pg-farm` namespace.  Manually you can run `kubectl config set-context --current --namespace=pg-farm` to switch to the namespace.

1. Build the app using `./cmds/local-dev.sh build` or VS Code task `Build Images`
2. Create the k8s secrets using `./cmds/create-secrets.sh local-dev`.  This only needs to be done once.  You will need access to the GCloud secret manager to get the secrets.
3. Deploy the app using `./cmds/local-dev.sh start` or VS Code task `Deploy Pods`.  Additionally, run this command any time you update the k8s config yaml files and want the changes to take effect.
4.  For webapp client development, startup the client code Webpack watch process using `./cmds/local-dev.sh exec client "npm run client-watch"` or VS Code task `Client Watch`.  

### Access the application

You can expose services, deployments or statefulsets to your host machine using the `kubectl port-forward` command.

- Access webapp using `kubectl port-forward svc/gateway-ingress 3000:80` or VS Code task `Proxy Gateway HTTP` 
- Access a local PG Farm Postgres instance using `kubectl port-forward svc/gateway-ingress 5432:5432` or VS Code task `Proxy Gateway PG`.  Now `psql` commands to localhost:5432 will be forwarded to the PG Farm instance.
- Access the admin database: `kubectl port-forward svc/admin-db 5433:5432` or VS Code task `Proxy Admin DB`.  Now `psql` commands to localhost:5433 will be forwarded to the PG Farm instance.

### Restart Services

If you need to restart a service after a code update, you can do so by running `kubectl rollout restart [type] [name]` ex: `kubectl rollout restart deployment admin`.

Most services have the host machine codes mounted as volumes so you can make changes to the code and the service (statefulset, deployment) will automatically have the changes.  You just need to restart the service.

#### Logging after restarting a service.

When you restart a service, the old service pod is normally still terminating after the new service is up. However, it is often the case the `kubectl logs -f deployment/[name]` will connect to the terminating pod and not the new pod.  You can use `./cmds/local-dev.sh logs [service-name]` where serivce name is something like `admin` to log from a service pod that is not terminating.

### Stop the application

This will remove all pods/services from the docker desktop k8s instance but leave the volumes intact.

`./cmds/local-dev.sh stop` or VS Code task `Remove all pods and services`