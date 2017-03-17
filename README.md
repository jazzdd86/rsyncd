# Rsync Daemon with support for multiple RSYNC Modules
This image is for starting a rsyncd container with oner or more rsync modules.

## Usage
It is recommended to use this image with docker-compose. The following code will show an example docker-compose.yml file:

```
rsyncd:
    container_name: rsyncd
    restart: always
    environment: 
        # (optional) - use only if non-default values should be used
        RSYNC_TIMEOUT: 300
        RSYNC_PORT: 873
        RSYNC_MAX_CONNECTIONS: 10

        # (optional) - global username and password
        RSYNC_PASSWORD: foobar
        RSYNC_USERNAME: rsync
        
        # ID_NAME is the only required parameter for each rsync module
        MOD1_NAME: Backup_From
        MOD1_VOLUME: /vol2
        MOD2_USERNAME: test
        MOD2_PASSWORD: secret
        MOD2_UID: nobody
        MOD2_GID: nobody
        MOD1_ALLOW: 192.168.1.0/24
        MOD1_READ_ONLY: "true"
        MOD2_EXCLUDE: /backup

        MOD2_NAME: Backup_To
        MOD2_VOLUME: /vol
        MOD2_ALLOW: 192.168.1.0/24
        MOD2_READ_ONLY: "false"

    volumes:
        - /data:/vol2
        - /data/backup:/vol
    ports:
        - "873:873"
    image: jazzdd/rsyncd
```

- Looking at the example compose file, the first three environment variables are completely optional and are predefined in the image.

- `RSYNC_USERNAME` and `RSYNC_PASSWORD` can be used to define a simple authentication which is used for all Rsync modules. If these parameters are not specified, authentication is disabled by default. This can be overwritten by module-wise environment variables

To define a Rsync module a simple `ID_NAME` is needed as environment variable. ID can be any letter or number and is of your choosing. The ID is used to identify all corresponding parameters. All other parameters are optional.

- `ID_NAME`: unique name of the Rsync module
- `ID_VOLUME`: path of the Rsync module, this should be a volume mounted to the container (/vol is the default directory if no VOLUME parameter is specified)
- `ID_USERNAME` and `ID_PASSWORD`: these two parameters can overwrite the global authentication parameters. If no global authentication is specified, it enables the username and password only for this specific Rsync module
- `ID_UID` and `ID_GID`: by default the rsyncd runs with root privileges, this can be overwritten for a specific module when uid and/or gid are declared
- `ID_ALLOW`: allows only specified IP addresses/ranges to connect to the Rsync module. If not declared all network addresses can connect to it
- `ID_READ_ONLY`: states if module is read only or not. It defaults to true.
- `ID_EXCLUDE`: this parameter can be used to exclude file patterns or folders from the rsync module