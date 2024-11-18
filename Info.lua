return {
    LrSdkVersion = 5.0,
    LrSdkMinimumVersion = 5.0,
    LrToolkitIdentifier = "com.phototagai.metadata.generator",
    LrPluginName = "PhotoTag.ai Plug-in",
    LrPluginInfoUrl = "https://www.phototag.ai/",
    LrPluginInfoProvider = "PluginInfoProvider.lua",
    LrExportMenuItems = {
        {
            title = "Generate Metadata for Selected Photos",
            file = "MetadataGenerator.lua",
            enabledWhen = "photosSelected",
        },
    },
    LrLibraryMenuItems = {
        {
            title = "Generate Metadata for Selected Photos",
            file = "MetadataGenerator.lua",
            enabledWhen = "photosSelected",
        },
    },
    VERSION = { major = 1, minor = 1, revision = 2 },
}
