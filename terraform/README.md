# Impostor Game - Terraform Deployment

## Architecture

- **S3 Bucket**: Stores binary, index.html, and wordlists
- **EC2 Instance**: Amazon Linux 2023 running the game server
- **IAM Role**: Allows EC2 to read from S3
- **Security Group**: HTTP (8080), HTTPS (443), SSH (22)
- **Elastic IP**: Stable public IP address
- **Systemd Service**: Auto-restart on failure

## Updating the Application

To deploy a new version:

(from root)
```bash
make deploy
```

The binary is compiled and pushed to S3. The user_data script will pull the latest artifacts from S3 on instance launch, thus an instance restart (recreation) is required.

## Viewing Logs

**Note that this is not possible without opening SSH in the security group as well as having terraform create a keypair upon creation of the EC2 instance.**

```bash
# SSH into instance
ssh -i /path/to/key.pem ec2-user@<instance-ip>

# View logs
sudo journalctl -u impostor -f

# Check service status
sudo systemctl status impostor
```

## Outputs

After deployment, Terraform outputs:

- `game_url`: Direct link to access the game
- `ssh_command`: Command to SSH into the instance
- `instance_public_ip`: Public IP address
- `s3_bucket_name`: S3 bucket containing artifacts

## Cleanup

Destroy all resources:

```bash
cd terraform
terraform destroy
```

Then manually empty and delete the S3 bucket:

```bash
aws s3 rm s3://your-bucket-name --recursive
aws s3 rb s3://your-bucket-name
```

## Troubleshooting

**Can't access game:**
- Verify security group allows port 8080 from 0.0.0.0/0
- Check instance is in a public subnet
- Confirm internet gateway is attached to VPC

**Service not running:**
```bash
sudo journalctl -u impostor -n 50
sudo systemctl restart impostor
```

**S3 access denied:**
- Verify IAM role is attached to instance
- Check S3 bucket exists and has artifacts