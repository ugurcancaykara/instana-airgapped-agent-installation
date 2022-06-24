# Instana agent installation with package for Linux(rpm,deb) and Windows
### Prerequisites

**This script configured for multibackend installation.**
**If you want to use just one backend then go to script file and change INSTANA_AGENT_ENDPOINT,INSTANA_AGENT_ENDPOINT_PORT in powershell script and 
INSTANA_AGENT_HOST, INSTANA_AGENT_PORT in bash script**

1) If you want to override them you can easily override them by adding the values to specified fields and running them on terminal before installation or you can give values via cli like shown at <a href="https://github.com/ugurcancaykara/instana-airgapped-agent-installation#1--for-one-backend-with-tags-and-zones">example usages</a>.
```
export INSTANA_AGENT_KEY=<agent-key>
export INSTANA_DOWNLOAD_KEY=<agent-key>
export INSTANA_AGENT_HOST=<agent-host>
export INSTANA_AGENT_PORT=<agent-port>
```
```
chmod +x setup.sh
```


### Linux Installation 
##### Quick tip: installating package -> curl -LO https://username:agentkey@packagelinkaddress

##### RHEL -> rpm package
#####  Debian -> dpkg


### Configuration Options

| Option      | Default              | Description                                                                     |
|-------------|----------------------|---------------------------------------------------------------------------------|
| a   | ""                | Agent Key                                                        |   
| d    | ""                | Download Key                                      |   
| e | ""                | First backend host (if you are going to use one backend, just leave it empty)                                                          |   
| g   | ""                | Second backend host (if you are going to use one backend, just leave it empty) |   
| p         | ""                   | package path                                                                   |   
| u    | ""                   | mvn-settings.xml path                                               |   
| t    | ""                   | agent tag                                               |   
| z    | ""                 | agent zone                                         |   


Example usage:
### 1- For one backend with tags and zones
 - 'a' -> agent key
 - 'd' -> download key
 - 't' -> agent tag
 - 'z' -> agent zone


```
./setup.sh -a agent-key -d agent-key -t agent-tag -z agent-zone -p package-path
```

### 2- For multibackend, you need to provide two parameter
    - 'e' -> First backend host
    - 'g' -> Second backend host

```
./setup.sh -a agent-key -d agent-key -t agent-tag -z agent-zone -p package-path -e first-host -g second-host
```

### 3- With previously configured mvn-settings file 
    - 'u' -> file full path

```
./setup.sh -a agent-key -d agent-key -t agent-tag -z agent-zone -p package-path -e first-host -g second-host -u mvn-settings.xml
```

### UNINSTALLING
- Find package name
```
rpm -qa | grep instana-agent
```
- Erase package
```
rpm -e <package-name>
```
- Delete all files
```
rm -rf /opt/instana
```


### Windows Installation

### Configuration Options

| Option      | Default              | Description                                                                     |
|-------------|----------------------|---------------------------------------------------------------------------------|
| INSTANA_AGENT_KEY   | ""                | Agent Key                                                        |   
| INSTANA_DOWNLOAD_KEY    | ""                | Download Key                                      |   
| INSTANA_AGENT_HOST_ONE | ""                | First backend host (if you are going to use one backend, just leave it empty)                                                          |   
| INSTANA_AGENT_HOST_TWO   | ""                | Second backend host (if you are going to use one backend, just leave it empty) |   
| INSTANA_PACKAGE_PATH         | ""                   | package path                                                                   |   
| INSTANA_MVN_CONF_PATH    | ""                   | mvn-settings.xml path                                               |   
| AGENT_TAG    | ""                   | agent tag                                               |   
| AGENT_ZONE    | ""                 | agent zone                                         |   



Example usage:


### 1- For one backend with tags and zones
 - 'INSTANA_AGENT_KEY' -> agent key
 - 'INSTANA_DOWNLOAD_KEY' -> download key
 - 'AGENT_TAG' -> agent tag
 - 'AGENT_ZONE' -> agent zone


```
C:\Users\Administrator\Desktop\setup.ps1 -AGENT_ZONE agentzone -AGENT_TAG agenttag -INSTANA_PACKAGE_PATH exepackagepath  -INSTANA_AGENT_KEY agent_key -INSTANA_DOWNLOAD_KEY download_key
```

### 2- For multibackend, you need to provide two parameter
    - 'INSTANA_AGENT_HOST_ONE' -> First backend host
    - 'INSTANA_AGENT_HOST_TWO' -> Second backend host

```
C:\Users\Administrator\Desktop\setup.ps1 -AGENT_ZONE agentzone -AGENT_TAG agenttag -INSTANA_AGENT_HOST_ONE firsthost -INSTANA_AGENT_HOST_TWO secondhost-INSTANA_PACKAGE_PATH exepackagepath  -INSTANA_AGENT_KEY agent_key -INSTANA_DOWNLOAD_KEY download_key
```

### 3- With previously configured mvn-settings file 
    - 'INSTANA_MVN_CONF_PATH' -> file full path

```
C:\Users\Administrator\Desktop\setup.ps1 -AGENT_ZONE agentzone -AGENT_TAG agenttag -INSTANA_AGENT_HOST_ONE firsthost -INSTANA_AGENT_HOST_TWO secondhost-INSTANA_PACKAGE_PATH exepackagepath  -INSTANA_AGENT_KEY agent_key -INSTANA_DOWNLOAD_KEY download_key -INSTANA_MVN_CONF_PATH mvnsettingspath
```

### UNINSTALLING
- delete Instana from 'Add or Remove Program'
- delete Instana directory at C:\Program Files\Instana