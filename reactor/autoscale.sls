#!py

def run():
    '''
    Run the reactor
    '''
    vm_ = data['new_data']

    vm_opts = __opts__.get('nova.autoscale', {})
    vm_['provider'] = vm_opts['provider']
    for key, value in vm_opts.iteritems():
        vm_[key] = value
    vm_['instances'] = data['new_data']['name']
    vm_['instance_id'] = data['new_data']['id']
    vm_list = []
    for key, value in vm_.iteritems():
        if not key.startswith('__') and key != 'state':
            vm_list.append({key: value})

    # Fire off an event to wait for the machine
    ret = {
        'autoscale_launch': {
            'runner.cloud.create': vm_list
        }
    }

    return ret