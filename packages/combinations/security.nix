# packages/combinations/security.nix
# Security scanning + network tooling
#   - Cloud / IaC / container / SBOM scanners (prowler, trivy, grype, syft, checkov, tfsec, terrascan, kics)
#   - Kubernetes hardening (kube-bench, kubeaudit, kubescape, kubesec)
#   - Secret scanning & supply chain (gitleaks, trufflehog, cosign, sops, age)
#   - SAST / DAST (semgrep, nuclei)
#   - Network diagnostics (nmap, tcpdump, tshark, mtr, iperf3, mitmproxy, doggo, httpie, socat, netcat)
{ pkgs }:

let
  inherit (pkgs) lib stdenv;
in
{
  packages = with pkgs; [
    # ── Cloud posture / CSPM ──
    prowler # AWS / Azure / GCP / K8s security assessment
    steampipe # SQL-driven cloud asset inspection

    # ── Container / image / SBOM ──
    trivy # vuln + misconfig + secret scanner
    grype # vulnerability scanner (anchore)
    syft # SBOM generator (anchore)
    dive # docker image layer inspector
    cosign # sigstore container signing / verification

    # ── IaC scanners ──
    checkov # terraform / cfn / k8s / docker policy
    tfsec # terraform static analysis
    terrascan # IaC compliance scanning
    kics # checkmarx IaC scanner

    # ── Kubernetes hardening ──
    kube-bench # CIS Kubernetes benchmark
    kubeaudit # cluster audit
    kubescape # NSA / MITRE / CIS posture
    kubesec # manifest risk scoring
    popeye # cluster sanitizer

    # ── Secrets / supply chain ──
    gitleaks # repo secret scanner
    trufflehog # high-entropy secret scanner
    sops # encrypted secrets (age / pgp / kms)
    age # modern file encryption
    pass # CLI password store

    # ── SAST / DAST / pentest ──
    semgrep # multi-language SAST
    nuclei # template-driven vuln scanner
    nikto # web server scanner
    sqlmap # SQL injection testing

    # ── Network diagnostics ──
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
}
