"""Contains all the data models used in inputs/outputs"""

from .architecture import Architecture
from .bandwidth_class import BandwidthClass
from .bootorder import Bootorder
from .cpu_topology import CpuTopology
from .disk import Disk
from .edit_disks_driver import EditDisksDriver
from .failover_i_pv_4 import FailoverIPv4
from .failover_i_pv_6 import FailoverIPv6
from .field_error import FieldError
from .firewall_action import FirewallAction
from .firewall_policy import FirewallPolicy
from .firewall_policy_save import FirewallPolicySave
from .firewall_policy_update_result import FirewallPolicyUpdateResult
from .firewall_protocol import FirewallProtocol
from .firewall_rule import FirewallRule
from .firewall_rule_direction import FirewallRuleDirection
from .get_api_v1_openapi_response_200 import GetApiV1OpenapiResponse200
from .get_api_v1_servers_server_id_metrics_cpu_response_200 import (
    GetApiV1ServersServerIdMetricsCpuResponse200,
)
from .get_api_v1_servers_server_id_metrics_disk_response_200 import (
    GetApiV1ServersServerIdMetricsDiskResponse200,
)
from .get_api_v1_servers_server_id_metrics_network_packet_response_200 import (
    GetApiV1ServersServerIdMetricsNetworkPacketResponse200,
)
from .get_api_v1_servers_server_id_metrics_network_response_200 import (
    GetApiV1ServersServerIdMetricsNetworkResponse200,
)
from .guest_agent_data import GuestAgentData
from .guest_agent_data_guest_agent_data import GuestAgentDataGuestAgentData
from .i_pv_4_address_minimal import IPv4AddressMinimal
from .i_pv_6_address_minimal import IPv6AddressMinimal
from .identifier_int import IdentifierInt
from .image_flavour import ImageFlavour
from .image_minimal import ImageMinimal
from .implicit_rule import ImplicitRule
from .interface import Interface
from .iso import Iso
from .iso_image import IsoImage
from .log import Log
from .log_type import LogType
from .maintenance import Maintenance
from .network_driver import NetworkDriver
from .not_found_error import NotFoundError
from .os_optimization import OsOptimization
from .post_api_v1_openapi_mcp_response_200 import PostApiV1OpenapiMcpResponse200
from .rdns import Rdns
from .rescue_system_status import RescueSystemStatus
from .response_error import ResponseError
from .route_failover_ip import RouteFailoverIp
from .s3_completed_part import S3CompletedPart
from .s3_download_infos import S3DownloadInfos
from .s3_download_infos_headers import S3DownloadInfosHeaders
from .s3_no_such_upload_error import S3NoSuchUploadError
from .s3_object import S3Object
from .s3_sign_part_url import S3SignPartURL
from .s3_upload import S3Upload
from .server import Server
from .server_attach_iso import ServerAttachIso
from .server_autostart_patch import ServerAutostartPatch
from .server_bootorder_patch import ServerBootorderPatch
from .server_cpu_topology_patch import ServerCpuTopologyPatch
from .server_create_nic_vlan import ServerCreateNicVlan
from .server_disk import ServerDisk
from .server_firewall import ServerFirewall
from .server_firewall_save import ServerFirewallSave
from .server_hostname_patch import ServerHostnamePatch
from .server_image_setup import ServerImageSetup
from .server_info import ServerInfo
from .server_interface import ServerInterface
from .server_interface_update import ServerInterfaceUpdate
from .server_ip_type import ServerIpType
from .server_ipv_4 import ServerIpv4
from .server_ipv_6 import ServerIpv6
from .server_ipv_6_rdns import ServerIpv6Rdns
from .server_keyboard_layout_patch import ServerKeyboardLayoutPatch
from .server_list_minimal import ServerListMinimal
from .server_minimal import ServerMinimal
from .server_nickname_patch import ServerNicknamePatch
from .server_os_optimization_patch import ServerOsOptimizationPatch
from .server_set_root_password_patch import ServerSetRootPasswordPatch
from .server_snapshot_create import ServerSnapshotCreate
from .server_snapshot_create_check import ServerSnapshotCreateCheck
from .server_state import ServerState
from .server_state_1 import ServerState1
from .server_state_patch import ServerStatePatch
from .server_template_minimal import ServerTemplateMinimal
from .server_uefi_patch import ServerUEFIPatch
from .server_user_image_setup import ServerUserImageSetup
from .set_rdns_ipv_4 import SetRdnsIpv4
from .set_rdns_ipv_6 import SetRdnsIpv6
from .site import Site
from .snapshot import Snapshot
from .snapshot_minimal import SnapshotMinimal
from .ssh_key import SSHKey
from .storage_driver import StorageDriver
from .storage_optimization import StorageOptimization
from .task_info import TaskInfo
from .task_info_minimal import TaskInfoMinimal
from .task_info_result import TaskInfoResult
from .task_info_step import TaskInfoStep
from .task_progress import TaskProgress
from .task_state import TaskState
from .user import User
from .user_minimal import UserMinimal
from .user_save import UserSave
from .v_lan import VLan
from .v_lan_save import VLanSave
from .validation_error import ValidationError

__all__ = (
    "Architecture",
    "BandwidthClass",
    "Bootorder",
    "CpuTopology",
    "Disk",
    "EditDisksDriver",
    "FailoverIPv4",
    "FailoverIPv6",
    "FieldError",
    "FirewallAction",
    "FirewallPolicy",
    "FirewallPolicySave",
    "FirewallPolicyUpdateResult",
    "FirewallProtocol",
    "FirewallRule",
    "FirewallRuleDirection",
    "GetApiV1OpenapiResponse200",
    "GetApiV1ServersServerIdMetricsCpuResponse200",
    "GetApiV1ServersServerIdMetricsDiskResponse200",
    "GetApiV1ServersServerIdMetricsNetworkPacketResponse200",
    "GetApiV1ServersServerIdMetricsNetworkResponse200",
    "GuestAgentData",
    "GuestAgentDataGuestAgentData",
    "IdentifierInt",
    "ImageFlavour",
    "ImageMinimal",
    "ImplicitRule",
    "Interface",
    "IPv4AddressMinimal",
    "IPv6AddressMinimal",
    "Iso",
    "IsoImage",
    "Log",
    "LogType",
    "Maintenance",
    "NetworkDriver",
    "NotFoundError",
    "OsOptimization",
    "PostApiV1OpenapiMcpResponse200",
    "Rdns",
    "RescueSystemStatus",
    "ResponseError",
    "RouteFailoverIp",
    "S3CompletedPart",
    "S3DownloadInfos",
    "S3DownloadInfosHeaders",
    "S3NoSuchUploadError",
    "S3Object",
    "S3SignPartURL",
    "S3Upload",
    "Server",
    "ServerAttachIso",
    "ServerAutostartPatch",
    "ServerBootorderPatch",
    "ServerCpuTopologyPatch",
    "ServerCreateNicVlan",
    "ServerDisk",
    "ServerFirewall",
    "ServerFirewallSave",
    "ServerHostnamePatch",
    "ServerImageSetup",
    "ServerInfo",
    "ServerInterface",
    "ServerInterfaceUpdate",
    "ServerIpType",
    "ServerIpv4",
    "ServerIpv6",
    "ServerIpv6Rdns",
    "ServerKeyboardLayoutPatch",
    "ServerListMinimal",
    "ServerMinimal",
    "ServerNicknamePatch",
    "ServerOsOptimizationPatch",
    "ServerSetRootPasswordPatch",
    "ServerSnapshotCreate",
    "ServerSnapshotCreateCheck",
    "ServerState",
    "ServerState1",
    "ServerStatePatch",
    "ServerTemplateMinimal",
    "ServerUEFIPatch",
    "ServerUserImageSetup",
    "SetRdnsIpv4",
    "SetRdnsIpv6",
    "Site",
    "Snapshot",
    "SnapshotMinimal",
    "SSHKey",
    "StorageDriver",
    "StorageOptimization",
    "TaskInfo",
    "TaskInfoMinimal",
    "TaskInfoResult",
    "TaskInfoStep",
    "TaskProgress",
    "TaskState",
    "User",
    "UserMinimal",
    "UserSave",
    "ValidationError",
    "VLan",
    "VLanSave",
)
