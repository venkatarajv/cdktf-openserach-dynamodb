
import { Construct } from "constructs";
import { App, TerraformStack, CloudBackend, NamedCloudWorkspace, TerraformOutput } from "cdktf";
import {
  dataAwsRegion,
  provider,
  dynamodbTable,
  opensearchDomain,
  dataAwsCallerIdentity,
} from "@cdktf/provider-aws";
import {Lambda} from "./.gen/modules/lambda";
import {Cloudwatch} from "./.gen/modules/cloudwatch";


class MyStack extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    new provider.AwsProvider(this, "aws", {
      region: "us-east-1",
    });

    const region = new dataAwsRegion.DataAwsRegion(this, "region");
    const aws_caller_identity = new dataAwsCallerIdentity.DataAwsCallerIdentity(this, "identity");

    const table = new dynamodbTable.DynamodbTable(this, "Hello", {
      name: `oslash`,
      hashKey: "oslash",
      attribute: [{ name: "id", type: "S" }],
      billingMode: "PAY_PER_REQUEST",
    });
    table.addOverride("hash_key", "id");
    table.addOverride("lifecycle", { create_before_destroy: true });

    new TerraformOutput(this, "table_name", {
      value: table.name,
    });

    const domain = new opensearchDomain.OpensearchDomain(this, "opensearch", {
      domainName : "oslash",
      engineVersion: "Elasticsearch_7.10",
      clusterConfig: {
        instanceType : "r4.large.search"
      },
      advancedSecurityOptions:{
        enabled: true,
        internalUserDatabaseEnabled: true,
        masterUserOptions:{
          masterUserName: "venkat",
          masterUserPassword: "EBecsSer1$1"
        }
      },
      encryptAtRest:{
        enabled: true
      },
      domainEndpointOptions:{
        enforceHttps: true,
        tlsSecurityPolicy: "Policy-Min-TLS-1-2-2019-07"
      },
      nodeToNodeEncryption:{
        enabled: true,
      },
      ebsOptions:{
        ebsEnabled: true,
        volumeSize: 10
      },

      accessPolicies: JSON.stringify({
        "Version": "2012-10-17",
        "Statement": [
          {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": `arn:aws:es:${region.name}:${aws_caller_identity.accountId}:domain/"oslash-domain"/*`,
            "Condition": {
              "IpAddress": {"aws:SourceIp": ["66.193.100.22/32"]}
            }
          }
        ]
      })

    });

   new Lambda(this,"lambda",{
      tableName: [table.name],
      endpoint: domain.endpoint,
      dynamodbTableArn: table.arn
    })

    // new TerraformOutput(this, "lambda-call", {
    //   value: lambda.node,
    // });

    new Cloudwatch(this,"cloudwatch-alerts",{
      domainName: domain.domainName,
      snsTopicPrefix: "oslash-",
      cpuUtilizationThreshold: 70,
      freeStorageSpaceThreshold: 30,
    })

    // new TerraformOutput(this, "alarams", {
    //   value: cloudwatch.alarmFreeStorageSpaceTotalTooLowPeriods,
    // });

 }

}


const app = new App();
const stack = new MyStack(app, "oslash");
new CloudBackend(stack, {
  hostname: "app.terraform.io",
  organization: "venkataraj",
  workspaces: new NamedCloudWorkspace("oslash")
});
app.synth();
