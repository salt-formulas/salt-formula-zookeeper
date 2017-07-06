zookeeper:
  backup:
    server:
      enabled: true
      hours_before_full: 24
      full_backups_to_keep: 5
      key:
        zookeeper_pub_key:
          enabled: true
          key: ssh-rsa