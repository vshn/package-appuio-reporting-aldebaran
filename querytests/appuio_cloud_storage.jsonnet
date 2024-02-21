local c = import 'promtest.libsonnet'; // provided by promtest-jsonnet

local config = std.extVar("main.yml");
local queryPattern = config.parameters.appuio_reporting_aldebaran.rules.appuio_cloud_storage.query_pattern ;
local query = queryPattern % {
  storage_class: "ssd*",
  storage_type: "file",
  zone: "c-appuio-cloudscale-lpg-2",
  name: "The Amazing Appuio Cluster",
};

local commonLabels = {
  cluster_id: 'c-appuio-cloudscale-lpg-2',
  tenant_id: 'c-appuio-cloudscale-lpg-2',
};

// One pvc, minimal (=1 byte) request
// 10 samples
local baseSeries = {
  testprojectNamespaceOrgLabel: c.series('kube_namespace_labels', commonLabels {
    namespace: 'testproject',
    label_appuio_io_organization: 'cherry-pickers-inc',
  }, '1x120'),

  testOrgInfo: c.series('appuio_control_organization_info', {"namespace": "appuio-control-api-production", "sales_order": "SO234234", "organization": "cherry-pickers-inc"}, '1x120'),
  local pvcID = 'pvc-da01b12d-2e31-44da-8312-f91169256221',
  pvCapacity: c.series('kube_persistentvolume_capacity_bytes', commonLabels {
    persistentvolume: pvcID,
  }, '1x120'),
  pvInfo: c.series('kube_persistentvolume_info', commonLabels {
    persistentvolume: pvcID,
    storageclass: 'ssd',
  }, '1x120'),
  pvcRef: c.series('kube_persistentvolume_claim_ref', commonLabels {
    claim_namespace: 'testproject',
    name: 'important-database',
    persistentvolume: pvcID,
  }, '1x120'),
};

local baseCalculatedLabels = {
  cluster_id: 'c-appuio-cloudscale-lpg-2',
  namespace: 'testproject',
  storageclass: 'ssd',
  name: 'The Amazing Appuio Cluster',
  organization: 'cherry-pickers-inc',
  sales_order: 'SO234234',
  storage_type: 'file',
};

{
  tests: [
    c.test('minimal PVC',
           baseSeries,
           query,
           {
             labels: c.formatLabels(baseCalculatedLabels),
             value: 60 * 1024,
           }),
    c.test('higher than 1GiB request',
           baseSeries {
             pvCapacity+: {
               values: '%sx120' % (5 * 1024 * 1024 * 1024),
             },
           },
           query,
           {
             labels: c.formatLabels(baseCalculatedLabels),
             value: 5 * 1024 * 60,
           }),

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
             value: 60 * 1024,
           }),

    c.test('organization changes do not throw many-to-many errors - there is an overlap since series go stale only after a few missed scrapes',
           baseSeries {
             testprojectNamespaceOrgLabel+: {
               // We cheat here and use an impossible value.
               // Since we use min() and bottomk() in the query this priotizes this series less than the other.
               // It's ugly but it prevents flaky tests since otherwise one of the series gets picked randomly.
               // Does not influence the result. The result is floored to a minimum of 1GiB.
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
             {
               labels: c.formatLabels(baseCalculatedLabels),
               value: 29 * 1024,
             },
             {
               labels: c.formatLabels(baseCalculatedLabels {
                 organization: 'carrot-pickers-inc',
                 sales_order: 'SO456456',
               }),
               value: 31 * 1024,
             },
           ]),

  ],
}
