local c = import 'promtest.libsonnet'; // provided by promtest-jsonnet

local config = std.extVar("main.yml");
local queryPattern = config.parameters.appuio_reporting_aldebaran.rules.cloud_kubernetes.query_pattern ;
local query = queryPattern % {
  cloud_provider: "aws",
  distribution: "eks",
  vshn_service_level: "best_effort",
};

local commonLabels = {
  cluster_id: 'c-managed-kubernetes',
  tenant_id: 't-managed-kubernetes',
  vshn_service_level: 'best_effort',
  sales_order: 'SO123123',
  cloud_provider: 'aws',
  distribution: 'eks',
};

local baseSeries = {
  appNodeCPUInfoLabel0: c.series('node_cpu_info', commonLabels {
    instance: 'app-test',
    cpu: '0',
  }, '1x120'),
  appNodeCPUInfoLabel1: c.series('node_cpu_info', commonLabels {
    instance: 'app-test',
    cpu: '1',
  }, '1x120'),
  appNodeCPUInfoLabel2: c.series('node_cpu_info', commonLabels {
    instance: 'app-test2',
    cpu: '0',
  }, '1x120'),
  appuioInfoLabel: c.series('appuio_managed_info', commonLabels, '1x120'),
};

local baseCalculatedLabels = {
  cluster_id: "c-managed-kubernetes",
  sales_order: "SO123123",
};

{
  tests: [
    c.test(
      'two app CPUs and one storage CPU',
      baseSeries,
      query,
      [
        {
          labels: c.formatLabels(baseCalculatedLabels {
          }),
          value: 3,
        },
      ]
    ),

  ],
}
