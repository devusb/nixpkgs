let
  common =
    { pkgs, ... }:
    {
      networking.firewall.enable = false;
      networking.useDHCP = false;
      # for a host utility with IPv6 support
      environment.systemPackages = [ pkgs.bind ];
    };
in
{ pkgs, ... }:
{
  name = "nsd";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ aszlig ];
  };

  nodes = {
    clientv4 =
      { lib, nodes, ... }:
      {
        imports = [ common ];
        networking.nameservers = lib.mkForce [
          (lib.head nodes.server.config.networking.interfaces.eth1.ipv4.addresses).address
        ];
        networking.interfaces.eth1.ipv4.addresses = [
          {
            address = "192.168.0.2";
            prefixLength = 24;
          }
        ];
      };

    clientv6 =
      { lib, nodes, ... }:
      {
        imports = [ common ];
        networking.nameservers = lib.mkForce [
          (lib.head nodes.server.config.networking.interfaces.eth1.ipv6.addresses).address
        ];
        networking.interfaces.eth1.ipv4.addresses = [
          {
            address = "dead:beef::2";
            prefixLength = 24;
          }
        ];
      };

    server =
      { lib, ... }:
      {
        imports = [ common ];
        networking.interfaces.eth1.ipv4.addresses = [
          {
            address = "192.168.0.1";
            prefixLength = 24;
          }
        ];
        networking.interfaces.eth1.ipv6.addresses = [
          {
            address = "dead:beef::1";
            prefixLength = 64;
          }
        ];
        services.nsd.enable = true;
        services.nsd.rootServer = true;
        services.nsd.interfaces = lib.mkForce [ ];
        services.nsd.keys."tsig.example.com." = {
          algorithm = "hmac-sha256";
          keyFile = pkgs.writeTextFile {
            name = "tsig.example.com.";
            text = "aR3FJA92+bxRSyosadsJ8Aeeav5TngQW/H/EF9veXbc=";
          };
        };
        services.nsd.zones."example.com.".data = ''
          @ SOA ns.example.com noc.example.com 666 7200 3600 1209600 3600
          ipv4 A 1.2.3.4
          ipv6 AAAA abcd::eeff
          deleg NS ns.example.com
          ns A 192.168.0.1
          ns AAAA dead:beef::1
        '';
        services.nsd.zones."example.com.".provideXFR = [ "0.0.0.0 tsig.example.com." ];
        services.nsd.zones."deleg.example.com.".data = ''
          @ SOA ns.example.com noc.example.com 666 7200 3600 1209600 3600
          @ A 9.8.7.6
          @ AAAA fedc::bbaa
        '';
        services.nsd.zones.".".data = ''
          @ SOA ns.example.com noc.example.com 666 7200 3600 1209600 3600
          root A 1.8.7.4
          root AAAA acbd::4
        '';
      };
  };

  testScript = ''
    start_all()

    clientv4.wait_for_unit("network.target")
    clientv6.wait_for_unit("network.target")
    server.wait_for_unit("nsd.service")

    with subtest("server tsig.example.com."):
        expected_tsig = "  secret: \"aR3FJA92+bxRSyosadsJ8Aeeav5TngQW/H/EF9veXbc=\"\n"
        tsig=server.succeed("cat /var/lib/nsd/private/tsig.example.com.")
        assert expected_tsig == tsig, f"Expected /var/lib/nsd/private/tsig.example.com. to contain '{expected_tsig}', but found '{tsig}'"

    def assert_host(type, rr, query, expected):
        self = clientv4 if type == 4 else clientv6
        out = self.succeed(f"host -{type} -t {rr} {query}").rstrip()
        self.log(f"output: {out}")
        import re
        assert re.search(
            expected, out
        ), f"DNS IPv{type} query on {query} gave '{out}' instead of '{expected}'"


    for ipv in 4, 6:
        with subtest(f"IPv{ipv}"):
            assert_host(ipv, "a", "example.com", "has no [^ ]+ record")
            assert_host(ipv, "aaaa", "example.com", "has no [^ ]+ record")

            assert_host(ipv, "soa", "example.com", "SOA.*?noc\.example\.com")
            assert_host(ipv, "a", "ipv4.example.com", "address 1.2.3.4$")
            assert_host(ipv, "aaaa", "ipv6.example.com", "address abcd::eeff$")

            assert_host(ipv, "a", "deleg.example.com", "address 9.8.7.6$")
            assert_host(ipv, "aaaa", "deleg.example.com", "address fedc::bbaa$")

            assert_host(ipv, "a", "root", "address 1.8.7.4$")
            assert_host(ipv, "aaaa", "root", "address acbd::4$")
  '';
}
