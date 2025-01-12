import datetime
import log
import utils

_global_dict = {}


def _init():
    global _global_dict
    _global_dict = {}


def set_value(key, value):
    _global_dict[key] = value


def get_value(key, value=None):
    try:
        return _global_dict[key]
    except KeyError:
        return value


# global shared variables
s_machine_cred = None
s_secure_channel_connection = None
s_connection_id = 1
s_reconnect_id = 0
s_connection_last_active_time = datetime.datetime.now()

s_lock = None

s_worker = None  # gunicorn worker object.
s_bind_account = None  # machine account bind to specific worker
s_computer_account_base = None
s_password_ro = None  # machine account password loaded from config file

# config for domain.conf - AD
c_netbios_name = None
c_realm = None
c_server_string = None
c_workgroup = None
c_workstation = None
c_password = None
c_additional_machine_accounts = None
c_domain = None
c_username = None
c_server_name = None
c_ad_server = None
c_listen_port = None
c_domain_identifier = None
c_dns_servers = None

# config for domain.conf - db
c_db_host = None
c_db_port = None
c_db_user = None
c_db_pass = None
c_db = None
c_db_unix_socket = None

# config for domain.conf - redis cache
c_cache_host = None
c_cache_port = None

# config for domain.conf - nt key cache
c_nt_key_cache_enabled = None
c_nt_key_cache_expire = None

c_ad_account_lockout_threshold = 0  # 0..999. Default=0, never locks
c_ad_account_lockout_duration = None  # Default not set
c_ad_reset_account_lockout_counter_after = None  # Default not set
c_ad_old_password_allowed_period = None  # Windows 2003+, Default not set, if not set, 60

c_max_allowed_password_attempts_per_device = None


def _debug():
    debug_basic_settings = f"""
Domain profile settings:
global_vars.c_server_name                   {c_server_name}
global_vars.c_ad_server                     {c_ad_server}
global_vars.c_realm                         {c_realm}
global_vars.c_workgroup                     {c_workgroup}
global_vars.c_username                      {c_username}
global_vars.c_password                      {c_password}
global_vars.c_additional_machine_accounts   {c_additional_machine_accounts}
global_vars.c_netbios_name                  {c_netbios_name}
global_vars.c_workstation                   {c_workstation}
global_vars.c_server_string                 {c_server_string}
global_vars.c_domain                        {c_domain}
global_vars.c_dns_servers                   {c_dns_servers}
----    
"""

    debug_nt_key_cache = f"""
NT Key cache settings:
global_vars.c_nt_key_cache_enabled  {c_nt_key_cache_enabled}
global_vars.c_nt_key_cache_expire   {c_nt_key_cache_expire}    

global_vars.c_ad_account_lockout_threshold              {c_ad_account_lockout_threshold}
global_vars.c_ad_account_lockout_duration               {c_ad_account_lockout_duration}
global_vars.c_ad_reset_account_lockout_counter_after    {c_ad_reset_account_lockout_counter_after}
global_vars.c_ad_old_password_allowed_period            {c_ad_old_password_allowed_period}
global_vars.c_max_allowed_password_attempts_per_device  {c_max_allowed_password_attempts_per_device}
----
"""

    debug_db_settings = f"""
Database settings:
global_vars.c_db_host           {c_db_host}
global_vars.c_db_port           {c_db_port}
global_vars.c_db_user           {c_db_user}
global_vars.c_db_pass           {utils.mask_password(c_db_pass)}
global_vars.c_db                {c_db}
global_vars.c_db_unix_socket    {c_db_unix_socket}
----
"""

    debug_redis_settings = f"""
Redis settings:
f"global_vars.c_cache_host    {c_cache_host}"
f"global_vars.c_cache_port    {c_cache_port}"
----
"""


    debug_computer_account_base = f"""
global_vars.s_computer_account_base     {s_computer_account_base}    
"""




