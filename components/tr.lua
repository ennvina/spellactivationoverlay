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
    };
    return string.format(tr(compatibilityWarningTranslations), addonBuild, expectedBuild);
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
