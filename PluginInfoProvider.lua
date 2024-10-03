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


            },
        }
    end,
}
