#!/bin/bash
set -e

REPOS_JSON=$(gh api user/repos --paginate --jq '
  sort_by(.updatedAt) | reverse |
  .[] | {
    name,
    description,
    language,
    visibility,
    updatedAt,
    stargazerCount,
    forkCount,
    isFork,
    isArchived,
    isTemplate
  }
')

REPOS=$(echo "$REPOS_JSON" | jq -s '.')

TOTAL=$(echo "$REPOS" | jq 'length')
PUBLIC=$(echo "$REPOS" | jq '[.[] | select(.visibility == "public")] | length')
PRIVATE=$(echo "$REPOS" | jq '[.[] | select(.visibility == "private")] | length')
STARS=$(echo "$REPOS" | jq '[.[] | .stargazerCount] | add')
FORKS=$(echo "$REPOS" | jq '[.[] | .forkCount] | add')

LANG_DATA=$(echo "$REPOS" | jq -r '
  [.[] | select(.language != null) | .language] |
  group_by(.) |
  map({name: .[0], count: length}) |
  sort_by(.count) | reverse |
  .[:6] |
  .[] | "\(.name)|\(.count)"
')

LANG_TOTAL=$(echo "$LANG_DATA" | awk -F'|' '{sum += $2} END {print sum}')
if [ -z "$LANG_TOTAL" ] || [ "$LANG_TOTAL" -eq 0 ]; then
  LANG_TOTAL=1
fi

LANG_BARS=""
LANG_BLOCK=""
while IFS='|' read -r lang count; do
  pct=$((count * 100 / LANG_TOTAL))
  filled=$((pct * 20 / 100))
  empty=$((20 - filled))
  bar=$(printf '%*s' "$filled" '' | tr ' ' '█')
  space=$(printf '%*s' "$empty" '' | tr ' ' '░')
  LANG_BARS+="  ${lang}\t\t${bar}${space}  ${pct}%\n"
  LANG_BLOCK+="    ${lang}\t${pct}%\n"
done < <(echo "$LANG_DATA")

TOP_REPOS=$(echo "$REPOS" | jq -r '
  [.[] | select(.isFork == false, .isArchived == false)] |
  sort_by(.stargazerCount, .updatedAt) | reverse |
  .[:8] |
  .[] | "\(.name)|\(.description // "No description")|\(.language // "N/A")"
')

PROJECTS=""
while IFS='|' read -r name desc lang; do
  if [ -z "$desc" ] || [ "$desc" = "No description" ]; then
    desc="No description"
    display_desc="-"
  else
    display_desc="${desc:0:40}"
  fi
  if [ ${#name} -gt 14 ]; then
    name_display="${name:0:13}…"
  else
    name_display=$(printf "%-15s" "$name")
  fi
  PROJECTS+="  │ ${name_display}│ ${display_desc}\n"
done < <(echo "$TOP_REPOS")

RECENT=$(echo "$REPOS" | jq -r '.[:10] | .[] | "\(.name)|\(.updatedAt)"')

ACTIVITY=""
while IFS='|' read -r name updated; do
  rel=$(echo "$updated" | xargs -I {} date -j -f "%Y-%m-%dT%H:%M:%SZ" {} "+%s" 2>/dev/null || echo "0")
  now=$(date "+%s")
  diff=$(( (now - rel) / 3600 ))
  if [ "$diff" -lt 1 ]; then
    time_ago="just now"
  elif [ "$diff" -lt 24 ]; then
    time_ago="${diff}h ago"
  else
    days=$((diff / 24))
    time_ago="${days}d ago"
  fi
  ACTIVITY+="    ▶ Updated ${name} · ${time_ago}\n"
done < <(echo "$RECENT")

YEAR=$(date +"%Y")
MONTH=$(date +"%B")
DAY=$(date +"%d")

read -r -d '' README << EOF || true
<div align="center">

\`\`\`asciidoc
╔═══════════════════════════════════════════════════════════════╗
║              BHARATHRAJ N · DEVTERMINAL v1.0                 ║
║                   Developer Command Center                   ║
╚═══════════════════════════════════════════════════════════════╝
\`\`\`

\`\`\`
┌─[SYS INFO]─────────────────────────────────────────────────────┐
│  USER       Bharathraj N                                       │
│  ROLE       Full-Stack Developer                               │
│  SHELL      Flutter · Go · TypeScript · Dart · Swift           │
│  REPOS      ${TOTAL} total (${PUBLIC} public · ${PRIVATE} private)               │
│  IMPACT     ${STARS} ⭐ · ${FORKS} 🍴                                            │
│  TRACKER    ${MONTH} ${DAY}, ${YEAR}                                            │
└────────────────────────────────────────────────────────────────┘

┌─[FEATURED PROJECTS]────────────────────────────────────────────┐
${PROJECTS}└────────────────────────────────────────────────────────────────┘

┌─[LANGUAGE DISTRIBUTION]────────────────────────────────────────┐
${LANG_BARS}└────────────────────────────────────────────────────────────────┘

┌─[CONTRIBUTION GRAPH]──────────────────────────────────────────┐
│                                                               │
│  ![Stats](https://github-readme-stats.vercel.app/api?username=BharathrajN2004&show_icons=true&theme=dark&hide_border=true&count_private=true&bg_color=0d1117&icon_color=58a6ff&text_color=c9d1d9&title_color=58a6ff)
│  ![Languages](https://github-readme-stats.vercel.app/api/top-langs/?username=BharathrajN2004&layout=compact&theme=dark&hide_border=true&bg_color=0d1117&text_color=c9d1d9&title_color=58a6ff)
│  ![Streak](https://github-readme-streak-stats.herokuapp.com/?user=BharathrajN2004&theme=dark&hide_border=true&background=0d1117&stroke=58a6ff)
│                                                               │
└────────────────────────────────────────────────────────────────┘

┌─[RECENT ACTIVITY]─────────────────────────────────────────────┐
│  Feed auto-generated on ${MONTH} ${DAY}, ${YEAR}                          │
│                                                               │
${ACTIVITY}└────────────────────────────────────────────────────────────────┘

┌─[CONNECT]──────────────────────────────────────────────────────┐
│                                                               │
│  📧  bharathrajn2004@gmail.com                                │
│  🐙  github.com/BharathrajN2004                               │
│  💼  linkedin.com/in/bharathraj-n                             │
│                                                               │
└────────────────────────────────────────────────────────────────┘
\`\`\`

---

<p align="center">
  <i>"Building apps that matter. One commit at a time."</i>
</p>

<p align="center">
  <sub>This README auto-updates daily via GitHub Actions · Last refresh: ${MONTH} ${DAY}, ${YEAR}</sub>
</p>

</div>
EOF

echo "$README" > README.md
echo "README generated successfully"
