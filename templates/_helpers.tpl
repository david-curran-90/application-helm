{{/*
Common labels
*/}}
{{- define "common.labels" -}}
helm.io/chart: {{ .Chart.Name | quote }}
helm.io/heritage: {{ .Release.Service | quote }}
helm.io/release: {{ .Release.Name | quote }}
{{- end -}}

{{/*
Common annotations*/}}
{{- define "common.annotations" -}}
{{- end -}}

{{/*
Set the name for pod specifications 
either .Release.Name or a user defined name in .Values.fullname
*/}}
{{- define "app.name" -}}
{{- $name := default .Release.Name .Values.fullname | lower -}}
{{- printf "%s" $name -}}
{{- end -}}

{{/*
Sets labels from defaults and user defined in .Values.labels
*/}}
{{- define "app.labels" -}}
{{- include "common.labels" . }}
app.kubernetes.io/name: {{ default .Release.Name .Values.labels.app | quote }}
{{ if .Values.app.labels -}}
{{- toYaml .Values.app.labels }}
{{- end -}}
{{- end -}}

{{/*
Sets annotations from defaults and user defined in .Values.annotations
*/}}
{{- define "app.annotations" -}}
{{- include "common.annotations" . }}
{{ if .Values.app.annotations -}}
{{- toYaml .Values.app.annotations }}
{{- end -}}
{{- end -}}

{{/*
Build the nodeSelector label from app.nodeSelector value
*/}}
{{- define "app.nodeSelector" -}}
{{- range .Values.app.nodeSelector }}
{{ toYaml . }}
{{- end -}}
{{- end -}}

{{/* 
Compute the maximum number of replicas, sets to .Values.app.replicas 
if .Values.applicaion.maxReplicas is not set
*/}}
{{- define "app.maxReplicas" -}}
{{- $replicas := default .Values.app.replicas .Values.app.maxReplicas -}}
{{- printf "%v" $replicas -}}
{{- end -}}

{{/*
Stateful set persistence
*/}}
{{- define "statefulset.volumeClaimTemplate" -}}
- metadata:
    {{- if .Values.persistence.name }}
    name: {{ .Values.persistence.name | lower }}
    {{- else }}
    name: {{ include "app.name" . }}-vol
    {{- end }}
  spec:
    accessModes: 
    - {{ .Values.persistence.accessMode | quote }}
    {{- if .Values.persistence.storageClass }}
    {{- if (eq "-" .Values.persistence.storageClass) }}
    storageClassName: ""
    {{- else }}
    storageClassName: {{ .Values.persistence.storageClass | quote }}
    {{- end }}
    {{- end }}
    resources:
      requests:
        storage: {{ .Values.persistence.size | quote }}
{{- end -}}

{{/*
BUild service name
*/}}
{{- define "service.name" -}}
{{ include "app.name" . }}-svc
{{- end -}}

{{/*
labels for service
*/}}
{{- define "service.labels" -}}
{{- include "common.labels" . }}
{{ if .Values.service.labels -}}
{{- toYaml .Values.service.labels }}
{{- end -}}
{{- end -}}

{{/*
annotations for service
*/}}
{{- define "service.annotations" -}}
{{- include "common.annotations" . }}
{{ if .Values.service.annotations -}}
{{- toYaml .Values.service.annotations }}
{{- end -}}
{{- end -}}

{{/*
labels for ingress
*/}}
{{- define "ingress.labels" -}}
{{- include "common.labels" . }}
{{ if .Values.ingress.labels -}}
{{- toYaml .Values.ingress.labels -}}
{{- end -}}
{{- end -}}

{{/*
annotations for ingress
*/}}
{{- define "ingress.annotations" -}}
{{- include "common.annotations" . }}
{{ if .Values.ingress.annotations -}}
{{- toYaml .Values.ingress.annotations }}
{{- end -}}
{{- end -}}

{{/*
labels for configmap
*/}}
{{- define "configmap.labels" -}}
{{- include "common.labels" . }}
{{ if .Values.configmap.labels -}}
{{- toYaml .Values.configmap.labels }}
{{- end -}}
{{- end -}}

{{/*
annotations for configmap
*/}}
{{- define "configmap.annotations" -}}
{{- include "common.annotations" . }}
{{ if .Values.configmap.annotations -}}
{{- toYaml .Values.configmap.annotations }}
{{- end -}}
{{- end -}}

{{/*
Build configmap data
*/}}
{{- define "configmap.data" -}}
{{- if .Values.configmap.data -}}
{{- toYaml .Values.configmap.data }}
{{- end -}}
{{- end -}}

{{/*
Compose the target ref for HPA
*/}}
{{- define "hpa.targetRef" -}}
apiVersion: apps/v1
kind: {{ .Values.app.type }}
name: {{ include "app.name" . }}
{{- end -}}
