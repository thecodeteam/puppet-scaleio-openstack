"""
MonkeyPatched python-swiftclient Connection() class
"""
#
# Copyright (c) 2015 EMC Corporation
# All Rights Reserved
#
# This software contains the intellectual property of EMC Corporation
# or is licensed to EMC Corporation from third parties.  Use of this
# software and the intellectual property contained therein is expressly
# limited to the terms and conditions of the License Agreement under which
# it is provided by or on behalf of EMC.
#

from swiftclient import client as swift

class Connection(swift.Connection):
    """
    epc-1094
    Patched Connection class insecure=True
    """
    def __init__(self, authurl=None, user=None, key=None, retries=5,
                 preauthurl=None, preauthtoken=None, snet=False,
                 starting_backoff=1, max_backoff=64, tenant_name=None,
                 os_options=None, auth_version="1", cacert=None,
                 insecure=True, ssl_compression=True,
                 retry_on_ratelimit=False):
        """
        :param authurl: authentication URL
        :param user: user name to authenticate as
        :param key: key/password to authenticate with
        :param retries: Number of times to retry the request before failing
        :param preauthurl: storage URL (if you have already authenticated)
        :param preauthtoken: authentication token (if you have already
                             authenticated) note authurl/user/key/tenant_name
                             are not required when specifying preauthtoken
        :param snet: use SERVICENET internal network default is False
        :param starting_backoff: initial delay between retries (seconds)
        :param max_backoff: maximum delay between retries (seconds)
        :param auth_version: OpenStack auth version, default is 1.0
        :param tenant_name: The tenant/account name, required when connecting
                            to an auth 2.0 system.
        :param os_options: The OpenStack options which can have tenant_id,
                           auth_token, service_type, endpoint_type,
                           tenant_name, object_storage_url, region_name
        :param insecure: Allow to access servers without checking SSL certs.
                         The server's certificate will not be verified.
        :param ssl_compression: Whether to enable compression at the SSL layer.
                                If set to 'False' and the pyOpenSSL library is
                                present an attempt to disable SSL compression
                                will be made. This may provide a performance
                                increase for https upload/download operations.
        :param retry_on_ratelimit: by default, a ratelimited connection will
                                   raise an exception to the caller. Setting
                                   this parameter to True will cause a retry
                                   after a backoff.
        """

        # epc-1094 setting insecure=True to prevent SSL certificate verify error
        super(Connection, self).__init__(authurl, user, key, retries,
                 preauthurl, preauthtoken, snet,
                 starting_backoff, max_backoff, tenant_name,
                 os_options, auth_version, cacert,
                 insecure, ssl_compression,
                 retry_on_ratelimit)


