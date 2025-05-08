local LrPrefs = import 'LrPrefs'
local LrView = import 'LrView'
local LrDialogs = import 'LrDialogs'
local LrHttp = import 'LrHttp'
local LrPasswords = import 'LrPasswords'

local prefs = LrPrefs.prefsForPlugin()

prefs.maxKeywords = prefs.maxKeywords or nil
prefs.minKeywords = prefs.minKeywords or nil
prefs.language = prefs.language or 'en'
prefs.customContext = prefs.customContext or nil
prefs.prohibitedCharacters = prefs.prohibitedCharacters or nil
prefs.maxDescriptionCharacters = prefs.maxDescriptionCharacters or nil
prefs.minDescriptionCharacters = prefs.minDescriptionCharacters or nil
prefs.maxTitleCharacters = prefs.maxTitleCharacters or nil
prefs.minTitleCharacters = prefs.minTitleCharacters or nil
prefs.useMetadataForContext = prefs.useMetadataForContext or false
prefs.useFileNameForContext = prefs.useFileNameForContext or false
prefs.singleWordKeywordsOnly = prefs.singleWordKeywordsOnly or false
prefs.disableTitleDescription = prefs.disableTitleDescription or false
prefs.beCreative = prefs.beCreative or false
prefs.titleCaseTitle = prefs.titleCaseTitle or false
prefs.requiredKeywords = prefs.requiredKeywords or nil
prefs.excludedKeywords = prefs.excludedKeywords or nil
prefs.externalApiType = prefs.externalApiType or 'phototagai'

return {
    sectionsForTopOfDialog = function(f, propertyTable)
        return {
            {
                title = "Settings",

                f:row {
                    f:static_text {
                        title = "PhotoTag.ai API token (required):",
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
                        width_in_chars = 20
                    },
                    f:push_button {
                        width = 150,
                        title = "Get PhotoTag.ai API token",
                        enabled = true,
                        action = function()
                            local url = "https://www.phototag.ai/api"
                            LrHttp.openUrlInBrowser(url)
                        end,
                    },
                },

                f:row {
                    f:static_text {
                        title = "OpenAI API key (optional):",
                    },
                    f:password_field {
                        value = LrView.bind {
                            key = 'openaiApiKey',
                            bind_to_object = prefs,
                            transform = function(openaiApiKeyValue)
                                if openaiApiKeyValue then
                                    LrPasswords.store("openai_api_key", openaiApiKeyValue)
                                end
                                return LrPasswords.retrieve("openai_api_key") or ""
                            end
                        },
                        width_in_chars = 20
                    },
                    f:push_button {
                        width = 150,
                        title = "Get OpenAI API key",
                        enabled = true,
                        action = function()
                            local url = "https://platform.openai.com/account/api-keys"
                            LrHttp.openUrlInBrowser(url)
                        end,
                    },
                },

                f:row {
                    f:static_text {
                        title = "Gemini API key (optional):",
                    },
                    f:password_field {
                        value = LrView.bind {
                            key = 'geminiApiKey',
                            bind_to_object = prefs,
                            transform = function(geminiApiKeyValue)
                                if geminiApiKeyValue then
                                    LrPasswords.store("gemini_api_key", geminiApiKeyValue)
                                end
                                return LrPasswords.retrieve("gemini_api_key") or ""
                            end
                        },
                        width_in_chars = 20
                    },
                    f:push_button {
                        width = 150,
                        title = "Get Gemini API key",
                        enabled = true,
                        action = function()
                            local url = "https://aistudio.google.com/app/apikey"
                            LrHttp.openUrlInBrowser(url)
                        end,
                    },
                },

            },
        }
    end,
}
