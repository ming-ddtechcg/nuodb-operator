# The NuoDB Operator
The NuoDB Kubernetes Operator deploys the NuoDB Community Edition (CE) database on OpenShift 3.11 or 4. It also supports either ephemeral or persistent storage options with configurations to run NuoDB Insights, a visual database monitoring Web UI, and start a sample SQL application (ycsb) to quickly generate a user-configurable SQL workload against the database.

# Prerequisites

### Clone a copy of the NuoDB Operator from Github
In your home or working directory, run:

&ensp; `git clone https://github.com/nuodb/nuodb-operator`

### Log into your Kubernetes cluster

&ensp; `Example: kubectl login -u system:admin`

### Create environment variables

```
export OPERATOR_NAMESPACE=nuodb
export STORAGE_NODE=yourStorageNodeName
```

### Disable Linux Transparent Huge Pages (THP) on each cluster node
Run these commmands as the root user (or a user with root group privilages) on each cluster node that will host NuoDB pods (containers).

```
echo madvise | sudo tee -a /sys/kernel/mm/transparent_hugepage/enabled
echo madvise | sudo tee -a /sys/kernel/mm/transparent_hugepage/defrag
```

### Node Labeling
Label the nodes you want to run NuoDB pods.

NOTE: The instructions on this page use the Kubernetes "kubectl" command for command portability reasons. You can replace the kubectl command with the OpenShift *oc* command when running commands if you prefer.

&ensp; `kubectl  label node <node name> nuodb.com/zone=a`

_**Note:** The label value, in this example "a", can be any value._

Next, label one of these nodes as your storage node. This is the node that will host your NouDB Storage Manager (SM) pod and is where you database persistent storage will reside. Ensure there is sufficient disk space. To create this label run:

&ensp; `kubectl  label node $STORAGE_NODE nuodb.com/node-type=storage`

### Set container local-storage permissions on each node

```
sudo mkdir -p /mnt/local-storage/disk0
sudo chmod -R 777 /mnt/local-storage/
sudo chcon -R unconfined_u:object_r:svirt_sandbox_file_t:s0 /mnt/local-storage
sudo chown -R root:root /mnt/local-storage
```

### Create the Kubernetes storage class "local-disk" and persistent volume

&ensp; `kubectl create -f nuodb-operator/local-disk-class.yaml`

### Create the "nuodb" project (if not already created)

&ensp; `kubectl new-project nuodb`

### Create the Kubernetes image pull secret to access the Red Hat Container Catalog (RHCC)

This secret will be used to pull the NuoDB Operator and NuoDB container images

```
Kubectl  create secret docker-registry pull-secret --n $OPERATOR_NAMESPACE \
   --docker-username='yourUserName' --docker-password='yourPassword' \
   --docker-email='yourEmailAddr'  --docker-server='registry.connect.redhat.com'
 ```

# Install the NuoDB Operator

To install the NuoDB Operator into your Kubernetes cluster, follow the steps indicated for the OpenShift version you are using.

## OpenShift 4

In OpenShift 4.x, the NuoDB Operator is available to install directly from the OpenShift OperatorHub, an integrated service catalog, accessible from within the OpenShift 4 Web UI which creates a seamless - single click experience - that allows users to install the NuoDB Operator from catalog-to-cluster in seconds.

1. Select &ensp;`Projects` from the OpenShift 4 left toolbar and click the &ensp;`NuoDB` project to make
   it your current project.
2. Select the &ensp;`OperatorHub` under the &ensp;`Catalog` section in the OCP 4 left toolbar.
3. Select the &ensp;`Database` filter and scroll down to the NuoDB Application tile and click the tile.
4. In the right-hand corner of the NuoDB Operator page, click the &ensp;`Install` button.
5. On the "Create Operator Subscription" page, select &ensp;`Subscribe` to subscribe to the NuoDB Operator.
6. In less than a minute, on the page that displays should indicate the NuoDB Operator has been
   installed, see "1 installed" message.
7. To verify the NuoDB Operator installed correctly, select &ensp;`Installed Operators` from the left
   toolbar. The STATUS column should show "Install Successed"
8. Select &ensp;`Status` under the &ensp;`Projects` on the left toolbar to view your running Operator.

## OpenShift 3.11 

 ```
# Change directory into the NuoDB Operator directory
cd nuodb-operator

 # Create the K8s Custom Resource Definition for the NuoDB Operator
kubectl create -f deploy/crd.yaml

 # Create the K8s Role Based Access Control for the NuoDB Operator
kubectl create -n $OPERATOR_NAMESPACE -f deploy/rbac.yaml

 # Create the NuoDB Operator
kubectl create -n $OPERATOR_NAMESPACE -f deploy/operator.yaml

# Create Cluster Service Version (ONLY RUN THIS IF YOU HAVE OLM INSTALLED)
kubectl create -n $OPERATOR_NAMESPACE -f deploy/csv.yaml
 ```

# Deploy the NuoDB Database
To deploy the NuoDB database into your Kubernetes cluster, run the following command:

 ```
 # Create the Custom Resource to deploy the NuoDB database
kubectl create -n $OPERATOR_NAMESPACE -f deploy/cr.yaml
 ```

&ensp; &ensp; _**Note:** Before running the above create Customer Resource file command, this is where you have the option to configure your database just the way you want it._

### Sample cr.yaml deployment files

The deploy directory includes sample Custom Resources to deploy NuoDB:

&ensp; `cr-ephemeral.yaml` deploys NuoDB CE domain without a persistent storage volume by setting storageMode to "ephemeral".

&ensp; `cr-persistent-insights-enabled.yaml` deploys NuoDB CE domain using persistent storage and has NuoDB Insights enabled.

Optionally, you can add any of these parameter values to your own `cr.yaml` to customize your database. Each are described in the Optional Database Parameter section.
```
spec:
  replicaCount: 1
  storageMode: persistent
  insightsEnabled: true
  adminCount: 3
  adminStorageSize: 2G
  adminStorageClass: local-disk
  dbName: test
  dbUser: dba
  dbPassword: secret
  smMemory: 4
  smCpu: 2
  smStorageSize: 20G
  smStorageClass: local-disk
  engineOptions: ""
  teCount: 1
  teMemory: 4
  teCpu: 2
  ycsbLoadName: ycsb-load
  ycsbWorkload: b
  ycsbLbPolicy: ""
  ycsbNoOfProcesses: 5
  ycsbNoOfRows: 10000
  ycsbNoOfIterations: 0
  ycsbOpsPerIteration: 10000
  ycsbMaxDelay: 240000
  ycsbDbSchema: User1
  ycsbContainer: nuodb/ycsb:latest
  container: nuodb/nuodb-ce:latest
```

### To check the status of NuoDB Insights visual monitoring tool
If you enabled NuoDB Insights (highly recommended) you can confirm it's run status by running:

&ensp; `oc exec -it nuodb-insights -c insights -- nuoca check insights`

### To remove the NuoDB database deployment and NuoDB Operator

```
kubectl delete -n $OPERATOR_NAMESPACE -f deploy/cr.yaml 
kubectl delete -n $OPERATOR_NAMESPACE -f deploy/csv.yaml 
kubectl delete -n $OPERATOR_NAMESPACE -f deploy/operator.yaml 
kubectl delete -n $OPERATOR_NAMESPACE -f deploy/rbac.yaml 
kubectl delete deployments nuodb-ce-operator
ssh $STORAGE_NODE 'rm -rf /mnt/local-storage/disk0/nuodb'
kubectl delete pv local-disk-0
kubectl delete sc local-disk
kubectl delete -f deploy/crd.yaml
```

### Option Database Parameters

**storageMode** - Run NuoDB CE using a persistent, local, disk volume "persistent" or volatile storage "ephemeral". Must be set to one of those values.

&ensp; `storageMode: persistent`


**insightsEnabled** - Use to control NuoDB Insights Opt In. NuoDB Insights provides database monitoring and visualization. Set to "true" to activate or "false" to deactivate.

&ensp; `insightsEnabled: false`


**adminCount** - Number of admin service pods. Requires 1 server node available for each Admin Service

&ensp; `adminCount: 1`


**adminStorageSize** - Admin service log volume size (GB)

&ensp; `adminStorageSize: 5G`


**adminStorageClass** - Admin persistent storage class name

&ensp; `adminStorageClass: glusterfs-storage`


**dbName** - NuoDB Database name. must consist of lowercase alphanumeric characters '[a-z0-9]+' 

&ensp; `dbName: test`


**dbUser** - Name of Database user

&ensp; `dbUser: dba`


**dbPassword** - Database password

&ensp; `dbPassword: secret`


**smMemory** - SM memory (in GB)

&ensp; `smMemory: 2`


**smCpu** - SM CPU cores to request

&ensp; `smCpu: 1`


**smStorageSize** - Storage manager (SM) volume size (GB)

&ensp; `smStorageSize: 20G`


**smStorageClass** - SM persistent storage class name

&ensp; `smStorageClass: local-disk`


**engineOptions** - Additional "nuodb" engine options Format: …

&ensp; `engineOptions: ""`


**teCount** - Number of transaction engines (TE) nodes. Limit is 3 in CE version of NuoDB

&ensp; `teCount: 1`


**teMemory** - TE memory (in GB)

&ensp; `teMemory: 2`


**teCpu** - TE CPU cores to request

&ensp; `teCpu: 1`


**ycsbLoadName** - YCSB workload pod name

&ensp; `ycsbLoadName: ycsb-load`


**ycsbWorkload** - Sample SQL activity workload. Valid values are a-f. Each letter determines a different mix of read and update workload percentage generated. a= 50/50, b=95/5, c=100 read. Refer to YCSB documentation for more detail.

&ensp; `ycsbWorkload: b`


**ycsbLbPolicy** - YCSB load-balancer policy. Name of an existing load-balancer policy, that has already been created using the 'nuocmd set load-balancer' command.

&ensp; `ycsbLbPolicy: ""`


**ycsbNoOfProcesses** - Number of YCSB processes. Number of concurrent YCSB processes that will be started in each YCSB pod. Each YCSB process makes a connection to the Database.

&ensp; `ycsbNoOfProcesses: 2`


**ycsbNoOfRows** - YCSB number of initial rows in table

&ensp; `ycsbNoOfRows: 10000`


**ycsbNoOfIterations** - YCSB number of iterations

&ensp; `ycsbNoOfIterations: 0`


**ycsbOpsPerIteration** - Number of YCSB SQL operations to perform in each iteration. This value controls the number of SQL operations performed in each benchmark iteration. Increasing this value increases the run-time of each iteration, and also reduces the frequency at which new connections are made during the sample workload run period.

&ensp; `ycsbOpsPerIteration: 10000`


**ycsbMaxDelay** - YCSB maximum workload delay in milliseconds (Default is 4 minutes)

&ensp; `ycsbMaxDelay: 240000`


**ycsbDbSchema** - YCSB Database schema. Default schema to use to resolve tables, views, etc.

&ensp; `ycsbDbSchema: User1`


**apiServer** - Load balancer service URL. hostname:port (or LB address) for nuocmd and nuodocker process to connect to.

&ensp; `apiServer: https://domain:8888`


**container** - NuoDB fully qualified image name (FQIN) for the Docker image to use

```
container: registry.connect.redhat.com/nuodb/nuodb-ce:latest
container: nuodb/nuodb-ce:latest
```


**ycsbContainer** - YCSB fully qualified image name (FQIN) for the Docker image to use

&ensp; `ycsbContainer: nuodb/ycsb:latest`
