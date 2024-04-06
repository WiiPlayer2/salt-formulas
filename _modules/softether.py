from io import StringIO
from typing import List, Dict
import subprocess
import csv
import logging
import salt.utils.path

CLI = salt.utils.path.which_bin([
    'vpncmd',
    'vpnserver-cli',
])

_DEFAULT_HOST = 'localhost'
_HOST_TYPE_SERVER = "SERVER"
_LOG = logging.getLogger('modules.softether')

def _dict_from_items(items: List[Dict[str, str]]):
    ret = {}
    for item in items:
        ret.update({item['Item']: item['Value']})
    return ret

def _map_keys(d: Dict[str, str], mapping: Dict[str, str]):
    ret = {}
    for k, v in d.items():
        new_key = mapping.get(k, k)
        ret.update({new_key: v})
    return ret

def _run(host_type, cmd, hub=None, password=None, host=None):
    try:
        return run(host_type, cmd, host=host, password=password, adminhub=hub)
    except subprocess.CalledProcessError as error:
        _LOG.warning('Failed to run command as server admin. Retrying as virtual hub admin. Error was {error}'.format(error=error))
        return run(host_type, cmd, hub=hub, host=host, password=password)

def __virtual__():
    return CLI is not None, 'The softether module can not be loaded: vpncmd is not available.'

def run(host_type, cmd, host=None, hub=None, password=None, adminhub=None):
    def get_output() -> str:
        _host = host
        if _host is None:
            _host = _DEFAULT_HOST
        args = [CLI, _host, '/{host_type}'.format(host_type=host_type), '/CSV', '/PROGRAMMING']
        if hub:
            args += ['/HUB:{hub}'.format(hub=hub)]
        if adminhub:
            args += ['/ADMINHUB:{adminhub}'.format(adminhub=adminhub)]
        if password:
            args += ['/PASSWORD:{password}'.format(password=password)]
        args += ['/CMD'] + cmd

        _LOG.debug('Run {args}'.format(args=args))
        output = subprocess.check_output(args).decode("utf-8")
        _LOG.debug('Got output: {output}'.format(output=output))
        return output

    def parse_csv(csv_string: str) -> List[Dict[str, str]]:
        f = StringIO(csv_string)
        reader = csv.reader(f, delimiter=',')
        headers = next(reader, None)
        _LOG.debug('Found headers: {headers}'.format(headers=headers))
        if not headers:
            return None
        def create_obj(row):
            obj = {}
            for i in range(len(headers)):
                key = headers[i]
                value = row[i]
                obj.update({key: value})
            return obj
        return list([create_obj(row) for row in reader if len(row) == len(headers)])

    return parse_csv(get_output())

def server_auth(password=None, host=None):
    try:
        server_hub_list(host=host, password=password)
        return True
    except subprocess.CalledProcessError:
        return False

def server_auth_hub(hub, password=None, host=None):
    try:
        server_user_list(hub, host=host, password=password)
        return True
    except subprocess.CalledProcessError:
        return False

def server_bridge_create(hub, device, is_tap_device=False, password=None, host=None):
    arg_tap = 'yes' if is_tap_device else 'no'
    _run(_HOST_TYPE_SERVER, ['BridgeCreate', hub, '/DEVICE:{device}'.format(device=device), '/TAP:{arg_tap}'.format(arg_tap=arg_tap)], password=password, host=host)

def server_bridge_delete(hub, device, password=None, host=None):
    _run(_HOST_TYPE_SERVER, ['BridgeDelete', hub, '/DEVICE:{device}'.format(device=device)], password=password, host=host)

def server_bridge_list(password=None, host=None):
    return _run(_HOST_TYPE_SERVER, ['BridgeList'], password=password, host=host)

def server_dynamic_dns_get_status(password=None, host=None):
    return _dict_from_items(_run(_HOST_TYPE_SERVER, ['DynamicDnsGetStatus'], host=host, password=password))

def server_dynamic_dns_set_hostname(hostname, password=None, host=None):
    _run(_HOST_TYPE_SERVER, ['DynamicDnsSetHostname', hostname], host=host, password=password)

def server_hub_create(hub, hub_password, password=None, host=None):
    _run(_HOST_TYPE_SERVER, ['HubCreate', hub, '/PASSWORD:{hub_password}'.format(hub_password=hub_password)], host=host, password=password)

def server_hub_delete(hub, password=None, host=None):
    _run(_HOST_TYPE_SERVER, ['HubDelete', hub], host=host, password=password)

def server_hub_list(password=None, host=None):
    return _run(_HOST_TYPE_SERVER, ['HubList'], host=host, password=password)

def server_radius_server_delete(hub, password=None, host=None):
    _run(_HOST_TYPE_SERVER, ['RadiusServerDelete'], hub, host=host, password=password)

def server_radius_server_get(hub, password=None, host=None):
    return _dict_from_items(_run(_HOST_TYPE_SERVER, ['RadiusServerGet'], hub, host=host, password=password))

def server_radius_server_set(hub, radius_host, secret, retry_interval, password=None, host=None):
    _run(_HOST_TYPE_SERVER, ['RadiusServerSet', radius_host, '/SECRET:{secret}'.format(secret=secret), '/RETRY_INTERVAL:{retry_interval}'.format(retry_interval=retry_interval)], hub, host=host, password=password)

def server_server_password_set(new_password, password=None, host=None):
    _run(_HOST_TYPE_SERVER, ['ServerPasswordSet', new_password], host=host, password=password)

def server_set_hub_password(hub, new_password, password=None, host=None):
    _run(_HOST_TYPE_SERVER, ['SetHubPassword', new_password], hub, host=host, password=password)

def server_status_get(hub, password=None, host=None):
    return _dict_from_items(_run(_HOST_TYPE_SERVER, ['StatusGet'], hub, host=host, password=password))

def server_user_create(hub, name, group=None, realname=None, note=None, password=None, host=None):
    if group is None:
        group = 'none'
    if realname is None:
        realname = 'none'
    if note is None:
        note = 'none'
    _run(_HOST_TYPE_SERVER, ['UserCreate', name, '/GROUP:{group}'.format(group=group), '/REALNAME:{realname}'.format(realname=realname), '/NOTE:{note}'.format(note=note)], hub, host=host, password=password)

def server_user_get(hub, name, password=None, host=None):
    return _dict_from_items(_run(_HOST_TYPE_SERVER, ['UserGet', name], hub, host=host, password=password))

def server_user_list(hub, password=None, host=None):
    return _run(_HOST_TYPE_SERVER, ['UserList'], hub, password, host=host)

def server_user_password_set(hub, name, user_password, password=None, host=None):
    _run(_HOST_TYPE_SERVER, ['UserPasswordSet', name, '/PASSWORD:{user_password}'.format(user_password=user_password)], hub, password=password, host=host)

def server_user_radius_set(hub, name, alias=None, password=None, host=None):
    if alias is None:
        alias = 'none'
    _run(_HOST_TYPE_SERVER, ['UserRadiusSet', name, '/ALIAS:{alias}'.format(alias=alias)], hub, password=password, host=host)

def server_user_set(hub, name, group=None, realname=None, note=None, password=None, host=None):
    if group is None:
        group = 'none'
    if realname is None:
        realname = 'none'
    if note is None:
        note = 'none'
    _run(_HOST_TYPE_SERVER, ['UserSet', name, '/GROUP:{group}'.format(group=group), '/REALNAME:{realname}'.format(realname=realname), '/NOTE:{note}'.format(note=note)], hub, password=password, host=host)

def server_vpn_azure_get_status(password=None, host=None):
    return _dict_from_items(_run(_HOST_TYPE_SERVER, ['VpnAzureGetStatus'], host=host, password=password))

def server_vpn_azure_set_enable(enable, password=None, host=None):
    _run(_HOST_TYPE_SERVER, ['VpnAzureSetEnable', 'yes' if enable else 'no'], password=password, host=host)
