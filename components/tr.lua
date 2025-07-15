local AddonName, SAO = ...
local Module = "tr"

--[[
    Translations based on game client constants
]]

-- Write a formatted 'number of stacks' text
-- SAO:NbStacks(4) -- "4 Stacks"
-- SAO:NbStacks(7,9) -- "7-9 Stacks"
function SAO:NbStacks(minStacks, maxStacks)
    if maxStacks then
        return string.format(CALENDAR_TOOLTIP_DATE_RANGE, tostring(minStacks), string.format(STACKS, maxStacks));
    end
    return string.format(STACKS, minStacks);
end

-- Something was updated recently
function SAO:RecentlyUpdated()
    return WrapTextInColor(KBASE_RECENTLY_UPDATED, GREEN_FONT_COLOR);
end

-- Execute text to tell enemy HP is below a certain threshold
function SAO:ExecuteBelow(threshold)
    return string.format(string.format(HEALTH_COST_PCT, "<%s%"), threshold);
end

-- Text to limit something to one kind of items (class, role, spec...)
function SAO:OnlyFor(item)
    return string.format(RACE_CLASS_ONLY, item);
end

--[[
    Explicit translations
]]

local function tr(translations)
    local locale = GetLocale();
    return translations[locale] or translations[locale:sub(1,2)] or translations["en"];
end

-- Get the "Heating Up" localized buff name
function SAO:translateHeatingUp()
    local heatingUpTranslations = {
        ["en"] = "Heating Up",
        ["de"] = "Aufwärmen",
        ["fr"] = "Réchauffement",
        ["es"] = "Calentamiento",
        ["ru"] = "Разогрев",
        ["it"] = "Riscaldamento",
        ["pt"] = "Aquecendo",
        ["ko"] = "열기",
        ["zh"] = "热力迸发",
        ["zhTW"] = "熱力迸發", -- Translated, not picked up from a game client
    };
    return tr(heatingUpTranslations);
end

-- Get the "Debuff" localized text
function SAO:translateDebuff()
    local debuffTranslations = {
        ["en"] = "Debuff",
        ["de"] = "Schwächung",
        ["fr"] = "Affaiblissement",
        ["es"] = "Perjuicio",
        ["ru"] = "Отрицательный эффект",
        ["it"] = "Penalità",
        ["pt"] = "Penalidade",
        ["ko"] = "약화",
        ["zh"] = "负面",
        ["zhTW"] = "減益",
    };
    return tr(debuffTranslations);
end

-- Get the "when castable" localized text
function SAO:whenCastable()
    local whenCastableTranslations = {
        ["en"] = "when castable",
        ["de"] = "wenn zauberbar",
        ["fr"] = "dès que lançable",
        ["es"] = "cuando se pueda lanzar",
        ["ru"] = "когда можно применить",
        ["it"] = "quando lanciabile",
        ["pt"] = "quando lançável",
        ["ko"] = "시전 가능할 때",
        ["zh"] = "可施放时",
        ["zhTW"] = "可施放時",
    };
    return tr(whenCastableTranslations);
end

-- Translate "Migrated options from pre-{version} to {version}"
function SAO:migratedOptions(version)
    local migratedTranslations = {
        ["en"] = "Migrated options from pre-%s to %s",
        ["de"] = "Optionen von vor %s auf %s migriert",
        ["fr"] = "Options migrées de la version pré-%s vers %s",
        ["es"] = "Opciones migradas de la versión previa a %s a %s",
        ["ru"] = "Параметры перенесены с версии до %s на %s",
        ["it"] = "Opzioni migrate da pre-%s a %s",
        ["pt"] = "Opções migradas de pré-%s para %s",
        ["ko"] = "%s 이전 버전에서 %s로 옵션이 마이그레이션되었습니다",
        ["zh"] = "从%s之前的版本迁移到%s的选项",
        ["zhTW"] = "從%s之前的版本遷移到%s的選項",
    };
    return string.format(tr(migratedTranslations), version, version);
end

-- Get the "Responsive Mode" localized text
function SAO:responsiveMode()
    local responsiveTranslations = {
        ["en"] = "Responsive mode (decreases performance)",
        ["de"] = "Responsiver Modus (verringert die Leistung)",
        ["fr"] = "Mode réactif (diminue les performances)",
        ["es"] = "Modo de respuesta (disminuye el rendimiento)",
        ["ru"] = "Отзывчивый режим (снижает производительность)",
        ["it"] = "Modalità reattiva (riduce le prestazioni)",
        ["pt"] = "Modo responsivo (diminui o desempenho)",
        ["ko"] = "반응형 모드(성능 저하)",
        ["zh"] = "响应模式（降低性能）",
        ["zhTW"] = "響應模式（降低性能）",
    };
    return tr(responsiveTranslations);
end

-- Get the "Unsupported Class" localized text
function SAO:unsupportedClass()
    local unsupportedClassTranslations = {
        ["en"] = "Unsupported Class",
        ["de"] = "Nicht unterstützte Klasse",
        ["fr"] = "Classe non prise en charge",
        ["es"] = "Clase no compatible",
        ["ru"] = "Неподдерживаемый класс",
        ["it"] = "Classe non supportata",
        ["pt"] = "Classe sem suporte",
        ["ko"] = "지원되지 않는 클래스",
        ["zh"] = "不支持的类",
        ["zhTW"] = "不支援的類別",
    };
    return tr(unsupportedClassTranslations);
end

-- Get the "Disabled class" localized text
function SAO:disabledClass()
    local unsupportedClassTranslations = {
        ["en"] = "Disabled class %s while development is in progress.\nPlease come back soon :)",
        ["de"] = "Deaktivierte Klasse %s, während der Entwicklungsphase.\nBitte kommen Sie bald wieder :)",
        ["fr"] = "Classe %s désactivée pendant que le développement est en cours.\nRevenez bientôt :)",
        ["es"] = "Clase %s desactivada mientras el desarrollo está en curso.\nVuelva pronto :)",
        ["ru"] = "Класс %s отключен на время разработки.\nПожалуйста, вернитесь в ближайшее время :)",
        ["it"] = "La classe %s è stata disabilitata mentre lo sviluppo è in corso.\nSi prega di tornare presto :)",
        ["pt"] = "Classe %s desativada enquanto o desenvolvimento está em andamento.\nPor favor, volte em breve :)",
        ["ko"] = "개발이 진행되는 동안 %s 클래스를 사용할 수 없습니다.\n곧 다시 돌아와주세요 :)",
        ["zh"] = "开发过程中禁用了%s类。请尽快回来 :)",
        ["zhTW"] = "開發過程中禁用了%s類。請儘快回來 :)",
    };
    return tr(unsupportedClassTranslations);
end

-- Get the "because of {reason}" localized text
function SAO:becauseOf(reason)
    local becauseOfTranslations = {
        ["en"] = "because of %s",
        ["de"] = "wegen %s",
        ["fr"] = "à cause de %s",
        ["es"] = "por %s",
        ["ru"] = "из-за %s",
        ["it"] = "a causa di %s",
        ["pt"] = "por causa de %s",
        ["ko"] = "%s 때문에",
        ["zh"] = "因为 %s",
        ["zhTW"] = "因為 %s",
    };
    return string.format(tr(becauseOfTranslations), reason);
end

-- Get the "Open {x}" localized text
function SAO:openIt(x)
    local openItTranslations = {
        ["en"] = "Open %s",
        ["de"] = "Öffnen %s",
        ["fr"] = "Ouvrir %s",
        ["es"] = "Abrir %s",
        ["ru"] = "Открыть %s",
        ["it"] = "Aprire %s",
        ["pt"] = "Abrir %s",
        ["ko"] = "열기 %s",
        ["zh"] = "打开 %s",
        ["zhTW"] = "打開 %s",
    };
    return string.format(tr(openItTranslations), x);
end

-- Get the "Disabled when {addon} is installed" localized text
function SAO:disableWhenInstalled(addon)
    local disableWhenInstalledTranslations = {
        ["en"] = "Disable when %s is installed",
        ["de"] = "Deaktivieren, wenn %s installiert ist",
        ["fr"] = "Désactiver lorsque %s est installé",
        ["es"] = "Desactivar cuando %s está instalado",
        ["ru"] = "Отключить при установке %s",
        ["it"] = "Disattivare quando è installato %s",
        ["pt"] = "Desativar quando %s estiver instalado",
        ["ko"] = "%s가 설치되어 있으면 사용 안 함",
        ["zh"] = "安装 %s 时禁用",
        ["zhTW"] = "安裝 %s 時禁用",
    };
    return string.format(tr(disableWhenInstalledTranslations), addon);
end

-- Get the "Optimized for {addonBuild}" localized text
function SAO:optimizedFor(addonBuild)
    local optimizedForTranslations = {
        ["en"] = "Optimized for %s",
        ["de"] = "Optimiert für %s",
        ["fr"] = "Optimisé pour %s",
        ["es"] = "Optimizado para %s",
        ["ru"] = "Оптимизировано для %s",
        ["it"] = "Ottimizzato per %s",
        ["pt"] = "Otimizado para %s",
        ["ko"] = "%s에 최적화됨",
        ["zh"] = "为 %s 优化",
        ["zhTW"] = "為 %s 優化",
    };
    return string.format(tr(optimizedForTranslations), addonBuild);
end

-- Get the "Universal Build" localized text
function SAO:universalBuild()
    local universalBuildTranslations = {
        ["en"] = "Universal Build",
        ["de"] = "Universelle Version",
        ["fr"] = "Version universelle",
        ["es"] = "Versión universal",
        ["ru"] = "Универсальная сборка",
        ["it"] = "Versione universale",
        ["pt"] = "Versão universal",
        ["ko"] = "범용 빌드",
        ["zh"] = "通用版本",
        ["zhTW"] = "通用版本",
    };
    return tr(universalBuildTranslations);
end

-- Translate the following text:
-- "You have installed the optimized build for {addonBuild} but the expected build is {expectedBuild}. Some effects may be missing for your class."
function SAO:compatibilityWarning(addonBuild, expectedBuild)
    local compatibilityWarningTranslations = {
        ["en"] = "You have installed the optimized build for %s but the expected build is %s. Some effects may be missing for your class.",
        ["de"] = "Sie haben die optimierte Version für %s installiert, aber die erwartete Version ist %s. Einige Effekte könnten für Ihre Klasse fehlen.",
        ["fr"] = "Vous avez installé la version optimisée pour %s mais la version attendue est %s. Certains effets peuvent manquer pour votre classe.",
        ["es"] = "Has instalado la versión optimizada para %s pero la versión esperada es %s. Algunos efectos pueden faltar para tu clase.",
        ["ru"] = "Вы установили оптимизированную сборку для %s, но ожидаемая сборка - %s. Некоторые эффекты могут отсутствовать для вашего класса.",
        ["it"] = "Hai installato la versione ottimizzata per %s ma la versione attesa è %s. Alcuni effetti potrebbero mancare per la tua classe.",
        ["pt"] = "Você instalou a versão otimizada para %s, mas a versão esperada é %s. Alguns efeitos podem estar faltando para sua classe.",
        ["ko"] = "%s에 최적화된 빌드를 설치했지만 예상 빌드는 %s입니다. 일부 효과가 클래스에 없을 수 있습니다.",
        ["zh"] = "您已安装了针对 %s 的优化版本，但预期版本为 %s。您的职业可能缺少某些效果。",
        ["zhTW"] = "您已安裝針對 %s 的最佳化版本，但預期版本為 %s。您的職業可能缺少某些效果。",
    };
    return string.format(tr(compatibilityWarningTranslations), addonBuild, expectedBuild);
end

-- Translate "Write debug to the chatbox (in English)"
function SAO:optionDebugToChatbox()
    local optionDebugToChatboxTranslations = {
        ["en"] = "Write debug to the chatbox",
        ["de"] = "Debug in den Chat schreiben (auf Englisch)",
        ["fr"] = "Écrire le débogage dans le tchat (en anglais)",
        ["es"] = "Escribir depuración en el chat (en inglés)",
        ["ru"] = "Выводить отладочную в чат (на английском)",
        ["it"] = "Scrivi il debug nella chat (in inglese)",
        ["pt"] = "Escrever depuração no chat (em inglês)",
        ["ko"] = "디버그를 채팅창에 작성하기 (영어로)",
        ["zh"] = "将调试信息写入聊天框（英文）",
        ["zhTW"] = "將除錯資訊寫入聊天框（英文）",
    };
    return tr(optionDebugToChatboxTranslations);
end

-- Translate "unknown spell" (lowercase in most languages)
function SAO:unknownSpell()
    local unknownSpellTranslations = {
        ["en"] = "unknown spell",
        ["de"] = "unbekannter Zauber", -- German nouns are always capitalized
        ["fr"] = "sort inconnu",
        ["es"] = "hechizo desconocido",
        ["ru"] = "неизвестное заклинание",
        ["it"] = "incantesimo sconosciuto",
        ["pt"] = "feitiço desconhecido",
        ["ko"] = "알 수 없는 주문",
        ["zh"] = "未知法术",
        ["zhTW"] = "未知法術",
    };
    return tr(unknownSpellTranslations);
end

-- Translate the following text:
-- "Unsupported SHOW event{details}. Please report it to the {AddonName} Discord, GitHub or CurseForge. (you can disable this message in options: /sao)"
function SAO:unsupportedShowEvent(details)
    local unsupportedShowEventTranslations = {
        ["en"] = "Unsupported SHOW event%s. Please report it to the %s Discord, GitHub or CurseForge. (you can disable this message in options: /sao)",
        ["de"] = "Nicht unterstütztes SHOW-Ereignis%s. Bitte melden Sie es im %s Discord, GitHub oder CurseForge. (Sie können diese Nachricht in den Optionen deaktivieren: /sao)",
        ["fr"] = "Événement SHOW non pris en charge%s. Veuillez le signaler sur le Discord, GitHub ou CurseForge de %s. (vous pouvez désactiver ce message dans les options : /sao)",
        ["es"] = "Evento SHOW no compatible%s. Por favor, repórtalo en el Discord, GitHub o CurseForge de %s. (puedes desactivar este mensaje en las opciones: /sao)",
        ["ru"] = "Неподдерживаемое событие SHOW%s. Пожалуйста, сообщите об этом в Discord, GitHub или CurseForge %s. (вы можете отключить это сообщение в настройках: /sao)",
        ["it"] = "Evento SHOW non supportato%s. Si prega di segnalarlo su Discord, GitHub o CurseForge di %s. (è possibile disattivare questo messaggio nelle opzioni: /sao)",
        ["pt"] = "Evento SHOW não suportado%s. Por favor, relate-o no Discord, GitHub ou CurseForge do %s. (você pode desativar esta mensagem nas opções: /sao)",
        ["ko"] = "지원되지 않는 SHOW 이벤트입니다%s. %s의 Discord, GitHub 또는 CurseForge에 보고해 주세요. (옵션에서 이 메시지를 비활성화할 수 있습니다: /sao)",
        ["zh"] = "不支持的 SHOW 事件%s。请在 %s 的 Discord、GitHub 或 CurseForge 上报告。(您可以在选项中禁用此消息：/sao)",
        ["zhTW"] = "不支援的 SHOW 事件%s。請在 %s 的 Discord、GitHub 或 CurseForge 上報告。(您可以在選項中停用此訊息：/sao)",
    };
    return string.format(tr(unsupportedShowEventTranslations), tostring(details), AddonName);
end

-- Translate "Report unsupported effects to Chatbox"
function SAO:reportUnsupportedOverlays()
    local reportUnsupportedOverlaysTranslations = {
        ["en"] = "Report unsupported effects to Chatbox",
        ["de"] = "Nicht unterstützte Effekte im Chatfenster melden",
        ["fr"] = "Signaler les effets non pris en charge dans le tchat",
        ["es"] = "Informar efectos no compatibles en el chat",
        ["ru"] = "Сообщить о неподдерживаемых эффектах в чате",
        ["it"] = "Segnala effetti non supportati nella chat",
        ["pt"] = "Relatar efeitos não suportados no chat",
        ["ko"] = "지원되지 않는 효과를 채팅창에 보고하기",
        ["zh"] = "在聊天框中报告不支持的效果",
        ["zhTW"] = "在聊天框中報告不支援的效果",
    };
    return tr(reportUnsupportedOverlaysTranslations);
end

-- Translate "{AddonName} spell alerts may conflict with the ones from the game.\n\nDo you want to disable the game's spell alerts?",
function SAO:spellAlertConflicts()
    local spellAlertConflictsTranslations = {
        ["en"] = "%s spell alerts may conflict with the ones from the game.\n\nDo you want to disable the game's spell alerts?",
        ["de"] = "%s Zauberwarnungen können mit denen des Spiels in Konflikt stehen.\n\nMöchten Sie die Zauberwarnungen des Spiels deaktivieren?",
        ["fr"] = "Les alertes de sort de %s peuvent entrer en conflit avec celles du jeu.\n\nVoulez-vous désactiver les alertes de sort du jeu ?",
        ["es"] = "Las alertas de hechizo de %s pueden entrar en conflicto con las del juego.\n\n¿Deseas desactivar las alertas de hechizo del juego?",
        ["ru"] = "Оповещения о заклинаниях %s могут конфликтовать с игровыми оповещениями.\n\nВы хотите отключить игровые оповещения о заклинаниях?",
        ["it"] = "%s gli avvisi sugli incantesimi potrebbero entrare in conflitto con quelli del gioco.\n\nVuoi disattivare gli avvisi sugli incantesimi del gioco?",
        ["pt"] = "Os alertas de feitiço do %s podem entrar em conflito com os do jogo.\n\nVocê deseja desativar os alertas de feitiço do jogo?",
        ["ko"] = "%s 주문 경고가 게임의 주문 경고와 충돌할 수 있습니다.\n\n게임의 주문 경고를 비활성화하시겠습니까?",
        ["zh"] = "%s 的法术警报可能与游戏中的法术警报冲突。\n\n您想禁用游戏的法术警报吗？",
        ["zhTW"] = "%s 的法術警報可能與遊戲中的法術警報衝突。\n\n您想停用遊戲的法術警報嗎？",
    };
    return string.format(tr(spellAlertConflictsTranslations), AddonName);
end

-- Translate "You previously chose to disable the game's spell alerts, and now they are back.\n\nDo you want to disable them again?"
function SAO:spellAlertConflictsAgain()
    local spellAlertConflictsAgainTranslations = {
        ["en"] = "You previously chose to disable the game's spell alerts, and now they are back.\n\nDo you want to disable them again?",
        ["de"] = "Sie haben sich zuvor entschieden, die Zauberwarnungen des Spiels zu deaktivieren, und jetzt sind sie wieder da.\n\nMöchten Sie sie erneut deaktivieren?",
        ["fr"] = "Vous avez précédemment choisi de désactiver les alertes de sort du jeu, et maintenant elles sont de retour.\n\nVoulez-vous les désactiver à nouveau ?",
        ["es"] = "Anteriormente elegiste desactivar las alertas de hechizo del juego, y ahora han vuelto.\n\n¿Deseas desactivarlas de nuevo?",
        ["ru"] = "Вы ранее выбрали отключить игровые оповещения о заклинаниях, и теперь они снова появились.\n\nВы хотите отключить их снова?",
        ["it"] = "Hai precedentemente scelto di disattivare gli avvisi sugli incantesimi del gioco, e ora sono tornati.\n\nVuoi disattivarli di nuovo?",
        ["pt"] = "Você escolheu desativar os alertas de feitiço do jogo, e agora eles voltaram.\n\nVocê deseja desativá-los novamente?",
        ["ko"] = "이전에 게임의 주문 경고를 비활성화하기로 선택했으며 이제 다시 나타났습니다.\n\n다시 비활성화하시겠습니까?",
        ["zh"] = "您之前选择禁用游戏的法术警报，现在它们又回来了。\n\n您想再次禁用它们吗？",
        ["zhTW"] = "您之前選擇停用遊戲的法術警報，現在它們又回來了。\n\n您想再次停用它們嗎？",
    };
    return tr(spellAlertConflictsAgainTranslations);
end

-- Translate "You chose to disable the game's spell alerts."
function SAO:gameSpellAlertsDisabled()
    local gameSpellAlertsDisabledTranslations = {
        ["en"] = "You chose to disable the game's spell alerts.",
        ["de"] = "Sie haben sich entschieden, die Zauberwarnungen des Spiels zu deaktivieren.",
        ["fr"] = "Vous avez choisi de désactiver les alertes de sort du jeu.",
        ["es"] = "Has elegido desactivar las alertas de hechizo del juego.",
        ["ru"] = "Вы выбрали отключить игровые оповещения о заклинаниях.",
        ["it"] = "Hai scelto di disattivare gli avvisi sugli incantesimi del gioco.",
        ["pt"] = "Você escolheu desativar os alertas de feitiço do jogo.",
        ["ko"] = "게임의 주문 경고를 비활성화하기로 선택했습니다.",
        ["zh"] = "您选择禁用游戏的法术警报。",
        ["zhTW"] = "您選擇停用遊戲的法術警報。",
    };
    return tr(gameSpellAlertsDisabledTranslations);
end

-- Translate "You chose to leave the game's spell alerts as they are."
function SAO:gameSpellAlertsLeftAsIs()
    local gameSpellAlertsLeftAsIsTranslations = {
        ["en"] = "You chose to leave the game's spell alerts as they are.",
        ["de"] = "Sie haben sich entschieden, die Zauberwarnungen des Spiels so zu belassen, wie sie sind.",
        ["fr"] = "Vous avez choisi de laisser les alertes de sort du jeu telles qu'elles sont.",
        ["es"] = "Has elegido dejar las alertas de hechizo del juego como están.",
        ["ru"] = "Вы выбрали оставить игровые оповещения о заклинаниях как есть.",
        ["it"] = "Hai scelto di lasciare gli avvisi sugli incantesimi del gioco così come sono.",
        ["pt"] = "Você escolheu deixar os alertas de feitiço do jogo como estão.",
        ["ko"] = "게임의 주문 경고를 그대로 두기로 선택했습니다.",
        ["zh"] = "您选择保持游戏的法术警报不变。",
        ["zhTW"] = "您選擇保持遊戲的法術警報不變。",
    };
    return tr(gameSpellAlertsLeftAsIsTranslations);
end

-- Translate "Remember that you can change this later in the game's interface options, under {optionSequence}"
function SAO:gameSpellAlertsChangeLater(optionSequence)
    local gameSpellAlertsChangeLaterTranslations = {
        ["en"] = "Remember that you can change this later in the game's interface options, under %s",
        ["de"] = "Denken Sie daran, dass Sie dies später in den Schnittstellenoptionen des Spiels unter %s ändern können.",
        ["fr"] = "N'oubliez pas que vous pouvez modifier cela plus tard dans les options d'interface du jeu, sous %s",
        ["es"] = "Recuerda que puedes cambiar esto más tarde en las opciones de interfaz del juego, bajo %s",
        ["ru"] = "Помните, что вы можете изменить это позже в параметрах интерфейса игры, в разделе %s",
        ["it"] = "Ricorda che puoi modificare questo in seguito nelle opzioni dell'interfaccia di gioco, sotto %s",
        ["pt"] = "Lembre-se de que você pode mudar isso mais tarde nas opções de interface do jogo, em %s",
        ["ko"] = "나중에 %s에서 게임의 인터페이스 옵션에서 이를 변경할 수 있음을 기억하십시오.",
        ["zh"] = "请记住，您可以稍后在游戏的界面选项中更改此设置，位于 %s 下。",
        ["zhTW"] = "請記住，您可以稍後在遊戲的介面選項中更改此設置，位於 %s 下。",
    };
    return string.format(tr(gameSpellAlertsChangeLaterTranslations), optionSequence);
end

-- Translate "Detect conflicts with the game's spell alerts"
function SAO:askToDisableGameAlerts()
    local askToDisableGameAlertsTranslations = {
        ["en"] = "Detect conflicts with the game's spell alerts",
        ["de"] = "Konflikte mit den Zauberwarnungen des Spiels erkennen",
        ["fr"] = "Détecter les conflits avec les alertes de sort du jeu",
        ["es"] = "Detectar conflictos con las alertas de hechizo del juego",
        ["ru"] = "Обнаружить конфликты с игровыми оповещениями о заклинаниях",
        ["it"] = "Rileva conflitti con gli avvisi sugli incantesimi del gioco",
        ["pt"] = "Detectar conflitos com os alertas de feitiço do jogo",
        ["ko"] = "게임의 주문 경고와의 충돌 감지",
        ["zh"] = "检测与游戏法术警报的冲突",
        ["zhTW"] = "檢測與遊戲法術警報的衝突",
    };
    return tr(askToDisableGameAlertsTranslations);
end
