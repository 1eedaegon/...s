# packages/combinations/security.nix
# Security scanning + network tooling, grouped into cohesive sets so other
# combinations (e.g. infra) can import only the relevant subset instead of the
# full suite. The `security` devShell still gets everything via `packages`.
{ pkgs }:

let
  inherit (pkgs) lib stdenv;

  # ── Cloud posture / CSPM ── (python-heavy; prowler's tests are flaky on aarch64)
  cloudPosture = with pkgs; [
    prowler # AWS / Azure / GCP / K8s security assessment
    steampipe # SQL-driven cloud asset inspection
  ];

  # ── Container / image / SBOM ── (Go; builds cleanly on aarch64)
  container = with pkgs; [
    trivy # vuln + misconfig + secret scanner
    grype # vulnerability scanner (anchore)
    syft # SBOM generator (anchore)
    dive # docker image layer inspector
    cosign # sigstore container signing / verification
  ];

  # ── IaC scanners ── (Go)
  # checkov removed: pulls python ecdsa 0.19.2 (CVE-2024-23342, marked
  # insecure in nixpkgs). Coverage retained via tfsec/terrascan/kics.
  iac = with pkgs; [
    tfsec # terraform static analysis
    terrascan # IaC compliance scanning
    kics # checkmarx IaC scanner
  ];

  # ── Kubernetes hardening ── (Go)
  k8s = with pkgs; [
    kube-bench # CIS Kubernetes benchmark
    kubeaudit # cluster audit
    kubescape # NSA / MITRE / CIS posture
    kubesec # manifest risk scoring
    popeye # cluster sanitizer
  ];

  # ── Secrets / supply chain ── (Go / Rust)
  secrets = with pkgs; [
    gitleaks # repo secret scanner
    trufflehog # high-entropy secret scanner
    sops # encrypted secrets (age / pgp / kms)
    age # modern file encryption
    pass # CLI password store
  ];

  # ── SAST / DAST / pentest ── (python-heavy; semgrep tests fail on aarch64)
  sast = with pkgs; [
    semgrep # multi-language SAST
    nuclei # template-driven vuln scanner
    nikto # web server scanner
    sqlmap # SQL injection testing
  ];

  # ── Network diagnostics ── (mostly C utils; mitmproxy is python)
  network = with pkgs; [
    nmap # port / host discovery (also platform-pinned on linux)
    masscan # mass port scanner
    tcpdump # packet capture
    wireshark-cli # tshark + dumpcap
    termshark # TUI for tshark
    mtr # traceroute + ping
    iperf3 # bandwidth measurement
    bandwhich # per-process bandwidth (linux/macOS)
    iftop # interface traffic top
    doggo # modern dig replacement
    bind # dig / nslookup / host
    httpie # human-friendly curl
    xh # rust-based httpie clone
    grpcurl # gRPC curl
    websocat # websocket curl
    mitmproxy # MITM proxy / inspector
    socat # multipurpose relay
    netcat-gnu # GNU ncat (cross-platform; openbsd variant is linux-only)
    ngrep # grep over network packets
    ipcalc # subnet calculator
    whois # whois client
  ] ++ lib.optionals stdenv.isLinux [
    nethogs # per-process net usage (linux only)
  ];
in
{
  # Named groups for selective import by other combinations.
  inherit cloudPosture container iac k8s secrets sast network;

  # Full suite — used by the `security` devShell.
  packages = cloudPosture ++ container ++ iac ++ k8s ++ secrets ++ sast ++ network;

  # IaC/cloud-relevant subset for the `infra` devShell. All Go/Rust tools that
  # build cleanly on aarch64 (Jetson); deliberately excludes the python-heavy
  # SAST/CSPM/MITM tools (semgrep, prowler, mitmproxy) whose test suites fail on
  # aarch64 and which aren't needed for IaC/devops work.
  iacSubset = container ++ iac ++ k8s ++ secrets;
}
