#!/bin/bash
set -euo pipefail

# ── Live: recent activity ticker ──
REPOS=$(gh api user/repos --paginate --jq '.[]' | jq -s '
  sort_by(.updated_at) | reverse |
  [.[] | select(.fork == false and .archived == false and .is_template == false) | .name]
')

TICKER=$(echo "$REPOS" | jq -r '.[:10] | .[]' | while read -r name; do
  printf '▶ %s  │  ' "$name"
done | sed 's/  │  $//')

SYNC_TIME=$(date -u "+%d %b %Y")

# ── Header SVG ──
cat > assets/header.svg << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 620 168" width="620" height="168">
  <rect width="620" height="168" fill="#0d1117" rx="6"/>

  <g transform="translate(18,22)">
    <circle cx="12" cy="10" r="7" fill="none" stroke="#58a6ff" stroke-width="1.5">
      <animate attributeName="opacity" from="0" to="1" dur="0.3s" begin="0s" fill="freeze"/>
    </circle>
    <path d="M2 28 Q12 18 22 28" fill="none" stroke="#58a6ff" stroke-width="1.5">
      <animate attributeName="opacity" from="0" to="1" dur="0.3s" begin="0s" fill="freeze"/>
    </path>
  </g>

  <text x="52" y="34" font-family="Courier New,monospace" font-size="12" fill="#8b949e" opacity="0">
    BharathrajN2004@github
    <animate attributeName="opacity" from="0" to="1" dur="0.3s" begin="0.3s" fill="freeze"/>
  </text>

  <line x1="52" y1="42" x2="570" y2="42" stroke="#30363d" stroke-width="0.5" opacity="0">
    <animate attributeName="opacity" from="0" to="1" dur="0.2s" begin="0.5s" fill="freeze"/>
  </line>

  <text x="52" y="76" font-family="Courier New,monospace" font-size="32" font-weight="bold" fill="#58a6ff" opacity="0">
    BHARATHRAJ N
    <animate attributeName="opacity" from="0" to="1" dur="0.01s" begin="1.8s" fill="freeze"/>
  </text>
  <rect x="52" y="50" height="34" fill="#0d1117" width="340">
    <animate attributeName="width" from="340" to="0" dur="1.5s" begin="0.7s" fill="freeze"/>
  </rect>

  <rect x="392" y="52" width="4" height="30" fill="#58a6ff" opacity="0">
    <animate attributeName="opacity" from="0" to="1" dur="0.01s" begin="2.2s" fill="freeze"/>
    <animate attributeName="opacity" values="1;1;0;0;1" dur="0.9s" begin="2.5s" repeatCount="indefinite"/>
  </rect>

  <text x="52" y="102" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="13" font-weight="600" fill="#3fb950" opacity="0">
    SDE @ Scrapuncle
    <animate attributeName="opacity" from="0" to="1" dur="0.4s" begin="2.6s" fill="freeze"/>
  </text>
  <text x="52" y="124" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="13" fill="#9aa4b2" opacity="0">
    Building customer-facing &amp; internal-ops apps, plus the
    <animate attributeName="opacity" from="0" to="1" dur="0.4s" begin="3s" fill="freeze"/>
  </text>
  <text x="52" y="144" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="13" fill="#9aa4b2" opacity="0">
    microservice + dashboard platform powering the org's tooling.  ♥
    <animate attributeName="opacity" from="0" to="1" dur="0.4s" begin="3.2s" fill="freeze"/>
  </text>
</svg>
SVGEOF

# ── Systems Composition SVG (hand-curated ranking, not raw repo byte-count) ──
cat > assets/lang-panel.svg << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 560 60" width="560" height="60">
  <rect x="0" y="0" width="560" height="14" rx="7" fill="#161b22"/>
  <rect x="0" y="0" width="134" height="14" rx="7" fill="#00B4AB"><animate attributeName="width" from="0" to="134" dur="0.8s" begin="0s" fill="freeze"/></rect>
  <rect x="134" y="0" width="112" height="14" fill="#00ADD8"><animate attributeName="width" from="0" to="112" dur="0.8s" begin="0.1s" fill="freeze"/></rect>
  <rect x="246" y="0" width="95" height="14" fill="#3178C6"><animate attributeName="width" from="0" to="95" dur="0.8s" begin="0.2s" fill="freeze"/></rect>
  <rect x="341" y="0" width="78" height="14" fill="#7F52FF"><animate attributeName="width" from="0" to="78" dur="0.8s" begin="0.3s" fill="freeze"/></rect>
  <rect x="419" y="0" width="62" height="14" fill="#F05138"><animate attributeName="width" from="0" to="62" dur="0.8s" begin="0.4s" fill="freeze"/></rect>
  <rect x="481" y="0" width="50" height="14" fill="#00599C"><animate attributeName="width" from="0" to="50" dur="0.8s" begin="0.5s" fill="freeze"/></rect>
  <rect x="531" y="0" width="29" height="14" rx="7" fill="#3776AB"><animate attributeName="width" from="0" to="29" dur="0.8s" begin="0.6s" fill="freeze"/></rect>

  <circle cx="8" cy="38" r="4" fill="#00B4AB"/><text x="17" y="42" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="11" fill="#e6e8eb" font-weight="600">Dart</text><text x="47" y="42" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="11" fill="#6e7681">24%</text>
  <circle cx="90" cy="38" r="4" fill="#00ADD8"/><text x="99" y="42" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="11" fill="#e6e8eb" font-weight="600">Go</text><text x="118" y="42" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="11" fill="#6e7681">20%</text>
  <circle cx="160" cy="38" r="4" fill="#3178C6"/><text x="169" y="42" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="11" fill="#e6e8eb" font-weight="600">TypeScript</text><text x="240" y="42" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="11" fill="#6e7681">17%</text>
  <circle cx="290" cy="38" r="4" fill="#7F52FF"/><text x="299" y="42" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="11" fill="#e6e8eb" font-weight="600">Kotlin</text><text x="345" y="42" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="11" fill="#6e7681">14%</text>
  <circle cx="390" cy="38" r="4" fill="#F05138"/><text x="399" y="42" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="11" fill="#e6e8eb" font-weight="600">Swift</text><text x="435" y="42" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="11" fill="#6e7681">11%</text>
  <circle cx="8" cy="56" r="4" fill="#00599C"/><text x="17" y="60" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="11" fill="#e6e8eb" font-weight="600">C++</text><text x="45" y="60" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="11" fill="#6e7681">9%</text>
  <circle cx="90" cy="56" r="4" fill="#3776AB"/><text x="99" y="60" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="11" fill="#e6e8eb" font-weight="600">Python</text><text x="145" y="60" font-family="-apple-system,Helvetica,Arial,sans-serif" font-size="11" fill="#6e7681">5%</text>
</svg>
SVGEOF

# ── README ──
cat > README.md << HEREDOC
<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/header.svg">
  <img src="assets/header.svg" width="580" alt="Bharathraj N">
</picture>

<br>

<sub><b>TELEMETRY FEED</b></sub>

<marquee width="88%" direction="left" scrollamount="3" scrolldelay="30">
  ${TICKER}
</marquee>

---

### How I build

\`SOLID\` — \`MVVM\` — \`DRY\` — \`CQRS\` — \`ACID\` — \`CAP\`

- Architecture bends to the problem, not the other way around.
- Boundaries live where change lives — everywhere else stays simple.
- Systems degrade gracefully; they don't go dark.
- Visibility ships before velocity — you can't fix what you can't see.

---

### Learning Projects

Built to learn a stack, not just to ship one.

- **[microservices-lab](https://github.com/BharathrajN2004/microservices-lab)** — a Go microservices study project: Fiber for HTTP, gRPC for service-to-service calls, Postgres via Ent, and NATS JetStream for async messaging. Built to understand how a real microservice mesh holds together end to end, not just the theory of it.
- **[macmonitor](https://github.com/BharathrajN2004/macmonitor)** — a native Swift macOS utility for system cleanup and monitoring. First serious dive into native macOS development outside the Flutter/Go comfort zone.
- **[studiov-video-editor](https://github.com/BharathrajN2004/studiov-video-editor)** + **[studiov-editor-workspace](https://github.com/BharathrajN2004/studiov-editor-workspace)** — a Flutter video editor handling frame extraction, green-screen removal, and overlay compositing, paired with its companion mobile + desktop workspace app.
- **[split-it](https://github.com/BharathrajN2004/split-it)** — a full-stack bill/expense-splitting app: Flutter frontend, Node/Express + MongoDB backend, UPI/wallet payments, group splitting.
- **[pond-water-quality-monitor-lite](https://github.com/BharathrajN2004/pond-water-quality-monitor-lite)** — a Flutter IoT app streaming real-time pond water-quality sensor data (dissolved oxygen, pH, temperature) via Firebase Realtime Database.
- **[student-permission-tracker](https://github.com/BharathrajN2004/student-permission-tracker)** → **[attendance-validator](https://github.com/BharathrajN2004/attendance-validator)** — an evolution story, not a single project: started as an EJS/Express/MongoDB prototype for tracking student leave-permission records, later rebuilt as a fuller React + Firebase attendance/leave validator.
- **[event-pod](https://github.com/BharathrajN2004/event-pod)** — a Flutter app for browsing and sharing public events, with a scraping-based recommendation feature.

---

### Personal Works

Private, not part of the public roster above.

- ✅ **nadai** — a habit tracker built in Flutter, active development.
- 🃏 **Literature** — a cards-game project, not yet pushed to GitHub.
- 🍳 **Cooking** — early stage, not yet pushed to GitHub.
- 🧩 **Handler** — an adaptive organizational OS that reshapes itself around a company's structure, discipline, and principles.

...and more in planning.

---

### Systems Composition

What I reach for most, in order.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/lang-panel.svg">
  <img src="assets/lang-panel.svg" width="560" alt="Systems Composition">
</picture>

<br>

![Stats](https://github-readme-stats.vercel.app/api?username=BharathrajN2004&show_icons=true&theme=dark&hide_border=true&bg_color=0d1117&icon_color=58a6ff&text_color=c9d1d9&title_color=58a6ff&hide=stars\&hide_rank=true\&include_all_commits=true\&count_private=true)

<br>

![Activity](https://github-readme-activity-graph.vercel.app/graph?username=BharathrajN2004&theme=react-dark&bg_color=0d1117&color=58a6ff&line=58a6ff&point=c9d1d9&hide_border=true&area=true)

---

### Tech Stack

Grouped by where it ships — each tool listed once.

<table>
<tr><td align="center" width="100"><sub><b>MOBILE</b></sub></td><td>

<img src="https://skillicons.dev/icons?i=flutter" height="28"/> <img src="https://img.shields.io/badge/React_Native-%2320232a.svg?style=flat-square&logo=react&logoColor=%2361DAFB" height="28"/> <img src="https://skillicons.dev/icons?i=kotlin" height="28"/> <img src="https://skillicons.dev/icons?i=swift" height="28"/>

</td></tr>
<tr><td align="center"><sub><b>WEBSITE</b></sub></td><td>

<img src="https://skillicons.dev/icons?i=react" height="28"/> <img src="https://skillicons.dev/icons?i=nextjs" height="28"/>

</td></tr>
<tr><td align="center"><sub><b>BACKEND</b></sub></td><td>

<img src="https://skillicons.dev/icons?i=go" height="28"/> <img src="https://skillicons.dev/icons?i=ts" height="28"/>

</td></tr>
<tr><td align="center"><sub><b>CLOUD</b></sub></td><td>

<img src="https://skillicons.dev/icons?i=firebase" height="28"/> <img src="https://skillicons.dev/icons?i=supabase" height="28"/> <img src="https://skillicons.dev/icons?i=gcp" height="28"/> <img src="https://skillicons.dev/icons?i=aws" height="28"/>

</td></tr>
<tr><td align="center"><sub><b>DEVOPS</b></sub></td><td>

<img src="https://skillicons.dev/icons?i=docker" height="28"/> <img src="https://skillicons.dev/icons?i=kubernetes" height="28"/> <img src="https://img.shields.io/badge/Helm-%230F1689.svg?style=flat-square&logo=helm&logoColor=%23FFFFFF" height="28"/> <img src="https://skillicons.dev/icons?i=terraform" height="28"/>

</td></tr>
<tr><td align="center"><sub><b>ANALYTICS</b></sub></td><td>

<img src="https://skillicons.dev/icons?i=grafana" height="28"/> <img src="https://img.shields.io/badge/PostHog-%23F54E00.svg?style=flat-square&logo=posthog&logoColor=%23FFFFFF" height="28"/> <img src="https://img.shields.io/badge/Mixpanel-%237856FF.svg?style=flat-square&logo=mixpanel&logoColor=%23FFFFFF" height="28"/> <img src="https://skillicons.dev/icons?i=sentry" height="28"/>

</td></tr>
</table>

<details>
<summary><b>▸ stack --verbose</b></summary>

<br>

**Flutter** — Riverpod • Bloc • MVVM • ObjectBox • Drift • Hive • Retrofit • Dio

**Backend** — Go (Fiber) • Node.js (Express) • Bun • PostgreSQL (Ent) • MongoDB • NATS JetStream • gRPC • JWT

**Frontend** — React • Next.js • Tailwind CSS • Redux Toolkit • Framer Motion • Three.js

**Cloud & DevOps** — Firebase • Supabase • GCP • AWS • Docker • Kubernetes • Helm • Terraform

**Observability** — Grafana • PostHog • Sentry • Mixpanel

</details>

---

\`\`\`
📧  bharathrajn2004@gmail.com
🐙  github.com/BharathrajN2004
💼  linkedin.com/in/bharathraj-n
\`\`\`

\`\$ █  [synced: ${SYNC_TIME}]\`

</div>
HEREDOC

echo "✅ Profile generated · $(echo "$REPOS" | jq 'length') repos · ${SYNC_TIME}"
