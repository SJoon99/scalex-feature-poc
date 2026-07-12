{{- define "rgw-analysis-web.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "rgw-analysis-web.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "rgw-analysis-web.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "rgw-analysis-web.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "rgw-analysis-web.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "rgw-analysis-web.commonLabels" -}}
helm.sh/chart: {{ include "rgw-analysis-web.chart" . }}
app.kubernetes.io/name: {{ include "rgw-analysis-web.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: rgw-analysis-web
scalex.io/release: {{ .Values.releaseLabel | quote }}
{{- end -}}

{{- define "rgw-analysis-web.componentLabels" -}}
{{ include "rgw-analysis-web.commonLabels" .root }}
app.kubernetes.io/component: {{ .component | quote }}
scalex.io/component: {{ .component | quote }}
{{- end -}}

{{- define "rgw-analysis-web.awsEnv" -}}
- name: S3_ENDPOINT_URL
  valueFrom:
    configMapKeyRef:
      name: {{ include "rgw-analysis-web.fullname" . }}-runtime
      key: S3_ENDPOINT_URL
- name: S3_BUCKET
  valueFrom:
    configMapKeyRef:
      name: {{ include "rgw-analysis-web.fullname" . }}-runtime
      key: S3_BUCKET
- name: AWS_DEFAULT_REGION
  valueFrom:
    configMapKeyRef:
      name: {{ include "rgw-analysis-web.fullname" . }}-runtime
      key: AWS_DEFAULT_REGION
- name: AWS_EC2_METADATA_DISABLED
  value: "true"
- name: HOME
  value: /tmp
- name: AWS_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.s3.secretName | quote }}
      key: AWS_ACCESS_KEY_ID
- name: AWS_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.s3.secretName | quote }}
      key: AWS_SECRET_ACCESS_KEY
{{- end -}}

{{- define "rgw-analysis-web.nodeScheduling" -}}
{{- with .Values.nodeSelector }}
nodeSelector:
{{ toYaml . | indent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
{{ toYaml . | indent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
{{ toYaml . | indent 2 }}
{{- end }}
{{- end -}}
