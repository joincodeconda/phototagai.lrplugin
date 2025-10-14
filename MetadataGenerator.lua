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

local errorCount = 0
local errorMessages = {}
local errorFiles = {}
local storedKeywords = {}

local function contains(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return true
        end
    end
    return false
end

local function logError(message, file)
    errorCount = errorCount + 1
    if message and not contains(errorMessages, message) then
        table.insert(errorMessages, message)
    end
    if file then
        table.insert(errorFiles, file)
    end
end

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
        LR_format = 'JPEG',
        LR_export_colorSpace = 'sRGB',
        LR_jpeg_useLimitSize = true,
        LR_jpeg_limitSize = 10 * 1024,
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

function generateMetadata(photo, callback)
    LrTasks.startAsyncTask(function()
        local apiToken = LrPasswords.retrieve("phototagai_token") or ""
        local url = "https://server.phototag.ai/api/keywords"

        if not isValidParam(apiToken) then
            logError("Please enter your PhotoTag.ai API token in the plug-in settings under 'File > Plug-in Manager'.", nil)
            callback()
            return
        end

        local fileName = photo:getFormattedMetadata("fileName") or nil

        if not photo then
            logError("File failed to load.", fileName)
            callback()
            return
        end

        local photoPath = exportJPEG(photo)

        if not isValidParam(photoPath) then
            if LrFileUtils.exists(photoPath) then
                LrFileUtils.delete(photoPath)
            end
            logError("File was not supported.", fileName)
            callback()
            return
        end

        local fileSize = LrFileUtils.fileAttributes(photoPath).fileSize
        if fileSize > 30 * 1024 * 1024 then
            if LrFileUtils.exists(photoPath) then
                LrFileUtils.delete(photoPath)
            end
            logError("File exceeded size limit.", fileName)
            callback()
            return
        end

        local cleanApiToken = trim(apiToken or "")
        local headers = {
            { field = 'Authorization', value = 'Bearer ' .. cleanApiToken },
            { field = 'Accept', value = 'application/json' },
            { field = 'User-Agent', value = 'LightroomPlugin-PhotoTagAI' },
        }

        local formData = {
            { name = 'file', fileName = photoPath, filePath = photoPath },
        }

        local context = ""
        if isValidParam(prefs.customContext) then
            context = prefs.customContext
        end
        if prefs.useMetadataForContext then
            local city = trim(photo:getFormattedMetadata("city") or photo:getRawMetadata("city") or "")
            local state = trim(photo:getFormattedMetadata("stateProvince") or photo:getRawMetadata("stateProvince") or photo:getFormattedMetadata("state") or photo:getRawMetadata("state") or "")
            local country = trim(photo:getFormattedMetadata("country") or photo:getRawMetadata("country") or "")

            if isValidParam(city) then
                if #context > 0 then
                    context = context .. "; City: " .. city
                else
                    context = "City: " .. city
                end
            end

            if isValidParam(state) then
                if #context > 0 then
                    context = context .. "; State: " .. state
                else
                    context = "State: " .. state
                end
            end

            if isValidParam(country) then
                if #context > 0 then
                    context = context .. "; Country: " .. country
                else
                    context = "Country: " .. country
                end
            end

            local existingTitle = photo:getFormattedMetadata("title") or ""
            local existingDescription = photo:getFormattedMetadata("caption") or ""

            if isValidParam(existingTitle) then
                if #context > 0 then
                    context = context .. "; " .. existingTitle
                else
                    context = existingTitle
                end
            end

            if isValidParam(existingDescription) then
                if #context > 0 then
                    context = context .. "; " .. existingDescription
                else
                    context = existingDescription
                end
            end
        end
        if isValidParam(context) then
            table.insert(formData, { name = 'customContext', value = context })
        end
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
        if isValidParam(prefs.prohibitedCharacters) then
            table.insert(formData, { name = 'prohibitedCharacters', value = prefs.prohibitedCharacters })
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
        if prefs.beCreative then
            table.insert(formData, { name = 'beCreative', value = tostring(prefs.beCreative) })
        end
        if not prefs.saveFile then
            table.insert(formData, { name = 'saveFile', value = 'false' })
        end
        if prefs.aiModelType then
            table.insert(formData, { name = 'aiModelType', value = prefs.aiModelType })
        end
        if prefs.titleCaseTitle then
            table.insert(formData, { name = 'titleCaseTitle', value = tostring(prefs.titleCaseTitle) })
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
        if prefs.disableKeywords then
            table.insert(formData, { name = 'disableKeywords', value = tostring(prefs.disableKeywords) })
        end

        local response = LrHttp.postMultipart(url, formData, headers, 45)

        if LrFileUtils.exists(photoPath) then
            LrFileUtils.delete(photoPath)
        end

        if response then
            local jsonResponse, _, err = json.decode(response)

            if err or not jsonResponse then
                logError("Failed to parse API response.", fileName)
                callback()
                return
            end

            if jsonResponse.error then
                logError(tostring(jsonResponse.error) .. ".", fileName)
                callback()
                return
            elseif jsonResponse.data then
                local title = jsonResponse.data.title
                local description = jsonResponse.data.description
                local keywords = jsonResponse.data.keywords

                local catalog = LrApplication.activeCatalog()

                local success = catalog:withWriteAccessDo("Update Metadata", function()
                    if not prefs.disableTitleDescription then
                        photo:setRawMetadata('title', title)
                        photo:setRawMetadata('caption', description)
                    end

                    if not prefs.disableKeywords then
                        local existingKeywords = photo:getRawMetadata("keywords")
                        if not prefs.preserveExistingKeywords then
                            for _, existingKeyword in ipairs(existingKeywords) do
                                photo:removeKeyword(existingKeyword)
                            end
                        end

                        for _, keyword in ipairs(keywords) do
                            createAndAddKeyword(photo, keyword)
                        end
                    end
                end, { timeout = 60 })

                if not success then
                    logError("Could not update metadata.", fileName)
                    callback()
                    return
                end
            else
                logError("Invalid response from API.", fileName)
                callback()
                return
            end
        else
            logError("Failed to generate metadata.", fileName)
            callback()
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
                    f:checkbox {
                        title = "Save file on web platform",
                        value = LrView.bind {
                            key = 'saveFile',
                            bind_to_object = prefs,
                        },
                    },
                },
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
                            { title = "Dutch", value = "nl" },
                            { title = "Romanian", value = "ro" },
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
                        title = "AI model:",
                        width = LrView.share 'label_width',
                    },
                    f:popup_menu {
                        value = LrView.bind {
                            key = 'aiModelType',
                            bind_to_object = prefs,
                        },
                        items = {
                            { title = "Precision, default (high consistency)", value = "precision" },
                            { title = "Lightning (allows explicit content, fast results)", value = "lightning" },
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
                    f:static_text {
                        title = "Prohibited characters:",
                        width = LrView.share 'label_width',
                    },
                    f:edit_field {
                        value = LrView.bind {
                            key = 'prohibitedCharacters',
                            bind_to_object = prefs,
                        },
                        width_in_chars = 15,
                    },
                },
                f:row {
                    f:checkbox {
                        title = "Use metadata for context",
                        value = LrView.bind {
                            key = 'useMetadataForContext',
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
            },

            f:group_box {
                title = "Title and Caption Settings",
                f:row {
                    f:checkbox {
                        title = "Disable title and caption generation",
                        value = LrView.bind {
                            key = 'disableTitleDescription',
                            bind_to_object = prefs,
                        },
                    },
                },
                f:row {
                    f:static_text {
                        title = "Max caption characters (50-500):",
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
                        title = "Min caption characters (5-200):",
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
                f:row {
                    f:checkbox {
                        title = "Title case capitalization for titles",
                        value = LrView.bind {
                            key = 'titleCaseTitle',
                            bind_to_object = prefs,
                        },
                    },
                },
                f:row {
                    f:checkbox {
                        title = "Creative titles and captions",
                        value = LrView.bind {
                            key = 'beCreative',
                            bind_to_object = prefs,
                        },
                    },
                },

            },

            f:group_box {
                title = "Keywords Settings",
                f:row {
                    f:checkbox {
                        title = "Disable keywords generation",
                        value = LrView.bind {
                            key = 'disableKeywords',
                            bind_to_object = prefs,
                        },
                    },
                },
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
                f:row {
                    f:checkbox {
                        title = "Preserve existing keywords",
                        value = LrView.bind {
                            key = 'preserveExistingKeywords',
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

                errorCount = 0
                errorMessages = {}
                errorFiles = {}

                local function processNextPhoto(index, numTasks)
                    if index > #selectedPhotos then
                        return
                    end

                    local photo = selectedPhotos[index]

                    generateMetadata(photo, function()
                        if index % numTasks == 1 then
                            progress:setPortionComplete(index, #selectedPhotos)
                        end
                        if index < #selectedPhotos and not progress:isCanceled() then
                            processNextPhoto(index + numTasks, numTasks)
                        elseif index == #selectedPhotos then
                            progress:done()
                            if errorCount > 0 then
                                local errorMessage = "Generated metadata for " .. (#selectedPhotos - errorCount) .. " out of " .. #selectedPhotos .. " photo(s)."
                                if #errorMessages > 0 then
                                    errorMessage = errorMessage .. " Error(s):"
                                    for i = 1, math.min(5, #errorMessages) do
                                        errorMessage = errorMessage .. " " .. errorMessages[i]
                                    end
                                    if #errorMessages > 5 then
                                        errorMessage = errorMessage .. " (and more...)"
                                    end
                                end
                                if #errorFiles > 0 then
                                    errorMessage = errorMessage .. " Failed file(s):"
                                    for i = 1, math.min(5, #errorFiles) do
                                        errorMessage = errorMessage .. " " .. errorFiles[i]
                                    end
                                    if #errorFiles > 5 then
                                        errorMessage = errorMessage .. " (and more...)"
                                    end
                                end
                                errorMessage = errorMessage .. " Please contact support for assistance."
                                LrDialogs.message("Alert", errorMessage)
                            else
                                LrDialogs.message("Success", "Metadata successfully generated for " .. #selectedPhotos .. " photo(s).")
                            end
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
