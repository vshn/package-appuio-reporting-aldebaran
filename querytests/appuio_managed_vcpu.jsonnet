local c = import 'promtest.libsonnet'; // provided by promtest-jsonnet

local config = std.extVar("main.yml");
local queryPattern = config.parameters.appuio_reporting_aldebaran.rules.appuio_managed_vcpu.query_pattern ;

local appParams = {
  cloud_provider: "cloudscale",
  vshn_service_level: "best_effort",
  distribution: "openshift4",
  role: "app",
};
local storageParams = {
  cloud_provider: "cloudscale",
  vshn_service_level: "best_effort",
  distribution: "openshift4",
  role: "storage",
};

local commonLabels = {
  cluster_id: 'c-managed-openshift',
};

local infoLabels = commonLabels {
  tenant_id: 't-managed-openshift',
  vshn_service_level: 'best_effort',
  cloud_provider: 'cloudscale',
  distribution: 'openshift4',
  sales_order: 'SO123123',
};

local baseSeries = {
  appNodeRoleLabel: c.series('kube_node_role', commonLabels {
    node: 'app-test',
    role: 'app',
  }, '1x120'),

  appNodeCPUInfoLabel0: c.series('node_cpu_info', commonLabels {
    instance: 'app-test',
    core: '0',
  }, '1x120'),
  appNodeCPUInfoLabel1: c.series('node_cpu_info', commonLabels {
    instance: 'app-test',
    core: '1',
  }, '1x120'),

  storageNodeRoleLabel: c.series('kube_node_role', commonLabels {
    node: 'storage-test',
    role: 'storage',
  }, '1x120'),

  storageNodeCPUInfoLabel0: c.series('node_cpu_info', commonLabels {
    instance: 'storage-test',
    core: '0',
  }, '1x120'),

  appuioInfoLabel: c.series('appuio_managed_info', infoLabels, '1x120'),
};

local baseCalculatedLabels = {
  cluster_id: "c-managed-openshift",
  sales_order: "SO123123",
};

{
  tests: [
    c.test(
      'two app CPUs',
      baseSeries,
      queryPattern % appParams,
      [
        {
          labels: c.formatLabels(baseCalculatedLabels {
            role: 'app',
          }),
          value: 2,
        },
      ]
    ),
    c.test(
      'and one storage CPU',
      baseSeries,
      queryPattern % storageParams,
      [
        {
          labels: c.formatLabels(baseCalculatedLabels {
            role: 'storage',
          }),
          value: 1,
        },
      ]
    ),
  ],
}
