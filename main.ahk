#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook true

; ============================================================================
;
;   sc07B = 無変換
;   sc079 = 変換
;
; Controls:
;   Shift + 無変換      -> IME OFF（英数）
;   Shift + 変換        -> IME ON （かな）
;   無変換 + Space      -> ARROW LOCK ON/OFF
;   Esc                 -> ARROW LOCK OFF + Esc
;
; Momentary layers:
;   無変換を押している間 -> navigation / editing
;   変換を押している間   -> symbols
;
; ARROW LOCK:
;   I J K L -> Up Left Down Right
;   U O     -> Home End
;
; Important:
;   - 出力は SendEvent を使い，SendInput による keyboard hook の一時解除を避ける．
;   - 記号は Unicode 文字を直接送らず，JIS 106/109 キーボード上の
;     「実キー相当」のイベントを送る．全角/半角・予測変換はIMEに任せる．
; ============================================================================


global ArrowLock := false

sc070::BackSpace

; ----------------------------------------------------------------------------
; IME
; ----------------------------------------------------------------------------

; Shift + 無変換 -> 英数へ一方向
sc07B & Shift::SendEvent("{vk1A}")  ; VK_IME_OFF

; Shift + 変換 -> かなへ一方向
sc079 & Shift::SendEvent("{vk16}")  ; VK_IME_ON


; ----------------------------------------------------------------------------
; ARROW LOCK
; ----------------------------------------------------------------------------

sc07B & Space::ToggleArrowLock()

; Escはロック解除の非常口を兼ねる．Esc自体は ~ により通常どおり通す．
~*Esc::DisableArrowLock()


; ----------------------------------------------------------------------------
; ARROW LOCK mappings
;
; ARROW LOCK中は対象キーのdown/upを明示的に捕捉する．
; SendEvent + {Blind} により，Shift/Ctrl/Alt/Winを維持する．
; ----------------------------------------------------------------------------

ArrowLockLayer := Map(
    "i", "Up",
    "j", "Left",
    "k", "Down",
    "l", "Right",
    "u", "Home",
    "o", "End"
)

RegisterArrowLockHotkeys(ArrowLockLayer)


; ----------------------------------------------------------------------------
; 無変換 momentary layer: navigation / editing
;
; ARROW LOCK中は I/J/K/L/U/O をARROW LOCK側だけで処理する．
; ----------------------------------------------------------------------------

#HotIf !IsArrowLock()

sc07B & i::SendEvent("{Blind}{Up}")
sc07B & j::SendEvent("{Blind}{Left}")
sc07B & k::SendEvent("{Blind}{Down}")
sc07B & l::SendEvent("{Blind}{Right}")
sc07B & u::SendEvent("{Blind}{Home}")
sc07B & o::SendEvent("{Blind}{End}")

#HotIf

; Enter
sc07B & sc027::SendEvent("{Blind}{Enter}")

; Ctrl + Enter
sc07B & p::SendEvent("{Blind}^{Enter}")

; F7
sc07B & b::SendEvent("{Blind}{F7}")

; Esc
sc07B & q::ExitArrowLockAndEsc()


; ----------------------------------------------------------------------------
; 変換 momentary layer: symbols
;
; ★ 配置を変えたい場合は，基本的にこのMapだけ編集すればよい．
;
; 値は SymbolKey(実キー, Shiftが必要か)．
; 文字そのものは送らないため，現在のIME状態をAHK側で管理しない．
;
; 下のscan codeは日本語JIS 106/109配列を前提としている．
; 例:
;   SymbolKey("sc009", true)  = Shift + 8 = (
;   SymbolKey("sc00C", false) = -
;   SymbolKey("sc00C", true)  = =
; ----------------------------------------------------------------------------

SymbolLayer := Map(
    ; ── home row ────────────────────────────────────────────────────────────
    ; physical:  A   S   D   F   G     H   J   K   L   ;
    ; output:    (   )   =   _   -     +   \\  /   *   :
    "a",     SymbolKey("sc009", true),   ; (
    "s",     SymbolKey("sc00A", true),   ; )
    "d",     SymbolKey("sc00C", true),   ; =
    "f",     SymbolKey("sc073", true),   ; _
    "g",     SymbolKey("sc00C", false),  ; -  （かなIMEでは通常「ー」）
    "h",     SymbolKey("sc027", true),   ; +
    "j",     SymbolKey("sc073", false),  ; \
    "k",     SymbolKey("sc035", false),  ; /
    "l",     SymbolKey("sc028", true),   ; *
    "sc027", SymbolKey("sc028", false),  ; :

    ; ── lower row ───────────────────────────────────────────────────────────
    ; physical:  Z   X   C   V   B     N   M   ,   .   /
    ; output:    [   ]   {   }   $     <   >   '   "   ^
    "z",     SymbolKey("sc01B", false),  ; [
    "x",     SymbolKey("sc02B", false),  ; ]
    "c",     SymbolKey("sc01B", true),   ; {
    "v",     SymbolKey("sc02B", true),   ; }
    "b",     SymbolKey("sc005", true),   ; $
    "n",     SymbolKey("sc033", true),   ; <
    "m",     SymbolKey("sc034", true),   ; >
    "sc033", SymbolKey("sc008", true),   ; '
    "sc034", SymbolKey("sc003", true),   ; "
    "sc035", SymbolKey("sc00D", false),  ; ^

    ; ── upper row ───────────────────────────────────────────────────────────
    ; physical:  Q   W   E   R   T     Y   U   I   O   P
    ; output:    !   ?   &   |   `     @   #   ~   %   ^
    "q", SymbolKey("sc002", true),   ; !
    "w", SymbolKey("sc035", true),   ; ?
    "e", SymbolKey("sc007", true),   ; &
    "r", SymbolKey("sc07D", true),   ; |
    "t", SymbolKey("sc01A", true),   ; `
    "y", SymbolKey("sc01A", false),  ; @
    "u", SymbolKey("sc004", true),   ; #
    "i", SymbolKey("sc00D", true),   ; ~
    "o", SymbolKey("sc006", true),   ; %
    "p", SymbolKey("sc00D", false)   ; ^
)

RegisterSymbolLayer("sc079", SymbolLayer)


; ----------------------------------------------------------------------------
; Helpers
; ----------------------------------------------------------------------------

SymbolKey(key, shifted := false) {
    return { key: key, shifted: shifted }
}

ToggleArrowLock(*) {
    global ArrowLock, ArrowLockLayer

    ArrowLock := !ArrowLock
    SetArrowLockHotkeys(ArrowLockLayer, ArrowLock)

    ; 無変換+Spaceを長押ししても1回だけ切り替える．
    KeyWait("sc07B")
}

DisableArrowLock(*) {
    global ArrowLock, ArrowLockLayer

    if !ArrowLock
        return

    ArrowLock := false
    SetArrowLockHotkeys(ArrowLockLayer, false)
}

RegisterArrowLockHotkeys(mappings) {
    for sourceKey, targetKey in mappings {
        Hotkey("*" sourceKey, ArrowLockKeyDown.Bind(targetKey), "Off")
        Hotkey("*" sourceKey " up", ArrowLockKeyUp.Bind(targetKey), "Off")
    }
}

SetArrowLockHotkeys(mappings, enabled) {
    option := enabled ? "On" : "Off"

    ; OFFにする前に，出力側のキーが押下状態で残らないよう全て解放する．
    if !enabled {
        for sourceKey, targetKey in mappings
            SendEvent("{Blind}{" targetKey " up}")
    }

    for sourceKey, targetKey in mappings {
        Hotkey("*" sourceKey, option)
        Hotkey("*" sourceKey " up", option)
    }
}

ArrowLockKeyDown(targetKey, *) {
    ; DownRで押下状態を維持し，物理キーのrepeatイベントにも対応する．
    SendEvent("{Blind}{" targetKey " DownR}")
}

ArrowLockKeyUp(targetKey, *) {
    SendEvent("{Blind}{" targetKey " up}")
}

IsArrowLock(*) {
    global ArrowLock
    return ArrowLock
}

ExitArrowLockAndEsc(*) {
    DisableArrowLock()
    SendEvent("{Esc}")
}

RegisterSymbolLayer(prefix, symbols) {
    for key, spec in symbols
        Hotkey(prefix " & " key, SendSymbolKey.Bind(spec))
}

SendSymbolKey(spec, *) {
    ; 完成済みUnicode文字ではなく，JIS配列上の実キー相当イベントを送る．
    ; そのため全角/半角，未確定入力，予測変換などは現在のIMEに任せられる．
    if spec.shifted
        SendEvent("+{" spec.key "}")
    else
        SendEvent("{" spec.key "}")
}
