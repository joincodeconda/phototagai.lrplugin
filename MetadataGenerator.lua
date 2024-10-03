local LrHttp = import 'LrHttp'
local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'
local LrFunctionContext = import 'LrFunctionContext'
local LrPrefs = import 'LrPrefs'
local LrApplication = import 'LrApplication'
local LrProgressScope = import 'LrProgressScope'
local LrView = import 'LrView'
local LrPasswords = import 'LrPasswords'

local json = require 'dkjson'

local prefs = LrPrefs.prefsForPlugin()

local debug = false

local function findKeywordByName(catalog, keywordName)
    local allKeywords = catalog:getKeywords()
    for _, keyword in ipairs(allKeywords) do
        if keyword:getName() == keywordName then
            return keyword
        end
    end
    return nil
end

local function isValidParam(param)
    return param ~= nil and param ~= ""
end

function generateMetadata(photo, callback)
    LrTasks.startAsyncTask(function()
        local apiToken = LrPasswords.retrieve("phototagai_token") or ""
        local url = "https://server.phototag.ai/api/keywords"

        if not isValidParam(apiToken) then
            LrDialogs.message("Notice", "Please enter your PhotoTag.ai API token in the Plug-in Manager settings.")
            callback()
            return
        end

        if not photo then
            if debug then
                LrDialogs.message("Error", "Invalid photo.")
            end
            callback()
            return
        end

        local photoPath = photo:getRawMetadata('path')

        if not isValidParam(photoPath) then
            if debug then
                LrDialogs.message("Error", "Invalid photo path.")
            end
            callback()
            return
        end

        local headers = {
            { field = 'Authorization', value = 'Bearer ' .. apiToken },
        }

        local formData = {
            { name = 'file', fileName = photoPath, filePath = photoPath },
        }

        if isValidParam(prefs.language) then
            table.insert(formData, { name = 'language', value = prefs.language })
        end
        if isValidParam(prefs.maxKeywords) then
            table.insert(formData, { name = 'maxKeywords', value = tostring(prefs.maxKeywords) })
        end
        if isValidParam(prefs.requiredKeywords) then
            table.insert(formData, { name = 'requiredKeywords', value = prefs.requiredKeywords })
        end
        if isValidParam(prefs.customContext) then
            table.insert(formData, { name = 'customContext', value = prefs.customContext })
        end
        if isValidParam(prefs.maxDescriptionCharacters) then
            table.insert(formData, { name = 'maxDescriptionCharacters', value = tostring(prefs.maxDescriptionCharacters) })
        end
        if isValidParam(prefs.minDescriptionCharacters) then
            table.insert(formData, { name = 'minDescriptionCharacters', value = tostring(prefs.minDescriptionCharacters) })
        end
        if isValidParam(prefs.maxTitleCharacters) then
            table.insert(formData, { name = 'maxTitleCharacters', value = tostring(prefs.maxTitleCharacters) })
        end
        if isValidParam(prefs.minTitleCharacters) then
            table.insert(formData, { name = 'minTitleCharacters', value = tostring(prefs.minTitleCharacters) })
        end
        if prefs.useFileNameForContext then
            table.insert(formData, { name = 'useFileNameForContext', value = tostring(prefs.useFileNameForContext) })
        end
        if prefs.singleWordKeywordsOnly then
            table.insert(formData, { name = 'singleWordKeywordsOnly', value = tostring(prefs.singleWordKeywordsOnly) })
        end
        if isValidParam(prefs.excludedKeywords) then
            table.insert(formData, { name = 'excludedKeywords', value = prefs.excludedKeywords })
        end

        local response, responseHeaders = LrHttp.postMultipart(url, formData, headers)

        if response then
            local jsonResponse, _, err = json.decode(response)

            if err and debug then
                LrDialogs.message("Error", "Failed to parse JSON response: " .. err)
                callback()
                return
            end

            if jsonResponse and jsonResponse.data then
                local title = jsonResponse.data.title
                local description = jsonResponse.data.description
                local keywords = jsonResponse.data.keywords

                local catalog = LrApplication.activeCatalog()

                local success = catalog:withWriteAccessDo("Update Metadata", function()
                    photo:setRawMetadata('title', title)
                    photo:setRawMetadata('caption', description)

                    for _, keyword in ipairs(keywords) do
                        local existingKeyword = findKeywordByName(catalog, keyword)
                        if not existingKeyword then
                            existingKeyword = catalog:createKeyword(keyword, {}, false, nil, true)
                        end
                        photo:addKeyword(existingKeyword)
                    end
                end, { timeout = 30 })

                if not success and debug then
                    LrDialogs.message("Error", "Could not update metadata. Another write operation is blocking it.")
                end
            elseif debug then
                LrDialogs.message("Error", "Invalid response from the PhotoTag.ai API.")
            end
        elseif debug then
            LrDialogs.message("Error", "Failed to generate metadata. Please check your API token or network connection.")
        end

        callback()
    end)
end

function showDialogAndGenerateMetadata()

    LrFunctionContext.callWithContext('showDialogAndGenerateMetadata', function(context)
        local catalog = LrApplication.activeCatalog()
        local selectedPhotos = catalog:getTargetPhotos()

        local f = LrView.osFactory()
        local contents = f:column {
            bind_to_object = prefs,
            spacing = f:control_spacing(),

            f:row {
                spacing = f:label_spacing(),
                f:static_text {
                    title = tostring(#selectedPhotos) .. " photo(s) selected",
                    font = "<system/bold>",
                    width = LrView.share 'label_width',
                },
            },

            f:group_box {
                title = "General Settings",
                f:row {
                    f:static_text {
                        title = "Output language:",
                        width = LrView.share 'label_width',
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
                        title = "Custom context:",
                        width = LrView.share 'label_width',
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
                    f:checkbox {
                        title = "Use file names for context",
                        value = LrView.bind {
                            key = 'useFileNameForContext',
                            bind_to_object = prefs,
                        },
                    },
                },
            },

            f:group_box {
                title = "Title and Description Settings",
                f:row {
                    f:static_text {
                        title = "Max description characters:",
                        width = LrView.share 'label_width',
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
                        width = LrView.share 'label_width',
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
                    f:static_text {
                        title = "Max title characters:",
                        width = LrView.share 'label_width',
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
                        width = LrView.share 'label_width',
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'minTitleCharacters',
                            bind_to_object = prefs,
                        },
                        width_in_chars = 5,
                    },
                },
            },

            f:group_box {
                title = "Keywords Settings",
                f:row {
                    f:static_text {
                        title = "Keyword count:",
                        width = LrView.share 'label_width',
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
                        title = "Required keywords (comma-separated):",
                        width = LrView.share 'label_width',
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
                        width = LrView.share 'label_width',
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'excludedKeywords',
                            bind_to_object = prefs,
                        },
                        width_in_chars = 30,
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
            },
        }

        local result = LrDialogs.presentModalDialog({
            title = "Generate Metadata for Selected Photos",
            contents = contents,
            actionVerb = "Start",
            cancelVerb = "Cancel"
        })

        if result == "ok" then
            LrFunctionContext.callWithContext('generateMetadata', function(context)
                local progress = LrProgressScope({
                    title = "Generating metadata for selected photos...",
                })
                progress:setCancelable(true)
                progress:setPortionComplete(0, #selectedPhotos)

                local function processNextPhoto(index)
                    local photo = selectedPhotos[index]

                    generateMetadata(photo, function()
                        progress:setPortionComplete(index, #selectedPhotos)
                        if index < #selectedPhotos and not progress:isCanceled() then
                            processNextPhoto(index + 1)
                        else
                            progress:done()
                        end
                    end)
                end

                processNextPhoto(1)
            end)
        end
    end)
end


showDialogAndGenerateMetadata()
