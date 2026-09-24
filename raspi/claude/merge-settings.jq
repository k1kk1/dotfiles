# ~/.claude/settings.json（.[0]）に raspi/claude/settings.json（.[1]）を足し込む。
# 既存の設定は消さず、許可リストは和集合、hooks は同じコマンドが無いときだけ追加する。
def union(a; b): (a // []) + ((b // []) - (a // []));

.[0] as $cur | .[1] as $add
| $cur
| .permissions.defaultMode = $add.permissions.defaultMode
| .permissions.allow = union($cur.permissions.allow; $add.permissions.allow)
| .permissions.ask   = union($cur.permissions.ask;   $add.permissions.ask)
| .permissions.deny  = union($cur.permissions.deny;  $add.permissions.deny)
| .hooks = reduce ($add.hooks | to_entries[]) as $e ($cur.hooks // {};
    (.[$e.key] // []) as $ex
    | ([$ex[].hooks[]?.command]) as $have
    | .[$e.key] = $ex + [$e.value[] | select(([.hooks[].command] - $have) | length > 0)])
