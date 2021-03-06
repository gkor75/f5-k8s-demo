# MyTypeLB: CRD

The following is a simple PoC of using type:LoadBalancer with
Container Ingress Services 2.2.0 it generates TransportServer
CRD instances to support L4 TCP services.

**This requires that you are running CIS in CRD mode!**

The process is to assign a service that includes "loadBalancerIP" OR use an IP address from a pre-allocated range (configurable via ConfigMap)

This script will identify these resources and create a BIG-IP
VirtaulServer with either the  IP address specified or pick from
an allocated range of IPs.

## Installing the script (standalone)

```
pip install -r requirements.txt
```
## Setting up the config

Modify 'data.json' to match your network and create a configuration file.
The script is hardcoded to look for a configmap "chenpam" in the namespace
"default"

An example of data.json
```
{
  "ranges": [
    "10.1.10.0/24"
  ],
  "allocated": [],
  "conflict": ["10.1.10.1"],
  "next": "10.1.10.81"
}
```
* "ranges" are IP ranges that you want to use.  
* "allocated" will be updated with any IPs that are being used by this "controller".
* "conflict" is a list of IPs that you want to exclude.
* "next" refers to the IP that you would like to use next.

```
kubectl create cm chenpam --from-file=config=data.json
```

## Running the Script

This script assumes that you have a kubeconfig file with
appropriate privileges.

```
# run --help to see additional options
python ./crdtypelb.py
2020-11-05 17:00:27,488 - chen_pam - INFO - creating default_my-crd-80 with IP 10.1.10.81
2020-11-05 17:00:27,509 - chen_pam - INFO - creating default_my-crd-443 with IP 10.1.10.81
2020-11-05 17:00:27,535 - chen_pam - INFO - creating nginx-ingress_nginx-ingress-crd-80 with IP 10.1.10.82
2020-11-05 17:00:27,557 - chen_pam - INFO - creating nginx-ingress_nginx-ingress-crd-443 with IP 10.1.10.82
```

## expected output.

If you start with two services w/out an IP.

```
$ oc get svc my-crd
NAME     TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
my-crd   LoadBalancer   172.30.83.160   <pending>     80:30213/TCP,443:31861/TCP   21s
$ oc get svc -n nginx-ingress nginx-ingress-crd
NAME                TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
nginx-ingress-crd   LoadBalancer   172.30.107.195   <pending>     80:30150/TCP,443:30485/TCP   42s
```
After you run the script you should see the status changed.
```$ oc get svc my-crd
NAME     TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
my-crd   LoadBalancer   172.30.83.160   10.1.10.80    80:30213/TCP,443:31861/TCP   103s
$ oc get svc -n nginx-ingress nginx-ingress-crd
NAME                TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
nginx-ingress-crd   LoadBalancer   172.30.107.195   10.1.10.81    80:30150/TCP,443:30485/TCP   103s
```
You will also see the script has created "TransportServer" entries.
```
$ oc get transportservers --all-namespaces
NAMESPACE       NAME                    AGE
default         my-crd-443              75m
default         my-crd-80               75m
nginx-ingress   nginx-ingress-crd-443   75m
nginx-ingress   nginx-ingress-crd-80    75m
```
These entries are used by CIS to generate the BIG-IP configuration.
```
admin@(bigip1)(cfg-sync Standalone)(Active)(/ocp)(tmos)# list /ltm virtual recursive one-line
ltm virtual Shared/crd_10_1_10_80_80 { creation-time 2020-11-04:04:06:38 description Shared destination 10.1.10.80:80 ip-protocol tcp last-modified-time 2020-11-04:04:06:38 mask 255.255.255.255 partition ocp persist { /Common/source_addr { default yes } } pool Shared/default_my_crd_8080 profiles { /Common/f5-tcp-progressive { } } serverssl-use-sni disabled source 0.0.0.0/0 source-address-translation { type automap } translate-address enabled translate-port enabled vs-index 48 }
ltm virtual Shared/crd_10_1_10_80_443 { creation-time 2020-11-04:04:06:38 description Shared destination 10.1.10.80:443 ip-protocol tcp last-modified-time 2020-11-04:04:06:38 mask 255.255.255.255 partition ocp persist { /Common/source_addr { default yes } } pool Shared/default_my_crd_8443 profiles { /Common/f5-tcp-progressive { } } serverssl-use-sni disabled source 0.0.0.0/0 source-address-translation { type automap } translate-address enabled translate-port enabled vs-index 47 }
ltm virtual Shared/crd_10_1_10_81_80 { creation-time 2020-11-04:04:06:38 description Shared destination 10.1.10.81:80 ip-protocol tcp last-modified-time 2020-11-04:04:06:38 mask 255.255.255.255 partition ocp persist { /Common/source_addr { default yes } } pool Shared/nginx_ingress_nginx_ingress_crd_443 profiles { /Common/f5-tcp-progressive { } } serverssl-use-sni disabled source 0.0.0.0/0 source-address-translation { type automap } translate-address enabled translate-port enabled vs-index 50 }
ltm virtual Shared/crd_10_1_10_81_443 { creation-time 2020-11-04:04:06:38 description Shared destination 10.1.10.81:443 ip-protocol tcp last-modified-time 2020-11-04:04:06:38 mask 255.255.255.255 partition ocp persist { /Common/source_addr { default yes } } pool Shared/nginx_ingress_nginx_ingress_crd_443 profiles { /Common/f5-tcp-progressive { } } serverssl-use-sni disabled source 0.0.0.0/0 source-address-translation { type automap } translate-address enabled translate-port enabled vs-index 49 }
```


## Known issues

* does not handle any DNS 

## Installing as a container.

First build the Dockerfile and push to a local repo.

Next create a service account and provide RBAC (chenpam_rbac.yaml is an example).

Deploy the container (chenpam.yaml is an example).

See the output from container.
```
2020-11-06 21:25:19,752 - chen_pam - INFO - creating default_my-crd-80 with IP 10.1.10.11
2020-11-06 21:25:19,780 - chen_pam - INFO - creating default_my-crd-443 with IP 10.1.10.11
2020-11-06 21:25:19,802 - chen_pam - INFO - creating nginx-ingress_nginx-ingress-crd-80 with IP 10.1.10.12
2020-11-06 21:25:19,857 - chen_pam - INFO - creating nginx-ingress_nginx-ingress-crd-443 with IP 10.1.10.12
```

# MyTypeLB: ConfigMap

The following is a simple PoC of using type:LoadBalancer with
Container Ingress Services 2.2.0

The process is to assign a service that includes "loadBalancerIP"

This script will identify these resources and create a BIG-IP
VirtaulServer with the IP address specified.

## Installing the script

```
pip install -r requirements.txt
```

## Running the Script

This script assumes that you have a kubeconfig file with
appropriate privileges.

```
# using AS3 configmap
./mytypelb.py
```

## Known issues

* Only uses a single port from the service (workaround: create multiple services with same loadBalancerIP 
* hardcodes "default" namespace and name of configmap
