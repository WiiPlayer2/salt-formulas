from typing import Callable, Dict
import salt.exceptions

def _run(name: str) -> Callable:
    return __salt__[f'softether.server_{name}']

def _ret(name: str) -> Dict[str, object]:
    return {
        'name': name,
        'changes': {},
        'result': False,
        'comment': '',
    }

def bridge(name, hub, device_name=None, is_tap_device=False, password=None):
    ret = _ret(name)
    _ITEM_HUB = 'Virtual Hub Name'
    _ITEM_DEVICE = 'Network Adapter or Tap Device Name'

    if device_name is None:
        device_name = name

    bridge_create = _run('bridge_create')
    bridge_delete = _run('bridge_delete')
    bridge_list = _run('bridge_list')

    def _get_bridge():
        bridges = bridge_list(password)
        for bridge in bridges:
            if bridge[_ITEM_DEVICE] == device_name:
                return bridge
        return None

    current_bridge_state = _get_bridge()
    current_hub = None
    if current_bridge_state:
        current_hub = current_bridge_state[_ITEM_HUB]
    
    check_bridge = current_bridge_state and current_hub.casefold() == hub.casefold()

    if check_bridge:
        ret['result'] = True
        ret['comment'] = 'Bridge is already configured.'
        return ret
    
    should_delete_bridge = current_bridge_state is not None

    if __opts__['test'] == True:
        ret['result'] = None
        if should_delete_bridge:
            ret['comment'] = 'Bridge will be deleted and recreated.'
        else:
            ret['comment'] = 'Bridge will be created.'
        ret['changes'] = {
            'old': current_bridge_state,
            'new': {
                _ITEM_HUB: hub,
                _ITEM_DEVICE: device_name,
            },
        }
        return ret

    if should_delete_bridge:
        bridge_delete(current_hub, device_name, password)
    bridge_create(hub, device_name, is_tap_device, password)
    ret['result'] = True
    if should_delete_bridge:
        ret['comment'] = 'Bridge has been deleted and recreated.'
    else:
        ret['comment'] = 'Bridge has been created.'
    ret['changes'] = {
        'old': current_bridge_state,
        'new': {
            _ITEM_HUB: hub,
            _ITEM_DEVICE: device_name,
        }
    }
    return ret

def dyndns(name, enable_vpnazure=True, password=None):
    ret = _ret(name)
    _ITEM_HOSTNAME = 'Assigned Dynamic DNS Hostname (Hostname)'
    _ITEM_VPNAZURE_ENABLED = 'VPN Azure Function is Enabled'
    _VALUE_VPNAZURE_ENABLED = 'Yes'
    _VALUE_VPNAZURE_DISABLED = 'No'

    dynamic_dns_get_status = _run('dynamic_dns_get_status')
    dynamic_dns_set_hostname = _run('dynamic_dns_set_hostname')
    vpn_azure_get_status = _run('vpn_azure_get_status')
    vpn_azure_set_enable = _run('vpn_azure_set_enable')

    current_dyndns_state = dynamic_dns_get_status(password)
    current_vpnazure_state = vpn_azure_get_status(password)
    current_dyndns_name = current_dyndns_state[_ITEM_HOSTNAME]
    current_vpnazure_enable = current_vpnazure_state[_ITEM_VPNAZURE_ENABLED] == _VALUE_VPNAZURE_ENABLED

    check_dyndns = current_dyndns_name == name
    check_vpnazure = current_vpnazure_enable == enable_vpnazure

    if check_dyndns and check_vpnazure:
        ret['result'] = True
        ret['comment'] = 'Dynamic DNS and VPNAzure are already configured.'
        return ret

    should_update_dyndns = not check_dyndns
    should_update_vpnazure = not check_vpnazure

    ret['changes'] = {
        'old': {},
        'new': {},
    }
    if __opts__['test'] == True:
        ret['result'] = None
        if should_update_dyndns:
            ret['comment'] += 'Dynamic DNS will be updated. '
            ret['changes']['old'].update({'dyndns': current_dyndns_state})
            ret['changes']['new'].update({'dyndns': {
                _ITEM_HOSTNAME: name,
            }})
        if should_update_vpnazure:
            ret['comment'] += 'VPNAzure will be updated. '
            ret['changes']['old'].update({'vpnazure': current_vpnazure_state})
            ret['changes']['new'].update({'vpnazure': {
                _ITEM_VPNAZURE_ENABLED: _VALUE_VPNAZURE_ENABLED if enable_vpnazure else _VALUE_VPNAZURE_DISABLED,
            }})
        return ret

    if should_update_dyndns:
        dynamic_dns_set_hostname(name, password)
        ret['comment'] += 'Dynamic DNS has been configured. '
        ret['changes']['old'].update({'dyndns': current_dyndns_state})
        ret['changes']['new'].update({'dyndns': {
            _ITEM_HOSTNAME: name,
        }})

    if should_update_vpnazure:
        vpn_azure_set_enable(enable_vpnazure, password)
        ret['comment'] += 'VPNAzure has been configured. '
        ret['changes']['old'].update({'vpnazure': current_vpnazure_state})
        ret['changes']['new'].update({'vpnazure': {
            _ITEM_VPNAZURE_ENABLED: _VALUE_VPNAZURE_ENABLED if enable_vpnazure else _VALUE_VPNAZURE_DISABLED,
        }})

    return ret

def password(name, new=None, current=None, old_passwords=None):
    ret = _ret(name)

    if not isinstance(old_passwords, list) and old_passwords is not None:
        raise salt.exceptions.SaltInvocationError(f'Argument "old_passwords" has to be a list, but is {type(old_passwords)}.')

    if old_passwords is None:
        old_passwords = []
    pws = [current, None] + old_passwords

    auth = _run('auth')
    server_password_set = _run('server_password_set')

    can_auth = auth(new)
    if can_auth:
        ret['result'] = True
        ret['comment'] = 'Password already set.'
        return ret

    if __opts__['test'] == True:
        ret['comment'] = f'Password will be changed.'
        ret['changes'] = {
            'old': False,
            'new': 'Setting password'
        }
        ret['result'] = None
        return ret
    
    for pw in pws:
        can_auth = auth(pw)
        if can_auth:
            server_password_set(new, pw)
            ret['comment'] = f'Password has been changed.'
            ret['changes'] = {
                'old': False,
                'new': 'Password set'
            }
            ret['result'] = True
            return ret
    
    ret['comment'] = f'Failed to authenticate on server.'
    return ret

def hub(name, hub_password, hub=None, password=None):
    ret = _ret(name)
    
    if hub is None:
        hub = name
    
    auth_hub = _run('auth_hub')
    status_get = _run('status_get')
    hub_create = _run('hub_create')
    set_hub_password = _run('set_hub_password')

    hub_status = None
    try:
        hub_status = status_get(hub, password)
    except:
        pass
    can_auth_hub = auth_hub(hub, hub_password)

    if hub_status and can_auth_hub:
        ret['result'] = True
        ret['comment'] = f'Hub {hub} already exists and password is set.'
        return ret
    
    if __opts__['test'] == True:
        ret['results'] = None
        if hub_status is None:
            ret['comment'] = f'Hub {hub} will be created.'
            ret['changes'] = {
                'old': None,
                'new': {
                    'name': hub,
                    'password': True,
                }
            }
        else:
            ret['comment'] = f'Password of hub {hub} will be changed.'
            ret['changes'] = {
                'old': {
                    'password': False,
                },
                'new': {
                    'password': True,
                }
            }
        return ret

    if hub_status is None:
        hub_create(hub, hub_password, password)
        ret['comment'] = f'Hub {hub} created.'
        ret['changes'] = {
            'old': None,
            'new': {
                'name': hub,
                'password': True,
            }
        }
        ret['result'] = True
        return ret
    
    if not can_auth_hub:
        set_hub_password(hub, hub_password, password)
        ret['comment'] = f'Password of hub {hub} has been changed.'
        ret['changes'] = {
                'old': {
                    'password': False,
                },
                'new': {
                    'password': True,
                }
        }
        ret['result'] = True
        return ret
    return ret

def radius(name, enable, host=None, port=None, secret=None, retry_interval=None, hub=None, password=None):
    ret = _ret(name)
    _ITEM_USE = 'Use RADIUS Server'
    _ITEM_HOST = 'RADIUS Server Host Name or IP Address: '
    _ITEM_PORT = 'RADIUS Server Port Number'
    _ITEM_SECRET = 'Shared Secret'
    _ITEM_RETRY_INTERVAL = 'Retry Interval (in milliseconds)'
    _VALUE_USE_ENABLED = 'Enable'
    _VALUE_USE_DISABLED = 'Disable'
    _DEFAULT_PORT = 1812

    if hub is None:
        hub = name
    if enable and port is None:
        port = _DEFAULT_PORT

    if enable and (host is None or port is None or secret is None or retry_interval is None):
        raise salt.exceptions.SaltInvocationError(f'Arguments host, secret and retry_interval have to be set when enabling radius server.')

    radius_server_get = _run('radius_server_get')
    radius_server_delete = _run('radius_server_delete')
    radius_server_set = _run('radius_server_set')

    radius_status = radius_server_get(hub, password)
    is_enabled = radius_status[_ITEM_USE] == _VALUE_USE_ENABLED

    if is_enabled == enable:
        if not enable:
            ret['comment'] = 'RADIUS is already disabled.'
            ret['result'] = True
            return ret
        else:
            current_host = radius_status[_ITEM_HOST]
            current_port = radius_status[_ITEM_PORT]
            current_secret = radius_status[_ITEM_SECRET]
            current_retry_interval = radius_status[_ITEM_RETRY_INTERVAL]
            if current_host == host and current_port == str(port) and current_secret == secret and current_retry_interval == str(retry_interval):
                ret['comment'] = 'RADIUS is already enabled and configured.'
                ret['result'] = True
                return ret

    if __opts__['test'] == True:
        ret['result'] = None
        if not enable:
            ret['comment'] = 'RADIUS will be disabled.'
            ret['changes'] = {
                'old': radius_status,
                'new': {
                    _ITEM_USE: _VALUE_USE_DISABLED,
                }
            }
        else:
            ret['comment'] = 'RADIUS will be enabled and configured.'
            ret['changes'] = {
                'old': radius_status,
                'new': {
                    _ITEM_USE: _VALUE_USE_ENABLED,
                    _ITEM_HOST: host,
                    _ITEM_PORT: str(port),
                    _ITEM_SECRET: secret,
                    _ITEM_RETRY_INTERVAL: str(retry_interval),
                }
            }
        return ret

    if not enable:
        radius_server_delete(hub, password)
        ret['result'] = True
        ret['comment'] = 'RADIUS has been disabled'
        ret['changes'] = {
            'old': radius_status,
            'new': radius_server_get(hub, password),
        }
        return ret
    else:
        radius_server_set(hub, f'{host}:{port}', secret, retry_interval, password)
        ret['result'] = True
        ret['comment'] = 'RADIUS has been enabled and configured.'
        ret['changes'] = {
            'old': radius_status,
            'new': radius_server_get(hub, password),
        }
        return ret

    return ret

def user(name, hub, group=None, realname=None, note=None, auth_type=None, auth_data=None, password=None):
    ret = _ret(name)
    _ITEM_NAME = 'User Name'
    _ITEM_FULLNAME = 'Full Name'
    _ITEM_DESCRIPTION = 'Description'
    _ITEM_AUTH_TYPE = 'Auth Type'
    _AUTH_TYPES = {
        'Password Authentication': 'password',
        'RADIUS Authentication': 'radius',
    }
    _VERBOSE_AUTH_TYPES = {
        'password': 'Password Authentication',
        'radius': 'RADIUS Authentication',
    }

    def _check_arg(arg, current_value):
        if arg is None:
            return True
        if current_value is None:
            return False
        return arg == current_value

    user_get = _run('user_get')
    user_set = _run('user_set')
    user_create = _run('user_create')
    user_password_set = _run('user_password_set')
    user_radius_set = _run('user_radius_set')

    current_user_state = None
    current_fullname = None
    current_description = None
    current_auth_type = None
    try:
        current_user_state = user_get(hub, name, password)
        current_fullname = current_user_state[_ITEM_FULLNAME]
        current_description = current_user_state[_ITEM_DESCRIPTION]
        current_auth_type = current_user_state[_ITEM_AUTH_TYPE]
    except:
        pass

    check_realname = _check_arg(realname, current_fullname)
    check_note = _check_arg(note, current_description)
    check_auth_type = _check_arg(auth_type, _AUTH_TYPES.get(current_auth_type))

    if current_user_state:
        if check_realname and check_note and check_auth_type:
            ret['result'] = True
            ret['comment'] = f'User {name} is already in desired state.'
            return ret

    ret['changes'] = {
        'old': current_user_state,
        'new': {}
    }

    should_create_user = current_user_state is None
    should_update_data = not check_realname or not check_note
    should_update_auth = not check_auth_type
    if __opts__['test'] == True:
        ret['result'] = None
        if should_create_user:
            ret['comment'] += f'User {name} will be created.'
            ret['changes']['new'].update({
                _ITEM_NAME: name,
                _ITEM_FULLNAME: realname,
                _ITEM_DESCRIPTION: note,
                _ITEM_AUTH_TYPE: _VERBOSE_AUTH_TYPES.get(auth_type),
            })

        if should_update_data:
            ret['comment'] += f'User {name} will be updated. '
            ret['changes']['new'].update({
                _ITEM_FULLNAME: realname,
                _ITEM_DESCRIPTION: note,
            })
        if should_update_auth:
            ret['comment'] += f'Authentication of user {name} will be changed.'
            ret['changes']['new'].update({
                _ITEM_AUTH_TYPE: _VERBOSE_AUTH_TYPES.get(auth_type),
            })
        return ret

    if should_create_user:
        user_create(hub, name, group, realname, note, password)
        ret['result'] = True
        ret['comment'] = f'User {name} has been created. '
        ret['changes']['new'].update({
            _ITEM_NAME: name,
            _ITEM_FULLNAME: realname,
            _ITEM_DESCRIPTION: note,
        })
    elif should_update_data:
        user_set(hub, name, group, realname, note, password)
        ret['result'] = True
        ret['comment'] = f'User {name} has been updated. '
        ret['changes']['new'].update({
            _ITEM_FULLNAME: realname,
            _ITEM_DESCRIPTION: note,
        })

    if should_update_auth:
        if auth_type == 'password':
            user_password_set(hub, name, auth_data, password)
            ret['result'] = True
            ret['comment'] += 'Password authentication has been set.'
            ret['changes']['new'].update({
                _ITEM_AUTH_TYPE: _VERBOSE_AUTH_TYPES['password'],
            })
        elif auth_type == 'radius':
            user_radius_set(hub, name, auth_data, password)
            ret['result'] = True
            ret['comment'] += 'RADIUS authentication has been set.'
            ret['changes']['new'].update({
                _ITEM_AUTH_TYPE: _VERBOSE_AUTH_TYPES['radius'],
            })
        else:
            ret['result'] = False
            ret['comment'] += f'Authentication type {auth_type} is not recognized.'
            return ret

    return ret
