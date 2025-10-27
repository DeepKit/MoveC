Param(
  [Parameter(Mandatory=$false)][string]$Path = 'C:\',
  [Parameter(Mandatory=$false)][int]$Port = 8787,
  [Parameter(Mandatory=$false)][int]$TopN = 200
)

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

function Normalize-Root([string]$p) {
  $rp = (Resolve-Path -LiteralPath $p).Path
  if (-not $rp.EndsWith('\')) { $rp += '\' }
  return $rp
}

$Root = Normalize-Root $Path
Write-Host "Scanning $Root ... (this can take several minutes)"

# Enumerate files
$files = Get-ChildItem -LiteralPath $Root -Recurse -File -Force -ErrorAction SilentlyContinue |
  Select-Object FullName, Length

# Index structures
$dirTotals = @{}
$fileSizes = @{}
$dirChildrenFiles = @{}
$dirChildrenDirs = @{}

function Add-ToList([hashtable]$map, [string]$key, [string]$value) {
  if (-not $map.ContainsKey($key)) { $map[$key] = New-Object System.Collections.Generic.List[string] }
  if (-not $map[$key].Contains($value)) { [void]$map[$key].Add($value) }
}
function Add-ToSet([hashtable]$map, [string]$key, [string]$value) {
  if (-not $map.ContainsKey($key)) { $map[$key] = @{} }
  $map[$key][$value] = $true
}

foreach ($f in $files) {
  $full = $f.FullName
  $len = [int64]$f.Length
  $fileSizes[$full] = $len

  $dir = Split-Path -Parent $full
  Add-ToList $dirChildrenFiles $dir $full

  $d = $dir
  while ($true) {
    if ([string]::IsNullOrEmpty($d)) { break }
    if (-not $dirTotals.ContainsKey($d)) { $dirTotals[$d] = 0L }
    $dirTotals[$d] += $len
    $parent = Split-Path -Parent $d
    if ([string]::IsNullOrEmpty($parent) -or $parent -eq $d) { break }
    Add-ToSet $dirChildrenDirs $parent $d
    $d = $parent
  }
}

# Helpers
Add-Type -AssemblyName System.Web | Out-Null
Add-Type -AssemblyName Microsoft.VisualBasic | Out-Null

function Human-Size([Int64]$bytes) {
  $units = 'B','KB','MB','GB','TB','PB'
  $i = 0; $n = [double]$bytes
  while ($n -ge 1024 -and $i -lt $units.Length - 1) { $n /= 1024; $i++ }
  return ('{0:N1} {1}' -f $n, $units[$i])
}

$RootKey = $Root.TrimEnd('\')
$TotalBytes = if ($dirTotals.ContainsKey($RootKey)) { [int64]$dirTotals[$RootKey] } else { ($files | Measure-Object -Property Length -Sum).Sum }
$Summary = @{
  root = $Root
  totalBytes = [int64]$TotalBytes
  totalHuman = (Human-Size $TotalBytes)
  generatedAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}

function Get-Children([string]$path) {
  if ([string]::IsNullOrEmpty($path)) { $path = $RootKey }
  $key = if ($path.EndsWith('\') -and $path.Length -gt 3) { $path.TrimEnd('\\') } else { $path }

  $result = New-Object System.Collections.Generic.List[object]

  if ($dirChildrenDirs.ContainsKey($key)) {
    foreach ($child in $dirChildrenDirs[$key].Keys) {
      $name = Split-Path -Leaf $child
      $value = [int64](if ($dirTotals.ContainsKey($child)) { $dirTotals[$child] } else { 0 })
      $result.Add([PSCustomObject]@{ type='dir'; name=$name; path=$child; value=$value })
    }
  }
  if ($dirChildrenFiles.ContainsKey($key)) {
    foreach ($file in $dirChildrenFiles[$key]) {
      $name = Split-Path -Leaf $file
      $value = [int64]$fileSizes[$file]
      $result.Add([PSCustomObject]@{ type='file'; name=$name; path=$file; value=$value })
    }
  }
  return ($result | Sort-Object -Property value -Descending)
}

function Get-TopFiles([string]$basePath, [int]$n) {
  if (-not $n) { $n = $TopN }
  $prefix = if ($basePath.EndsWith('\')) { $basePath } else { $basePath + '\\' }
  $list = foreach ($kv in $fileSizes.GetEnumerator()) {
    if ($kv.Key.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
      [PSCustomObject]@{ name = (Split-Path -Leaf $kv.Key); path = $kv.Key; value = [int64]$kv.Value }
    }
  }
  $list | Sort-Object value -Descending | Select-Object -First $n
}

function Path-UnderRoot([string]$p) {
  if ([string]::IsNullOrEmpty($p)) { return $false }
  try {
    $fp = [System.IO.Path]::GetFullPath($p)
    return $fp.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)
  } catch { return $false }
}

function Remove-FromIndex([string]$p) {
  # Update indexes after deletion
  if (Test-Path -LiteralPath $p -PathType Leaf) { return }
  if ($fileSizes.ContainsKey($p)) {
    $len = [int64]$fileSizes[$p]
    $parent = Split-Path -Parent $p
    # update ancestor totals
    $d = $parent
    while ($true) {
      if ([string]::IsNullOrEmpty($d)) { break }
      if ($dirTotals.ContainsKey($d)) { $dirTotals[$d] = [math]::Max(0, $dirTotals[$d] - $len) }
      $pp = Split-Path -Parent $d
      if ([string]::IsNullOrEmpty($pp) -or $pp -eq $d) { break }
      $d = $pp
    }
    # remove from children map
    if ($dirChildrenFiles.ContainsKey($parent)) { $dirChildrenFiles[$parent].Remove($p) | Out-Null }
    $fileSizes.Remove($p) | Out-Null
  } else {
    # directory: remove all files under it
    $prefix = if ($p.EndsWith('\')) { $p } else { $p + '\\' }
    $toRemove = @()
    foreach ($kv in $fileSizes.GetEnumerator()) {
      if ($kv.Key.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) { $toRemove += $kv.Key }
    }
    foreach ($f in $toRemove) { Remove-FromIndex $f }
    # unlink from parent children set
    $parent = Split-Path -Parent $p
    if ($dirChildrenDirs.ContainsKey($parent)) { $dirChildrenDirs[$parent].Remove($p) | Out-Null }
    $dirTotals.Remove($p) | Out-Null
  }
}

# HTTP server
$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Serving at $prefix"

Start-Process $prefix | Out-Null

function Add-Cors($res) {
  $res.Headers['Access-Control-Allow-Origin'] = '*'
  $res.Headers['Access-Control-Allow-Methods'] = 'GET,POST,OPTIONS'
  $res.Headers['Access-Control-Allow-Headers'] = 'Content-Type'
}

function Write-Json($res, $obj) {
  $json = $obj | ConvertTo-Json -Depth 12 -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
  $res.ContentType = 'application/json; charset=utf-8'
  Add-Cors $res
  $res.ContentLength64 = $bytes.Length
  $res.OutputStream.Write($bytes, 0, $bytes.Length)
}

function Write-Text($res, [string]$text, [string]$contentType) {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
  $res.ContentType = $contentType
  Add-Cors $res
  $res.ContentLength64 = $bytes.Length
  $res.OutputStream.Write($bytes, 0, $bytes.Length)
}

# UI HTML
$html = @'
<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>磁盘占用可视化</title>
<style>
  :root { --fg:#222; --muted:#666; --bg:#fff; --card:#fafafa; --border:#e5e5e5; }
  * { box-sizing: border-box; }
  body { margin: 16px; font-family: -apple-system, Segoe UI, Roboto, Helvetica, Arial, "Microsoft Yahei", sans-serif; color: var(--fg); background: var(--bg); }
  h1 { margin: 0 0 8px 0; font-size: 20px; }
  .meta { color: var(--muted); margin-bottom: 12px; }
  .row { display: grid; grid-template-columns: 1.4fr 1fr; gap: 16px; }
  .card { background: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 12px; }
  #treemap { width: 100%; height: 540px; }
  .label { font-size: 12px; pointer-events: none; fill: #111; text-shadow: 0 1px 0 rgba(255,255,255,.6); }
  .crumbs { display:flex; flex-wrap:wrap; gap:6px; margin: 6px 0 12px; font-size: 13px; }
  .crumbs a { color:#0860d1; cursor:pointer; text-decoration:none; }
  .crumbs .sep { color:#aaa; }
  table { width:100%; border-collapse: collapse; font-size: 13px; }
  th, td { border-bottom: 1px solid var(--border); padding: 6px 8px; text-align: left; }
  th.size, td.size { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
  td.path { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .ctx { position: fixed; background: #fff; border: 1px solid var(--border); border-radius: 6px; box-shadow: 0 8px 20px rgba(0,0,0,.12); display:none; min-width: 220px; z-index:9999; }
  .ctx .item { padding: 8px 12px; cursor: pointer; }
  .ctx .item:hover { background: #f0f6ff; }
  .muted { color: var(--muted); }
  .pill { border:1px solid var(--border); border-radius:20px; padding:2px 8px; font-size:12px; color:#555; }
</style>
</head>
<body>
  <h1>磁盘占用可视化</h1>
  <div class="meta" id="meta"></div>
  <div class="crumbs" id="crumbs"></div>
  <div class="row">
    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">
        <strong>Treemap</strong>
        <span class="pill" id="where"></span>
      </div>
      <svg id="treemap"></svg>
    </div>
    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:center;">
        <strong>当前目录（按大小降序）</strong>
        <button id="up">上一级</button>
      </div>
      <table>
        <thead>
          <tr><th style="width:60%">名称</th><th class="size" style="width:20%">大小</th><th class="size" style="width:20%">占比</th></tr>
        </thead>
        <tbody id="tbody"></tbody>
      </table>
      <div style="margin-top:12px;display:flex;justify-content:space-between;align-items:center;">
        <strong>最大文件 Top N</strong>
        <select id="topN"><option>50</option><option selected>100</option><option>200</option></select>
      </div>
      <table>
        <thead>
          <tr><th style="width:70%">路径</th><th class="size" style="width:15%">大小</th><th class="size" style="width:15%">占比</th></tr>
        </thead>
        <tbody id="top"></tbody>
      </table>
    </div>
  </div>

  <div class="ctx" id="ctx">
    <div class="item" data-act="open">打开</div>
    <div class="item" data-act="show">在资源管理器中定位</div>
    <div class="item" data-act="delete">删除到回收站</div>
    <div class="item muted" data-act="copy">复制完整路径</div>
  </div>

<script src="https://cdn.jsdelivr.net/npm/d3@7"></script>
<script>
const $ = sel => document.querySelector(sel);
let summary, curPath;
let ctxTarget = null;

function fmt(b){
  const u=['B','KB','MB','GB','TB','PB'];let i=0,n=+b;while(n>=1024&&i<u.length-1){n/=1024;i++}return n.toFixed(1)+' '+u[i];
}
function pct(x,total){return total? (x/total*100).toFixed(2)+'%':'-'}
function api(u,o){ return fetch(u,o).then(r=>{ if(!r.ok) throw new Error(r.status+' '+r.statusText); return r.json(); }); }
function esc(s){ return s.replace(/[&<>]/g, c=> ({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]) ); }

async function loadSummary(){
  summary = await api('/api/summary');
  $('#meta').textContent = `根路径: ${summary.root} · 总计: ${summary.totalHuman} · 生成于: ${summary.generatedAt}`;
  goto(summary.root);
}

function crumbs(path){
  const parts = path.replace(/\\$/,'').split('\\');
  let acc = parts[0]+"\\"; const out=[];
  for(let i=1;i<parts.length;i++){
    const name = parts[i];
    out.push(`<a data-path="${acc}">${acc}</a>`);
    acc += name + '\\';
  }
  out.push(`<span class="muted">${path}</span>`);
  $('#crumbs').innerHTML = out.join('<span class="sep">›</span>');
  $('#crumbs').querySelectorAll('a').forEach(a=>a.onclick=()=>goto(a.dataset.path));
}

async function goto(path){
  curPath = path.endsWith('\\') && path.length>3 ? path.slice(0,-1): path;
  $('#where').textContent = curPath;
  crumbs(path);
  const children = await api('/api/children?path='+encodeURIComponent(curPath));
  renderTreemap(children);
  renderTable(children);
  loadTop();
}

async function loadTop(){
  const n = +$('#topN').value; const list = await api(`/api/top?path=${encodeURIComponent(curPath)}&n=${n}`);
  const tbody = $('#top'); tbody.innerHTML='';
  for(const it of list){
    const tr = document.createElement('tr');
    tr.innerHTML = `<td class="path">${esc(it.path)}</td><td class="size">${fmt(it.value)}</td><td class="size">${pct(it.value, summary.totalBytes)}</td>`;
    tr.oncontextmenu = e=> showCtx(e, it);
    tr.ondblclick = ()=> openPath(it.path, 'open');
    tbody.appendChild(tr);
  }
}

function renderTable(items){
  const tbody = $('#tbody'); tbody.innerHTML='';
  for(const it of items){
    const tr = document.createElement('tr');
    tr.innerHTML = `<td class="path">${esc(it.name)}${it.type==='dir'?' /':''}</td><td class="size">${fmt(it.value)}</td><td class="size">${pct(it.value, summary.totalBytes)}</td>`;
    tr.oncontextmenu = e=> showCtx(e, it);
    tr.onclick = ()=> { if(it.type==='dir'){ goto(it.path); } };
    tr.ondblclick = ()=> { if(it.type==='file'){ openPath(it.path,'open'); } };
    tbody.appendChild(tr);
  }
}

function showCtx(ev, it){
  ev.preventDefault(); ctxTarget = it; const m=$('#ctx');
  m.style.display='block'; m.style.left=ev.clientX+'px'; m.style.top=ev.clientY+'px';
}
window.addEventListener('click', ()=> $('#ctx').style.display='none');
$('#ctx').addEventListener('click', async e=>{
  const act = e.target.dataset.act; if(!act||!ctxTarget) return; const p = ctxTarget.path||ctxTarget.name;
  if(act==='open'){ openPath(p,'open'); }
  if(act==='show'){ openPath(p,'show'); }
  if(act==='copy'){ navigator.clipboard?.writeText(p); }
  if(act==='delete'){
    if(confirm('确认将\n'+p+'\n删除到回收站？')){ await api('/api/delete',{method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({path:p})}); await goto(curPath); }
  }
});
$('#up').onclick = ()=>{ const idx = curPath.replace(/\\$/,'').lastIndexOf('\\'); if(idx>2){ goto(curPath.slice(0,idx)); } };
$('#topN').onchange = ()=> loadTop();

function openPath(path, action){ fetch('/api/open',{method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({path, action})}); }

function renderTreemap(items){
  const svg = d3.select('#treemap'); svg.selectAll('*').remove();
  const width = svg.node().clientWidth || 640; const height = svg.node().clientHeight || 540;
  const data = { name: curPath, children: items };
  const root = d3.hierarchy(data).sum(d=>d.value);
  d3.treemap().size([width,height]).padding(1)(root);
  const palette = d3.scaleOrdinal(d3.schemeCategory10);
  const node = svg.selectAll('g').data(root.leaves()).join('g').attr('transform', d=>`translate(${d.x0},${d.y0})`);
  node.append('rect').attr('width',d=>Math.max(0,d.x1-d.x0)).attr('height',d=>Math.max(0,d.y1-d.y0)).attr('fill',d=>palette(d.data.name))
    .on('click', (e,d)=> { if(d.data.type==='dir'){ goto(d.data.path); } })
    .on('contextmenu', (e,d)=> showCtx(e, d.data))
    .append('title').text(d=>`${d.data.name}\n${fmt(d.data.value)} (${pct(d.data.value, summary.totalBytes)})`);
  node.append('text').attr('class','label').attr('x',4).attr('y',14)
    .text(d=>d.data.name).append('tspan').attr('x',4).attr('dy',14).text(d=>fmt(d.data.value));
}

loadSummary();
</script>
</body>
</html>
'@

# Request loop
while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response

    if ($req.HttpMethod -eq 'OPTIONS') {
      Add-Cors $res; $res.StatusCode = 204; $res.OutputStream.Close(); continue
    }

    $path = $req.Url.AbsolutePath
    if ($path -eq '/') {
      Write-Text $res $html 'text/html; charset=utf-8'
    }
    elseif ($path -eq '/api/summary') {
      Write-Json $res $Summary
    }
    elseif ($path -eq '/api/children') {
      $q = [System.Web.HttpUtility]::ParseQueryString($req.Url.Query)
      $p = $q['path']
      Write-Json $res (Get-Children $p)
    }
    elseif ($path -eq '/api/top') {
      $q = [System.Web.HttpUtility]::ParseQueryString($req.Url.Query)
      $p = if ($q['path']) { $q['path'] } else { $Root }
      $n = if ($q['n']) { [int]$q['n'] } else { $TopN }
      Write-Json $res (Get-TopFiles $p $n)
    }
    elseif ($path -eq '/api/delete') {
      try {
        $sr = New-Object System.IO.StreamReader($req.InputStream, $req.ContentEncoding)
        $body = $sr.ReadToEnd()
        $sr.Close()
        $payload = if ($body) { $body | ConvertFrom-Json } else { $null }
        $p = $payload.path
        if (-not (Path-UnderRoot $p)) { $res.StatusCode = 403; Write-Json $res @{ ok=$false; error='Forbidden' }; continue }
        if (Test-Path -LiteralPath $p -PathType Container) {
          [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($p, [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs, [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin)
        }
        elseif (Test-Path -LiteralPath $p -PathType Leaf) {
          [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($p, [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs, [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin)
        } else {
          $res.StatusCode = 404; Write-Json $res @{ ok=$false; error='Not found' }; continue
        }
        Remove-FromIndex $p
        Write-Json $res @{ ok=$true }
      } catch {
        $res.StatusCode = 500; Write-Json $res @{ ok=$false; error=$_.Exception.Message }
      }
    }
    elseif ($path -eq '/api/open') {
      try {
        $sr = New-Object System.IO.StreamReader($req.InputStream, $req.ContentEncoding)
        $body = $sr.ReadToEnd(); $sr.Close()
        $payload = if ($body) { $body | ConvertFrom-Json } else { $null }
        $p = $payload.path; $act = $payload.action
        if (-not (Path-UnderRoot $p)) { $res.StatusCode = 403; Write-Json $res @{ ok=$false; error='Forbidden' }; continue }
        if ($act -eq 'show') {
          Start-Process explorer.exe "/select,`"$p`"" | Out-Null
        } else {
          if (Test-Path -LiteralPath $p -PathType Container) { Start-Process explorer.exe "`"$p`"" | Out-Null } else { Start-Process "`"$p`"" | Out-Null }
        }
        Write-Json $res @{ ok=$true }
      } catch {
        $res.StatusCode = 500; Write-Json $res @{ ok=$false; error=$_.Exception.Message }
      }
    }
    else {
      $res.StatusCode = 404; Write-Text $res 'Not Found' 'text/plain'
    }
  } catch {
    try { $ctx.Response.StatusCode = 500; Write-Text $ctx.Response 'Internal Error' 'text/plain' } catch { }
  } finally {
    try { $ctx.Response.OutputStream.Close() } catch { }
  }
}
