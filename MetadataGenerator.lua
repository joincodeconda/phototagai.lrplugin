local LrHttp = import 'LrHttp'
local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'
local LrFunctionContext = import 'LrFunctionContext'
local LrPrefs = import 'LrPrefs'
local LrApplication = import 'LrApplication'
local LrProgressScope = import 'LrProgressScope'
local LrView = import 'LrView'
local LrPasswords = import 'LrPasswords'
local LrFileUtils = import 'LrFileUtils'
local LrExportSession = import 'LrExportSession'
local LrPathUtils = import 'LrPathUtils'

local json = require 'dkjson'
local prefs = LrPrefs.prefsForPlugin()

local storedKeywords = {}

local function trim(s)
    return s:match'^%s*(.*%S)' or ''
end

local function createAndAddKeyword(photo, keywordName)
    keywordName = trim(keywordName)
    local catalog = photo.catalog
    local keyword = storedKeywords[keywordName] or catalog:createKeyword(keywordName, {}, true, nil, true)
    storedKeywords[keywordName] = keyword
    photo:addKeyword(keyword)
    return keyword
end

local function isValidParam(param)
    return param ~= nil and param ~= ""
end

local function exportJPEG(photo)
    local tempFolder = LrPathUtils.getStandardFilePath('temp')
    local exportSettings = {
        LR_export_destinationType = 'specificFolder',
        LR_export_destinationPathPrefix = tempFolder,
        LR_export_useSubfolder = false,
        LR_export_format = 'JPEG',
        LR_export_colorSpace = 'sRGB',
        LR_jpeg_quality = 80,
        LR_jpeg_limitSize = 0,
        LR_export_resolution = 240,
        LR_minimizeEmbeddedMetadata = true,
        LR_removeLocationMetadata = true,
    }

    local exportSession = LrExportSession({
        photosToExport = { photo },
        exportSettings = exportSettings
    })

    for _, rendition in exportSession:renditions() do
        local success, path = rendition:waitForRender()
        if success then
            return path
        end
    end

    return nil
end

function generateMetadata(progress, photo, callback)
    LrTasks.startAsyncTask(function()
        local apiToken = LrPasswords.retrieve("phototagai_token") or ""
        local url = "https://server.phototag.ai/api/keywords"

        if not isValidParam(apiToken) then
            LrDialogs.message("Error", "Please enter your PhotoTag.ai API token in the Plug-in Manager settings.")
            progress:done()
            return
        end

        if not photo then
            LrDialogs.message("Error", "Failed to load selected photo. Please try again or contact support.")
            progress:done()
            return
        end

        local photoPath = exportJPEG(photo)

        if not isValidParam(photoPath) then
            LrDialogs.message("Error", "Selected photo is not supported. Please contact support for assistance.")
            progress:done()
            return
        end

        local fileSize = LrFileUtils.fileAttributes(photoPath).fileSize
        if fileSize > 30 * 1024 * 1024 then
            LrDialogs.message("Error", "Selected photo is too large. Please contact support for assistance.")
            progress:done()
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
        if isValidParam(prefs.minKeywords) then
            table.insert(formData, { name = 'minKeywords', value = tostring(prefs.minKeywords) })
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

        local response = LrHttp.postMultipart(url, formData, headers, 15)

        if LrFileUtils.exists(photoPath) then
            LrFileUtils.delete(photoPath)
        end

        if response then
            local jsonResponse, _, err = json.decode(response)

            if err then
                LrDialogs.message("Error", "Failed to parse response from the PhotoTag.ai API. Please try again or contact support.")
                progress:done()
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

                    local existingKeywords = photo:getRawMetadata("keywords")
                    for _, existingKeyword in ipairs(existingKeywords) do
                        photo:removeKeyword(existingKeyword)
                    end

                    for _, keyword in ipairs(keywords) do
                        createAndAddKeyword(photo, keyword)
                    end
                end, { timeout = 60 })

                if not success then
                    LrDialogs.message("Error", "Could not update metadata. Please try again or contact support.")
                    progress:done()
                    return
                end
            else
                LrDialogs.message("Error", "Invalid response from the PhotoTag.ai API. Please try again or contact support.")
                progress:done()
                return
            end
        else
            LrDialogs.message("Error", "Failed to generate metadata. Please check your API token or network connection.")
            progress:done()
            return
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
                        title = "Max description characters (50-500):",
                        width = LrView.share 'label_width',
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'maxDescriptionCharacters',
                            bind_to_object = prefs,
                            transform = function(value)
                                if isValidParam(value) then
                                    prefs.minDescriptionCharacters = ""
                                end
                                return value
                            end,
                        },
                        width_in_chars = 5,
                    },
                },
                f:row {
                    f:static_text {
                        title = "Min description characters (5-200):",
                        width = LrView.share 'label_width',
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'minDescriptionCharacters',
                            bind_to_object = prefs,
                        },
                        width_in_chars = 5,
                        enabled = LrView.bind {
                            key = 'maxDescriptionCharacters',
                            transform = function(value)
                                return not isValidParam(value)
                            end,
                        },
                    },
                },
                f:row {
                    f:static_text {
                        title = "Max title characters (50-500):",
                        width = LrView.share 'label_width',
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'maxTitleCharacters',
                            bind_to_object = prefs,
                            transform = function(value)
                                if isValidParam(value) then
                                    prefs.minTitleCharacters = ""
                                end
                                return value
                            end,
                        },
                        width_in_chars = 5,
                    },
                },
                f:row {
                    f:static_text {
                        title = "Min title characters (5-200):",
                        width = LrView.share 'label_width',
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'minTitleCharacters',
                            bind_to_object = prefs,
                        },
                        width_in_chars = 5,
                        enabled = LrView.bind {
                            key = 'maxTitleCharacters',
                            transform = function(value)
                                return not isValidParam(value)
                            end,
                        },
                    },
                },
            },

            f:group_box {
                title = "Keywords Settings",
                f:row {
                    f:static_text {
                        title = "Maximum keyword count (5-200):",
                        width = LrView.share 'label_width',
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'maxKeywords',
                            bind_to_object = prefs,
                            transform = function(value)
                                if isValidParam(value) then
                                    prefs.minKeywords = ""
                                end
                                return value
                            end,
                        },
                        width_in_chars = 5,
                    },
                },
                f:row {
                    f:static_text {
                        title = "Minimum keyword count (5-40):",
                        width = LrView.share 'label_width',
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'minKeywords',
                            bind_to_object = prefs,
                        },
                        width_in_chars = 5,
                        enabled = LrView.bind {
                            key = 'maxKeywords',
                            transform = function(value)
                                return not isValidParam(value)
                            end,
                        },
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

                local function processNextPhoto(index, numTasks)
                    if index > #selectedPhotos then
                        return
                    end

                    local photo = selectedPhotos[index]

                    generateMetadata(progress, photo, function()
                        if index % numTasks == 0 then
                            progress:setPortionComplete(index, #selectedPhotos)
                        end
                        if index < #selectedPhotos and not progress:isCanceled() then
                            processNextPhoto(index + numTasks, numTasks)
                        else
                            progress:done()
                        end
                    end)

                end

                local numParallelTasks = 3
                for i = 1, numParallelTasks do
                    processNextPhoto(i, numParallelTasks)
                end
            end)
        end
    end)
end


showDialogAndGenerateMetadata()
