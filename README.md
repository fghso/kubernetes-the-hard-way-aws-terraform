# Kubernetes The Hard Way AWS Terraform

aws ec2 describe-instances \
  --filters Name=vpc-id,Values=<vpc-id> \
  --query 'sort_by(Reservations[].Instances[],&PrivateIpAddress)[].{d_INTERNAL_IP:PrivateIpAddress,e_EXTERNAL_IP:PublicIpAddress,a_NAME:Tags[?Key==`Name`].Value | [0],b_ZONE:Placement.AvailabilityZone,c_MACHINE_TYPE:InstanceType,f_STATUS:State.Name}' \
  --output table

ssh -i ./modules/03-compute-resources/sshkey-k8s-the-hard-way-key-pair ubuntu@<ip>
