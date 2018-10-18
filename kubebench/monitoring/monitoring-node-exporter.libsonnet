local k = import "k.libsonnet";

{
  parts(nodeExporterName, namespace):: {
   
    //Node Exporter DaemonSet
    local daemonSet = {
      apiVersion: "apps/v1beta2",
      kind: "DaemonSet",
      metadata: {
        name: nodeExporterName,
        namespace: namespace,
        labels: {
          app: "prometheus",
          component: nodeExporterName
        },
      },
      spec: {
        selector: {
          matchLabels: {
            app: "prometheus",
          },
        },
        template: {
          metadata: {
            name: nodeExporterName,
            labels: {
              app: "prometheus",
              component: nodeExporterName
            },
          },
          spec: {
            containers: [
              {
                image: "quay.io/prometheus/node-exporter:v0.16.0",
                imagePullPolicy: "Always",
                name: nodeExporterName,
                ports: [
                  {
                    name: "http-node-exp",
                    containerPort: 9100,
                    hostPort: 9100,
                  },
                ],
              },
            ],
            hostNetwork: true,
            serviceAccountName: nodeExporterName,
          },
        },
      },
    }, 
    daemonSet:: daemonSet,

    //Node Exporter Service
    local service = {
      apiVersion: "v1",
      kind: "Service",
      metadata: {
        annotations: {
          "prometheus.io/scrape": "true"
        },
        name: nodeExporterName,
        namespace: namespace,
        labels: {
          app: "prometheus",
          component: nodeExporterName
        },
      },
      spec: {
        ports: [
          {
            name: "http-node-exp",
            port: 9100,
            protocol: "TCP",
          },
        ],
        selector: {
          app: "prometheus",
          component: nodeExporterName
        },
      },
    },
    service:: service,
    
    //Node Exporter Service Account
    local serviceAccount = {
      apiVersion: "v1",
      kind: "ServiceAccount",
      metadata: {
        name: nodeExporterName,
        namespace: namespace,
      },
    }, 
    serviceAccount:: serviceAccount,

    //Node Exporter Role
    local role = {
      apiVersion: "rbac.authorization.k8s.io/v1",
      kind: "Role",
      metadata: {
        name: nodeExporterName,
        namespace: namespace,
      },
      rules: [
        {
          apiGroups: ["authentication.k8s.io"], 
          resources: ["tokenreviews"],
          verbs: ["create"],
        },
        {
          apiGroups: ["authorization.k8s.io"],
          resources: ["subjectaccessreviews"],
          verbs: ["create"],
        },
      ],
    },
    role:: role,
    
    //Node Exporter Role Binding
    local roleBinding = {
      apiVersion: "rbac.authorization.k8s.io/v1",
      kind: "RoleBinding",
      metadata: {
        name: nodeExporterName,
        namespace: namespace,
      },
      roleRef: {
        apiGroup: "rbac.authorization.k8s.io",
        kind: "Role",
        name: nodeExporterName,
      },
      subjects: [
        {
          kind: "ServiceAccount",
          name: nodeExporterName,
          namespace: namespace,
        },
      ],
    },
    roleBinding:: roleBinding,

    all:: [
      self.daemonSet,
      self.service,
      self.serviceAccount,
      self.role,
      self.roleBinding,
    ],

    //Create Objects
    list(obj=self.all)::k.core.v1.list.new(obj,),
    
  },
}
