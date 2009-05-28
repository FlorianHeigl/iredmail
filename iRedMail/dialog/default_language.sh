#!/usr/bin/env bash

# Author:	Zhang Huangbin <michaelbibby (at) gmail.com>

# Set default language for webmails.

${DIALOG} --backtitle "${DIALOG_BACKTITLE}" \
    --title "Choose the \Zb\Z2default language\Zn for your webmail(s)" \
    --radiolist "\
Choose the \Zb\Z2default language\Zn for your webmail(s):

TIP:
    * Use 'Space' key to select item.

" 20 76 5 \
  'en_US' 'English (US)' 'on' \
  'zh_CN' 'Chinese (Simplified)' 'off' \
  'zh_TW' 'Chinese (Traditional)' 'off' \
  'sq_AL' 'Albanian' 'off' \
  'ar_SA' 'Arabic' 'off' \
  'hy_AM' 'Armenian' 'off' \
  'az_AZ' 'Azerbaijani' 'off' \
  'bs_BA' 'Bosnian (Serbian Latin)' 'off' \
  'bg_BG' 'Bulgarian' 'off' \
  'ca_ES' 'Català' 'off' \
  'cy_GB' 'Cymraeg' 'off' \
  'hr_HR' 'Croatian (Hrvatski)' 'off' \
  'cs_CZ' 'Czech' 'off' \
  'da_DK' 'Dansk' 'off' \
  'de_DE' 'Deutsch (Deutsch)' 'off' \
  'de_CH' 'Deutsch (Schweiz)' 'off' \
  'en_GB' 'English (GB)' 'off' \
  'es_ES' 'Español' 'off' \
  'eo'    'Esperanto' 'off' \
  'et_EE' 'Estonian' 'off' \
  'eu_ES' 'Euskara (Basque)' 'off' \
  'fi_FI' 'Finnish (Suomi)' 'off' \
  'nl_BE' 'Flemish' 'off' \
  'fr_FR' 'Français' 'off' \
  'gl_ES' 'Galego (Galician)' 'off' \
  'ka_GE' 'Georgian (Kartuli)' 'off' \
  'el_GR' 'Greek' 'off' \
  'he_IL' 'Hebrew' 'off' \
  'hi_IN' 'Hindi' 'off' \
  'hu_HU' 'Hungarian' 'off' \
  'is_IS' 'Icelandic' 'off' \
  'id_ID' 'Indonesian' 'off' \
  'ga_IE' 'Irish' 'off' \
  'it_IT' 'Italiano' 'off' \
  'ja_JP' 'Japanese (日本語)' 'off' \
  'ko_KR' 'Korean' 'off' \
  'ku'    'Kurdish (Kurmancî)' 'off' \
  'lv_LV' 'Latvian' 'off' \
  'lt_LT' 'Lithuanian' 'off' \
  'mk_MK' 'Macedonian' 'off' \
  'ms_MY' 'Malay' 'off' \
  'nl_NL' 'Nederlands' 'off' \
  'ne_NP' 'Nepali' 'off' \
  'nb_NO' 'Norsk (Bokmål)' 'off' \
  'nn_NO' 'Norsk (Nynorsk)' 'off' \
  'fa'    'Persian (Farsi)' 'off' \
  'pl_PL' 'Polski' 'off' \
  'pt_BR' 'Portuguese (Brazilian)' 'off' \
  'pt_PT' 'Portuguese (Standard)' 'off' \
  'ro_RO' 'Romanian' 'off' \
  'ru_RU' 'Русский' 'off' \
  'sr_CS' 'Serbian (Cyrillic)' 'off' \
  'si_LK' 'Sinhala' 'off' \
  'sk_SK' 'Slovak' 'off' \
  'sl_SI' 'Slovenian' 'off' \
  'sv_SE' 'Swedish (Svenska)' 'off' \
  'th_TH' 'Thai' 'off' \
  'tr_TR' 'Türkçe' 'off' \
  'uk_UA' 'Ukrainian' 'off' \
  'vi_VN' 'Vietnamese' 'off' \
   2>/tmp/language

DEFAULT_LANG="$(cat /tmp/language)"
export DEFAULT_LANG="${DEFAULT_LANG}" && echo "export DEFAULT_LANG='${DEFAULT_LANG}'" >> ${CONFIG_FILE}
rm -f /tmp/language
