local c = import 'promtest.libsonnet';  // provided by promtest-jsonnet

local config = std.extVar('main.yml');
local queryPattern = config.parameters.appuio_reporting_aldebaran.rules.appuio_cloud_compute.query_pattern;
local query = queryPattern % {
  node_class: 'flex',
  zone: 'c-appuio-cloudscale-lpg-2',
  cpu_ratio: '4294967296',
  name: 'The Amazing Appuio Cluster',
};

local commonLabels = {
  cluster_id: 'c-appuio-cloudscale-lpg-2',
  tenant_id: 'c-appuio-cloudscale-lpg-2',
};

// One running pod, minimal (=1 byte) memory request and usage, no CPU request
// 10 samples
local baseSeries = {
  flexNodeLabel: c.series('kube_node_labels', commonLabels {
    label_appuio_io_node_class: 'flex',
    label_kubernetes_io_hostname: 'flex-x666',
    node: 'flex-x666',
  }, '1x120'),
  testprojectNamespaceOrgLabel: c.series('kube_namespace_labels', commonLabels {
    namespace: 'testproject',
    label_appuio_io_organization: 'cherry-pickers-inc',
  }, '1x120'),
  testOrgInfo: c.series('appuio_control_organization_info', { namespace: 'appuio-control-api-production', sales_order: 'SO234234', organization: 'cherry-pickers-inc' }, '1x120'),
  local podLbls = commonLabels {
    namespace: 'testproject',
    pod: 'running-pod',
    uid: '35e3a8b1-b46d-496c-b2b7-1b52953bf904',
  },
  // Phases
  runningPodPhase: c.series('kube_pod_status_phase', podLbls {
    phase: 'Running',
  }, '1x120'),
  // Requests
  runningPodMemoryRequests: c.series('kube_pod_container_resource_requests', podLbls {
    resource: 'memory',
    node: 'flex-x666',
  }, '1x120'),
  runningPodCPURequests: c.series('kube_pod_container_resource_requests', podLbls {
    resource: 'cpu',
    node: 'flex-x666',
  }, '0x120'),
  // Real usage
  runningPodMemoryUsage: c.series('container_memory_working_set_bytes', podLbls {
    image: 'busybox',
    node: 'flex-x666',
  }, '1x120'),
};

local baseCalculatedLabels = {
  cluster_id: 'c-appuio-cloudscale-lpg-2',
  label_appuio_io_node_class: 'flex',
  name: 'The Amazing Appuio Cluster',
  namespace: 'testproject',
  organization: 'cherry-pickers-inc',
  sales_order: 'SO234234',
};

// Constants from the query
local minMemoryRequestMib = 128;
local cloudscaleFairUseRatio = 4294967296;

{
  tests: [
    c.test('minimal pod',
           baseSeries,
           query,
           {
             labels: c.formatLabels(baseCalculatedLabels),
             value: minMemoryRequestMib * 60,
           }),
    c.test('pod with higher memory usage',
           baseSeries {
             runningPodMemoryUsage+: {
               values: '%sx120' % (500 * 1024 * 1024),
             },
           },
           query,
           {
             labels: c.formatLabels(baseCalculatedLabels),
             value: 500 * 60,
           }),
    c.test('pod with higher memory requests',
           baseSeries {
             runningPodMemoryRequests+: {
               values: '%sx120' % (500 * 1024 * 1024),
             },
           },
           query,
           {
             labels: c.formatLabels(baseCalculatedLabels),
             value: 500 * 60,
           }),
    c.test('pod with CPU requests violating fair use',
           baseSeries {
             runningPodCPURequests+: {
               values: '1x120',
             },
           },
           query,
           {
             labels: c.formatLabels(baseCalculatedLabels),
             // See per cluster fair use ratio in query
             //  value: 2.048E+04,
             value: (cloudscaleFairUseRatio / 1024 / 1024) * 60,
           }),
    c.test('non-running pods are not counted',
           baseSeries {
             local lbls = commonLabels {
               namespace: 'testproject',
               pod: 'succeeded-pod',
               uid: '2a7a6e32-0840-4ac3-bab4-52d7e16f4a0a',
             },
             succeededPodPhase: c.series('kube_pod_status_phase', lbls {
               phase: 'Succeeded',
             }, '1x120'),
             succeededPodMemoryRequests: c.series('kube_pod_container_resource_requests', lbls {
               resource: 'memory',
               node: 'flex-x666',
             }, '1x120'),
             succeededPodCPURequests: c.series('kube_pod_container_resource_requests', lbls {
               node: 'flex-x666',
               resource: 'cpu',
             }, '1x120'),
           },
           query,
           {
             labels: c.formatLabels(baseCalculatedLabels),
             value: minMemoryRequestMib * 60,
           }),
    c.test('unrelated kube_node_labels changes do not throw errors - there is an overlap since series go stale only after a few missed scrapes',
           baseSeries {
             flexNodeLabelUpdated: self.flexNodeLabel {
               _labels+:: {
                 label_csi_driver_id: '18539CC3-0B6C-4E72-82BD-90A9BEF7D807',
               },
               values: '_x30 1x30 _x60',
             },
           },
           query,
           {
             labels: c.formatLabels(baseCalculatedLabels),
             value: minMemoryRequestMib * 60,
           }),
    c.test('node class adds do not throw errors - there is an overlap since series go stale only after a few missed scrapes',
           baseSeries {
             flexNodeLabel+: {
               _labels+:: {
                 label_appuio_io_node_class:: null,
               },
               values: '1x60',
             },
             flexNodeLabelUpdated: super.flexNodeLabel {
               values: '_x30 1x90',
             },
           },
           query,
           [
             // I'm not sure why this is 61min * minMemoryRequestMib. Other queries always result in 60min
             // TODO investigate where the extra min comes from
             {
               labels: c.formatLabels(baseCalculatedLabels),
               value: minMemoryRequestMib * 46,
             },
           ]),

    c.test('unrelated kube_namespace_labels changes do not throw errors - there is an overlap since series go stale only after a few missed scrapes',
           baseSeries {
             testprojectNamespaceOrgLabelUpdated: self.testprojectNamespaceOrgLabel {
               _labels+:: {
                 custom_appuio_io_myid: '672004be-a86b-44e0-b446-1255a1f8b340',
               },
               values: '_x30 1x30 _x60',
             },
           },
           query,
           {
             labels: c.formatLabels(baseCalculatedLabels),
             value: minMemoryRequestMib * 60,
           }),

    c.test('organization changes do not throw many-to-many errors - there is an overlap since series go stale only after a few missed scrapes',
           baseSeries {
             testprojectNamespaceOrgLabel+: {
               // We cheat here and use an impossible value.
               // Since we use min() and bottomk() in the query this priotizes this series less than the other.
               // It's ugly but it prevents flaky tests since otherwise one of the series gets picked randomly.
               // Does not influence the result. The result is floored to a minimum of 128MiB.
               values: '2x120',
             },
             testprojectNamespaceOrgLabelUpdated: self.testprojectNamespaceOrgLabel {
               _labels+:: {
                 label_appuio_io_organization: 'carrot-pickers-inc',
               },
               values: '_x60 1x60',
             },
             testOrgInfoUpdated: self.testOrgInfo {
               _labels+:: {
                 organization: 'carrot-pickers-inc',
                 sales_order: 'SO456456',
               },
             },
           },
           query,
           [
             // I'm not sure why this is 61min * minMemoryRequestMib. Other queries always result in 60min
             // TODO investigate where the extra min comes from
             {
               labels: c.formatLabels(baseCalculatedLabels),
               value: minMemoryRequestMib * 30,
             },
             {
               labels: c.formatLabels(baseCalculatedLabels {
                 organization: 'carrot-pickers-inc',
                 sales_order: 'SO456456',
               }),
               value: minMemoryRequestMib * 31,
             },
           ]),

    c.test('duplicated organization metrics do not throw many-to-many errors - there can an overlap on control-api restarts',
           baseSeries {
             testOrgInfo+: {
               _labels+:: {
                 pod: 'old-pod',
                 instance: '192.0.2.16:8080',
               },
               values: '2x120',
             },
             testOrgInfoUpdated: self.testOrgInfo {
               _labels+:: {
                 pod: 'new-pod',
                 instance: '192.0.2.29:8080',
               },
               values: '_x60 1x60',
             },
           },
           query,
           [
             {
               labels: c.formatLabels(baseCalculatedLabels),
               value: minMemoryRequestMib * 60,
             },
           ]),
  ],
}
