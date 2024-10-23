local c = import 'promtest.libsonnet'; // provided by promtest-jsonnet

local config = std.extVar("main.yml");
local queryPattern = config.parameters.appuio_reporting_aldebaran.rules.cilium_addons.query_pattern ;

local advancedParams = {
  vshn_service_level: "best_effort",
  cilium_addon: 'advanced',
  addon_display: "Advanced Networking",
};
local tetragonParams = {
  vshn_service_level: "best_effort",
  cilium_addon: 'tetragon',
  addon_display: "Tetragon",
};

local commonLabels = {
  cluster_id: 'c-managed-openshift',
};

local infoLabels = commonLabels {
  tenant_id: 't-managed-openshift',
  vshn_service_level: 'best_effort',
  cilium_addons: 'cilium-advanced,tetragon',
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
      'total CPUs',
      baseSeries,
      queryPattern % advancedParams,
      [
        {
          labels: c.formatLabels(baseCalculatedLabels {
            cilium_addon: "advanced",
            addon_display: "Advanced Networking",
          }),
          value: 3,
        },
      ]
    ),
    c.test(
      'total CPUs',
      baseSeries,
      queryPattern % tetragonParams,
      [
        {
          labels: c.formatLabels(baseCalculatedLabels {
            cilium_addon: "tetragon",
            addon_display: "Tetragon",
          }),
          value: 3,
        },
      ]
    )
  ],
}
