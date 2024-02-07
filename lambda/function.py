import boto3

def lambda_handler(event, context):
    ec2_client = boto3.client('ec2')

    # Get all regions
    regions = [region['RegionName'] for region in ec2_client.describe_regions()['Regions']]

    for region in regions:
        ec2 = boto3.client('ec2', region_name=region)
        security_groups = ec2.describe_security_groups()['SecurityGroups']

        for sg in security_groups:
            for permission in sg['IpPermissions']:
                if permission.get('IpRanges'):
                    for ip_range in permission['IpRanges']:
                        if (ip_range['CidrIp'] == '0.0.0.0/0' or ip_range['CidrIp'] == '::/0') \
                                and permission['FromPort'] not in [80, 443]:
                            print(f"Security group {sg['GroupId']} in {region} allows inbound traffic from the internet on ports other than HTTP and HTTPS.")
                            # You can customize the action here, such as sending a notification or taking corrective action


