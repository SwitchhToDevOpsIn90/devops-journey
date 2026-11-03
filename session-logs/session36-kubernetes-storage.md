# Session 36 - Kubernetes Storage

## What was done
- Proved ephemeral storage on Minikube: a file in /tmp was lost when the pod was replaced (storage-demo ...ndwwf to ...qp7zd), while an accidental rerun on the same pod kept the file
- Built a PVC and saw a PV created automatically through the default StorageClass (dynamic provisioning)
- Mounted the PVC at /data: the file survived pod replacement (...mjb92 to ...jzzdh)
- Boundary test: deleting the PVC under reclaim policy Delete removed the PV, and the file was gone after recreating everything
- Built a 2-replica StatefulSet with a headless Service and volumeClaimTemplates: web-0 returned with its own name and its own file after deletion
- Created a real EKS cluster (session36-storage, eu-north-1, t3.small, NAT gateway disabled) with the aws-ebs-csi-driver add-on
- Created a gp3 StorageClass with WaitForFirstConsumer
- Ran PostgreSQL 16 as a StatefulSet: the PVC created a real 1 GB gp3 EBS volume (in-use, eu-north-1a)
- Inserted customer rows, deleted postgres-0, and confirmed the same rows on the same volume afterwards
- Ran a pg_dump backup job from a CronJob: db.sql was 1,053 bytes and contained the customer row

## Why this matters
Stateful workloads are where Kubernetes mistakes become data loss. The session proved each layer separately, then proved the chain on real AWS: PVC, StorageClass, EBS CSI driver, EBS volume. The rule: the data lives in the PV, the PVC keeps the PV alive, and pods come and go.

## Teardown - verified, disks before cluster
- PVCs deleted before the cluster, so the CSI driver could remove the EBS volumes
- EKS clusters: none listed
- CloudFormation session36 stacks: none listed
- VPCs: default VPC only
- Running EC2 instances: ServerWatch t3.micro only
- Unattached EBS volumes: none
- IAM roles named session36: none
- All 5 temporary permissions removed from mac-cli-user; AccessDeniedException on eks:ListClusters proved it

## Honest gaps
- The Deployment-deletion test (Test 1) was run, but its output was not captured in these notes
- Retain was explained but not tested
- The actual cost of the session is still to be checked against the AWS Billing page

## Key gotchas
- Two pasted blocks joined together, so a pod was never deleted. Old and New showing the same name exposed it. Paste one block at a time
- A new EBS volume has lost+found at its root, so PGDATA must point to a subfolder
- EKS 1.30+ has no default StorageClass, so storageClassName is set explicitly
- A backup in the same cluster is not disaster recovery. Real backups go off-cluster
