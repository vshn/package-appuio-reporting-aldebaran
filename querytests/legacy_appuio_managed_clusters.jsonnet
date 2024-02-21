local c = import 'promtest.libsonnet'; // provided by promtest-jsonnet

local config = std.extVar("main.yml");
local queryPattern = config.parameters.appuio_reporting_aldebaran.rules.legacy_appuio_managed_clusters.query_pattern ;
local query = queryPattern % {
  cloud_provider: "cloudscale",
  vshn_service_level: "standard",
};

local commonLabels = {
  cluster_id: 'c-managed-openshift',
};

local infoLabels = commonLabels {
  tenant_id: 't-managed-openshift',
  vshn_service_level: 'standard',
  cloud_provider: 'cloudscale',
  sales_order: 'SO123123'
};

local baseSeries = {
  appuioInfoLabel: c.series('appuio_managed_info', infoLabels, '1x120'),
  appuioInfoLabel2: c.series('appuio_managed_info', infoLabels {
    vshn_service_level: 'best_effort',
  }, '1x120'),
};

local baseCalculatedLabels = {
  cluster_id: "c-managed-openshift",
  sales_order: "SO123123",
};

{
  tests: [
    c.test(
      'one cluster',
      baseSeries,
      query,
      [
        {
          labels: c.formatLabels(baseCalculatedLabels {}),
          value: 1,
        },
      ]
    ),

  ],
}
