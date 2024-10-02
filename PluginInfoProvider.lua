local LrPrefs = import 'LrPrefs'
local LrView = import 'LrView'
local LrDialogs = import 'LrDialogs'
local LrHttp = import 'LrHttp'
local LrPasswords = import 'LrPasswords'

local prefs = LrPrefs.prefsForPlugin()

prefs.maxKeywords = prefs.maxKeywords or false
prefs.language = prefs.language or false
prefs.customContext = prefs.customContext or false
prefs.maxDescriptionCharacters = prefs.maxDescriptionCharacters or false
prefs.minDescriptionCharacters = prefs.minDescriptionCharacters or false
prefs.maxTitleCharacters = prefs.maxTitleCharacters or false
prefs.minTitleCharacters = prefs.minTitleCharacters or false
prefs.useFileNameForContext = prefs.useFileNameForContext or false
prefs.singleWordKeywordsOnly = prefs.singleWordKeywordsOnly or false
prefs.requiredKeywords = prefs.requiredKeywords or false
prefs.excludedKeywords = prefs.excludedKeywords or false

return {
    sectionsForTopOfDialog = function(f, propertyTable)
        return {
            {
                title = "Settings",

                f:row {
                    f:static_text {
                        title = "API token (required):",
                    },
                    f:password_field {
                        value = LrView.bind {
                            key = 'apiToken',
                            bind_to_object = prefs,
                            transform = function(apiTokenValue)
                                if apiTokenValue then
                                    LrPasswords.store("phototagai_token", apiTokenValue)
                                end
                                return LrPasswords.retrieve("phototagai_token") or ""
                            end
                        },
                        width_in_chars = 30
                    },
                    f:push_button {
                        width = 150,
                        title = "Get API token",
                        enabled = true,
                        action = function()
                            local url = "https://www.phototag.ai/api"
                            LrHttp.openUrlInBrowser(url)
                        end,
                    },
                },

                f:row {
                    f:static_text {
                        title = "Keyword count:",
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'maxKeywords',
                            bind_to_object = prefs,
                        },
                        width_in_chars = 5,
                    },
                },

                f:row {
                    f:static_text {
                        title = "Output language:",
                    },
                    f:popup_menu {
                        value = LrView.bind {
                            key = 'language',
                            bind_to_object = prefs,
                        },
                        items = {
                            { title = "English", value = "en" },
                            { title = "Spanish", value = "es" },
                            { title = "French", value = "fr" },
                            { title = "Italian", value = "it" },
                            { title = "Portuguese", value = "pt" },
                            { title = "German", value = "de" },
                            { title = "Polish", value = "pl" },
                            { title = "Russian", value = "ru" },
                            { title = "Ukrainian", value = "uk" },
                            { title = "Hindi", value = "hi" },
                            { title = "Indonesian", value = "id" },
                            { title = "Japanese", value = "ja" },
                            { title = "Korean", value = "ko" },
                            { title = "Chinese", value = "zh" },
                            { title = "Hebrew", value = "he" },
                            { title = "Arabic", value = "ar" },
                        },
                    },
                },

                f:row {
                    f:static_text {
                        title = "Max title characters:",
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'maxTitleCharacters',
                            bind_to_object = prefs,
                        },
                        width_in_chars = 5,
                    },
                },

                f:row {
                    f:static_text {
                        title = "Min title characters:",
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'minTitleCharacters',
                            bind_to_object = prefs,
                        },
                        width_in_chars = 5,
                    },
                },

                f:row {
                    f:static_text {
                        title = "Max description characters:",
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'maxDescriptionCharacters',
                            bind_to_object = prefs,
                        },
                        width_in_chars = 5,
                    },
                },
                f:row {
                    f:static_text {
                        title = "Min description characters:",
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'minDescriptionCharacters',
                            bind_to_object = prefs,
                        },
                        width_in_chars = 5,
                    },
                },

                f:row {
                    f:checkbox {
                        title = "Single word keywords only",
                        value = LrView.bind {
                            key = 'singleWordKeywordsOnly',
                            bind_to_object = prefs,
                        },
                    },
                },

                f:row {
                    f:checkbox {
                        title = "Use file names for context",
                        value = LrView.bind {
                            key = 'useFileNameForContext',
                            bind_to_object = prefs,
                        },
                    },
                },

                f:row {
                    f:static_text {
                        title = "Custom context:",
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'customContext',
                            bind_to_object = prefs,
                        },
                        width_in_chars = 30,
                    },
                },

                f:row {
                    f:static_text {
                        title = "Required keywords (comma-separated):",
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'requiredKeywords',
                            bind_to_object = prefs,
                        },
                        width_in_chars = 30,
                    },
                },

                f:row {
                    f:static_text {
                        title = "Excluded keywords (comma-separated):",
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'excludedKeywords',
                            bind_to_object = prefs,
                        },
                        width_in_chars = 30,
                    },
                },
            },
        }
    end,
}
