import 'package:hiddify/core/http_client/http_client_provider.dart';
import 'package:hiddify/features/config/model/config_models.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'config_repository.g.dart';

// مخزن واکشی کانفیگ ها
// Handles fetching configuration data from the server.
abstract class ConfigRepository with AppLogger {
  Future<ServerData> fetchData();
}

class ConfigRepositoryImpl extends ConfigRepository {
  ConfigRepositoryImpl(this.ref);
  final Ref ref;

  @override
  Future<ServerData> fetchData() async {
    final client = ref.read(httpClientProvider);
    loggy.info("fetching server data (MOCKED)");

    try {
      // در حالت واقعی، اینجا درخواست به سرور ارسال می‌شود
      // In a real scenario, this is where we would make the API call
      // final response = await client.get("https://your-server.com/api/configs");
      // return ServerData.fromJson(response.data as Map<String, dynamic>);

      // شبیه سازی تاخیر شبکه
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // داده های نمونه برای تست
      // Mock data for testing
      return ServerData(
        usage: UserUsage(remainingDataGB: 45.8, remainingDays: 18),
        configs: [
          // کانفیگ های V2Ray
          // V2Ray configs
          ServerConfig(
            id: "v1",
            name: "Germany - Frankfurt (V2Ray)",
            type: ConfigType.v2ray,
            data: "vless://6ee386fa-4d5c-4b5c-8c76-a5d7c6f82e1a@frankfurt.example.com:443?encryption=none&security=tls&sni=frankfurt.example.com&type=ws&host=frankfurt.example.com&path=%2Fws#Germany%20V2Ray",
          ),
          ServerConfig(
            id: "v2",
            name: "Netherlands - Amsterdam (V2Ray)",
            type: ConfigType.v2ray,
            data: "vless://8fc386fa-1a5c-4b5c-8c76-a5d7c6f82e1a@amsterdam.example.com:443?encryption=none&security=tls&sni=amsterdam.example.com&type=ws&host=amsterdam.example.com&path=%2Fws#Netherlands%20V2Ray",
          ),
          ServerConfig(
            id: "v3",
            name: "USA - New York (V2Ray)",
            type: ConfigType.v2ray,
            data: "vless://3ab386fa-4d5c-4b5c-8c76-a5d7c6f82e1a@newyork.example.com:443?encryption=none&security=tls&sni=newyork.example.com&type=ws&host=newyork.example.com&path=%2Fws#USA%20V2Ray",
          ),

          // کانفیگ های OpenVPN
          // OpenVPN configs
          ServerConfig(
            id: "o1",
            name: "Germany - Berlin (OpenVPN)",
            type: ConfigType.openvpn,
            data: """client
dev tun
proto udp
remote berlin.example.com 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verify-x509-name server_ADBKlGAJD name
auth SHA256
auth-nocache
cipher AES-128-GCM
tls-client
tls-version-min 1.2
tls-cipher TLS-ECDHE-RSA-WITH-AES-128-GCM-SHA256
ignore-unknown-option block-outside-dns
setenv opt block-outside-dns
verb 3
<ca>
-----BEGIN CERTIFICATE-----
MIIBwjCCAWigAwIBAgIUJY8hsXDETdF/qZwHXZ8zg3T4+aowCgYIKoZIzj0EAwIw
FDESMBAGADVQQDDAlPcGVuVlBOIENBMB4XDTIzMDgxMjIwMjY0OVoXDTMzMDgw
OTIwMjY0OVowFDESMBAGA1UEAwwJT3BlblZQTiBDQTBZMBMGByqGSM49AgEGCCqG
SM49AwEHA0IABPqHyQQvbGAC2ZcYKmL0SrQnIvJCj1zOBNvHWV9hEUbCXjIP3Tn9
XdUeKGrVjZBvlAQdT7onfhgLk3KHQbTyBv+jgY0wgYowHQYDVR0OBBYEFJSmVuVA
eFKrNCgtkCCdpTwVU5xXME4GA1UdIwRHMEWAFJSmVuVAeFKrNCgtkCCdpTwVU5xX
oRikFjAUMRIwEAYDVQQDDAlPcGVuVlBOIENBghQljyGxcMRN0X+pnAddnzODdPj5
qjAMBgNVHRMEBTADAQH/MAsGA1UdDwQEAwIBBjAKBggqhkjOPQQDAgNIADBFAiEA
1OCFYBZlIWK+Jzs/jARfJQKHyD4jWJ0qZpfn7Tb9W0QCIHVO3ioqZvq0zL4+1CYR
nvvT+EGvQIQTLUmLPj4LMKVS
-----END CERTIFICATE-----
</ca>""",
          ),
          ServerConfig(
            id: "o2",
            name: "UK - London (OpenVPN)",
            type: ConfigType.openvpn,
            data: """client
proto udp
tun-mtu 1420
explicit-exit-notify
remote  Vexor.vyzenn.online  50323
remote  hermes.vyzenn.online  50323
remote  lomus.vyzenn.online  53450
remote  lomus.vyzenn.online  53420
dev tun
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verify-x509-name server_bbk1T68Ly40iURH4 name
auth SHA256
auth-nocache
cipher AES-256-GCM
tls-client
tls-version-min 1.2
tls-cipher TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256
ignore-unknown-option block-outside-dns
setenv opt block-outside-dns # Prevent Windows 10 DNS leak
verb 3
<ca>
-----BEGIN CERTIFICATE-----
MIIB1zCCAX2gAwIBAgIUN7P6dv4ZgnhkMOGyUE3mNe28GMUwCgYIKoZIzj0EAwIw
HjEcMBoGA1UEAwwTY25fOVRMOFoxcnJiR3M3d1VzbzAeFw0yNTAyMDYxNTQ5NTBa
Fw0zNTAyMDQxNTQ5NTBaMB4xHDAaBgNVBAMME2NuXzlUTDhaMXJyYkdzN3dVc28w
WTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARzWfIJ+rr++IXug2YJdnUWWeWX/dxh
Mg0YncM3zw8FnR8V3fQxZJDXZrAZt0Sb8/JX6xFTDw/TquOv/1T4K+8yo4GYMIGV
MAwGA1UdEwQFMAMBAf8wHQYDVR0OBBYEFL54MwizsDqOEOnPsH6U1QvNXt0GMFkG
A1UdIwRSMFCAFL54MwizsDqOEOnPsH6U1QvNXt0GoSKkIDAeMRwwGgYDVQQDDBNj
bl85VEw4WjFycmJHczd3VXNvghQ3s/p2/hmCeGQw4bJQTeY17bwYxTALBgNVHQ8E
BAMCAQYwCgYIKoZIzj0EAwIDSAAwRQIgXHPTXH6yQSMMRiISJicoMKmvjHW7rXS1
IMy+8UyhffoCIQDSV7DRnmIs3wByDse9ygk4foLCNVRpX8Z7NxpVc7ALug==
-----END CERTIFICATE-----
</ca>
<cert>
-----BEGIN CERTIFICATE-----
MIIB3DCCAYOgAwIBAgIRAN5YtlmNoYzdjJzRe8xpgYwwCgYIKoZIzj0EAwIwHjEc
MBoGA1UEAwwTY25fOVRMOFoxcnJiR3M3d1VzbzAeFw0yNTAyMDYxNTUwMDhaFw0z
NTAyMDQxNTUwMDhaMBUxEzARBgNVBAMMCkxPTkRPTi1ORVcwWTATBgcqhkjOPQIB
BggqhkjOPQMBBwNCAAR0T8XCiSBC3JP7k5/Bksu24DXFpGFQNuGw37Os5KXwSGCh
uFHZtxFJEF8dhFONlYoqCH/rDkJTYGNVZISpIazzo4GqMIGnMAkGA1UdEwQCMAAw
HQYDVR0OBBYEFPdX3TI2n7o2S1kxT2dhkpp0JZ87MFkGA1UdIwRSMFCAFL54Mwiz
sDqOEOnPsH6U1QvNXt0GoSKkIDAeMRwwGgYDVQQDDBNjbl85VEw4WjFycmJHczd3
VXNvghQ3s/p2/hmCeGQw4bJQTeY17bwYxTATBgNVHSUEDDAKBggrBgEFBQcDAjAL
BgNVHQ8EBAMCB4AwCgYIKoZIzj0EAwIDRwAwRAIgAKN87JhxOPRYfxT7whGehfPC
gaIuFQ4n7hWU37jHEKUCIE+6evlqNtzIoncJzvyq6VNMp9Ld04Fc0ORvK9HEc6Hi
-----END CERTIFICATE-----
</cert>
<key>
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgzu8sLWWgjbtYtf76
bl3+2+VI1X6R3PFvN4Ol4DbJFf+hRANCAAR0T8XCiSBC3JP7k5/Bksu24DXFpGFQ
NuGw37Os5KXwSGChuFHZtxFJEF8dhFONlYoqCH/rDkJTYGNVZISpIazz
-----END PRIVATE KEY-----
</key>
<tls-crypt>
#
# 2048 bit OpenVPN static key
#
-----BEGIN OpenVPN Static key V1-----
c542b22d3ef79997d69747ad38b41b52
c5c58edf20f10cf4fcb6b1eb9d06f0c6
745676916555f19cea5485daf1a8d6f9
240daaf68c61a030ad0d08caa71ed7f7
868360593d37e2a8b25f6a21fe90b1df
b3d1d3e545ef2cba3769d3b6f92744f7
9c08e082083cad48f3ce8427d85a69e7
3315242dcd974a473fb57b16577d2531
d9263a895aa2857eb923f57a115a8aba
5bace528c13b57f1aaec3bd2e735d2fe
a4a7fe1d479332c7a75fc71f5988c1d0
fd5c4fc21bd62a2a13a25f2345de57ce
c207906b62481f80ac86afb1836b1723
0353d3662c79eccf36e4c91ca3d55b20
0754f460e800fba30736219b78ea8aee
01c9a348e89760a583ea12ea9875fbef
-----END OpenVPN Static key V1-----
</tls-crypt>
""",
          ),
        ],
      );
    } catch (e, stackTrace) {
      loggy.error("Error fetching configurations", e, stackTrace);
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
ConfigRepository configRepository(ConfigRepositoryRef ref) {
  return ConfigRepositoryImpl(ref);
}
