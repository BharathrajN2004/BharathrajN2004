#!/bin/bash
set -euo pipefail

# Cross-platform date → epoch
if date -d "2020-01-01" "+%s" 2>/dev/null; then
  to_epoch() { date -d "$1" "+%s" 2>/dev/null || echo "0"; }
else
  to_epoch() { date -j -f "%Y-%m-%dT%H:%M:%SZ" "$1" "+%s" 2>/dev/null || echo "0"; }
fi

# ── Fetch repos ──
REPOS=$(gh api user/repos --paginate --jq '.[]' | jq -s '
  sort_by(.updated_at) | reverse |
  [.[] | select(.fork == false and .archived == false and .is_template == false) |
  {name,description,language,visibility,updated_at,stargazers_count,forks_count}]
')

COUNT=$(echo "$REPOS" | jq 'length')

# ── Language distribution ──
LANG_RAW=$(echo "$REPOS" | jq -r '
  [.[] | select(.language != null) | .language] |
  group_by(.) | map({lang: .[0], count: length}) |
  sort_by(-.count) | .[:6] | .[] | "\(.lang)|\(.count)"
')

TOTAL_LANG=$(echo "$LANG_RAW" | awk -F'|' '{s+=$2} END{print s+0}')
[[ "$TOTAL_LANG" -eq 0 ]] && TOTAL_LANG=1

# ── Generate language bars SVG ──
Y=26
BARS=""

get_color() {
  case "$1" in
    Dart) echo "#00B4AB" ;; Go) echo "#00ADD8" ;;
    TypeScript) echo "#3178C6" ;; JavaScript) echo "#F7DF1E" ;;
    Swift) echo "#F05138" ;; Python) echo "#3776AB" ;;
    "C++") echo "#00599C" ;; EJS) echo "#B52E31" ;;
    CSS) echo "#663399" ;; *) echo "#8b949e" ;;
  esac
}

i=0
while IFS='|' read -r lang count; do
  pct=$(( count * 100 / TOTAL_LANG ))
  w=$(( count * 380 / TOTAL_LANG ))
  [[ "$w" -lt 4 ]] && w=4
  color=$(get_color "$lang")
  BARS+=$'\n'"    <text x=\"10\" y=\"$((Y+14))\" font-family=\"Courier New,monospace\" font-size=\"11\" fill=\"#c9d1d9\">$lang</text>"
  BARS+=$'\n'"    <rect x=\"120\" y=\"$((Y+3))\" width=\"$w\" height=\"14\" rx=\"3\" fill=\"$color\" opacity=\"0.9\">"
  BARS+=$'\n'"      <animate attributeName=\"width\" from=\"0\" to=\"$w\" dur=\"1s\" begin=\"$((i * 15 / 10)).$((i * 15 % 10))s\" fill=\"freeze\"/>"
  BARS+=$'\n'"    </rect>"
  BARS+=$'\n'"    <text x=\"$((120 + w + 8))\" y=\"$((Y+14))\" font-family=\"Courier New,monospace\" font-size=\"9\" fill=\"#8b949e\">${pct}%</text>"
  Y=$((Y + 24))
  i=$((i + 1))
done < <(echo "$LANG_RAW")

HEADER_LINE='<text x="10" y="16" font-family="Courier New,monospace" font-size="9" fill="#58a6ff">┌─ LANGUAGE DISTRIBUTION ───────────────────────────────────┐</text>'
FOOTER_LINE="<text x=\"10\" y=\"$((Y+12))\" font-family=\"Courier New,monospace\" font-size=\"9\" fill=\"#58a6ff\">└──────────────────────────────────────────────────────────┘</text>"
SVG_H=$((Y + 24))

cat > assets/lang-bars.svg << SVGEOF
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 $SVG_H" width="500" height="$SVG_H">
  <rect width="500" height="$SVG_H" fill="#0d1117" rx="6"/>
  $HEADER_LINE
  $BARS
  $FOOTER_LINE
</svg>
SVGEOF

# ── Ticker ──
TICKER=$(echo "$REPOS" | jq -r '.[:10] | .[] | "\(.name)|\(.updated_at)"' | while IFS='|' read -r name updated; do
  ts=$(to_epoch "$updated")
  now=$(date "+%s")
  diff=$(( (now - ts) / 3600 ))
  if [ "$diff" -lt 1 ]; then ago="just now"
  elif [ "$diff" -lt 24 ]; then ago="${diff}h ago"
  else ago="$((diff/24))d ago"; fi
  echo -n "▶ $name · $ago  │  "
done | sed 's/  │  $//')

# ── Market board ──
MARKET=$(echo "$REPOS" | jq -r '
  sort_by(-.stargazers_count, .updated_at) |
  .[:8] | .[] |
  "\(.name)|\(.language // "N/A")|\(.stargazers_count)|\(.updated_at)"
' | while IFS='|' read -r name lang stars updated; do
  sym="\$"$(echo "$name" | head -c 5 | tr '[:lower:]' '[:upper:]')
  ts=$(to_epoch "$updated")
  days=$(( ( $(date "+%s") - ts ) / 86400 ))
  if [ "$days" -lt 30 ]; then stat="🟢"
  elif [ "$days" -lt 180 ]; then stat="🔵"
  else stat="🟣"; fi
  printf "%-7s │ %-20s │ %-10s │ ★ %-3s │ ▸ 0  │ %s\n" "$sym" "${name:0:20}" "$lang" "$stars" "$stat"
done)

# ── Kanban ──
ACTIVE=""; STABLE=""; SHIPPED=""
while IFS='|' read -r name lang updated; do
  ts=$(to_epoch "$updated")
  days=$(( ( $(date "+%s") - ts ) / 86400 ))
  n=$(printf "%-15s" "${name:0:14}")
  l=$(printf "%-12s" "${lang:-N/A}")
  if [ "$days" -eq 0 ]; then dstr="today   "
  elif [ "$days" -eq 1 ]; then dstr="1d ago  "
  else dstr="${days}d ago  "; fi
  card="│ ${n}│ ${l}│ ${dstr}│"
  if [ "$days" -lt 30 ]; then
    ACTIVE+="${card}\n"
  elif [ "$days" -lt 180 ]; then
    STABLE+="${card}\n"
  else
    SHIPPED+="${card}\n"
  fi
done < <(echo "$REPOS" | jq -r '.[] | "\(.name)|\(.language // "N/A")|\(.updated_at)"')

# ── Generate README ──
SYNC_TIME=$(date -u "+%d %b %Y %H:%M UTC")

cat > README.md << 'HEREDOC_HEADER'
<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/header.svg">
  <img src="assets/header.svg" width="580" alt="Bharathraj N">
</picture>

<br>

<marquee width="88%" direction="left" scrollamount="3" scrolldelay="30">
HEREDOC_HEADER

echo "  ${TICKER}" >> README.md

cat >> README.md << 'HEREDOC_BODY'

</marquee>

<br>

```
🤖  Full-stack. Flutter · Go · TypeScript · Swift.
    I build things that ship.
```

---

<details open>
<summary><b>▸ $ code-rules</b></summary>

```
Architecture that bends to the problem, not the other way.
```

</details>

<details>
<summary><b>▸ $ arch-patterns</b></summary>

```
Boundaries where change lives. Otherwise, none.
```

</details>

<details>
<summary><b>▸ $ sys-design</b></summary>

```
Degrade. Never die. Visibility before velocity.
```

</details>

<details>
<summary><b>▸ $ scrapuncle --work</b></summary>

```
┌────────────────┬─────────────────┬──────────────────┐
│  CUSTOMER APP  │  OPERATIONS     │  CORE SERVICES   │
│  Flutter/Dart  │  Flutter/Dart   │  Go / TypeScript │
│  Consumer      │  Internal ops   │  Backend infra   │
└────────────────┴─────────────────┴──────────────────┘

▸ Full-stack ownership. Mobile to infra.
▸ Private work — architecture gists only.
```

</details>

<details>
<summary><b>▸ $ portfolio --show</b></summary>

<br>

#### 📊 MARKET

```
SYM    │ PROJECT              │ TECH        │ PRICE │ CHG  │ STAT
───────┼──────────────────────┼─────────────┼───────┼──────┼─────
HEREDOC_BODY

echo "${MARKET}" >> README.md

cat >> README.md << 'HEREDOC_KANBAN'
```

#### 📋 KANBAN

```
HEREDOC_KANBAN

printf "%-44s %-44s %-44s\n" "🟢 ACTIVE" "🔵 STABLE" "🟣 SHIPPED" >> README.md
printf "%-44s %-44s %-44s\n" "" "" "" >> README.md

# Interleave ACTIVE/STABLE/SHIPPED
IFS=$'\n' read -rd '' -a active_lines  <<< "$(echo -e "$ACTIVE")"  || true
IFS=$'\n' read -rd '' -a stable_lines  <<< "$(echo -e "$STABLE")"  || true
IFS=$'\n' read -rd '' -a shipped_lines <<< "$(echo -e "$SHIPPED")" || true

max_len=${#active_lines[@]}
[[ ${#stable_lines[@]} -gt $max_len ]] && max_len=${#stable_lines[@]}
[[ ${#shipped_lines[@]} -gt $max_len ]] && max_len=${#shipped_lines[@]}
[[ $max_len -eq 0 ]] && max_len=1

for ((idx=0; idx<max_len; idx++)); do
  a="${active_lines[$idx]:-                                              }"
  s="${stable_lines[$idx]:-                                              }"
  h="${shipped_lines[$idx]:-                                             }"
  printf "%-44s %-44s %-44s\n" "$a" "$s" "$h" >> README.md
done

cat >> README.md << 'HEREDOC_FOOTER'
```

</details>

<details>
<summary><b>▸ $ blog --queue</b></summary>

```
📝  Clean Arch in Flutter
    ✅ domain/ isolation     ❌ boilerplate cost

📝  Go Microservices
    ✅ DI by hand            ❌ framework magic

📝  Firebase: The Bait & Switch
    ✅ week 0 prototype      ❌ week 52 lock-in

📝  Flutter Perf at Scale
    ✅ lazy everything       ❌ monolith widget tree

📍  Publishing soon — Substack / blog site
```

</details>

---

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/lang-bars.svg">
  <img src="assets/lang-bars.svg" width="500" alt="Language Distribution">
</picture>

<br>

![Stats](https://github-readme-stats.vercel.app/api?username=BharathrajN2004&show_icons=true&theme=dark&hide_border=true&bg_color=0d1117&icon_color=58a6ff&text_color=c9d1d9&title_color=58a6ff&hide=stars\&hide_rank=true\&include_all_commits=true\&count_private=true)

<br>

![Activity](https://github-readme-activity-graph.vercel.app/graph?username=BharathrajN2004&theme=react-dark&bg_color=0d1117&color=58a6ff&line=58a6ff&point=c9d1d9&hide_border=true&area=true)

---

```
┌─ CONNECT ──────────────────────────────────────────┐
│                                                     │
│      📧  bharathrajn2004@gmail.com                  │
│      🐙  github.com/BharathrajN2004                 │
│      💼  linkedin.com/in/bharathraj-n               │
│                                                     │
└─────────────────────────────────────────────────────┘
```
HEREDOC_FOOTER

echo "" >> README.md
echo '```' >> README.md
echo "\$ █  [synced: ${SYNC_TIME}]" >> README.md
echo '```' >> README.md
echo "" >> README.md
echo '</div>' >> README.md

echo "✅ Profile generated · ${COUNT} repos · ${SYNC_TIME}"
