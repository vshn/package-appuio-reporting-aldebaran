local c = import 'promtest.libsonnet';  // provided by promtest-jsonnet

local config = std.extVar('main.yml');
local queryPattern = config.parameters.appuio_reporting_aldebaran.rules.appuio_managed_core.query_pattern;

local appParams = {
  cloud_provider: 'baremetal',
  distribution: 'oke',
  vshn_service_level: 'best_effort',
};

local commonLabels = {
  cluster_id: 'c-managed-openshift',
};

local infoLabels = commonLabels {
  tenant_id: 't-managed-openshift',
  vshn_service_level: 'best_effort',
  cloud_provider: 'baremetal',
  distribution: 'oke',
  sales_order: 'SO123123',
};

local baseSeries = {
  appNodeRoleLabel: c.series('kube_node_role', commonLabels {
    node: 'app-test',
    role: 'worker',
  }, '1x120'),

  appNodeCPUInfoLabel0: c.series('node_cpu_info', commonLabels {
    instance: 'app-test',
    cpu: '1',
    core: '0',
  }, '1x120'),
  appNodeCPUInfoLabel2: c.series('node_cpu_info', commonLabels {
    instance: 'app-test',
    cpu: '2',
    core: '0',
  }, '1x120'),
  appNodeCPUInfoLabel1: c.series('node_cpu_info', commonLabels {
    instance: 'app-test',
    cpu: '1',
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

local displayNameChange = {
  appNodeRoleLabel: c.series('kube_node_role', commonLabels {
    node: 'app-test',
    role: 'worker',
    cluster_name: 'foo',
  }, '1x60 _x60') + c.series('kube_node_role', commonLabels {
    node: 'app-test',
    role: 'worker',
    cluster_name: 'Foo',
  }, '_x60 1x60'),

  appNodeCPUInfoLabel0: c.series('node_cpu_info', commonLabels {
    instance: 'app-test',
    cpu: '1',
    core: '0',
    cluster_name: 'foo',
  }, '1x60 _x60') + c.series('node_cpu_info', commonLabels {
    instance: 'app-test',
    cpu: '1',
    core: '0',
    cluster_name: 'Foo',
  }, '_x60 1x60'),
  appNodeCPUInfoLabel2: c.series('node_cpu_info', commonLabels {
    instance: 'app-test',
    cpu: '2',
    core: '0',
    cluster_name: 'foo',
  }, '1x60 _x60') + c.series('node_cpu_info', commonLabels {
    instance: 'app-test',
    cpu: '2',
    core: '0',
    cluster_name: 'Foo',
  }, '_x60 1x60'),
  appNodeCPUInfoLabel1: c.series('node_cpu_info', commonLabels {
    instance: 'app-test',
    cpu: '1',
    core: '1',
    cluster_name: 'foo',
  }, '1x60 _x60') + c.series('node_cpu_info', commonLabels {
    instance: 'app-test',
    cpu: '1',
    core: '1',
    cluster_name: 'Foo',
  }, '_x60 1x60'),

  appuioInfoLabel:
    c.series('appuio_managed_info', infoLabels { cluster_name: 'foo' }, '1x60 _x60') +
    c.series('appuio_managed_info', infoLabels { cluster_name: 'Foo' }, '_x60 1x60'),
};

local baseCalculatedLabels = {
  cluster_id: 'c-managed-openshift',
  sales_order: 'SO123123',
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
            role: 'worker',
          }),
          value: 2,
        },
      ]
    ),
    c.test(
      'two app CPUs with display name change',
      baseSeries + displayNameChange,
      queryPattern % appParams,
      [
        {
          labels: c.formatLabels(baseCalculatedLabels {
            role: 'worker',
          }),
          value: 2,
        },
      ]
    ),
    c.test(
      'no openshift',
      baseSeries {
        appuioInfoLabel: c.series('appuio_managed_info', infoLabels { distribution: 'openshift4' }, '1x120'),
      },
      queryPattern % appParams,
      [
      ]
    ),
  ],
}
