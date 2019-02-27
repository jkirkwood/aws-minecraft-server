const util = require('util');
const AWS = require('aws-sdk');

exports.handler = async (event) => {
  const region = process.env.AWS_REGION;

  // Set the region
  AWS.config.update({region});

  // Get instance id of minecraft server
  const ssm = new AWS.SSM({apiVersion: '2014-11-06'});

  const parameter = await util.promisify(ssm.getParameter.bind(ssm))(
    {Name: "/minecraft-server/server-instance-id"}
  );

  const instanceId = parameter.Parameter.Value;

  // Create EC2 service object
  const ec2 = new AWS.EC2({apiVersion: '2016-11-15'});

  const instances = await util.promisify(ec2.describeInstances.bind(ec2))(
    {InstanceIds: [instanceId]}
  );
  const instance = instances.Reservations[0].Instances[0];

  const response = {
    statusCode: 200,
    body: 'OK',
    headers: {
      'content-type': 'text/plain',
      'strict-transport-security': 'max-age=31536000'
    }
  };

  if (!instance) {
    response.statusCode = 404;
    response.body = "The Minecraft server instance was not found."
    return response;
  }

  const state = instance.State.Name;

  if (event.path === '/') {
    response.body = `The minecraft server is currently ${state}.`;
  }
  else if (event.path === '/start') {
    if (state === "running") {
      response.body = "The Minecraft server available at minecraft.fastigy.com."
      return;
    }

    await util.promisify(ec2.startInstances.bind(ec2))({
      InstanceIds: [instanceId]
    });

    response.body = "The minecraft server is booting up and will be available at minecraft.fastigy.com shortly...";
  }
  else if (event.path === '/stop') {
    if (state === "stopped") {
      response.body = "The Minecraft server is already stopped."
      return;
    }

    await util.promisify(ec2.stopInstances.bind(ec2))({
      InstanceIds: [instanceId]
    });

    response.body = "The minecraft server is now shutting down...";
  }
  else {
    response.statusCode = 404;
    response.body = "Not found";
  }

  return response;
};