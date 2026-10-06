# Releasing the Lightroom Classic plug-in

An installable version requires a GitHub release with a ZIP package. A repository push alone does not publish the plug-in.

## Version and package

Update `VERSION` in `Info.lua` for each release. Use the same three-part version for the Git tag and include it in the release title, without a `v` prefix. Use a new patch version for a compatible documentation or code change.

From the repository root, create the package from the release commit:

```bash
git archive --format=zip --prefix=phototagai.lrplugin/ --output=../phototagai.lrplugin.zip HEAD
```

The ZIP must contain one top-level `phototagai.lrplugin/` directory with the plug-in files. Do not include local settings, catalogs, previews, test photos, credentials, or other private data. Inspect the archive before uploading it:

```bash
unzip -l ../phototagai.lrplugin.zip
```

## Publish and verify

Create a GitHub release from the matching version tag and attach the ZIP as `phototagai.lrplugin.zip`. Mark it as the latest release when it should become the current download. Confirm that the asset downloads, extracts into one plug-in directory, and loads in Lightroom Classic. Keep the previous working release available in case the new one needs to be replaced.
