# The NuoDB Operator
The NuoDB Kubernetes Operator deploys the NuoDB Community Edition (CE) database on OpenShift 3.11 or 4. It also supports either ephemeral or persistent storage options with configurations to run NuoDB Insights, a visual database monitoring Web UI, and start a sample SQL application (ycsb) to quickly generate a user-configurable SQL workload against the database.

The NuoDB Community Edition (CE) feature set is rich enough to allow first time users to experience all the benefits and value points of NuoDB including: 

* Ease of scale-out to meet changing application throughput requirements
* Continuous availability even in the event of common network, hardware, and software failures
* NuoDB database and workload visual monitoring with NuoDB Insights
* ANSI SQL
* ACID transactions

To trial or run a PoC of the NuoDB Enterprise Edition (EE) which also allows users to scale the Storage Manager (SM) database process, contact NuoDB Sales at sales@nuodb.com for a PoC time-based enterprise edition license.

This page is organized in the following sections:

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Install Prerequisites](#Install-Prerequisites)

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Install the NuoDB Operator](#Install-the-NuoDB-Operator)

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[Deploy the NuoDB Database](#Deploy-the-NuoDB-Database)


# Install Prerequisites

_**Note:** The instructions on this page use the Kubernetes &ensp;`kubectl` command for command portability reasons. You can replace the kubectl command with the OpenShift &ensp;`oc` command when running commands if you prefer._

### Create the "nuodb" project (if not already created)

&ensp; `kubectl new-project nuodb`

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
Run these commands as the root user (or a user with root group privileges) on each cluster node that will host NuoDB pods (containers). These commands will disable THP.
NOTE: If the nodes are rebooted THP will be reenabled by default, and the commands will need to executed again to disable THP.

```
echo madvise | sudo tee -a /sys/kernel/mm/transparent_hugepage/enabled
echo madvise | sudo tee -a /sys/kernel/mm/transparent_hugepage/defrag
```

### Set container storage pre-requisites

Red hat GlusterFS storage is the default storage class for both NuoDB Admin and Storage Manager (SM) pods. 
If you would like to change the default, please see below: 

#### FOR ON-PREM: Set container local-storage permissions on each cluster node
NOTE: When using the local disk storage option only 1 Admin pod is supported.

```
sudo mkdir -p /mnt/local-storage/disk0
sudo chmod -R 777 /mnt/local-storage/
sudo chcon -R unconfined_u:object_r:svirt_sandbox_file_t:s0 /mnt/local-storage
sudo chown -R root:root /mnt/local-storage
```
Create the Kubernetes storage class "local-disk" and persistent volume

&ensp; `kubectl create -f nuodb-operator/deploy/local-disk-class.yaml`

Set the Kubernetes storage class to use in cr.yaml

```
adminStorageClass: local-disk
smStorageClass: local-disk
```

#### FOR Amazon AWS: Set the Kubernetes storage class to use in cr.yaml

```
adminStorageClass: gp2
smStorageClass: gp2
```

#### FOR Google GCP: Set the Kubernetes storage class to use in cr.yaml 

```
adminStorageClass: standard
smStorageClass: standard
```

### Node Labeling
Label the nodes you want to run NuoDB pods.

&ensp; `kubectl  label node <node name> nuodb.com/zone=a`

_**Note:** The label value, in this example "a", can be any value._

Next, label one of these nodes as your storage node. This is the node that will host your NouDB Storage Manager (SM) pod and is where you database persistent storage will reside. Ensure there is sufficient disk space. To create this label run:

&ensp; `kubectl  label node $STORAGE_NODE nuodb.com/node-type=storage`

### Create the NuoDB Community Edition (CE) license file

&ensp; `kubectl create configmap nuodb-lic-configmap -n $OPERATOR_NAMESPACE --from-literal=nuodb.lic=""`

### Create the Kubernetes image pull secret to access the Red Hat Container Catalog (RHCC).
NOTE: If using Quay.io to pull the NuoDB Operator image, a secret is not required because the NuoDB Quay.io repository is public.

This secret will be used to pull the NuoDB Operator and NuoDB container images from the  Red Hat Container
Catalog (RHCC). Enter your Red Hat login credentials for the --docker-username and --docker-password values.

```
kubectl  create secret docker-registry pull-secret \
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
   toolbar. The STATUS column should show "Install Succeeded".
8. Select &ensp;`Status` under the &ensp;`Projects` on the left toolbar to view your running Operator.

## OpenShift 3.11 

### Install the Operator Lifecycle Manager (OLM)
```
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.10.1/crds.yaml
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.10.1/olm.yaml
```
### Run the NuoDB Operator yaml files
```
kubectl create -f catalogSource.yaml 
kubectl create -f cluster_role_binding.yaml
kubectl create -n $OPERATOR_NAMESPACE -f operatorGroup.yaml
kubectl create -n $OPERATOR_NAMESPACE -f cluster_role.yaml
kubectl create -n $OPERATOR_NAMESPACE -f role.yaml
kubectl create -n $OPERATOR_NAMESPACE -f role_binding.yaml
kubectl create -n $OPERATOR_NAMESPACE -f service_account.yaml 
kubectl create -f olm-catalog/nuodb-operator/0.0.4/nuodb.crd.yaml 
sed "s/placeholder/$OPERATOR_NAMESPACE/" olm-catalog/nuodb-operator/0.0.4/nuodb.v0.0.4.clusterserviceversion.yaml > nuodb-csv.yaml
kubectl create  -n $OPERATOR_NAMESPACE -f nuodb-csv.yaml
 ```

# Deploy the NuoDB Database
To deploy the NuoDB database into your Kubernetes cluster, run the following command:

 ```
kubectl create -n $OPERATOR_NAMESPACE -f deploy/cr.yaml
 ```

_**Note:** Before running the above create Custom Resource file command, this is where you have the option to configure your database just the way you want it._

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
  smCount: 1
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

### Check the status of NuoDB Insights visual monitoring tool
If you enabled NuoDB Insights (highly recommended) you can confirm it's run status by running:

&ensp; `oc exec -it nuodb-insights -c insights -- nuoca check insights`

# Remove the NuoDB database
```
kubectl delete -n $OPERATOR_NAMESPACE pvc --all 
```
Note: Delete the NuoDB Storage Manager(SM) disk storage
OpenShift 4 example: 
```
ssh -i ~/Documents/cluster.pem $JUMP_HOST
ssh -i ~/.ssh/cluster.pem core@ip-n-n-n-n.ec2.internal  'rm -rf /mnt/local-storage/disk0/*'
```
Delete the NuoDB database
```
kubectl delete nuodb nuodb
```
Note: Delete the nuodb database finalizer by running this command, remove the finalizer, and run the final nuodb delete commmand
```
kubectl edit nuodb nuodb
kubectl delete nuodb nuodb
```
### Remove local-disk storage class (if running on-prem)
```
kubectl delete -f local-disk-class.yaml
```

# Remove the NuoDB Operator

```
kubectl delete configmap nuodb-lic-configmap -n $OPERATOR_NAMESPACE

cd nuodb-operator/deploy
kubectl delete -n $OPERATOR_NAMESPACE -f nuodb-csv.yaml
kubectl delete -f catalogSource.yaml
kubectl delete -f cluster_role_binding.yaml
kubectl delete -n $OPERATOR_NAMESPACE -f operatorGroup.yaml
kubectl delete -n $OPERATOR_NAMESPACE -f cluster_role.yaml
kubectl delete -n $OPERATOR_NAMESPACE -f role.yaml
kubectl delete -n $OPERATOR_NAMESPACE -f role_binding.yaml
kubectl delete -n $OPERATOR_NAMESPACE -f service_account.yaml
kubectl delete -f olm-catalog/nuodb-operator/0.0.4/nuodb.crd.yaml
```
Note: Delete the crd finalizer by running this command, remove the finalizer, and run the final crd delete commmand
```
kubectl edit crd nuodbs.nuodb.com
kubectl delete crd nuodbs.nuodb.com
 
kubectl delete project $OPERATOR_NAMESPACE
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
