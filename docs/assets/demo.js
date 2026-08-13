/*
 * The demo that runs at the top of this page.
 *
 * Consently is a Rails gem, and GitHub Pages serves static files, so the two
 * halves that live on the server - the helper that renders every tag blocked
 * or live, and the partial that renders the banner - are reproduced here in
 * plain JavaScript. Everything below the server line is the real thing: the
 * markup is what `consently_tags` and `consently_banner` emit, the stylesheet
 * is the gem's own, and the release logic is a port of the two Stimulus
 * controllers the gem ships, attribute for attribute.
 *
 * What the demo cannot fake, and does not: whether the browser fetched a
 * script. That comes from the Resource Timing API, and it is empty until you
 * press a button.
 */

// -- Configuration: the initializer this page pretends to have ---------------
//
//   Consently.configure do |c|
//     c.tag :google_tag_manager, id: "GTM-DEM0123"
//     c.tag :google_analytics,   id: "G-DEM0DEM0D"
//     c.tag :clarity,            id: "demo1234"
//     c.tag :meta_pixel,         id: "123456789012345"
//   end

const CONFIG = {
  cookie: "consently",
  version: "1",
  maxAge: 60 * 60 * 24 * 180,
  path: "/",
  categories: ["analytics", "marketing"],
  googleConsentMode: true,
  respectGpc: true,
  respectDoNotTrack: false
}

const TAGS = [
  {
    key: "google_tag_manager",
    title: "Google Tag Manager",
    id: "GTM-DEM0123",
    category: "analytics",
    cookies: [],
    scripts: [
      { src: "assets/vendor/gtm.js", async: true },
      { inline: "window.dataLayer = window.dataLayer || [];\nwindow.dataLayer.push({'gtm.start': new Date().getTime(), event: 'gtm.js'});" }
    ]
  },
  {
    key: "google_analytics",
    title: "Google Analytics 4",
    id: "G-DEM0DEM0D",
    category: "analytics",
    cookies: [
      { name: "_ga", days: 730 },
      { name: "_ga_*", days: 730 },
      { name: "_gid", days: 1 },
      { name: "_gat", days: null }
    ],
    scripts: [
      { src: "assets/vendor/ga4.js", async: true },
      { inline: "window.dataLayer = window.dataLayer || [];\nfunction gtag(){dataLayer.push(arguments);}\ngtag('js', new Date());\ngtag('config', 'G-DEM0DEM0D', { 'anonymize_ip': true });" }
    ]
  },
  {
    key: "clarity",
    title: "Microsoft Clarity",
    id: "demo1234",
    category: "analytics",
    cookies: [
      { name: "_clck", days: 365 },
      { name: "_clsk", days: 1 },
      { name: "CLID", days: 365 },
      { name: "MUID", days: 390 },
      { name: "ANONCHK", days: null }
    ],
    scripts: [{ src: "assets/vendor/clarity.js", async: true }]
  },
  {
    key: "meta_pixel",
    title: "Meta Pixel",
    id: "123456789012345",
    category: "marketing",
    cookies: [
      { name: "_fbp", days: 90 },
      { name: "fr", days: 90 }
    ],
    scripts: [{ src: "assets/vendor/pixel.js", async: true }]
  }
]

const EMBED = {
  category: "marketing",
  src: "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ",
  ratio: "16 / 9"
}

// -- Translations, straight from the gem's config/locales ---------------------

const LOCALES = {
  en: { name: "English", banner: { message: "We use cookies to run this site, and - with your consent - to understand how it is used and to show you relevant offers.", policy_link: "Read our cookie policy.", accept_all: "Accept all", reject_all: "Reject all", preferences: "Settings", save: "Save choices", cancel: "Cancel" }, preferences_link: "Cookie settings", embed: { blocked: "This content is loaded from another site and needs your %{category} consent.", allow: "Allow and show", title_youtube: "Video" }, policy: { granted: "you agreed", denied: "not agreed", no_tags: "Nothing in this category.", no_cookies: "Sets no cookies.", cookie_name: "Cookie", cookie_duration: "Kept for", duration_days: { one: "%{count} day", other: "%{count} days" }, duration_session: "until you close the browser", own_heading: "The consent cookie itself", own_body: "Your choice is kept in one cookie in your browser: the categories you agreed to, the version of this policy and the time. Nothing about you.", own_version: "Policy version" }, categories: { necessary: { name: "Necessary", description: "Needed for the site to work. They cannot be switched off." }, analytics: { name: "Analytics", description: "Help us see how the site is used, so we can improve it." }, marketing: { name: "Marketing", description: "Let us show you offers that fit what you are interested in." } } },
  pl: { name: "Polski", banner: { message: "Używamy plików cookie, żeby ta strona działała, a za Twoją zgodą także po to, by rozumieć, jak z niej korzystasz, i pokazywać Ci trafne oferty.", policy_link: "Przeczytaj naszą politykę cookies.", accept_all: "Akceptuję wszystkie", reject_all: "Odrzuć wszystkie", preferences: "Ustawienia", save: "Zapisz wybór", cancel: "Anuluj" }, preferences_link: "Ustawienia cookies", embed: { blocked: "Ta treść ładuje się z innej strony i wymaga Twojej zgody na kategorię %{category}.", allow: "Zezwól i pokaż", title_youtube: "Wideo" }, policy: { granted: "zgoda udzielona", denied: "brak zgody", no_tags: "Nic w tej kategorii.", no_cookies: "Nie ustawia ciasteczek.", cookie_name: "Ciasteczko", cookie_duration: "Przechowywane", duration_days: { one: "%{count} dzień", few: "%{count} dni", many: "%{count} dni", other: "%{count} dni" }, duration_session: "do zamknięcia przeglądarki", own_heading: "Samo ciasteczko zgody", own_body: "Twój wybór trzymamy w jednym ciasteczku w Twojej przeglądarce: kategorie, na które się zgodziłeś, wersja tej polityki i czas. Nic o Tobie.", own_version: "Wersja polityki" }, categories: { necessary: { name: "Niezbędne", description: "Potrzebne do działania strony. Nie można ich wyłączyć." }, analytics: { name: "Analityczne", description: "Pokazują nam, jak korzystasz ze strony, dzięki czemu możemy ją ulepszać." }, marketing: { name: "Marketingowe", description: "Pozwalają pokazywać Ci oferty dopasowane do Twoich zainteresowań." } } },
  de: { name: "Deutsch", banner: { message: "Wir verwenden Cookies, damit diese Website funktioniert - und mit Ihrer Einwilligung, um zu verstehen, wie sie genutzt wird, und Ihnen passende Angebote zu zeigen.", policy_link: "Zur Cookie-Richtlinie.", accept_all: "Alle akzeptieren", reject_all: "Alle ablehnen", preferences: "Einstellungen", save: "Auswahl speichern", cancel: "Abbrechen" }, preferences_link: "Cookie-Einstellungen", embed: { blocked: "Dieser Inhalt wird von einer anderen Website geladen und braucht Ihre Einwilligung für %{category}.", allow: "Erlauben und anzeigen", title_youtube: "Video" }, policy: { granted: "eingewilligt", denied: "nicht eingewilligt", no_tags: "Nichts in dieser Kategorie.", no_cookies: "Setzt keine Cookies.", cookie_name: "Cookie", cookie_duration: "Speicherdauer", duration_days: { one: "%{count} Tag", other: "%{count} Tage" }, duration_session: "bis zum Schließen des Browsers", own_heading: "Das Einwilligungs-Cookie selbst", own_body: "Ihre Wahl liegt in einem Cookie in Ihrem Browser: die Kategorien, denen Sie zugestimmt haben, die Version dieser Richtlinie und die Uhrzeit. Nichts über Sie.", own_version: "Version der Richtlinie" }, categories: { necessary: { name: "Notwendig", description: "Für den Betrieb der Website erforderlich. Sie lassen sich nicht abschalten." }, analytics: { name: "Statistik", description: "Zeigen uns, wie die Website genutzt wird, damit wir sie verbessern können." }, marketing: { name: "Marketing", description: "Erlauben uns, Ihnen Angebote zu zeigen, die zu Ihren Interessen passen." } } },
  fr: { name: "Français", banner: { message: "Nous utilisons des cookies pour faire fonctionner ce site et, avec votre accord, pour comprendre comment il est utilisé et vous proposer des offres pertinentes.", policy_link: "Consulter notre politique de cookies.", accept_all: "Tout accepter", reject_all: "Tout refuser", preferences: "Paramètres", save: "Enregistrer mes choix", cancel: "Annuler" }, preferences_link: "Paramètres des cookies", embed: { blocked: "Ce contenu provient d'un autre site et nécessite votre accord pour %{category}.", allow: "Autoriser et afficher", title_youtube: "Vidéo" }, policy: { granted: "accepté", denied: "non accepté", no_tags: "Rien dans cette catégorie.", no_cookies: "Ne dépose aucun cookie.", cookie_name: "Cookie", cookie_duration: "Conservé", duration_days: { one: "%{count} jour", other: "%{count} jours" }, duration_session: "jusqu'à la fermeture du navigateur", own_heading: "Le cookie de consentement lui-même", own_body: "Votre choix tient dans un cookie de votre navigateur : les catégories acceptées, la version de cette politique et l'heure. Rien sur vous.", own_version: "Version de la politique" }, categories: { necessary: { name: "Nécessaires", description: "Indispensables au fonctionnement du site. Ils ne peuvent pas être désactivés." }, analytics: { name: "Mesure d'audience", description: "Nous montrent comment le site est utilisé, afin de l'améliorer." }, marketing: { name: "Marketing", description: "Nous permettent de vous proposer des offres correspondant à vos centres d'intérêt." } } },
  es: { name: "Español", banner: { message: "Usamos cookies para que este sitio funcione y, con tu consentimiento, para entender cómo se usa y mostrarte ofertas relevantes.", policy_link: "Lee nuestra política de cookies.", accept_all: "Aceptar todo", reject_all: "Rechazar todo", preferences: "Ajustes", save: "Guardar selección", cancel: "Cancelar" }, preferences_link: "Ajustes de cookies", embed: { blocked: "Este contenido se carga desde otro sitio y necesita tu consentimiento de %{category}.", allow: "Permitir y mostrar", title_youtube: "Vídeo" }, policy: { granted: "consentido", denied: "sin consentimiento", no_tags: "Nada en esta categoría.", no_cookies: "No instala cookies.", cookie_name: "Cookie", cookie_duration: "Se conserva", duration_days: { one: "%{count} día", other: "%{count} días" }, duration_session: "hasta que cierres el navegador", own_heading: "La propia cookie de consentimiento", own_body: "Tu elección se guarda en una cookie de tu navegador: las categorías que aceptaste, la versión de esta política y la hora. Nada sobre ti.", own_version: "Versión de la política" }, categories: { necessary: { name: "Necesarias", description: "Imprescindibles para que el sitio funcione. No se pueden desactivar." }, analytics: { name: "Analíticas", description: "Nos muestran cómo se usa el sitio para poder mejorarlo." }, marketing: { name: "Marketing", description: "Nos permiten mostrarte ofertas acordes con tus intereses." } } },
  it: { name: "Italiano", banner: { message: "Usiamo i cookie per far funzionare questo sito e, con il tuo consenso, per capire come viene usato e mostrarti offerte pertinenti.", policy_link: "Leggi la nostra cookie policy.", accept_all: "Accetta tutto", reject_all: "Rifiuta tutto", preferences: "Impostazioni", save: "Salva le scelte", cancel: "Annulla" }, preferences_link: "Impostazioni cookie", embed: { blocked: "Questo contenuto viene caricato da un altro sito e richiede il tuo consenso per %{category}.", allow: "Consenti e mostra", title_youtube: "Video" }, policy: { granted: "consenso dato", denied: "nessun consenso", no_tags: "Niente in questa categoria.", no_cookies: "Non imposta cookie.", cookie_name: "Cookie", cookie_duration: "Conservato", duration_days: { one: "%{count} giorno", other: "%{count} giorni" }, duration_session: "fino alla chiusura del browser", own_heading: "Il cookie di consenso", own_body: "La tua scelta sta in un cookie nel tuo browser: le categorie accettate, la versione di questa policy e l'ora. Nulla su di te.", own_version: "Versione della policy" }, categories: { necessary: { name: "Necessari", description: "Servono al funzionamento del sito. Non possono essere disattivati." }, analytics: { name: "Statistici", description: "Ci mostrano come viene usato il sito, così possiamo migliorarlo." }, marketing: { name: "Marketing", description: "Ci permettono di mostrarti offerte in linea con i tuoi interessi." } } },
  nl: { name: "Nederlands", banner: { message: "We gebruiken cookies om deze site te laten werken en, met jouw toestemming, om te begrijpen hoe de site gebruikt wordt en je relevante aanbiedingen te tonen.", policy_link: "Lees ons cookiebeleid.", accept_all: "Alles accepteren", reject_all: "Alles weigeren", preferences: "Instellingen", save: "Keuze opslaan", cancel: "Annuleren" }, preferences_link: "Cookie-instellingen", embed: { blocked: "Deze inhoud komt van een andere site en heeft je toestemming voor %{category} nodig.", allow: "Toestaan en tonen", title_youtube: "Video" }, policy: { granted: "toegestaan", denied: "niet toegestaan", no_tags: "Niets in deze categorie.", no_cookies: "Plaatst geen cookies.", cookie_name: "Cookie", cookie_duration: "Bewaard", duration_days: { one: "%{count} dag", other: "%{count} dagen" }, duration_session: "tot je de browser sluit", own_heading: "De toestemmingscookie zelf", own_body: "Je keuze staat in één cookie in je browser: de categorieën die je toestond, de versie van dit beleid en het tijdstip. Niets over jou.", own_version: "Versie van het beleid" }, categories: { necessary: { name: "Noodzakelijk", description: "Nodig om de site te laten werken. Deze kun je niet uitzetten." }, analytics: { name: "Statistieken", description: "Laten ons zien hoe de site gebruikt wordt, zodat we hem kunnen verbeteren." }, marketing: { name: "Marketing", description: "Hiermee kunnen we je aanbiedingen tonen die bij je interesses passen." } } },
  cs: { name: "Čeština", banner: { message: "Používáme soubory cookie, aby tento web fungoval, a s vaším souhlasem také k tomu, abychom rozuměli, jak jej používáte, a mohli vám ukazovat relevantní nabídky.", policy_link: "Přečtěte si naše zásady cookies.", accept_all: "Přijmout vše", reject_all: "Odmítnout vše", preferences: "Nastavení", save: "Uložit volbu", cancel: "Zrušit" }, preferences_link: "Nastavení cookies", embed: { blocked: "Tento obsah se načítá z jiného webu a vyžaduje váš souhlas pro kategorii %{category}.", allow: "Povolit a zobrazit", title_youtube: "Video" }, policy: { granted: "souhlas udělen", denied: "bez souhlasu", no_tags: "V této kategorii nic není.", no_cookies: "Nenastavuje žádné cookies.", cookie_name: "Cookie", cookie_duration: "Doba uložení", duration_days: { one: "%{count} den", few: "%{count} dny", many: "%{count} dne", other: "%{count} dní" }, duration_session: "do zavření prohlížeče", own_heading: "Samotná cookie se souhlasem", own_body: "Vaše volba je uložená v jedné cookie ve vašem prohlížeči: kategorie, se kterými jste souhlasili, verze těchto zásad a čas. Nic o vás.", own_version: "Verze zásad" }, categories: { necessary: { name: "Nezbytné", description: "Nutné pro fungování webu. Nelze je vypnout." }, analytics: { name: "Analytické", description: "Ukazují nám, jak web používáte, abychom jej mohli zlepšovat." }, marketing: { name: "Marketingové", description: "Umožňují nám ukazovat vám nabídky, které odpovídají vašim zájmům." } } },
  sk: { name: "Slovenčina", banner: { message: "Používame súbory cookie, aby táto stránka fungovala, a s vaším súhlasom aj na to, aby sme rozumeli, ako ju používate, a mohli vám ukazovať relevantné ponuky.", policy_link: "Prečítajte si naše zásady cookies.", accept_all: "Prijať všetko", reject_all: "Odmietnuť všetko", preferences: "Nastavenia", save: "Uložiť voľbu", cancel: "Zrušiť" }, preferences_link: "Nastavenia cookies", embed: { blocked: "Tento obsah sa načítava z inej stránky a vyžaduje váš súhlas pre kategóriu %{category}.", allow: "Povoliť a zobraziť", title_youtube: "Video" }, policy: { granted: "súhlas udelený", denied: "bez súhlasu", no_tags: "V tejto kategórii nič nie je.", no_cookies: "Nenastavuje žiadne cookies.", cookie_name: "Cookie", cookie_duration: "Doba uloženia", duration_days: { one: "%{count} deň", few: "%{count} dni", many: "%{count} dňa", other: "%{count} dní" }, duration_session: "do zatvorenia prehliadača", own_heading: "Samotná cookie so súhlasom", own_body: "Vaša voľba je uložená v jednej cookie vo vašom prehliadači: kategórie, s ktorými ste súhlasili, verzia týchto zásad a čas. Nič o vás.", own_version: "Verzia zásad" }, categories: { necessary: { name: "Nevyhnutné", description: "Potrebné na fungovanie stránky. Nedajú sa vypnúť." }, analytics: { name: "Analytické", description: "Ukazujú nám, ako stránku používate, aby sme ju mohli zlepšovať." }, marketing: { name: "Marketingové", description: "Umožňujú nám ukazovať vám ponuky, ktoré zodpovedajú vašim záujmom." } } },
  hu: { name: "Magyar", banner: { message: "Sütiket használunk, hogy az oldal működjön, és - a hozzájárulásoddal - hogy megértsük, hogyan használod, illetve releváns ajánlatokat mutassunk.", policy_link: "Olvasd el a süti szabályzatunkat.", accept_all: "Összes elfogadása", reject_all: "Összes elutasítása", preferences: "Beállítások", save: "Választás mentése", cancel: "Mégse" }, preferences_link: "Süti beállítások", embed: { blocked: "Ez a tartalom másik oldalról töltődik be, és a(z) %{category} kategóriához adott hozzájárulásod kell hozzá.", allow: "Engedélyezés és megjelenítés", title_youtube: "Videó" }, policy: { granted: "hozzájárultál", denied: "nincs hozzájárulás", no_tags: "Ebben a kategóriában nincs semmi.", no_cookies: "Nem helyez el sütit.", cookie_name: "Süti", cookie_duration: "Megőrzés", duration_days: { one: "%{count} nap", other: "%{count} nap" }, duration_session: "a böngésző bezárásáig", own_heading: "Maga a hozzájárulási süti", own_body: "A választásod egyetlen sütiben van a böngésződben: az elfogadott kategóriák, e szabályzat verziója és az idő. Rólad semmi.", own_version: "Szabályzat verziója" }, categories: { necessary: { name: "Szükséges", description: "Az oldal működéséhez kellenek. Nem kapcsolhatók ki." }, analytics: { name: "Statisztikai", description: "Megmutatják, hogyan használod az oldalt, hogy fejleszthessük." }, marketing: { name: "Marketing", description: "Segítenek olyan ajánlatokat mutatni, amelyek érdekelhetnek." } } }
}

let locale = "en"

// The gem's translations carry one/few/many/other where the language needs
// them, so "1 days" cannot happen. This picks the same form Rails would.
function pluralForm(forms, count) {
  if (count === 1 && forms.one) return forms.one

  if (["pl", "cs", "sk"].includes(locale)) {
    const tens = count % 10
    const hundreds = count % 100
    if (tens >= 2 && tens <= 4 && !(hundreds >= 12 && hundreds <= 14)) return forms.few ?? forms.other
    if (locale === "pl") return forms.many ?? forms.other
  }

  return forms.other
}

const t = (path, replacements = {}) => {
  let value = path.split(".").reduce((node, key) => (node ? node[key] : undefined), LOCALES[locale]) ?? ""
  if (value && typeof value === "object") value = pluralForm(value, replacements.count)

  return Object.entries(replacements).reduce((text, [key, replacement]) => text.replaceAll(`%{${key}}`, replacement), value)
}

// -- The consent cookie, in the format the gem reads -------------------------

function readConsent() {
  const raw = document.cookie.split("; ").find((pair) => pair.startsWith(`${CONFIG.cookie}=`))
  if (!raw) return null

  try {
    const parsed = JSON.parse(decodeURIComponent(raw.slice(CONFIG.cookie.length + 1)))
    if (parsed.v !== CONFIG.version) return null

    return parsed
  } catch {
    return null
  }
}

const grantedCategories = () => readConsent()?.c ?? []
const decided = () => readConsent() !== null

// -- The server half: what `consently_tags` renders --------------------------
//
// A tag whose category is granted is a live <script>; anything else is an
// inert one whose src sits in a data attribute, so the browser has nothing to
// fetch. This is the markup, attribute for attribute.

function renderTags() {
  const granted = new Set([...grantedCategories(), "necessary"])
  const container = document.getElementById("demo-tags")
  container.textContent = ""

  for (const tag of TAGS) {
    for (const script of tag.scripts) {
      const element = document.createElement("script")
      element.dataset.consentlyCategory = tag.category

      if (granted.has(tag.category)) {
        if (script.src) element.src = script.src
        if (script.async) element.async = true
        if (script.inline) element.textContent = script.inline
      } else {
        if (script.src) element.dataset.consentlySrc = script.src
        if (script.async) element.dataset.consentlyAsync = "true"
        if (script.inline) element.textContent = script.inline
        element.type = "text/plain"
      }

      container.append(element)
    }
  }
}

// Google's consent mode v2 defaults, emitted before any Google tag - never
// blocked, because its job is to tell those tags to store nothing yet.
function consentModeDefaults() {
  window.dataLayer = window.dataLayer || []
  const gtag = function () { window.dataLayer.push(arguments) }

  gtag("consent", "default", {
    ad_storage: "denied",
    ad_user_data: "denied",
    ad_personalization: "denied",
    analytics_storage: "denied",
    functionality_storage: "granted",
    security_storage: "granted",
    wait_for_update: 500
  })

  const consent = readConsent()
  if (consent) {
    const analytics = consent.c.includes("analytics") ? "granted" : "denied"
    const marketing = consent.c.includes("marketing") ? "granted" : "denied"
    gtag("consent", "update", { analytics_storage: analytics, ad_storage: marketing, ad_user_data: marketing, ad_personalization: marketing })
  }
}

// -- The banner: the partial the gem renders, in the language you pick -------

function renderBanner() {
  const consent = readConsent()
  const granted = consent?.c ?? []

  document.getElementById("demo-banner").innerHTML = `
    <div id="consently"
         class="consently"
         data-turbo-permanent
         data-controller="consently-banner"
         data-action="click@document->consently-banner#openFromLink"
         data-consently-banner-open-class="consently__panel--open"
         data-consently-banner-hidden-class="consently-hidden"
         data-consently-banner-cookie-value="${CONFIG.cookie}"
         data-consently-banner-version-value="${CONFIG.version}"
         data-consently-banner-max-age-value="${CONFIG.maxAge}"
         data-consently-banner-path-value="${CONFIG.path}"
         data-consently-banner-categories-value="${escapeHtml(JSON.stringify(CONFIG.categories))}"
         data-consently-banner-google-consent-mode-value="basic"
         data-consently-banner-decided-value="${consent !== null}">
      <div class="consently__card${consent ? " consently-hidden" : ""}"
           data-consently-banner-target="card"
           role="dialog"
           aria-modal="false"
           aria-labelledby="consently-message"
           tabindex="-1">
        <p class="consently__text" id="consently-message">
          ${escapeHtml(t("banner.message"))}
          <a class="consently__link" href="#policy">${escapeHtml(t("banner.policy_link"))}</a>
        </p>

        <div class="consently__panel" id="consently-preferences" data-consently-banner-target="preferences">
          <div class="consently__panel-inner">
            <div class="consently__options">
              <label class="consently__option">
                <input type="checkbox" checked disabled>
                <span>
                  <span class="consently__option-name">${escapeHtml(t("categories.necessary.name"))}</span>
                  <span class="consently__option-description">${escapeHtml(t("categories.necessary.description"))}</span>
                </span>
              </label>
              ${CONFIG.categories.map((category) => `
                <label class="consently__option">
                  <input type="checkbox" value="${category}" id="consently-${category}"
                         data-consently-banner-target="category"${granted.includes(category) ? " checked" : ""}>
                  <span>
                    <span class="consently__option-name">${escapeHtml(t(`categories.${category}.name`))}</span>
                    <span class="consently__option-description">${escapeHtml(t(`categories.${category}.description`))}</span>
                  </span>
                </label>`).join("")}
            </div>
          </div>
        </div>

        <div class="consently__actions">
          <button type="button" data-action="consently-banner#acceptAll" class="consently__button consently__button--primary">${escapeHtml(t("banner.accept_all"))}</button>
          <button type="button" data-action="consently-banner#rejectAll" class="consently__button">${escapeHtml(t("banner.reject_all"))}</button>
          <button type="button" data-action="consently-banner#openPreferences" data-consently-banner-target="settingsButton"
                  aria-expanded="false" aria-controls="consently-preferences"
                  class="consently__button consently__button--quiet">${escapeHtml(t("banner.preferences"))}</button>
          <button type="button" data-action="consently-banner#savePreferences" data-consently-banner-target="saveButton"
                  class="consently__button consently-hidden">${escapeHtml(t("banner.save"))}</button>
          <button type="button" data-action="consently-banner#closePreferences" data-consently-banner-target="cancelButton"
                  class="consently__button consently__button--quiet consently-hidden">${escapeHtml(t("banner.cancel"))}</button>
        </div>
      </div>
    </div>`

  bindBanner()
}

// -- The controller: a port of app/javascript/consently/banner_controller.js --

// Set by bindBanner, so the one document-level listener below always reaches
// the banner currently on the page.
let openPanel = () => {}

function bindBanner() {
  const root = document.getElementById("consently")
  const target = (name) => root.querySelector(`[data-consently-banner-target="${name}"]`)
  const targets = (name) => [...root.querySelectorAll(`[data-consently-banner-target="${name}"]`)]

  const card = target("card")
  const preferences = target("preferences")
  const settingsButton = target("settingsButton")
  const saveButton = target("saveButton")
  const cancelButton = target("cancelButton")

  const collapse = () => {
    preferences.classList.remove("consently__panel--open")
    settingsButton.classList.remove("consently-hidden")
    settingsButton.setAttribute("aria-expanded", "false")
    saveButton.classList.add("consently-hidden")
    cancelButton.classList.add("consently-hidden")
  }

  const open = (event) => {
    if (event) event.preventDefault()

    card.classList.remove("consently-hidden")
    preferences.classList.add("consently__panel--open")
    settingsButton.classList.add("consently-hidden")
    settingsButton.setAttribute("aria-expanded", "true")
    saveButton.classList.remove("consently-hidden")
    cancelButton.classList.remove("consently-hidden")
    card.focus({ preventScroll: true })
  }

  const store = (categories) => {
    writeCookie(categories)
    activateScripts(categories)
    updateGoogleConsent(categories)

    collapse()
    card.classList.add("consently-hidden")

    document.dispatchEvent(new CustomEvent("consently:change", { detail: { categories } }))
  }

  root.querySelector('[data-action="consently-banner#acceptAll"]').addEventListener("click", () => store(CONFIG.categories))
  root.querySelector('[data-action="consently-banner#rejectAll"]').addEventListener("click", () => store([]))
  settingsButton.addEventListener("click", open)
  cancelButton.addEventListener("click", () => {
    collapse()
    if (decided()) card.classList.add("consently-hidden")
  })
  saveButton.addEventListener("click", () => {
    store(targets("category").filter((box) => box.checked).map((box) => box.value))
  })

  openPanel = open

  // An opt-out signal is an answer, so the banner never appears for it.
  if (!decided() && CONFIG.respectGpc && navigator.globalPrivacyControl === true) store([])
}

// Anything anywhere on the page carrying data-consently-open reopens the
// panel - that is how the footer link works, and the button on a blocked embed.
document.addEventListener("click", (event) => {
  if (event.target.closest("[data-consently-open]")) openPanel(event)
})

function writeCookie(categories) {
  const value = JSON.stringify({ v: CONFIG.version, c: categories, t: new Date().toISOString() })
  const secure = window.location.protocol === "https:" ? "; Secure" : ""

  document.cookie = `${CONFIG.cookie}=${encodeURIComponent(value)}; path=${CONFIG.path}; max-age=${CONFIG.maxAge}; SameSite=Lax${secure}`
}

// The part that matters: an inert tag becomes a live one, in place, with no
// reload. Everything the server put on it is copied over except the gem's own
// bookkeeping, so vendor attributes survive.
function activateScripts(categories) {
  const granted = new Set([...categories, "necessary"])

  document.querySelectorAll('script[type="text/plain"][data-consently-category]').forEach((blocked) => {
    if (!granted.has(blocked.dataset.consentlyCategory)) return

    const script = document.createElement("script")
    for (const { name, value } of blocked.attributes) {
      if (name === "type" || name.startsWith("data-consently-")) continue
      script.setAttribute(name, value)
    }
    script.dataset.consentlyCategory = blocked.dataset.consentlyCategory

    if (blocked.dataset.consentlySrc) {
      script.src = blocked.dataset.consentlySrc
    } else {
      script.textContent = blocked.textContent
    }
    if (blocked.dataset.consentlyAsync) script.async = true
    if (blocked.dataset.consentlyDefer) script.defer = true

    blocked.replaceWith(script)
  })
}

function updateGoogleConsent(categories) {
  if (!CONFIG.googleConsentMode) return

  const analytics = categories.includes("analytics") ? "granted" : "denied"
  const marketing = categories.includes("marketing") ? "granted" : "denied"

  window.dataLayer = window.dataLayer || []
  const gtag = function () { window.dataLayer.push(arguments) }
  gtag("consent", "update", {
    analytics_storage: analytics,
    ad_storage: marketing,
    ad_user_data: marketing,
    ad_personalization: marketing
  })
  window.dataLayer.push({ event: "consently_consent_update", consently_categories: categories.join(",") })
}

// -- The embed: a port of embed_controller.js, plus its partial --------------

function renderEmbed() {
  const granted = grantedCategories().includes(EMBED.category)
  const categoryName = t(`categories.${EMBED.category}.name`)
  const element = document.getElementById("demo-embed")

  element.innerHTML = `
    <div class="consently-embed" style="--consently-embed-ratio: ${EMBED.ratio}"
         data-controller="consently-embed"
         data-consently-embed-category-value="${EMBED.category}"
         data-consently-embed-src-value="${EMBED.src}"
         data-consently-embed-title-value="${escapeHtml(t("embed.title_youtube"))}"
         data-consently-embed-hidden-class="consently-hidden"
         data-action="consently:change@document->consently-embed#granted">
      ${granted ? `<iframe src="${EMBED.src}" title="${escapeHtml(t("embed.title_youtube"))}" loading="lazy" allowfullscreen class="consently-embed__frame"></iframe>` : ""}
      <div class="consently-embed__placeholder${granted ? " consently-hidden" : ""}" data-consently-embed-target="placeholder">
        <p class="consently-embed__text">${escapeHtml(t("embed.blocked", { category: categoryName }))}</p>
        <button type="button" data-consently-open class="consently__button consently__button--primary">${escapeHtml(t("embed.allow"))}</button>
      </div>
    </div>`
}

function releaseEmbed(categories) {
  if (!categories.includes(EMBED.category)) return

  const element = document.querySelector("#demo-embed .consently-embed")
  if (!element || element.querySelector("iframe")) return

  const frame = document.createElement("iframe")
  frame.src = EMBED.src
  frame.title = t("embed.title_youtube")
  frame.loading = "lazy"
  frame.allowFullscreen = true
  frame.className = "consently-embed__frame"

  element.prepend(frame)
  element.querySelector(".consently-embed__placeholder").classList.add("consently-hidden")
}

// -- The cookie policy, rendered from the same configuration ----------------

function renderPolicy() {
  const granted = grantedCategories()
  const categories = ["necessary", ...CONFIG.categories]

  const duration = (days) => (days === null ? t("policy.duration_session") : t("policy.duration_days", { count: days }))

  const vendorMarkup = (tag) => `
    <div class="consently-policy__vendor">
      <p class="consently-policy__vendor-name">${escapeHtml(tag.title)}<span class="consently-policy__vendor-id">${escapeHtml(tag.id)}</span></p>
      ${tag.cookies.length === 0 ? `<p class="consently-policy__empty">${escapeHtml(t("policy.no_cookies"))}</p>` : `
        <table class="consently-policy__table">
          <thead><tr><th>${escapeHtml(t("policy.cookie_name"))}</th><th>${escapeHtml(t("policy.cookie_duration"))}</th></tr></thead>
          <tbody>${tag.cookies.map((cookie) => `<tr><td><code>${escapeHtml(cookie.name)}</code></td><td>${escapeHtml(duration(cookie.days))}</td></tr>`).join("")}</tbody>
        </table>`}
    </div>`

  document.getElementById("demo-policy").innerHTML = `
    <div class="consently-policy">
      ${categories.map((category) => {
        const tags = TAGS.filter((tag) => tag.category === category)
        const isGranted = category === "necessary" || granted.includes(category)

        return `
          <section class="consently-policy__category">
            <div class="consently-policy__heading">
              <h2 class="consently-policy__title">${escapeHtml(t(`categories.${category}.name`))}</h2>
              <span class="consently-policy__status${isGranted ? " consently-policy__status--granted" : ""}">${escapeHtml(isGranted ? t("policy.granted") : t("policy.denied"))}</span>
            </div>
            <p class="consently-policy__description">${escapeHtml(t(`categories.${category}.description`))}</p>
            ${tags.length === 0 ? `<p class="consently-policy__empty">${escapeHtml(t("policy.no_tags"))}</p>` : tags.map(vendorMarkup).join("")}
          </section>`
      }).join("")}

      <section class="consently-policy__category">
        <h2 class="consently-policy__title">${escapeHtml(t("policy.own_heading"))}</h2>
        <p class="consently-policy__description">${escapeHtml(t("policy.own_body"))}</p>
        <table class="consently-policy__table">
          <thead><tr><th>${escapeHtml(t("policy.cookie_name"))}</th><th>${escapeHtml(t("policy.cookie_duration"))}</th><th>${escapeHtml(t("policy.own_version"))}</th></tr></thead>
          <tbody><tr><td><code>${CONFIG.cookie}</code></td><td>${escapeHtml(t("policy.duration_days", { count: CONFIG.maxAge / 86400 }))}</td><td>${CONFIG.version}</td></tr></tbody>
        </table>
      </section>

      <p class="consently-policy__footer"><a href="#consently" data-consently-open>${escapeHtml(t("preferences_link"))}</a></p>
    </div>`
}

// -- The panels: what the browser actually did ------------------------------

const loadedVendors = new Set()

window.__consentlyDemo = {
  vendorLoaded(name) {
    loadedVendors.add(name)
    refresh()
  }
}

function refreshTags() {
  const rows = TAGS.map((tag) => {
    const running = grantedCategories().includes(tag.category)

    return `
      <tr>
        <td>${escapeHtml(tag.title)}</td>
        <td><code>${tag.category}</code></td>
        <td><span class="pill pill--${running ? "running" : "blocked"}">${running ? "running" : "blocked"}</span></td>
      </tr>`
  }).join("")

  document.querySelector("#panel-tags tbody").innerHTML = rows
}

function refreshMarkup() {
  const markup = [...document.getElementById("demo-tags").children]
    .map((script) => script.outerHTML.replace("></script>", ">\n</script>"))
    .join("\n\n")

  const code = document.querySelector("#panel-markup code")
  code.textContent = markup
  highlight(code, "html")
}

function refreshRequests() {
  const entries = performance.getEntriesByType("resource").filter((entry) => entry.name.includes("/assets/vendor/"))
  const panel = document.querySelector("#panel-requests .panel-body")

  if (entries.length === 0) {
    panel.innerHTML = `<p class="empty">No requests to any vendor. The browser has not fetched a single tag.</p>`
    return
  }

  panel.innerHTML = `
    <table>
      <thead><tr><th>Request</th><th>At</th></tr></thead>
      <tbody>${entries.map((entry) => `
        <tr>
          <td><code>${escapeHtml(entry.name.split("/").pop())}</code></td>
          <td>${(entry.startTime / 1000).toFixed(1)}s after load</td>
        </tr>`).join("")}
      </tbody>
    </table>
    <p>${entries.length} request${entries.length === 1 ? "" : "s"}, every one of them after your click.</p>`
}

function refreshCookies() {
  const cookies = document.cookie.split("; ").filter(Boolean).map((pair) => {
    const index = pair.indexOf("=")
    return { name: pair.slice(0, index), value: decodeURIComponent(pair.slice(index + 1)) }
  })
  const panel = document.querySelector("#panel-cookies .panel-body")

  if (cookies.length === 0) {
    panel.innerHTML = `<p class="empty">No cookies at all. Not even a consent one: nothing has been decided yet.</p>`
    return
  }

  const consent = cookies.find((cookie) => cookie.name === CONFIG.cookie)
  const vendors = cookies.filter((cookie) => cookie.name !== CONFIG.cookie)

  panel.innerHTML = `
    ${consent ? `<pre><code>${escapeHtml(CONFIG.cookie)} = ${escapeHtml(JSON.stringify(JSON.parse(consent.value), null, 2))}</code></pre>` : ""}
    ${vendors.length === 0
      ? `<p class="empty">No vendor cookies.</p>`
      : `<table><thead><tr><th>Vendor cookie</th><th>Set by</th></tr></thead><tbody>${vendors.map((cookie) => `
          <tr><td><code>${escapeHtml(cookie.name)}</code></td><td>${escapeHtml(vendorFor(cookie.name))}</td></tr>`).join("")}</tbody></table>`}`
}

function vendorFor(name) {
  return TAGS.find((tag) => tag.cookies.some((cookie) => cookie.name === name))?.title ?? "the demo"
}

function refreshDataLayer() {
  const calls = (window.dataLayer ?? []).map((entry) => {
    if (Array.isArray(entry) || typeof entry.length !== "number") return JSON.stringify(entry, null, 2)

    const args = [...entry].map((argument) => JSON.stringify(argument, null, 2))
    return `gtag(${args.join(", ")})`
  })

  const code = document.querySelector("#panel-datalayer code")
  code.textContent = calls.join("\n\n")
  highlight(code, "js")
}

function refreshState() {
  const granted = grantedCategories()
  const state = decided()
    ? granted.length === 0 ? "consent given: nothing granted" : `consent given: ${granted.join(", ")}`
    : "no consent yet"

  document.getElementById("demo-state").textContent = state
}

function refresh() {
  refreshTags()
  refreshMarkup()
  refreshRequests()
  refreshCookies()
  refreshDataLayer()
  refreshState()
  renderPolicy()
}

// -- A very small syntax highlighter, so the snippets read as code ----------

const escapeHtml = (text) => String(text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")

function highlight(element, language = element.dataset.lang) {
  const held = []
  const hold = (type, text) => {
    held.push(`<span class="tok-${type}">${text}</span>`)
    return `\u0000${held.length - 1}\u0000`
  }

  let html = escapeHtml(element.textContent)

  html = html.replace(/(&quot;[^\n]*?&quot;|'[^'\n]*')/g, (match) => hold("string", match))

  if (language === "ruby") {
    html = html.replace(/#[^\n\u0000]*/g, (match) => hold("comment", match))
    html = html.replace(/(?<![\w:])(:[a-z_][\w]*)/g, (match) => hold("symbol", match))
    html = html.replace(/\b(do|end|true|false|nil|def|module|class)\b/g, (match) => hold("keyword", match))
  } else if (language === "js") {
    html = html.replace(/\/\/[^\n\u0000]*/g, (match) => hold("comment", match))
    html = html.replace(/\b(const|let|function|return|window|document|new)\b/g, (match) => hold("keyword", match))
  } else if (language === "erb" || language === "html") {
    html = html.replace(/&lt;%#[\s\S]*?%&gt;/g, (match) => hold("comment", match))
    html = html.replace(/&lt;%=?[\s\S]*?%&gt;/g, (match) => hold("symbol", match))
    html = html.replace(/&lt;\/?[\w-]+|\/?&gt;/g, (match) => hold("tag", match))
  } else if (language === "shell") {
    html = html.replace(/#[^\n\u0000]*/g, (match) => hold("comment", match))
  }

  element.innerHTML = html.replace(/\u0000(\d+)\u0000/g, (_, index) => held[Number(index)])
}

// -- Wiring ------------------------------------------------------------------

function reset() {
  const expiry = "; path=/; max-age=0"
  document.cookie.split("; ").filter(Boolean).forEach((pair) => {
    document.cookie = `${pair.split("=")[0]}=${expiry}`
  })

  window.location.reload()
}

document.addEventListener("consently:change", ({ detail }) => {
  releaseEmbed(detail.categories)
  // Resource timings land a tick after the script element is inserted.
  setTimeout(refresh, 50)
  refresh()
})

document.querySelectorAll("pre code[data-lang]").forEach((code) => highlight(code))

consentModeDefaults()
renderTags()
renderBanner()
renderEmbed()
refresh()

document.getElementById("demo-reset").addEventListener("click", reset)

document.getElementById("demo-locale").addEventListener("change", (event) => {
  locale = event.target.value
  renderBanner()
  renderEmbed()
  renderPolicy()
  if (!decided()) document.querySelector("#consently .consently__card").classList.remove("consently-hidden")
})

// The gem's custom properties live on :root, so one override themes the banner,
// the blocked embed and the policy alike.
document.getElementById("demo-accent").addEventListener("input", (event) => {
  document.documentElement.style.setProperty("--consently-accent", event.target.value)
})

document.getElementById("demo-radius").addEventListener("input", (event) => {
  document.documentElement.style.setProperty("--consently-radius", `${event.target.value}rem`)
})
