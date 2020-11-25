# aws-parallelcluster-slurm

To install AWS ParallelCluster:
```
pip install aws-parallelcluster
```

To create a cluster, set up the `key_name`, `vpc_id`, and `master_subnet_id` in the config file, and:
```bash
pcluster create -c ./parallelcluster-config my-cluster-name
```

To SSH into the master node:
```bash
pcluster ssh -c ./parallelcluster-config my-cluster-name
```