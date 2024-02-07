import boto3
from botocore.exceptions import ClientError

def send_email(subject, body):
    # Replace these values with your own
    sender = 'your_sender_email@example.com'
    recipient = 'your_recipient_email@example.com'
    
    # Create a new SES resource
    ses = boto3.client('ses', region_name='your_ses_region')

    # Try to send the email
    try:
        # Provide the contents of the email.
        response = ses.send_email(
            Destination={
                'ToAddresses': [recipient],
            },
            Message={
                'Body': {
                    'Text': {
                        'Charset': 'UTF-8',
                        'Data': body,
                    },
                },
                'Subject': {
                    'Charset': 'UTF-8',
                    'Data': subject,
                },
            },
            Source=sender
        )
    except ClientError as e:
        print("Error sending email:", e.response['Error']['Message'])
    else:
        print("Email sent! Message ID:", response['MessageId'])

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
                            rule_detail = f"FromPort: {permission['FromPort']}, ToPort: {permission['ToPort']}, Protocol: {permission['IpProtocol']}, CidrIp: {ip_range['CidrIp']}"
                            email_subject = "Insecure Inbound Rule Detected in AWS Security Group"
                            email_body = f"Region: {region}\nSecurity Group Name: {sg['GroupName']}\nSecurity Group ID: {sg['GroupId']}\nInbound Rule Detail: {rule_detail}"
                            
                            send_email(email_subject, email_body)

