{%- from "zookeeper/map.jinja" import backup with context %}

{%- if backup.client is defined %}

{%- if backup.client.enabled %}

zookeeper_backup_client_packages:
  pkg.installed:
  - names: {{ backup.pkgs }}

zookeeper_backup_runner_script:
  file.managed:
  - name: /usr/local/bin/zookeeper-backup-runner.sh
  - source: salt://zookeeper/files/backup/zookeeper-backup-client-runner.sh
  - template: jinja
  - mode: 655
  - require:
    - pkg: zookeeper_backup_client_packages

zookeeper_backup_dir:
  file.directory:
  - name: {{ backup.backup_dir }}/full
  - user: root
  - group: root
  - makedirs: true

zookeeper_backup_runner_cron:
  cron.present:
  - name: /usr/local/bin/zookeeper-backup-runner.sh
  - user: root
{%- if not backup.cron %}
  - commented: True
{%- endif %}
  - minute: 0
{%- if backup.client.hours_before_full is defined %}
{%- if backup.client.hours_before_full <= 23 and backup.client.hours_before_full > 1 %}
  - hour: '*/{{ backup.client.hours_before_full }}'
{%- elif not backup.client.hours_before_full <= 1 %}
  - hour: 2
{%- endif %}
{%- else %}
  - hour: 2
{%- endif %}
  - require:
    - file: zookeeper_backup_runner_script

{%- if backup.client.restore_latest is defined %}

zookeeper_backup_restore_script:
  file.managed:
  - name: /usr/local/bin/zookeeper-backup-restore.sh
  - source: salt://zookeeper/files/backup/zookeeper-backup-client-restore.sh
  - template: jinja
  - mode: 655
  - require:
    - pkg: zookeeper_backup_client_packages

zookeeper_backup_call_restore_script:
  file.managed:
  - name: /usr/local/bin/zookeeper-backup-restore-call.sh
  - source: salt://zookeeper/files/backup/zookeeper-backup-client-restore-call.sh
  - template: jinja
  - mode: 655
  - require:
    - file: zookeeper_backup_restore_script

zookeeper_run_restore:
  cmd.run:
  - name: /usr/local/bin/zookeeper-backup-restore-call.sh
  - unless: "[ -e {{ backup.backup_dir }}/dbrestored ]"
  - require:
    - file: zookeeper_backup_call_restore_script

{%- endif %}

{%- endif %}

{%- endif %}

{%- if backup.server is defined %}

{%- if backup.server.enabled %}

zookeeper_backup_server_packages:
  pkg.installed:
  - names: {{ backup.pkgs }}

zookeeper_user:
  user.present:
  - name: zookeeper
  - system: true
  - home: {{ backup.backup_dir }}

{{ backup.backup_dir }}/full:
  file.directory:
  - mode: 755
  - user: zookeeper
  - group: zookeeper
  - makedirs: true
  - require:
    - user: zookeeper_user
    - pkg: zookeeper_backup_server_packages

{%- for key_name, key in backup.server.key.iteritems() %}

{%- if key.get('enabled', False) %}

zookeeper_key_{{ key.key }}:
  ssh_auth.present:
  - user: zookeeper
  - name: {{ key.key }}
  - require:
    - file: {{ backup.backup_dir }}/full

{%- endif %}

{%- endfor %}

zookeeper_server_script:
  file.managed:
  - name: /usr/local/bin/zookeeper-backup-runner.sh
  - source: salt://zookeeper/files/backup/zookeeper-backup-server-runner.sh
  - template: jinja
  - mode: 655
  - require:
    - pkg: zookeeper_backup_server_packages

zookeeper_server_cron:
  cron.present:
  - name: /usr/local/bin/zookeeper-backup-runner.sh
  - user: zookeeper
{%- if not backup.cron %}
  - commented: True
{%- endif %}
  - minute: 0
  - hour: 2
  - require:
    - file: zookeeper_server_script

zookeeper_server_call_restore_script:
  file.managed:
  - name: /usr/local/bin/zookeeper-restore-call.sh
  - source: salt://zookeeper/files/backup/zookeeper-backup-server-restore-call.sh
  - template: jinja
  - mode: 655
  - require:
    - pkg: zookeeper_backup_server_packages

{%- endif %}

{%- endif %}
