from pulumi import Output
import pulumi_aws as aws


vpc = aws.ec2.Vpc(
    "vpc",
    cidr_block="10.0.0.0/16",
)
efs_sg = aws.ec2.SecurityGroup(
    "efs-sg",
    vpc_id=vpc.id,
    ingress=[
        aws.ec2.SecurityGroupIngressArgs(
            protocol="tcp", from_port=2049, to_port=2049, cidr_blocks=[vpc.cidr_block]
        )
    ],
    egress=[
        aws.ec2.SecurityGroupEgressArgs(
            protocol="-1", from_port=0, to_port=0, cidr_blocks=["0.0.0.0/0"]
        )
    ],
)

efs = aws.efs.FileSystem(
    "efs",
    encrypted=True,
    performance_mode="generalPurpose",
    throughput_mode="bursting",
)

private_subnets_result = vpc.id.apply(
    lambda vpc_id: aws.ec2.get_subnets(
        [
            aws.ec2.GetSubnetFilterArgs(name="vpc-id", values=[vpc_id]),
            aws.ec2.GetSubnetFilterArgs(name="tag:Environment", values=["Private"]),
        ]
    )
)
mount_points = private_subnets_result.apply(
    lambda res: map(
        lambda i, snet_id: aws.efs.MountTarget(
            f"aws-efs-{i}",
            file_system_id=efs.id,
            subnet_id=snet_id,
            security_groups=[efs_sg.id],
        ),
        enumerate(res.ids),
    )
)

cluster = aws.ecs.Cluster("cluster")

task = aws.ecs.TaskDefinition()