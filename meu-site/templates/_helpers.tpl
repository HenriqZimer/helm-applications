{{/* Labels padrão combinando as globais e as específicas */}}
{{/* No seu _helpers.tpl */}}
{{- define "app.labels" -}}
app: {{ .name | quote }}
project: {{ .Values.global.project | quote }}
{{- end -}}

{{/* Recursos com fallback para não quebrar o template se faltar algum valor */}}
{{- define "app.resources" -}}
resources:
  {{- if .resources }}
  {{- toYaml .resources | nindent 2 }}
  {{- else }}
  requests:
    cpu: 100m
    memory: 128Mi
  {{- end }}
{{- end -}}

{{/* Portas do Container: Aceita tanto porta simples quanto mapeamento completo */}}
{{- define "app.containerPorts" -}}
{{- range .ports }}
- containerPort: {{ .containerPort | default .port }}
  name: {{ .name | default "http" }}
  protocol: {{ .protocol | default "TCP" }}
{{- end }}
{{- end -}}

{{/* Helper de fullname: permite sobrescrever via .Values.fullnameOverride
   ou gera um prefixo baseado em Release e Chart. */}}
{{- define "meu-site.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- printf "%s" .Values.fullnameOverride }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name }}
{{- end }}
{{- end }}

{{/* Ingress Annotations: Usa toYaml para evitar problemas com tipos de dados */}}
{{- define "ingress.annotations" -}}
{{- if .annotations }}
  {{- toYaml .annotations }}
{{- else }}
  kubernetes.io/ingress.class: nginx
{{- end }}
{{- end -}}

{{/* Ingress Rules: Corrigido para suportar múltiplos caminhos por host (DRY) */}}
{{- define "ingress.rules" -}}
{{- range .hosts }}
- host: {{ .host }}
  http:
    paths:
      {{- range .paths }}
      - path: {{ .path }}
        pathType: {{ .pathType | default "Prefix" }}
        backend:
          service:
            name: {{ .serviceName | default $.serviceName }}
            port:
              number: {{ .port }}
      {{- end }}
{{- end }}
{{- end -}}