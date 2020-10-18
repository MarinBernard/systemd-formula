{%- set  sls_path = "systemd" -%}
{%- from sls_path + "/map.jinja" import systemd with context %}
{%- from sls_path + "/libtofs.jinja" import files_switch with context -%}

{%- set resolved = systemd.get('resolved', {}) %}
{%- set paths = resolved.get('paths', {}) %}
{%- set trust_anchors = resolved.get('trust_anchors', {}) %}

resolved-dnssec_trust_anchors_d:
  file.directory:
    - name: {{ paths.dnssec_trust_anchors_d }}
    - user: root
    - group: root
    - dir_mode: 0755
    - file_mode: 0644
    - allow_symlink: False
    - force: True

{% for id,anchors in trust_anchors.positive.items() %}
{% set ta_file_path = paths.dnssec_trust_anchors_d + '/' + id + '.positive' %}

resolved-dnssec_trust_anchor-{{ id }}:
  file.managed:
    - name: {{ ta_file_path }}
    - source: salt://{{ sls_path }}/resolved/files/templates/dnssec_trust_anchor.positive.j2
    - template: jinja
    - mode: 0644
    - user: root
    - group: root
    - anchors: {{ anchors }}
    - require:
      - file: resolved-dnssec_trust_anchors_d
    - watch_in:
      - service: resolved

{% endfor %}
