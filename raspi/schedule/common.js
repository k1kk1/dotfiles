// 定期実行・常駐の両ページで使う
const qs = new URLSearchParams(location.search);
const SYS = qs.get("system") === "1";
const esc = s => String(s ?? "").replace(/[&<>"]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c]));
const WT = {heavy:"重い", mid:"中", light:"軽い", unknown:"未計測"};
const color = r => r.mine ? "var(--c-user)" : "var(--c-sys)";
const pad = n => String(n).padStart(2, "0");
const hm = m => `${pad(Math.floor(m / 60) % 24)}:${pad(Math.floor(m % 60))}`;

function fmtDur(s){
  if (s == null) return "—";
  if (s < 1) return "1 秒未満";
  if (s < 60) return `${s.toFixed(s < 10 ? 1 : 0)} 秒`;
  if (s < 3600) return `${Math.floor(s / 60)} 分 ${Math.round(s % 60)} 秒`;
  if (s < 86400) return `${Math.floor(s / 3600)} 時間 ${Math.round(s % 3600 / 60)} 分`;
  return `${Math.floor(s / 86400)} 日 ${Math.floor(s % 86400 / 3600)} 時間`;
}
function fmtBytes(b){
  if (b == null) return "—";
  const u = ["B","KB","MB","GB"]; let i = 0;
  while (b >= 1024 && i < 3){ b /= 1024; i++; }
  return `${b.toFixed(b < 10 && i > 1 ? 1 : 0)}${u[i]}`;
}
function fmtTime(ts){
  if (!ts) return "—";
  const d = new Date(ts * 1000), now = new Date();
  const same = d.toDateString() === now.toDateString();
  return (same ? "" : `${d.getMonth() + 1}/${d.getDate()} `) + `${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function header(page, data){
  const link = (p, sys) => `${p}${sys ? "?system=1" : ""}`;
  const mine = (page === "timers" ? data.timers : data.services);
  const n = mine.filter(r => SYS || r.mine).length;
  document.getElementById("hdr").innerHTML = `
    <h1>raspi ${page === "timers" ? "定期実行" : "常駐"}</h1>
    <div class="bar-row">
      <nav class="seg" aria-label="ページ">
        <a href="${link("./", SYS)}" aria-current="${page === "timers"}">定期実行</a>
        <a href="${link("services.html", SYS)}" aria-current="${page === "services"}">常駐</a>
      </nav>
      <nav class="seg" aria-label="表示する範囲">
        <a href="${link(location.pathname, false)}" aria-current="${!SYS}">ユーザー設定</a>
        <a href="${link(location.pathname, true)}" aria-current="${SYS}">システムも表示</a>
      </nav>
      <span class="mono">${n} / ${mine.length} 件 · 更新 ${fmtTime(data.generated)}</span>
    </div>`;
}

async function load(){
  const r = await fetch("data.json", {cache: "no-store"});
  if (!r.ok) throw new Error(`data.json を読めません（${r.status}）`);
  return r.json();
}

function tooltip(lookup){
  const tip = document.getElementById("tip");
  const show = (el, x, y) => {
    const html = lookup(el.dataset.k); if (!html) return;
    tip.innerHTML = html; tip.hidden = false;
    const r = tip.getBoundingClientRect();
    tip.style.left = Math.max(8, Math.min(innerWidth - r.width - 8, x + 14)) + "px";
    tip.style.top = (y + 16 + r.height > innerHeight ? y - r.height - 10 : y + 16) + "px";
  };
  document.addEventListener("pointermove", e => {
    const el = e.target.closest("[data-k]"); if (el) show(el, e.clientX, e.clientY); else tip.hidden = true;
  });
  document.addEventListener("focusin", e => {
    const el = e.target.closest("[data-k]");
    if (el){ const r = el.getBoundingClientRect(); show(el, r.left, r.bottom); } else tip.hidden = true;
  });
  document.addEventListener("focusout", () => tip.hidden = true);
}

function boot(fn){
  load().then(fn).catch(e => {
    document.querySelector(".wrap").insertAdjacentHTML("beforeend", `<p class="empty">${esc(e.message)}</p>`);
  });
}
