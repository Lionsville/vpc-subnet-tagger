import os
import logging
import boto3


logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))


def lookup_subnet_name(subnet_id):
   ec2_client = boto3.client('ec2')
   response = ec2_client.describe_subnets(SubnetIds=[subnet_id])
   logger.debug(f"Subnets lookup for subnet id {subnet_id} yielded: {response}")

   if not response.get('Subnets', []):
      logger.error(f"Cannot find subnet for subnet id {subnet_id}!")
      
   tags = response['Subnets'][0].get('Tags', []) if response['Subnets'] else []
   if not tags:
      logger.error(f"Cannot find tags for subnet id {subnet_id}!")
      
   filtered_tags = [tag for tag in tags if tag['Key'] == "Name"]
   subnet_name = filtered_tags[0]["Value"] if filtered_tags else None
   if not subnet_name:
      logger.error(f"Cannot find name for subnet id {subnet_id}!")
   else:
      subnet_name = subnet_name[subnet_name.index(" ") + 1:subnet_name.rindex(" ")]
      
   logger.info(f"Found name {subnet_name}, AccountID {account_id}, subnetType {subnet_type}, aws-cdk:subnet-type {cdk_subnet_type} for subnet id {subnet_id}!")
   return subnet_name

def assume_role(account_id):
   sts_client = boto3.client('sts')
   role_to_assume_arn = f"arn:aws:iam::{account_id}:role/LambdaTaggerRole"
   response = sts_client.assume_role(
      RoleArn=role_to_assume_arn,
      RoleSessionName='AssumeRoleInChildAccount'
   )
   logger.debug(f"Assuming role for {role_to_assume_arn} yielded: {response}")
   
   if not 'Credentials' in response:
      logger.error(f"Assuming role for {role_to_assume_arn} failed!")
      return None

   credentials = response['Credentials']
   ec2_client = boto3.client(
      'ec2',
      aws_access_key_id=credentials['AccessKeyId'],
      aws_secret_access_key=credentials['SecretAccessKey'],
      aws_session_token=credentials['SessionToken']
   )
   return ec2_client


def tag_subnet(ec2_client, subnet_id, tag_key, tag_value):
   response = ec2_client.create_tags(
      Resources=[subnet_id],
      Tags=[{'Key': tag_key, 'Value': tag_value}]
   )
   logger.info(f"Tagged subnet {subnet_id} with the tag {tag_key}: {tag_value} yielded: {response}")


def lambda_handler(event, _):
   logger.info(f"Lambda was called with: {event}")

   resource_arns = event["detail"]["requestParameters"]["resourceArns"]
   for arn in resource_arns:
    if "subnet" not in arn:
      logger.warn("The lambda was called with a wrong event!")
      continue
    arn.rfind("/")
    subnet_id = arn[arn.rfind("/") + 1:]
    subnet_name = lookup_subnet_name(subnet_id)
    ec2_client = assume_role(account_id)
    if subnet_name and ec2_client:
        tag_subnet(ec2_client, subnet_id, 'Name', subnet_name)
    else:
        raise Exception("Couldn't tag the resource in child account!")
