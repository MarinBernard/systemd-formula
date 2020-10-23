{%- from "systemd/map.jinja" import systemd with context %}
{%- from "systemd/libtofs.jinja" import files_switch with context -%}

{%- set resolved = systemd.get('resolved', {}) %}
{%- set config = resolved.get('config', {}) %}

{%- set version = salt['pkg.version']('systemd') %}
{%- set major_version = (version.split('-'))[0] | int %}

resolved:
  {%- if resolved.pkg %}
  pkg.installed:
    - name: {{ resolved.pkg }}
  {%- endif %}
  {%- if resolved.config_source == 'file' %}
  file.managed:
    - name: /etc/systemd/resolved.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source: {{ files_switch(['resolved.conf'],
                              lookup='resolved',
                              use_subpath=True
                              )
              }}
  {%- elif resolved.config_source == 'pillar' %}
  ini.options_present:
    - name: /etc/systemd/resolved.conf
    - separator: '='
    - strict: True
    - sections:
        Resolve:
          DNS: >-
            {%  if config.servers.primary -%}
            {{    config.servers.primary | join(' ') }}
            {%- else -%}
            {{    '' }}
            {%- endif %}
          FallbackDNS: >-
            {%  if config.servers.secondary -%}
            {{    config.servers.secondary | join(' ') }}
            {%- else -%}
            {{    '' }}
            {%- endif %}
          Domains: >-
            {%  if config.search_suffixes -%}
            {{    config.search_suffixes | join(' ') }}
            {%- else -%}
            {{    '' }}
            {%- endif %}
          LLMNR: >-
            {{ 'yes' if config.features.llmnr else 'no' }}
          MulticastDNS: >-
            {{ 'yes' if config.features.multicast_dns else 'no' }}
          DNSSEC: >-
            {%  if config.features.dnssec -%}
            {%-   if config.features.dnssec_downgrading -%}
            {{      'allow-downgrading' }}
            {%-   else -%}
            {{      'yes' }}
            {%-   endif -%}
            {%- else -%}
            {{    'no' }}
            {%- endif %}
          DNSOverTLS: >-
            {{ 'yes' if config.features.dns_over_tls else 'no' }}
          Cache: >-
            {{ 'yes' if config.features.caching else 'no' }}
          DNSStubListener: >-
            {{ 'yes' if config.features.dns_stub_listener else 'no' }}
      {%- if major_version >= 240 %}
          ReadEtcHosts: >-
            {{ 'yes' if config.features.read_host_file else 'no' }}
      {%- endif %}
    {%- endif %}
    - listen_in:
      - service: resolved
  service.running:
    - name: systemd-resolved
    - enable: True

resolv.conf:
  file.symlink:
    - name: {{ resolved.paths.resolv_file }}
    - target: {{ resolved.paths.resolv_target }}
    - force: True
    - backupname: /etc/resolv.conf.bak
    - listen_in:
      - service: resolved
