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
prefs.saveFile = prefs.saveFile or true

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
