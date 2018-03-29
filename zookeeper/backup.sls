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

{%- if backup.cron %}

zookeeper_backup_runner_cron:
  cron.present:
  - name: /usr/local/bin/zookeeper-backup-runner.sh
  - user: root
{%- if backup.client.backup_times is defined %}
{%- if backup.client.backup_times.dayOfWeek is defined %}
  - dayweek: {{ backup.client.backup_times.dayOfWeek }}
{%- endif -%}
{%- if backup.client.backup_times.month is defined %}
  - month: {{ backup.client.backup_times.month }}
{%- endif %}
{%- if backup.client.backup_times.dayOfMonth is defined %}
  - daymonth: {{ backup.client.backup_times.dayOfMonth }}
{%- endif %}
{%- if backup.client.backup_times.hour is defined %}
  - hour: {{ backup.client.backup_times.hour }}
{%- endif %}
{%- if backup.client.backup_times.minute is defined %}
  - minute: {{ backup.client.backup_times.minute }}
{%- endif %}
{%- elif backup.client.hours_before_incr is defined %}
  - minute: 0
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

{%- else %}

zookeeper_backup_runner_cron:
  cron.absent:
  - name: /usr/local/bin/zookeeper-backup-runner.sh
  - user: root

{%- endif %}


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

{{ backup.backup_dir }}/.ssh/authorized_keys:
  file.managed:
  - user: zookeeper
  - group: zookeeper
  - template: jinja
  - source: salt://zookeeper/files/backup/authorized_keys
  - require:
    - file: {{ backup.backup_dir }}/full

zookeeper_server_script:
  file.managed:
  - name: /usr/local/bin/zookeeper-backup-runner.sh
  - source: salt://zookeeper/files/backup/zookeeper-backup-server-runner.sh
  - template: jinja
  - mode: 655
  - require:
    - pkg: zookeeper_backup_server_packages

{%- if backup.cron %}

zookeeper_server_cron:
  cron.present:
  - name: /usr/local/bin/zookeeper-backup-runner.sh
  - user: zookeeper
  - minute: 0
  - hour: 2
  - require:
    - file: zookeeper_server_script

{%- else %}

zookeeper_server_cron:
  cron.absent:
  - name: /usr/local/bin/zookeeper-backup-runner.sh
  - user: zookeeper

{%- endif %}

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
